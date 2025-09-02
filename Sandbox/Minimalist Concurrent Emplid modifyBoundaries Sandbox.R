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
concurrentEMPLIDs <- readRDS(here::here("Data", "concurrentEMPLIDs.rds"))
exclusiveEMPLIDs <- readRDS(here::here("Data", "exclusiveEMPLIDs.rds"))
oobEMPLIDs <- readRDS(here::here("Data", "out_of_bounds_concurrent_emplids.rds"))

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
  data$EFFDT <- as.Date(data$EFFDT)
  
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
  checkFail <- which(boundaryDates_very_wide[,"EFFDT.entry_0"] != apply(boundaryDates_very_wide[,-1], 1, min, na.rm=TRUE))
  # apply is messing with the "date" format and it's not working very well
  
  # length(checkFail) # 10 
  
  # I guess I deal with these a little differently?
  
  # nah, this will work great
  
  # the logic is that if the entry date
  # is the minimum of the entry dates per EMPLID,
  # then append the word ", university" to the entry
  
  # calculate minimum entry date per emplid
  
  aggFilter <- data$boundary == "entry" & !is.na(data$boundary)
  minEntry <- aggregate(EFFDT ~ EMPLID, data = data[aggFilter, ], min)
  minEntry$min_entry <- "min_entry"
  
  data2 <- merge(data, minEntry, by = c("EMPLID","EFFDT"), all.x = TRUE)
  
  data2$boundary_type <- ifelse(data2$min_entry == "min_entry", paste(data2$boundary_type, ", university", sep = ""),data2$boundary_type)
  
  # ok, that's great! 
  # I can do the same for the maximum date . . . 
  # unless they are currently employed
  
  aggFilter <- data$boundary == "exit" & !is.na(data$boundary)
  maxExit <- aggregate(EFFDT ~ EMPLID, data = data[aggFilter, ], max)
  maxExit$max_exit <- "max_exit"
  
  data3 <- merge(data2, maxExit, by = c("EMPLID","EFFDT"), all.x = TRUE)
  
  data3$boundary_type <- ifelse(data3$max_exit == "max_exit", paste(data3$boundary_type, ", university", sep = ""),data3$boundary_type)
  
  
}

# I think I can re-label "primary" as "university"
# either that, or append "university" to "primary"

# I think I'll append it for now.

# I like "boundaryDates_wide" .... looks good ...
# but don't I want it on one row?

# What's my check for this?


assignSimpleModifications <- function(data){
  
  # where data is the journey data for workers with these conditions:
  #   concurrent journey
  #   minimalist regime (max two entries and two employment records)
  #   no workbreaks or leave
  
  # This executes after "assignBoundaries"
  
  # First, modify data 
  # sort data by EFFDT in ascending order
  # re-assign EFFDT class
  
  data <- data[order(data$EFFDT),]
  data$EFFDT <- as.Date(data$EFFDT)
  
  # calculate minimum entry date per emplid
  
  aggFilter <- data$boundary == "entry" & !is.na(data$boundary)
  minEntry <- aggregate(EFFDT ~ EMPLID, data = data[aggFilter, ], min)
  minEntry$min_entry <- "min_entry"
  
  # calculate maximum exit date per emplid
  
  aggFilter <- data$boundary == "exit" & !is.na(data$boundary)
  maxExit <- aggregate(EFFDT ~ EMPLID, data = data[aggFilter, ], max)
  maxExit$max_exit <- "max_exit"
  
  
  # merge values back into data
  
  data <- merge(data, minEntry, by = c("EMPLID","EFFDT"), all.x = TRUE)
  data <- merge(data, maxExit, by = c("EMPLID","EFFDT"), all.x = TRUE)
  
  # append "university" value if it's the minimum or maximum
  
  data$boundary_type <- ifelse(data$min_entry == "min_entry", paste(data$boundary_type, ", university", sep = ""), data$boundary_type)
  data$boundary_type <- ifelse(data$max_exit == "max_exit", paste(data$boundary_type, ", university", sep = ""), data$boundary_type)
  
  # delete the extra columns
  data$min_entry <- NULL
  data$max_exit <- NULL
  
  # return the modified data
  
  return(data)
  
}


####################
## 3-PLUS ENTRIES ##
####################

# Next, I will attempt to look at the EMPLIDs of 
# two records and three-plus entries, and no other breaks or leaves

simp3PopFilter <- !journeyPopulation$EMPLID %in% minimalistEMPLIDs & 
  !journeyPopulation$EMPLID %in% exclusiveEMPLIDs & 
  !journeyPopulation$EMPLID %in% oobEMPLIDs &
  journeyPopulation$RECORDS_PER_EMPLID == 2 &
  journeyPopulation$WORKBREAK == "not_wb" & 
  journeyPopulation$LEAVE == "not_leave"

simp3EMPLIDs <- journeyPopulation$EMPLID[simp3PopFilter] # EMPLID's with 3+ entries, max 2 records, no breaks or leaves

library(skimr)
skim(journeyPopulation[journeyPopulation$EMPLID %in% simp3EMPLIDs, "RECORDS_PER_EMPLID"])

table(journeyPopulation[journeyPopulation$EMPLID %in% simp3EMPLIDs, "RECORDS_PER_EMPLID"])
#  1    2    3    4    5    6    7    8    9   10   11   12 
# 13 5971 2403  519  104   37   17   11    6    2    2    2 

# the 1 value probably had an HCJ
# why so many 2 values though? Shouldn't they be in "minimalist?
# no, because they have more than 2 entries -- the people I'm looking for

# I need to whittle down to just the 5,971 with the 2 empl records

table(journeyPopulation[journeyPopulation$EMPLID %in% simp3EMPLIDs, "RECORDS_PER_EMPLID"])

2 
5971

# DONE!  o.k., good !
# ok, let's see who we can do for them


simp3J <- concurrentJourney[concurrentJourney$EMPLID %in% simp3EMPLIDs,] |> # emplids with simplest concurrent journey
  assignBoundaries()

data <- simp3J

# test ID's

simp3picks <- sample(simp3EMPLIDs, 20)

# > simp3picks
# [1] "00364067" "00032553" "00884644" "01311938" "00176699"
# [6] "00551008" "00507286" "06005635" "00376291" "00285246"
# [11] "00369928" "00243071" "00714284" "00963048" "00175416"
# [16] "06019029" "00963589" "00284980" "00496910" "00870819"


assignSimple3Modifications <- function(data){
  
  # where data is the journey data for workers with these conditions:
  #   concurrent journey
  #   max two employment records
  #   three or more entries
  #   no workbreaks or leave
  
  # This executes after "assignBoundaries"
  
  # First, modify data 
  # sort data by EFFDT in ascending order
  # re-assign EFFDT class
  
  data <- data[order(data$EFFDT),]
  data$EFFDT <- as.Date(data$EFFDT)
  
  # minimum entry date is a university entry

  # calculate minimum entry date per emplid
  
  aggFilter <- data$boundary == "entry" & !is.na(data$boundary)
  minEntry <- aggregate(EFFDT ~ EMPLID, data = data[aggFilter, ], min)
  minEntry$min_entry <- "min_entry"  
  
  # merge values back into data
  data <- merge(data, minEntry, by = c("EMPLID","EFFDT"), all.x = TRUE)
  
  # append "university" value if it's the minimum or maximum
  data$boundary_type <- ifelse(data$min_entry == "min_entry", paste(data$boundary_type, ", university", sep = ""), data$boundary_type)
  
  # Investigate re-shapes 
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
  
}

# ok, we have a new regime that 0000006 belongs to
# Looks like they are a student before 2013,
# and got re-hired long after 2013.
# I should create a regime for this

# question is, should I create it now?
# Or keep working on this one?

# Looks like a pretty high proportion of my random samples
# are pre-2013 students.
# Maybe I'll just create that regime, as it will probably be 
# easier anyway.



