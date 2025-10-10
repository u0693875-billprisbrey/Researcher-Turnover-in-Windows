# Extract Brute Force Stops and Starts
# Extract University Boundaries
# 10/10/2025

# PURPOSE:  This script applies the "brute force" logic to cj_diff
# and extracts a list of university-level starts and stops per employee

# I might develop a function

# It might just be this script

# It follows "Brute Force Sandbox.R"

##########
## LOAD ##
##########

cj_diff <- readRDS(here::here("Data", "concurrentJourney_timeDiff.rds") )

###############
## FUNCTIONS ##
###############

source(here::here("Functions", "Brute Force Functions.R"))


# GOAL: 
# Create a list, one per employee, with two vectors: list of start dates,
# and list of stop dates.
# These will be university entrances and exits
# And, should be all I need to calculate university headcount!



# FIRST, recombine cj_diff into one data frame per employee

# Extract the unique emplids

emplids <- names(cj_diff) |>
  (\(x){
  gsub("\\.[[:digit:]]+$",
        "",
        x)
  })() |> 
  unique()


    
cjEmplids <- lapply(emplids, function(emplid) {

  list_positions <- grep(emplid, names(cj_diff))
  
  full_frame <- do.call(rbind, cj_diff[list_positions])  
  
  return(full_frame)
  
}  )
names(cjEmplids) <- emplids

# Calculate delta head count per employee

emplidForce <- lapply(cjEmplids[1:10], function(x){ 

daily_head_count_per_emplid <-  x |>
assignBoundaries() |>
  (\(x){deltaHeadCount(data = x,
                       minDate = min(x$EFFDT),
                       maxDate = max(x$EFFDT)
  )})()
  
daily_head_count_per_emplid$force <- pmax(0, pmin(1, daily_head_count_per_emplid$delta.cum))
  
return(daily_head_count_per_emplid)

})  
names(emplidForce) <- names(cjEmplids[1:10])

# o.k., now I need to extract that
# ....and I think I want to turn this into a single function,
# not a list-by-list adventure like I have up to here

extractUniversityBoundaries <- function(data){
  
  # where data is the HR activity per EMPLID
  
  # calculate the daily head count per EMPLID
  
  daily_head_count_per_emplid <-  data |>
    assignBoundaries() |>
    (\(x){deltaHeadCount(data = x,
                         minDate = min(x$EFFDT),
                         maxDate = max(x$EFFDT)
    )})()
  
  # Force the cumulative delta head count to 0 or 1
  daily_head_count_per_emplid$force <- pmax(0, pmin(1, daily_head_count_per_emplid$delta.cum))

  # Identify changes in that force fit delta
  daily_head_count_per_emplid$change <- c(0, diff(daily_head_count_per_emplid$force))
  
  # Identify starts (delta values of +1)
  starts <- daily_head_count_per_emplid$EFFDT[daily_head_count_per_emplid$change == 1]
  
  # First day adjustment for starts
  if (daily_head_count_per_emplid$force[1] == 1) {
    starts <- c(daily_head_count_per_emplid$EFFDT[1], starts)
  }

  # Identify stops (delta values of -1)
  stops  <- daily_head_count_per_emplid$EFFDT[daily_head_count_per_emplid$change == -1]
    
  # return as a list
  return(list(starts = starts, stops = stops))
  
}

universityBoundaries <- lapply(cjEmplids[1:10], extractUniversityBoundaries)
names(universityBoundaries) <- names(cjEmplids[1:10])

# o.k., now I want to plot this
# and I want to use this to calcualte headcount (!)



