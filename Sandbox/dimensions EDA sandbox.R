# Dimensions EDA sandbox
# 6.10.2025

# PURPOSE:  Establish the connection, review the tables, run "skimr", 
#   investigate queries by Kaidon

# SUMMARY:  The queries seem to be missing almost a third of the
# PI's from the proposal data!  This is a long ways away from "I suspect the majority have been mapped" !

###########
## QUERY ##
###########

# Obtain data

keyring::keyring_unlock(keyring = "BIPR", password = "Excelsior!")

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), Driver = "oracle", Host = "ocm-campus01.it.utah.edu", 
                         SVC = keyring::key_list(keyring = "BIPR")[1, 1], 
                         UID = keyring::key_list(keyring = "BIPR")[1, 2], 
                         PWD = keyring::key_get(keyring = "BIPR", service = keyring::key_list(keyring = "BIPR")[1, 1]), 
                         Port = 2080)


crosswalkQuery <- "
select *
from vpr_dimensions.dimensions_crosswalk
"


# crosswalkQuery <- "
# select distinct
#               confidence,
#               confidence_desc
# from vpr_dimensions.dimensions_crosswalk
# order by confidence;
# "

cwData <- dbGetQuery(con.ds,
                      crosswalkQuery)

ageQuery <- "
SELECT *
FROM vpr_dimensions.ds_uu_academic_age
"

ageQuery <- "
select
               dc.emplid,
               daa.first_pub_yr,
               daa.last_pub_yr,
               daa.total_publications,
               daa.first_pub_title,
               daa.first_pub_id,
               daa.first_grant_yr,
               daa.last_grant_yr,
               daa.total_grants,
               dc.dim_id,
               dc.confidence,
               dc.confidence_desc
from vpr_dimensions.dimensions_crosswalk dc
left join vpr_dimensions.ds_uu_academic_age daa on daa.uu_researcher_dim_id = dc.dim_id
where confidence <> 'W'

"

ageData <- dbGetQuery(con.ds,
                      ageQuery)

DBI::dbDisconnect(con.ds)

library(skimr)

skim(cwData)
skim(ageData)

# let's compare to each other

cwData$EMPLID[!cwData$EMPLID %in% ageData$EMPLID] |> unique() |> length() # 174
ageData$EMPLID[!ageData$EMPLID %in% cwData$EMPLID] |> unique() |> length() # 0 per join definition

# let's compare to the proposals data that I've been using

# PREP SCRIPT

source(here::here("Prep scripts","Adjusting prepData and loading things.R"))

prepData$PROPOSAL_PI_EMPLID[!(prepData$PROPOSAL_PI_EMPLID %in% cwData$EMPLID)] |> unique() |> length()
# 812

prepData$PROPOSAL_PI_EMPLID[!(prepData$PROPOSAL_PI_EMPLID %in% ageData$EMPLID)] |> unique() |> length()
# 841

# That's a pretty big number

missingEmplid <- prepData$PROPOSAL_PI_EMPLID[!(prepData$PROPOSAL_PI_EMPLID %in% ageData$EMPLID)] |> unique()

# I need to describe these missing PI's.  Are they one-off losers?  Or highly prolific?

# In any case, I think we can move this to a stand-alone report.

# there, I need to identify all of the missing values, maybe do an ML project to identify them
# see if they are randomly placed



