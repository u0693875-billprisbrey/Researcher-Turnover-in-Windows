# Query sandbox
# All of the emplids and PI's in the prepData


library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), 
                         Driver = "oracle", 
                         Host = "ocm-campus01.it.utah.edu", 
                         SVC = "biprodusr.sys.utah.edu",
                         UID = Sys.getenv("userid"),
                         PWD = Sys.getenv("pwd"),
                         Port = 2080)


propQuery <- "SELECT *
              FROM OSP_PROPOSALS_VW
              WHERE PROPOSAL_UPLOAD_DATE <= TO_DATE('2025-04-17', 'YYYY-MM-DD')
"

propData <- dbGetQuery(con.ds, propQuery)

piQuery <- "SELECT DISTINCT PROPOSAL_PI_EMPLID
              FROM OSP_PROPOSALS_VW"

piData <- dbGetQuery(con.ds, piQuery)

# ok, now I need to filter this in my Shiny app
# how quickly can I do this?

# I guess it's a radio button ?  A TRUE/FALSE?
# What's the query?

piJourneyQuery <- "SELECT * FROM ds_hr.EMPL_AGE_RANGE_ACTION_MV_V 
             WHERE EFFDT < TRUNC(SYSDATE) AND
             EMPLID IN (SELECT DISTINCT PROPOSAL_PI_EMPLID FROM OSP_PROPOSALS_VW)"  

piJourney <- dbGetQuery(con.ds, piJourneyQuery)


journeyQuery <- "SELECT * FROM ds_hr.EMPL_AGE_RANGE_ACTION_MV_V 
             WHERE 1 = 0" # just row names

journeyData <- dbGetQuery(con.ds, journeyQuery)

# I need to bake in my filter criteria used in "prepData"
# should be doable

# No PI's in "Engineering" dept?

testQuery <- "
SELECT * FROM ds_hr.EMPL_AGE_RANGE_ACTION_MV_V 
WHERE EFFDT < TRUNC(SYSDATE) 
 
AND EMPLID IN (SELECT DISTINCT PROPOSAL_PI_EMPLID FROM OSP_PROPOSALS_VW)"

# AND DEPT_NAME IN ('Engineering')

jDat <- dbGetQuery(con.ds, testQuery)

# Ok, that's great.

# Can I select only the PI's in eAwards?  I mean, they got designated a PI somehow

# Nah, I'd rather spend my time on calculating concurrent jobs
# And after that, the other categories that I've got



