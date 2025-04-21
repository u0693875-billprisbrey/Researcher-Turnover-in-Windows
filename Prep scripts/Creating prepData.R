# Creating Prep Data
# 4.21.2025

# PURPOSE:  This creates the file "prepData" by doing an initial portion of "Prep Script 
# Grants-Exploratory.R

# This is pulled into a separate prep file because calculating all of the "prior" win rates
# takes a few minutes.

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


##########
## SAVE ##
##########

saveRDS(prepData, here::here("Data", "prepData17Apr2025.rds"))


