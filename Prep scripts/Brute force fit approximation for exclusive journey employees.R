# Brute Force Fit Approximation FOR EXCLUSIVE JOURNEY EMPLOYEES

# PURPOSE:  The purpose of this script is to create the brute force fit approximation
# for employees with exclusive jobs.

# An immediate improvement is to use the data that was used to create "exc_diff" instead of 
# re-combining it here.  I want one frame per EMPLID in a list.

# This follows "Brute force fit approximation for concurrent journey employees"

##########
## LOAD ##
##########

exc_diff <- readRDS(here::here("Data", "exclusiveJourney_timeDiff.rds") )

source(here::here("Functions", "Turnover Functions.R"))
source(here::here("Functions", "Brute Force Functions.R"))

library(lubridate)

##########
## PREP ##
##########

# This could/should be replaced with raw data manipulation instead of a 
# re-combining exc_diff list.

startTime <- Sys.time()

# Extract unique EMPLIDs

emplids <- names(exc_diff) |>
  (\(x){
    gsub("\\.[[:digit:]]+$",
         "",
         x)
  })() |> 
  unique()

# Re-combine frames into one per EMPLID
excEmplids <- lapply(emplids, function(emplid) {
  
  list_positions <- grep(emplid, names(exc_diff))
  
  full_frame <- do.call(rbind, exc_diff[list_positions])  
  
  return(full_frame)
  
}  )
names(excEmplids) <- emplids


###############################
## BRUTE FORCE APPROXIMATION ##
###############################

universityBoundaries <- lapply(excEmplids, extractUniversityBoundaries)
names(universityBoundaries) <- names(excEmplids)

univBound <- do.call(rbind, universityBoundaries)

endTime <- Sys.time()

print(rep(endTime - startTime,3))

##########
## SAVE ##
##########

saveRDS(excEmplids, here::here("Data", "Journey Activity from Brute Force Fit Approximation for Exclusive Journey Employees.rds"))
saveRDS(univBound, here::here("Data", "Brute Force Fit Approximation for Exclusive Journey Employees.rds"))
