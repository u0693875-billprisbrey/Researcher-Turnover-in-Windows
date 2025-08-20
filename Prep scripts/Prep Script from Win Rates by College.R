# Preparatory Script
# Combining "Developing machine learning models per college.Rmd" and "Win Rates by College"
# Updated for Researcher Turn-over on 4.17.2025
# initiated 2.04.2025

# PURPOSE: To create one multi-use prep script for reports
# and especially powerpoints and powerpoint children.

# BACKGROUND:  I thought loading the cleaned data was sufficient.
# But now I find myself copying and pasting while I create reports
# and powerpoints on the same material.  And I'd like to experiment
# with creating powerpoint children, as my mega-powerpoint is 
# starting to get unwieldy.  The idea is a few slides per topic
# that can be in an appendix or in the main body.

#  So I am experimenting with the prep script and subject-specific
# markdown children.

# PROVENANCE:
#  On 4.17.2025 rather than upload prepData, I copied and pasted the section from 
#  "Developing machine learning models per college.Rmd" from Grants-Exploratory project
#  This is initially copied from "Win rates by college.Rmd" on 4 Feb 2025.

# DICSUSSION:
#  Not sure I want to include the "cuts" and "aggregations" in here, but eh I'll give it a try.
#  Now let's give it a test run

###############
## LIBRARIES ##
###############

library(tidyverse)
library(skimr)
library(plotly)
library(RColorBrewer)
library(scales)
library(kableExtra)
#library(tm)
library(caret)
library(xgboost)
library(FactoMineR)
library(factoextra)
#library(dynamicTreeCut)


###############
## FUNCTIONS ##
###############

lapply(list.files(here::here("Functions"), full.names = TRUE), source)

##########
## LOAD ##
##########

cleanData <- readRDS(here::here("Data","cleanData17Apr2025.rds"))

# prepData code is mostly duplicated from "Developing machine learning models per college.rds" so I don't
# have to copy that report over into this project.

# modelAll and collegeModels aren't relevant to this project.

# prepData <- readRDS(here::here("Data", "prepData from Developing machine learning models per college.rds"))
# modelAll <- readRDS(here::here("Robjects", "All Colleges with cardinality substitutions from Developing machine learning models.rds"))
# collegeModels <- readRDS(here::here("Robjects", "Per five college groups with cardinality substitutions from Developing machine learning models.rds"))

# Date extraction

dateColumns <- colnames(cleanData)[sapply(cleanData, function(col) inherits(col, c("POSIXct", "POSIXt")))]

interim <-lapply(dateColumns, function(dt){
  
  
  theWeek <- isoweek(cleanData[,dt])
  theMonth <- month(cleanData[,dt])
  # theYear <- year(cleanData[,dt]) # I don't want to use variation by year to predict
  
  return(data.frame(week=theWeek, month = theMonth)) #, year = theYear))
  
})
names(interim) <- dateColumns

dateExtraction <- do.call(cbind, interim)

###############################
## Calculate prior win rates ##
###############################

##########################
## PRIOR WIN RATE BY PI ##
##########################

piYr <- elapsed(target = "PROPOSAL_PI_EMPLID", date = "PROPOSAL_UPLOAD_DATE", period = "years", data = cleanData)

piYr$each$interval_floor <- floor(piYr$each$interval)

intervalPriors_pi <- lapply(1:max(piYr$elapsed$interval),
                            function(x) {
                              
                              thePrior <- calculatePriors(data = piYr$elapsed, targetInterval = x)      
                              thePrior$interval_floor <- x
                              names(thePrior)[grepl("prior", names(thePrior))] <- "priorPI"
                              thePrior$PROPOSAL_PI_EMPLID <- row.names(thePrior)
                              row.names(thePrior) <- NULL
                              return(thePrior)     
                              
                            })

intervalFrame_pi <- do.call(rbind, intervalPriors_pi)


priorsAdded_pi <- merge(piYr$each, intervalFrame_pi, by.x = c( "PROPOSAL_PI_EMPLID", "interval_floor"), by.y = c("PROPOSAL_PI_EMPLID", "interval_floor") , all.x = TRUE)


###########################
## PRIOR WIN RATE BY ORG ##
###########################

orgYr <- elapsed(target = "PROPOSAL_ORG", date = "PROPOSAL_UPLOAD_DATE", period = "years", data = cleanData)

orgYr$each$interval_floor <- floor(orgYr$each$interval)

intervalPriors_org <- lapply(1:max(orgYr$elapsed$interval),
                             function(x) {
                               
                               thePrior <- calculatePriors(data = orgYr$elapsed, targetInterval = x)      
                               thePrior$interval_floor <- x
                               names(thePrior)[grepl("prior", names(thePrior))] <- "priorOrg"
                               thePrior$PROPOSAL_ORG <- row.names(thePrior)
                               row.names(thePrior) <- NULL
                               return(thePrior)     
                               
                             })

intervalFrame_org <- do.call(rbind, intervalPriors_org)


priorsAdded_org <- merge(orgYr$each, intervalFrame_org, by.x = c( "PROPOSAL_ORG", "interval_floor"), by.y = c("PROPOSAL_ORG", "interval_floor") , all.x = TRUE)

#################################################
## Impute year zero win rates by college group ##
#################################################

# Overall win rate in the year 0 per PI

intervalCounts <- aggregate(cbind(win,loss,count) ~ interval, data = piYr$elapsed[piYr$elapsed$year < 2023,], sum, na.rm = TRUE )

filter <- intervalCounts$interval == 0
overallZero <- intervalCounts$win[filter]/intervalCounts$count[filter]

# Identify duplicate PI's per college 

theDupes <- unique(cleanData[,c("PROPOSAL_COLLEGE", "PROPOSAL_PI_EMPLID")]) |>
  (\(x){table(x[,2])})() |>
  (\(x){x[x>1]})() |>
  names()

# length(theDupes) # 256
# Dupes will be filtered out

theColleges <- unique(cleanData$PROPOSAL_COLLEGE)

collegeList <- list(
  Med = "Spencer Fox Eccles School of Medicine",
  Engr = "The John and Marcia Price College of Engineering",
  Science = "College of Science",
  Hunt = "Huntsman Cancer Institute",
  Rest = theColleges[!theColleges %in% c(
    "Spencer Fox Eccles School of Medicine",
    "The John and Marcia Price College of Engineering",
    "College of Science",
    "Huntsman Cancer Institute"
  )]
  
)

intervalCounts_college <- lapply(collegeList, function(x){
  
  collegeFilter <- piYr$elapsed$PROPOSAL_PI_EMPLID %in% unique(cleanData$PROPOSAL_PI_EMPLID[cleanData$PROPOSAL_COLLEGE %in% x])
  dupesFilter <- !piYr$elapsed$PROPOSAL_PI_EMPLID %in% theDupes        
  
  theAgg <- aggregate(cbind(win,loss,count) ~ interval, data = piYr$elapsed[collegeFilter & dupesFilter & piYr$elapsed$year < 2023,], sum, na.rm = TRUE )
  
  return(theAgg)
  
})

# check
# > sapply(intervalCounts_college, function(x) { x[1,"count"]} ) |> sum()
# [1] 6264
# > intervalCounts[1,"count"]
# [1] 7215

collegeZeros_winrate <- sapply(intervalCounts_college, function(x) {  
  x[1,"win"]/x[1,"count"]
})

###############################
## CALCULATE PRIOR WIN RATES ##
###############################

#####################
## PREP ORG PRIORS ##
#####################

# First, merge the zero year win rates by college

# convert college zeros to a dataframe
cZw <- data.frame(college = names(collegeZeros_winrate), prior = collegeZeros_winrate, interval_floor = 0 )

# Expand collegeList into a dataframe
collegeDF <- do.call(rbind, lapply(names(collegeList), function(college) {
  data.frame(college = college,
             PROPOSAL_COLLEGE = unlist(collegeList[[college]]), # Unlist each element
             stringsAsFactors = FALSE)
}))

# merge the college names in
cZw <- merge(cZw, collegeDF, by = "college")

# merge the organization names in
cZw <- merge(cZw, unique(cleanData[,c("PROPOSAL_COLLEGE","PROPOSAL_ORG")]), by = "PROPOSAL_COLLEGE")

# merge
orgPriors <- merge(priorsAdded_org, cZw[, c("PROPOSAL_ORG", "interval_floor", "prior")], by = c("PROPOSAL_ORG", "interval_floor"), all.x = TRUE)

# clean up the merge
orgPriors$priorOrg[orgPriors$interval_floor == 0] <- orgPriors$prior[orgPriors$interval_floor == 0]

orgPriors <- orgPriors[,-which(colnames(orgPriors) %in% c("PROPOSAL_COLLEGE", "prior"))]

orgPriors[is.na(orgPriors)] <- 0

colnames(orgPriors)[colnames(orgPriors) %in% c("win.x", "win.y", "loss", "count")] <- c("win", "win.count.prior", "loss.count.prior", "total.count.prior")

####################
## PREP PI PRIORS ##
####################

# First, merge the zero year win rates by college

# convert college zeros to a dataframe
cZw <- data.frame(college = names(collegeZeros_winrate), prior = collegeZeros_winrate, interval_floor = 0 )

# Expand collegeList into a dataframe
collegeDF <- do.call(rbind, lapply(names(collegeList), function(college) {
  data.frame(college = college,
             PROPOSAL_COLLEGE = unlist(collegeList[[college]]), # Unlist each element
             stringsAsFactors = FALSE)
}))

# merge the college names in
cZw <- merge(cZw, collegeDF, by = "college")

# explode with the appropriate PI
cZw <- merge(cZw, unique(cleanData[,c("PROPOSAL_COLLEGE","PROPOSAL_PI_EMPLID")]), by = "PROPOSAL_COLLEGE")

# remove duplicates
cZw <- cZw[!cZw$PROPOSAL_PI_EMPLID %in% theDupes,]

# merge
piPriors <- merge(priorsAdded_pi, cZw[,c("PROPOSAL_PI_EMPLID", "interval_floor", "prior")], by = c("PROPOSAL_PI_EMPLID", "interval_floor"), all.x = TRUE)

# clean up the merge
piPriors$priorPI[piPriors$interval_floor == 0] <- piPriors$prior[piPriors$interval_floor == 0]

piPriors <- piPriors[,-which(colnames(piPriors) %in% c("PROPOSAL_COLLEGE", "prior"))]

# Assign universal win rate for zero values of duplicate PI's (who were in multiple colleges)
filter <- piPriors$PROPOSAL_PI_EMPLID %in% theDupes & 
  piPriors$interval_floor == 0 &
  is.na(piPriors$priorPI)
piPriors$priorPI[filter] <- overallZero 

piPriors[is.na(piPriors)] <- 0

colnames(piPriors)[colnames(piPriors) %in% c("win.x", "win.y", "loss", "count")] <- c("win", "win.count.prior", "loss.count.prior", "total.count.prior")



################################
## MERGE CALCULATIONS BACK IN ## 
################################

# merge dates back into cleanData

prepData <- cbind(cleanData, dateExtraction) # I hate doing this without a merge

# check
# all(isoweek(prepData$PROPOSAL_UPLOAD_DATE) == prepData$PROPOSAL_UPLOAD_DATE.week ) # [1] TRUE

# merge orgPriors in

prepData <- merge(prepData, orgPriors[,c("PROPOSAL_ID", "interval", "win.count.prior","loss.count.prior", "total.count.prior", "priorOrg")], by = "PROPOSAL_ID")


# merge piPriors in 

prepData <- merge(prepData, piPriors[,c("PROPOSAL_ID", "interval", "win.count.prior","loss.count.prior", "total.count.prior", "priorPI")], by = "PROPOSAL_ID")

# fix names
colnames(prepData)[grep("\\.x", colnames(prepData))] <- gsub("\\.x", ".org", colnames(prepData)[grep("\\.x", colnames(prepData))])

colnames(prepData)[grep("\\.y", colnames(prepData))] <- gsub("\\.y", ".PI", colnames(prepData)[grep("\\.y", colnames(prepData))])

# identify  where proposal and appointment colleges differ
prepData$collegeDiffer <- as.character(prepData$"PROPOSAL_COLLEGE") == as.character(prepData$"PROPOSAL_PI_APPOINTMENT_COLLEGE")

##############################
## CARDINALITY SUBSTITUTION ##
##############################

# Replacing the high cardinality columns slightly improved the recall, so I am keeping it

###################
## ACADEMIC RANK ##
###################

top_five <- names(sort(table(cleanData[, "PROPOSAL_PI_ACADEMIC_RANK"]), decreasing = TRUE)[1:5])

top_ten <- names(sort(table(cleanData[, "PROPOSAL_PI_ACADEMIC_RANK"]), decreasing = TRUE)[1:10])

rank_four <- names(sort(table(cleanData[, "PROPOSAL_PI_ACADEMIC_RANK"]), decreasing = TRUE)[1:4])

prepData$PROPOSAL_PI_ACADEMIC_RANK <- ifelse(
  prepData$PROPOSAL_PI_ACADEMIC_RANK %in% rank_four,
  as.character(prepData$PROPOSAL_PI_ACADEMIC_RANK),
  "theRest"
)

prepData$PROPOSAL_PI_ACADEMIC_RANK <- factor(prepData$PROPOSAL_PI_ACADEMIC_RANK)

######################
## PROPOSAL_COLLEGE ##
######################

prepData$PROPOSAL_COLLEGE <- ifelse(
  prepData$PROPOSAL_COLLEGE %in% collegeList,
  as.character(prepData$PROPOSAL_COLLEGE),
  "theRest"  
)

prepData$PROPOSAL_COLLEGE <- factor(prepData$PROPOSAL_COLLEGE)

############################
## PI_APPOINTMENT_COLLEGE ##
############################

appt_four <- names(sort(table(cleanData[, "PROPOSAL_PI_APPOINTMENT_COLLEGE"]), decreasing = TRUE)[1:4])

prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE <- ifelse(
  prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE %in% appt_four,
  as.character(prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE),
  "theRest"
)

prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE <- factor(prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE)

##########################
## NEXT HIGHEST ACRONYM ##
##########################

agency_four <- names(sort(table(cleanData[, "NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM"]), decreasing = TRUE)[1:4])

prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM <- ifelse(
  prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM %in% agency_four,
  as.character(prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM),
  "theRest"
)

prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM <- factor(prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM)

##################
## KEEP COLUMNS ##
##################

keepColumns <- c(
  # "PROPOSAL_ID",                             
  "win",                                     
  "PROPOSAL_DIRECT_COST",                    
  "PROPOSAL_FA_COST",                        
  "PROPOSAL_TOTAL_SPONSOR_BUDGET",           
  "PROPOSAL_UNIVERSITY_COSTSHARE",           
  "PROPOSAL_3RD_PARTY_COSTSHARE",            
  "PROPOSAL_DIRECT_COST_prop",               
  "PROPOSAL_FA_COST_prop",                   
  "PROPOSAL_UNIVERSITY_COSTSHARE_prop",      
  "PROPOSAL_3RD_PARTY_COSTSHARE_prop",       
  # "PROPOSAL_SHORT_TITLE",                    
  "PROPOSAL_TYPE",                           
  "PROPOSAL_PURPOSE",                        
  "PROPOSAL_RECIPIENT_FUNDING_TYPE",         
  "PROPOSAL_COST_SHARE_INDICATOR",           
  "PROPOSAL_FANDA_WAIVER_INDIVATOR",         
  "PROPOSAL_FANDA_OFF_CAMPUS_RATE_INDICATOR",
  "PROPOSAL_UPLOAD_DATE_FISCAL_YEAR",        
  # "PROPOSAL_PI_EMPLID",                      
  # "PROPOSAL_PI_NAME",                        
  # "PROPOSAL_PI_APPOINTMENT_DEPT",            
  "PROPOSAL_PI_APPOINTMENT_COLLEGE",     
  "PROPOSAL_PI_ACADEMIC_RANK",               
  "PROPOSAL_PI_TENURE_STATUS",               
  "PROPOSAL_PI_FACULTY_CATEGORY",            
  "PROPOSAL_PI_FACULTY_SUBCATEGORY",         
  "PROPOSAL_PI_ACADEMIC_RANK_LEVEL",         
  "PROPOSAL_PI_RANK_SORTED",                 
  "PROPOSAL_PI_FACULTY_LINE_SORTED",         
  # "PROPOSAL_ORG",                            
  # "PROPOSAL_DEPT",                           
  "PROPOSAL_COLLEGE",                        
  # "VPR_PROPOSAL_COLLEGE",                    
  # "PROPOSAL_VP",                             
  # "VPR_PROPOSAL_VP",                         
  # "PROPOSAL_SPONSOR_ID",                     
  # "PROPOSAL_SPONSOR_NAME",                   
  "PROPOSAL_SPONSOR_TYPE_CODE",              
  # "PROPOSAL_SPONSOR_TYPE",                   
  "PROPOSAL_IACUC_IRB_DIM_KEY",              
  # "PROPOSAL_SPO_EMPLID",                     
  # "PROPOSAL_SPO_NAME",                       
  # "PROPOSAL_CREATION_DATE",                  
  # "PROPOSAL_OSP_RECEIVED_DATE",              
  # "PROPOSAL_OSP_REVIEW_DATE",                
  # "PROPOSAL_UPLOAD_DATE",                    
  # "PROPOSAL_PROJECT_START_DATE",             
  # "PROPOSAL_PROJECT_END_DATE",               
  # "PROPOSAL_SPONSOR_DUE_DATE",               
  "HIGHEST_GOVERNMENT_AGENCY_ACRONYM",       
  "NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM",  
  "PROPOSAL_CREATION_DATE.week",             
  "PROPOSAL_CREATION_DATE.month",            
  "PROPOSAL_OSP_RECEIVED_DATE.week",         
  "PROPOSAL_OSP_RECEIVED_DATE.month",        
  "PROPOSAL_OSP_REVIEW_DATE.week",           
  "PROPOSAL_OSP_REVIEW_DATE.month",          
  "PROPOSAL_UPLOAD_DATE.week",               
  "PROPOSAL_UPLOAD_DATE.month",              
  "PROPOSAL_PROJECT_START_DATE.week",        
  "PROPOSAL_PROJECT_START_DATE.month",       
  "PROPOSAL_PROJECT_END_DATE.week",          
  "PROPOSAL_PROJECT_END_DATE.month",         
  "PROPOSAL_SPONSOR_DUE_DATE.week",          
  "PROPOSAL_SPONSOR_DUE_DATE.month",         
  "interval.org",                            
  "win.count.prior.org",                     
  "loss.count.prior.org",                    
  "total.count.prior.org",                   
  "priorOrg",                                
  "interval.PI",                             
  "win.count.prior.PI",                      
  "loss.count.prior.PI",                     
  "total.count.prior.PI",                    
  "priorPI"        
)

##################
## FISCAL YEARS ##
##################

# Add fiscal years of uploading
prepData$upload_year <- year(prepData$PROPOSAL_UPLOAD_DATE)
prepData$upload_fiscal_year <- quarter(prepData$PROPOSAL_UPLOAD_DATE, with_year = TRUE, fiscal_start = 7) |> stringr::str_sub(1, 4) |> as.numeric()  # awkward work-around

################################
## CLEAN UP AND SUBSTITUTIONS ##
################################

# In a questionable shortcut, I replaced prepData$PROPOSAL_COLLEGE
# with a substitution instead of creating a new college.
# I'm going to fix that here.

prepData$big5 <- prepData$PROPOSAL_COLLEGE
prepData$PROPOSAL_COLLEGE <- NULL

prepData <- merge(prepData, cleanData[,c("PROPOSAL_ID", "PROPOSAL_COLLEGE")], by = "PROPOSAL_ID")

sweet16 <- levels(cleanData$PROPOSAL_COLLEGE)[grep("^(?!.*graduate).*(college|school)", tolower(levels(cleanData$PROPOSAL_COLLEGE)), perl = TRUE)] # regex is difficult to learn

bigInst <- c(
  "Energy & Geoscience Institute (EGI)",
  "Huntsman Cancer Institute",
  "Scientific Computing and Imaging Institute (SCI)",
  "Cardiovascular Research and Training Institute (CVRTI)",
  "Institute for Clean and Secure Energy (ICSE)",
  "Clinical and Translational Science Institute (CTSI)"
)

# confirm
# all(prepData$PROPOSAL_ID == cleanData$PROPOSAL_ID) # TRUE

prepData$college16_bigInst <- ifelse(
  cleanData$PROPOSAL_COLLEGE %in% c(sweet16, bigInst),
  as.character(cleanData$PROPOSAL_COLLEGE),
  "other"  
)

prepData$college16_bigInst <- factor(prepData$college16_bigInst)


#prepData$PROPOSAL_COLLEGE <- ifelse(
# prepData$PROPOSAL_COLLEGE %in% collegeList,
# as.character(prepData$PROPOSAL_COLLEGE),
# "other"  
# )

prepData$PROPOSAL_COLLEGE <- factor(prepData$PROPOSAL_COLLEGE)

####################
## DETAIL MAPPING ##
####################

collegeAbbrv <- cbind(
  college = c(sweet16, bigInst, "other"),
  abbrv = c("Arch",
            "Educ",
            "FinArt",
            "Health",
            "Hum",
            "Nurs",
            "Pharm",
            "Science",
            "SocBeh",
            "SocWrk",
            "Bus",
            "Law",
            "Tran",
            "Dent",
            "Med",
            "Engr",
            "EGI",
            "Hunt",
            "SCI",
            "CVRTI",
            "ICSE",
            "CTSI",
            "other"
  ),
  color = c(
    "lightslategray",
    "orange",
    "cyan", 
    "hotpink", 
    "brown", 
    "darkgoldenrod", 
    "gold", 
    "green",
    "navy", 
    "magenta", 
    "olivedrab4", 
    "salmon", 
    "darkgreen",
    "yellowgreen", 
    "red",
    "blue",
    "chocolate", 
    "purple",
    "violet", 
    "khaki",
    "deepskyblue3",
    "chartreuse",
    "darkmagenta"
  ),
  pch = c(
    1,14,15,2,3,4,17,6,5,8,9,10,11,12,13,0,16,7,18, 23, 24, 25, 20  
    
    
  ),
  
  cex = rep(NA, length(c(sweet16, bigInst, "other")) )
)

prepData$college <- collegeAbbrv[match(prepData$college16_bigInst, collegeAbbrv[,"college"])  ,"abbrv"]


## ACADEMIC RANK

top_five <- names(sort(table(cleanData[, "PROPOSAL_PI_ACADEMIC_RANK"]), decreasing = TRUE)[1:5])

top_ten <- names(sort(table(cleanData[, "PROPOSAL_PI_ACADEMIC_RANK"]), decreasing = TRUE)[1:10])

rank_four <- names(sort(table(cleanData[, "PROPOSAL_PI_ACADEMIC_RANK"]), decreasing = TRUE)[1:4])

prepData$PROPOSAL_PI_ACADEMIC_RANK <- ifelse(
  prepData$PROPOSAL_PI_ACADEMIC_RANK %in% rank_four,
  as.character(prepData$PROPOSAL_PI_ACADEMIC_RANK),
  "other"
)

prepData$PROPOSAL_PI_ACADEMIC_RANK <- factor(prepData$PROPOSAL_PI_ACADEMIC_RANK)


## PI_APPOINTMENT_COLLEGE ##

appt_four <- names(sort(table(cleanData[, "PROPOSAL_PI_APPOINTMENT_COLLEGE"]), decreasing = TRUE)[1:4])

prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE <- ifelse(
  prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE %in% appt_four,
  as.character(prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE),
  "other"
)

prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE <- factor(prepData$PROPOSAL_PI_APPOINTMENT_COLLEGE)

## NEXT HIGHEST ACRONYM ##

agency_four <- names(sort(table(cleanData[, "NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM"]), decreasing = TRUE)[1:4])

prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM <- ifelse(
  prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM %in% agency_four,
  as.character(prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM),
  "other"
)

prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM <- factor(prepData$NEXT_HIGHEST_GOVERNMENT_AGENCY_ACRONYM)

##########
## CUTS ##
##########

# Calculate cuts
prepData$total_cut <- log(prepData[,"PROPOSAL_TOTAL_SPONSOR_BUDGET"]) |>
  cut(breaks = seq(from = 5, to = 19, by = 0.5), include.lowest=TRUE)

## TOTAL SPONSOR BUDGET ##

totalCut <- calculateWinRates(data = prepData, categoryColumn = "total_cut", functionList = list(mean = mean, median = median)) |> (\(x){ return(x$summary[levels(prepData$total_cut),]) })()

row.names(totalCut)[row.names(totalCut) == "NA"] <- "(18,18.5]" # fix the name of a cut without any values

# prepData$cut has been lost to time; it doesn't work in the latest version
# I would need to unwind through GitHub for some time to figure out what it is.

# college_by_cut <- lapply(unique(prepData$college), function(sp_cut){
  
#  theCut <- prepData[prepData$college == sp_cut,] # prepData[prepData$cut == sp_cut,] # confused about this one; can't find where prepData$cut was defined.  How is "cut" equal to a college, anyway?  Previous push didn't clarify
#  theAgg <- calculateWinRates(data = theCut, categoryColumn = "upload_fiscal_year", functionList = list(mean = mean, median = median)) |> (\(x){ return(x$summary[levels(prepData$total_cut),]) })()
  
#  return(theAgg)  
  
# })
# names(college_by_cut) <- unique(prepData$college)

college_by_cut <- lapply(unique(prepData$college), function(x) {
  
  theCut <- calculateWinRates(data = prepData[prepData[,"college"] == x,], categoryColumn = "total_cut", functionList = list(mean = mean, median = median))   
  theCut <- theCut$summary[match(levels(prepData$total_cut), row.names(theCut$summary)),] ;
  return(theCut)
  
  })

names(college_by_cut) <- unique(prepData$college)


##################
## AGGREGATIONS ##
##################

## ALL

mainOrgs <- calculateWinRates(data = prepData, categoryColumn = "college16_bigInst", functionList = list(mean = mean, median = median)) |>
  (\(x){ return(x$summary[order(x$summary$win.sum, decreasing = TRUE),]) })()

## TRENDS

# FISCAL YEAR -- ALL

yearRates <- calculateWinRates(data = prepData, categoryColumn = "upload_fiscal_year", functionList = list(mean = mean, median = median)) |>
  (\(x){ return(x$summary[order(as.numeric(row.names(x$summary)), decreasing = FALSE),]) })()

# FISCAL YEAR -- BY COLLEGE

college_by_year <- lapply(unique(prepData$college), function(college){
  
  theCut <- prepData[prepData$college == college,]
  theAgg <- calculateWinRates(data = theCut, categoryColumn = "upload_fiscal_year", functionList = list(mean = mean, median = median)) |>
    (\(x){ return(x$summary[order(as.numeric(row.names(x$summary)), decreasing = FALSE),]) })()
  
  return(theAgg)  
  
})
names(college_by_year) <- unique(prepData$college)

message("Script loaded successfully")

