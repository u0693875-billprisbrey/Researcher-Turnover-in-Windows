# Adjusting preData and loading functions
# 4.21.2025


# PURPOSE:  This loads libraries, functions, and data sets that I like to use.  This includes modifying
# "prepData".

# OBJECTS LOADED:
#  Functions
#  cleanData
#  prepData
#  collegeAbbrv
#  mainOrgs
#  yearRates

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
prepData <- readRDS(here::here("Data", "prepData17Apr2025.rds"))


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
