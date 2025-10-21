# Brute Force Fit Approximation

# PURPOSE:  The purpose of this script is to create the brute force fit approximation
# for employees with concurrent jobs. 

# An immediate improvement is to use the data that was used to create "cj_diff" instead of 
# re-combining it here.  I want one frame per EMPLID in a list.

# This follows "Brute Force Sandbox" starting with "All Concurrent Employees" at about line 695.

##########
## LOAD ##
##########

cj_diff <- readRDS(here::here("Data", "concurrentJourney_timeDiff.rds") )

source(here::here("Functions", "Turnover Functions.R"))
source(here::here("Functions", "Brute Force Functions.R"))

library(lubridate)

##########
## PREP ##
##########

# This could/should be replaced with raw data manipulation instead of a 
# re-combining cj_diff list.

startTime <- Sys.time()

# Extract unique EMPLIDs

emplids <- names(cj_diff) |>
  (\(x){
    gsub("\\.[[:digit:]]+$",
         "",
         x)
  })() |> 
  unique()

# Re-combine frames into one per EMPLID
cjEmplids <- lapply(emplids, function(emplid) {
  
  list_positions <- grep(emplid, names(cj_diff))
  
  full_frame <- do.call(rbind, cj_diff[list_positions])  
  
  return(full_frame)
  
}  )
names(cjEmplids) <- emplids


###############################
## BRUTE FORCE APPROXIMATION ##
###############################

universityBoundaries <- lapply(cjEmplids, extractUniversityBoundaries)
names(universityBoundaries) <- names(cjEmplids)

univBound <- do.call(rbind, universityBoundaries)

endTime <- Sys.time()

print(rep(endTime - startTime,3))

##########
## SAVE ##
##########

saveRDS(cjEmplids, here::here("Data", "Journey Activity from Brute Force Fit Approximation for Concurrent Journey Employees.rds"))
saveRDS(univBound, here::here("Data", "Brute Force Fit Approximation for Concurrent Journey Employees.rds"))
