# REGIME CREATION
# Concurrent Out of Bounds EMPLID's

# PURPOSE:  This script runs in the background to create a list of EMPLID's that belong to the "out of bounds" regime.

# REGIME DEFINITION:  These are EMPLID's that have either no activity after 1 Jan 2013, or only have
# minimal activity after 2013.  To be specific, of their six most recent actions, after 1 Jan 2013,
# they only have "DTA" actions.

# JUSTIFICATION:  Per HR, HR data is accurate after 2013 and is unreliable before.  Per OSP 
# (Dave Howell) proposal data is accurate after 2014 and is unreliable before.  Analyses too old are less interesting;
# therefore starting after 2013 is good enough.  

# I requested the query to provide the full history of all employees with activity after 2010.  
# Some of these employees have no activity after 2013 (my true start date of interest.)  
# Some of these employees retired or were terminated before 2013, but have some kind of adjustment that is called
# a "DTA" action but didn't have any boundary actions that would affect the headcount.

# These employees can be safely excluded from further analysis.

# This regime is not meaningful for emplids with an "exclusive" job history as the logic applied to them is accurate 
# for headcount metrics due to their simpler histories.

##########
## LOAD ##
##########

concurrentJourney <- readRDS(here::here("Data", "concurrentJourney.rds"))
journeyPopulation <- readRDS(here::here("Data", "journeyPopulation.rds"))
concurrentEMPLIDs <- readRDS(here::here("Data", "concurrentEMPLIDs.rds"))

#############
## PROCESS ##
#############

startTime <- Sys.time()
mostRecentActions <- lapply(concurrentEMPLIDs, function(x) {
  
  extract <- concurrentJourney[concurrentJourney$EMPLID == x,c("EMPLID", "EFFDT","ACTION")]
  sorted <- extract[order(extract$EFFDT, decreasing = TRUE),]
  lastFive <- head(sorted)
  return(lastFive)
  
}  )
names(mostRecentActions) <- concurrentEMPLIDs
endTime <- Sys.time(); endTime - startTime # 9min

noActivityAfter2013 <- lapply(mostRecentActions, function(x) { max(x$EFFDT)}) |> unlist() |> (\(x){which(x <= as.numeric(as.POSIXct("2013-01-01", tz = "UTC"))  )})() |> names()

length(noActivityAfter2013) # 2321 # About 7.3% pared off

minActivityAfter2013 <- lapply(mostRecentActions[-which(names(mostRecentActions) %in% noActivityAfter2013)], function(x) { 
  
  # the logic here is first it checks if there is any activity before 2013, then if yes 
  # it checks to see if the only actions after 2013 are "DTA".
  # Recall these are the most recent six actions
  
  ifelse(any(as.Date(x[,"EFFDT"]) <= as.Date("2013-01-01")),
         
         all(x[,"ACTION"][as.Date(x[,"EFFDT"]) >= as.Date("2013-01-01") ] == "DTA" ), FALSE)
  
}) |> unlist() |> which() |> names()

length(minActivityAfter2013) # 314

# Both of these lists could use double-checking

saveRDS(c(noActivityAfter2013,minActivityAfter2013), here::here("Data","out_of_bounds_concurrent_emplids.rds"))
