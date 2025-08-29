# Minimalist Concurrent EMPLID
# Assign Boundaries Sandbox

# PURPOSE:  This sandbox develops a modification of assignBoundaries, or a secondary "modifyBoundaries", that 
# applies to EMPLID's that only have a maximum of two employee records (concurrent jobs) and two primary entries.

##############
## FUNCTION ##
##############

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

##########
## LOAD ##
##########

concurrentJourney <- readRDS(here::here("Data", "concurrentJourney.rds"))
journeyPopulation <- readRDS(here::here("Data", "journeyPopulation.rds"))
minimalistEMPLIDs <- readRDS(here::here("Data", "minimalist_concurrent_emplids.rds"))

#############
## PROCESS ##
#############


minJ <- concurrentJourney[concurrentJourney$EMPLID %in% minimalistEMPLIDs,] # minimum concurrent journey

# What's the number of leave and short work breaks in this group?

minFilter <- journeyPopulation$EMPLID %in% minimalistEMPLIDs
aggregate(cbind("WORKBREAK","LEAVE") ~ EMPLID, data = journeyPopulation[aggFilter,], function(x){length(unique(x))})

aggregate(cbind("WORKBREAK","LEAVE") ~ EMPLID, data = journeyPopulation[aggFilter,], table) 

# ok I'll do it dumber

table(journeyPopulation$WORKBREAK[minFilter])

# not_wb     wb 
#   9025   2548 

table(journeyPopulation$LEAVE[minFilter])

# leave not_leave 
# 1694      9879 


# first I'd like to deal with the people who do none of this

table(journeyPopulation[minFilter,c("WORKBREAK","LEAVE")])

#            LEAVE
# WORKBREAK leave not_leave
# not_wb  1616      7409
# wb        78      2470

# so I'm looking at 7,409 EMPLID's

simpEMPLIDs <- journeyPopulation$EMPLID[minFilter & journeyPopulation$WORKBREAK == "not_wb" & journeyPopulation$LEAVE == "not_leave"] # simplest EMPLID's

View(minJ[minJ$EMPLID %in% simpEMPLIDs,])

# to double-check
> sample(simpEMPLIDs, 10)
[1] "01194328" "01275586" "01363644" "00055528"
[5] "06052845" "00644139" "01005856" "00169904"
[9] "00783480" "01435526"
> sample(simpEMPLIDs, 12)
[1] "01033492" "01147177" "06011381" "01309354"
[5] "00771824" "06041500" "01043444" "00470551"
[9] "01560284" "01019687" "01540854" "01361805"

# My approach is to aggregate the primary entry and exits
# per employment record, then compare overlaps to identify
# university entries or exits

simpJ <- concurrentJourney[concurrentJourney$EMPLID %in% simpEMPLIDs,] |> # emplids with simplest concurrent journey
 assignBoundaries()

assignSimpleModifications <- function(data){
  
  # where data is the journey data for workers with these conditions:
  #   concurrent journey
  #   minimalist regime (max two entries and two employment records)
  #   no workbreaks or leave
  
  # This executes after "assignBoundaries"
  
  # First, sort data by EFFDT in ascending order
  
  data <- data[order(data$EFFDT),]
  
  # First, aggregate dates by employment record
  boundaryDates <- aggregate(EFFDT ~ EMPLID + boundary + EMPL_RCD, data = data, min)
  
  # Reshape
  boundaryDates$ID <- paste(boundaryDates$EMPLID, boundaryDates$EMPL_RCD, sep="_")
  boundaryDates_wide <- reshape(boundaryDates, direction = "wide", idvar = "ID", timevar = "boundary",
          v.names = c("EFFDT")) 

  boundaryDates$record_boundary <- paste(boundaryDates$boundary, boundaryDates$EMPL_RCD, sep = "_")
  boundaryDates_very_wide <- reshape(boundaryDates[,-which(colnames(boundaryDates) %in% c("ID", "boundary", "EMPL_RCD") )], 
                 direction = "wide", 
                 idvar = "EMPLID", 
                 timevar = c("record_boundary") ,
                 v.names = c("EFFDT")) 
  
  # ok, what's my logic
  
  # check EFFDT.entry_0 should be the minimum value
  all(boundaryDates_very_wide[,"EFFDT.entry_0"] == apply(boundaryDates_very_wide[,-1]), 1, min)
  # apply is messing with the "date" format and it's not working very well
  
  
}

# I think I can re-label "primary" as "university"
# either that, or append "university" to "primary"

# I think I'll append it for now.

# I like "boundaryDates_wide" .... looks good ...
# but don't I want it on one row?

