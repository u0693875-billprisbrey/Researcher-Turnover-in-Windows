# Time Difference Data
# 9.3.2025

# PURPOSE:  This document creates a copy of "exclusiveJourney" and "concurrentJourney"
# that has a "time difference" column that is the difference in days between
# actions.  

# I'm not sure if this is worth creating its own script and save the data, or if I should 
# just calculate this on the fly.  It takes just long enough that this might be 
# worthwhile.

# My computer speed is inconsistent though; drags some times and is fast others.

##########
## LOAD ##
##########

exclusiveJourney <- readRDS(here::here("Data", "exclusiveJourney.rds"))
concurrentJourney <- readRDS(here::here("Data", "concurrentJourney.rds"))

#################
## PRE-PROCESS ##
#################

concurrentJourney$EFFDT <- as.Date(concurrentJourney$EFFDT)
exclusiveJourney$EFFDT <- as.Date(exclusiveJourney$EFFDT)

###############################
## CALCULATE TIME DIFFERENCE ##
###############################

## CONCURRENT

perEMPLID_RCD <- split(concurrentJourney, ~ EMPLID + EMPL_RCD, drop = TRUE)

# add a time difference column
perEMPLID_RCD <- lapply(perEMPLID_RCD, function(df) {
  df <- df[order(df$EFFDT), ]  # ensure chronological order
  df$timeBetweenActions <- c(NA, diff(df$EFFDT))
  return(df)
})

# Extract EMPLID and EMPL_RCD from the names
split_names <- names(perEMPLID_RCD)
emplid_part <- sub("\\..*", "", split_names)      # everything before the dot
rcd_part    <- sub(".*\\.", "", split_names)      # everything after the dot

# Create an order: first by EMPLID, then by EMPL_RCD
ordering <- order(emplid_part, as.numeric(rcd_part))

# Reorder the list
perEMPLID_RCD <- perEMPLID_RCD[ordering]

## EXCLUSIVE  

exclusive_perEMPLID_RCD <- split(exclusiveJourney, ~ EMPLID + EMPL_RCD, drop = TRUE)

# add a time difference column
exclusive_perEMPLID_RCD <- lapply(exclusive_perEMPLID_RCD, function(df) {
  df <- df[order(df$EFFDT), ]  # ensure chronological order
  df$timeBetweenActions <- c(NA, diff(df$EFFDT))
  return(df)
})


##########
## SAVE ##
##########  

saveRDS(perEMPLID_RCD, here::here("Data","concurrentJourney_timeDiff.rds"))
saveRDS(exclusive_perEMPLID_RCD, here::here("Data","exclusiveJourney_timeDiff.rds"))

