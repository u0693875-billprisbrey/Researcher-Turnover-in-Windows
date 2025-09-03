# REGIME CREATION
# Pre 2013 Student EMPLID's

# PURPOSE:  This script runs in the background to create a list of EMPLID's that belong to the "pre 2013 students" regime.

# REGIME DEFINITION:  These are EMPLID's that have activity before and after 1 Jan 2013.
# However, their last action prior to 2013 was an exit, and their first action post 2013 was an entry.
# They weren't necessarily students that were rehired, but some probably were.

# JUSTIFICATION:  Per HR, HR data is accurate after 2013 and is unreliable before.  Per OSP 
# (Dave Howell) proposal data is accurate after 2014 and is unreliable before.  Analyses too old are less interesting;
# therefore starting after 2013 is good enough, and I can ignore activity before 1 Jan 2013 if
# it concluded with an exit action.

# These employees are not excluded from further analysis, but their history prior to 1 Jan 2013 can be.

# These employees will require further processing on their journey data, as only their pre-2013 activity will be deleted.

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

# Convert it to "Date"

concurrentJourney$EFFDT <- as.Date(concurrentJourney$EFFDT) 

# Activity before and after 2013

preAndPost2013 <- aggregate(EFFDT ~ EMPLID, data = concurrentJourney, function(x) (any(as.Date(x) < as.Date("2013-01-01")) & any(as.Date(x) >= as.Date("2013-01-01"))   ) ) 

# Max date before 2013

preAndPost2013EMPLIDs <- preAndPost2013$EMPLID[preAndPost2013$EFFDT]

maxPre2013 <- aggregate(EFFDT ~ EMPLID, data = concurrentJourney[concurrentJourney$EMPLID %in% preAndPost2013EMPLIDs & concurrentJourney$EFFDT < as.Date("2013-01-01"), ], function(x){ max(as.Date(x)) } )

maxPre2013$max_date <- "max_date"

# Min date before 2013

minPost2013 <- aggregate(EFFDT ~ EMPLID, data = concurrentJourney[concurrentJourney$EMPLID %in% preAndPost2013EMPLIDs & concurrentJourney$EFFDT >= as.Date("2013-01-01"), ], function(x){ min(as.Date(x)) } )

minPost2013$min_date <- "min_date"

# merge these back into the target population 

targetPopulation <- merge(concurrentJourney[concurrentJourney$EMPLID %in% preAndPost2013EMPLIDs,],
                          maxPre2013,
                          by = c("EMPLID", "EFFDT"),
                          all.x=TRUE
                          )

targetPopulation <- merge(targetPopulation,
                          minPost2013,
                          by = c("EMPLID", "EFFDT"),
                          all.x=TRUE
)

# Actions on the max date
aggFilter <- targetPopulation$max_date == "max_date" & !is.na(targetPopulation$max_date)
maxPre2013Actions <- aggregate(ACTION ~ EMPLID, data = targetPopulation[aggFilter,], function(x) { paste(unique(x), collapse = ", ")})
names(maxPre2013Actions)[names(maxPre2013Actions) %in% "ACTION"] <- "max_actions"

# Actions on the min date
aggFilter <- targetPopulation$min_date == "min_date" & !is.na(targetPopulation$min_date)
minPost2013Actions <- aggregate(ACTION ~ EMPLID, data = targetPopulation[aggFilter,], function(x) { paste(unique(x), collapse = ", ")})
names(minPost2013Actions)[names(minPost2013Actions) %in% "ACTION"] <- "min_actions"

# merge together
identifyStudents <- merge(maxPre2013Actions, minPost2013Actions, by = "EMPLID")

# pick out codes

unique_max_codes <- unique(identifyStudents$max_actions) |>
  (\(x){unlist(strsplit(x, ",\\s*"))})()  |>
  unique()

#> unique_max_codes
#[1] "REH" "PAY" "DTA" "TER" "LOA" "POS" "XFR"
#[8] "RWB" "RFL" "HIR" "SWB" "RET" "LTO" "PLA"
#[15] "RWP" "JRC"

unique_min_codes <- unique(identifyStudents$min_actions) |>
  (\(x){unlist(strsplit(x, ",\\s*"))})()  |>
  unique()

# > unique_min_codes
# [1] "DTA" "REH" "PAY" "SWB" "RWB" "TER" "PLA"
# [8] "XFR" "HIR" "RET" "RFL" "RWP" "LOA" "JRC"

identifyStudents$student <- ifelse(grepl("TER|RET", identifyStudents$max_actions) &
                                   grepl("HIR|REH", identifyStudents$min_actions),   
                                     "student",
                                   "not_student"
                                     )



studentEMPLIDs <- identifyStudents$EMPLID[identifyStudents$student == "student"]

# manually check some of these
# sample(studentEMPLIDs, 20)

# [1] "00072017" "00068752" "00620987" "00150729"
# [5] "00431232" "00209980" "00084335" "00555061"
# [9] "00292731" "00305526" "00046324" "00391497"
# [13] "00584154" "00700492" "00717006" "00032728"
# [17] "00060121" "00095378" "00483066" "00810875"


# "00000006" didn't make the cut ecause they were terminated 
# in 2001 then re-hired in 2012.
# Seems like I could modify my logic considerably to find 
# people like this

# 00072017, 00700492, 00810875
# Logic fails for these due to the other employment record spanning the gap

# Logic fails for 00072017, as he was terminated in Nov 2012 and re-hired
# in 2013, but it looks like his EMPL_RCD 1 bridged this gap

# I might be back to the drawing board on this one.

# 00068752, 00620987, 00150729, 00209980, 00084335
# 00305526, 00046324, 00391497, 00584154, 00060121
# 00095378, 
# These work as they are supposed to

# 00431232, 00717006, 00483066
# Works correctly but edge cases 
# 00431232 all but a little bit of activity is before 2013

# 00555061, 00292731
# Technically correct, so I guess it's o.k., but not exactly the
# situation I was looking for

# 00032728
# Fails because it's too complex

# So I gotta figure this out
#  ... or do I?  Maybe there's no hard-and-fast rules,
# maybe there's only probabilities
# And I can save a "maybeStudents" list, that will be double-checked 
# against other methods or something.

possibleStudentEmplids <- studentEMPLIDs

saveRDS(possibleStudentEmplids, here::here("Data","possible_student_concurrent_emplids.rds"))





