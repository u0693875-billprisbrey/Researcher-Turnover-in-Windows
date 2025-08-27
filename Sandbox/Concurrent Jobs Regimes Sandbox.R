# Concurrent Job Regimes
# EDA Sandbox

# I would like to load the concurrent jobs, and explore the counts per different "regimes."

##########
## LOAD ##
##########

concurrentJourney <- readRDS(here::here("Data", "concurrentJourney.rds"))
journeyPopulation <- readRDS(here::here("Data", "journeyPopulation.rds"))
concurrentEMPLIDs <- readRDS(here::here("Data", "concurrentEMPLIDs.rds"))

#################################
## MINIMAL ACTIVITY AFTER 2013 ##
#################################

# Reasoning:  Some people have activity after 2010 but before 2013, meaning they are irrelevant to my study
# that starts in 2013 (good HR data) or 2014 (good proposal data).

# So I can filter out a few more people.

# These would have no activity, or only one or two DTA actions, after 2013.

# Create a flag # Don't create a flag

# concurrentJourney$post2013 <- as.Date(concurrentJourney$EFFDT) >= as.Date("2013-01-01")

aggregate(cbind("EFFDT","ACTION") ~ EMPLID, function() )

startTime <- Sys.time()
mostRecentActions <- lapply(concurrentEMPLIDs, function(x) {
  
  extract <- concurrentJourney[concurrentJourney$EMPLID == x,c("EMPLID", "EFFDT","ACTION")]
  sorted <- extract[order(extract$EFFDT, decreasing = TRUE),]
  lastFive <- head(sorted)
  return(lastFive)
  
}  )
names(mostRecentActions) <- concurrentEMPLIDs
endTime <- Sys.time(); endTime - startTime # 9min

# I should have completed the logic before running it for everyone.  This'll take 20min before I can do the next step.

# let's see the lowest max date

lapply(mostRecentActions[1:10], function(x) { max(x$EFFDT)}) |> unlist() |> (\(x){which(x == min(x))})()

# let's get the list of EMPLIDs that have NOTHING after 2013-01-01

noLateActivity <- lapply(mostRecentActions, function(x) { max(x$EFFDT)}) |> unlist() |> (\(x){which(x <= as.numeric(as.POSIXct("2013-01-01", tz = "UTC"))  )})()

length(noLateActivity) # 2321 # well, that's paring some away anyway.

# Let's get the list of EMPLIDs that only have "DTA" 

lateDTAActivity <- lapply(mostRecentActions[-noLateActivity][1:1000], function(x) { 
  
  all(x[,"ACTION"][as.Date(x[,"EFFDT"]) >= as.Date("2013-01-01") ] == "DTA" )
  
  }) |> unlist() |> which()

# This pulled out some correct examples, like 00027811 00027818, but
# there it is ..  00027886

# I need SOME activity before 2013, and then ONLY DTA after 2013

lateDTAActivity <- lapply(mostRecentActions[-noLateActivity][1:1000], function(x) { 
  
  ifelse(any(as.Date(x[,"EFFDT"]) <= as.Date("2013-01-01")),
  
  all(x[,"ACTION"][as.Date(x[,"EFFDT"]) >= as.Date("2013-01-01") ] == "DTA" ), FALSE)
  
}) |> unlist() |> which()

# This is looking much more promising.


lateDTAActivity <- lapply(mostRecentActions[-noLateActivity], function(x) { 
  
  # the logic here is first it checks if there is any activity before 2013, then if yes 
  # it checks to see if the only actions after 2013 are "DTA".
  # Recall these are the most recent six actions
  
  ifelse(any(as.Date(x[,"EFFDT"]) <= as.Date("2013-01-01")),
         
         all(x[,"ACTION"][as.Date(x[,"EFFDT"]) >= as.Date("2013-01-01") ] == "DTA" ), FALSE)
  
}) |> unlist() |> which() |> names()

length(lateDTAActivity) # 314 # not a lot, but it pares it down a little more

# check

mostRecentActions[lateDTAActivity[sample(1:length(lateDTAActivity),1)]]

# I checked a half-dozen and so far they are all good catches

# I'll want to create a script to save in "Data" that runs these functions and saves the results.
# The script is called something like "No or Retired Data Changes Only After 2013" 

################
## MINIMALIST ##
################

# They have a maximum of two primary entries and two employment records

assignBoundaries <- function(data) {
  
  # where data is "actionReasonFrame"
  
  # This takes the "data" and assigns entry/exit boundaries.
  # It also assigns plotting parameters.
  
  # I might have to do this in waves or sections to manage current and non-concurrent jobs; 
  # it may need another function to merge this with
  # the journeyData using some more complicated logic than just a join
  
  # I need complete flexibility around plot values
  
  ###############
  ## DATA PREP ##
  ###############
  
  data$boundary <- NA
  data$boundary_type <- NA
  data$shape_color <- NA
  data$shape_shape <- NA
  data$shape_size <- NA
  
  ########################
  ## NO CONCURRENT JOBS ##
  ########################
  
  primeEntryFilter <- data$ACTION %in% c("HIR", "REH")
  primeExitFilter <- data$ACTION %in% c("TER", "RET", "RWP")
  
  data$boundary[primeEntryFilter] <- "entry"
  data$boundary[primeExitFilter] <- "exit"
  data$boundary_type[primeEntryFilter|primeExitFilter] <- "primary"
  
  # Break entry or exit
  
  breakEntryFilter <- data$ACTION %in% c("RWB")
  breakExitFilter <- data$ACTION %in% c("SWB")
  
  data$boundary[breakEntryFilter] <- "entry"
  data$boundary[breakExitFilter] <- "exit"
  data$boundary_type[breakEntryFilter|breakExitFilter] <- "break"
  
  # Leave entry or exit
  
  leaveEntryFilter <- data$ACTION %in% c("RFL")
  leaveExitFilter <- data$ACTION %in% c("LOA","LTO", "PLA") & !(data$ACTION_REASON %in% c("EXT"))
  
  data$boundary[leaveEntryFilter] <- "entry"
  data$boundary[leaveExitFilter] <- "exit"
  data$boundary_type[leaveEntryFilter|leaveExitFilter] <- "leave"  
  
  #################
  ## PLOT VALUES ##
  #################
  
  # COLOR
  
  data$shape_color[is.na(data$boundary_type)] <- "plum1"
  data$shape_color[data$boundary_type == "primary" & !is.na(data$boundary_type)] <- "chocolate"
  data$shape_color[data$boundary_type == "break" & !is.na(data$boundary_type)] <- "steelblue"
  data$shape_color[data$boundary_type == "leave" & !is.na(data$boundary_type)] <- "coral"
  data$shape_color[data$ACTION == "REH"] <- "chocolate4"
  data$shape_color[data$ACTION_REASON == "HCJ"] <- "mediumorchid1"
  
  # SHAPE
  
  data$shape_shape[is.na(data$boundary)] <- 1
  data$shape_shape[data$boundary == "entry" & !is.na(data$boundary)] <- 13
  data$shape_shape[data$boundary == "exit" & !is.na(data$boundary)] <- 19
  data$shape_shape[data$ACTION == "REH"] <- 10
  
  
  # SIZE
  
  data$shape_size[is.na(data$boundary_type)] <- 0.75
  data$shape_size[data$boundary_type == "primary" & !is.na(data$boundary_type)] <- 2
  data$shape_size[data$boundary_type == "break" & !is.na(data$boundary_type)] <- 1
  data$shape_size[data$boundary_type == "leave" & !is.na(data$boundary_type)] <- 1  
  
  return(data)
}

concJ <- concurrentJourney |> assignBoundaries()

joggo <- aggregate(boundary ~ EMPLID, data = concJ[concJ$boundary_type == "primary" & concJ$boundary == "entry",], length )


maxTwoEntries <- joggo$EMPLID[joggo$boundary <= 2]

# these people still have breaks and leaves

# I wonder how many of my PI's are in this minimalist group?

# This is another script to run in data and another list to populate.

# It might make sense to break out people with 1-2 "exits" (?) ... (?)  I wonder?




