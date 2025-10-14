# Brute Force sandbox
# 9.3.2025

# PURPOSE:  Attempting to see what a "brute force" attempt looks like.

# METHOD:
# Pull in the time diff data
# ASsign the boundaries (per record, per emplid)
# No modifications
# Apply a version of the delta headcount
#  Create a dataframe per day
#  Have columns per EMPL_RCD that has the headcount
#  Look for deviations from value of zero and one

# Eh let's play with it

##########
## LOAD ##
##########

cj_diff <- readRDS(here::here("Data", "concurrentJourney_timeDiff.rds") )

###############
## LIBRARIES ##
###############

library(lubridate)

###############
## FUNCTIONS ##
###############

source(here::here("Functions", "Brute Force Functions.R"))


# How much am I going to re-invent the wheel here?

# Let's pick a few choices ---

# pre Student sample EMPLIDs

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

######################
## ATTEMPTING DELTA ##
######################

emplid <- "00072017.1"

cj_diff[[emplid]] |>
  assignBoundaries() |>
  (\(x){deltaHeadCount(data = x,
    minDate = min(cj_diff[[emplid]][["EFFDT"]]),
    maxDate = max(cj_diff[[emplid]][["EFFDT"]])
  )})() |>
  (\(x){summary(x[,"delta.cum"])})()

# ok, let's, like, do a lot of them . . .?
# but, like, which regime?

# Let's try the combining the EMPL_RCD's

emplid <- "00072017"

theData <- rbind(cj_diff[[paste(emplid,"0", sep = ".")]], cj_diff[[paste(emplid,"1", sep = ".")]])

theData |>
  assignBoundaries() |>
  (\(x){deltaHeadCount(data = x,
                       minDate = min(x$EFFDT),
                       maxDate = max(x$EFFDT)
  )})() |>
  (\(x){summary(x[,"delta.cum"])})()

# there's my error -- max of 2 !

# I can create a force fit column ... let's see

forceFit <- theData |>
  assignBoundaries() |>
  (\(x){deltaHeadCount(data = x,
                       minDate = min(x$EFFDT),
                       maxDate = max(x$EFFDT)
  )})()

# maybe overlay this --
> plot(forceFit[,"exit"])
> plot(forceFit[,"entry"])
> plot(forceFit[,"delta"])
> plot(forceFit[,"delta.cum"])

# over the plotJourney?  A combined graphic, or two on top?

# "00072017" is actually kind of simple
# No, I've made a mistake somewhere; the data is doubled

par(mfrow =c(2,1), mar = c(1,2,1,1) )

plot(forceFit[,"delta.cum"])

theData |>
  assignBoundaries() |>
  plotJourney()

# This is actually an interesting graphic

par(mfrow =c(2,1), mar = c(1,2,1,1) )

plot(forceFit[,"delta.cum"], type = "b",cex = 0.5, lty = 1, col = "brown")

theData |>
  assignBoundaries() |>
  plotJourney()

# wow, that's my new "plotJourney" fer sure!

# And maybe the "forceFit" is just the way to go
# Probably will take a lot of computational power, though

forceFit$force <- pmax(0, pmin(1, forceFit$delta.cum))

par(mfrow =c(2,1), mar = c(1,2,1,1) )

plot(forceFit[,"delta.cum"], type = "b",cex = 0.5, lty = 1, col = "brown")
lines(forceFit[,"force"], type = "b", cex = 0.75, lty = 1, col = "skyblue")

theData |>
  assignBoundaries() |>
  plotJourney()

# I need a closer look at what is happening with the
# short work break in the EMPL_RCD == 1 in th middle


View(assignBoundaries(cj_diff[[paste(emplid,"1", sep = ".")]]))

# He essentially left the RCD == 1 on 2011-01-01, 
# returning from a "work break" just to terminate 
# the second position on the same day on 2013-10-01

View(assignBoundaries(cj_diff[[paste(emplid,"0", sep = ".")]]))

# In Job 0, he was terminated on 2011-12-16
# Then re-hired on 2013-07-01

# I need to modify my stacked plots to show dates...
# The force fit is looking o.k.


par(mfrow =c(2,1), mar = c(2.5,2,1,1) )

plot(y = forceFit[,"delta.cum"],
     x = forceFit[,"EFFDT"],
     type = "b",cex = 0.5, lty = 1, col = "brown")
lines(y = forceFit[,"force"], 
      x = forceFit[,"EFFDT"],
      type = "b", cex = 0.75, lty = 1, col = "skyblue")

theData |>
  assignBoundaries() |>
  plotJourney()

# I think the force fit is working great in this case.

# I like the stacked plot; that's my new "plotJourney"

# I need to figure out how to combine for 2+ employees
# (do I merge on the dates?)

# And, I can call this an approximation with declining
# accuracy per regime.

# And/or I can use this as a double-check compared to 
# other more prosaic ways

# Then I need to add transfers, and possible age-outs.

#################
## ANOTHER ONE ##
#################

emplid <- "00700492"

theData2 <- rbind(cj_diff[[paste(emplid,"0", sep = ".")]], cj_diff[[paste(emplid,"1", sep = ".")]])

forceFit2 <- theData2 |>
  assignBoundaries() |>
  (\(x){deltaHeadCount(data = x,
                       minDate = min(x$EFFDT),
                       maxDate = max(x$EFFDT)
  )})()

forceFit2$force <- pmax(0, pmin(1, forceFit2$delta.cum))

par(mfrow =c(2,1), mar = c(2.5,2,1,1) )

plot(y = forceFit2[,"delta.cum"],
     x = forceFit2[,"EFFDT"],
     type = "b",cex = 0.75, lty = 1, col = "brown")
lines(y = forceFit2[,"force"], 
      x = forceFit2[,"EFFDT"],
      type = "b", cex = 0.35, lty = 1, col = "skyblue")

theData2 |>
  assignBoundaries() |>
  plotJourney()

# Such a weird one -- the SWB in Job 0, and the short stints
# in Job 2
# Time to look at the data

View(assignBoundaries(theData2))

# The force fit is a completely reasonable interpretation of the data
# Let's do a third, then try to combine them

###############
## THIRD ONE ##
###############

emplid <- "00810875"

theData3 <- rbind(cj_diff[[paste(emplid,"0", sep = ".")]], cj_diff[[paste(emplid,"1", sep = ".")]])

forceFit3 <- theData3 |>
  assignBoundaries() |>
  (\(x){deltaHeadCount(data = x,
                       minDate = min(x$EFFDT),
                       maxDate = max(x$EFFDT)
  )})()

forceFit3$force <- pmax(0, pmin(1, forceFit3$delta.cum))

par(mfrow =c(2,1), mar = c(2.5,2,1,1) )

plot(y = forceFit3[,"delta.cum"],
     x = forceFit3[,"EFFDT"],
     type = "b",cex = 0.75, lty = 1, col = "brown")
lines(y = forceFit3[,"force"], 
      x = forceFit3[,"EFFDT"],
      type = "b", cex = 0.35, lty = 1, col = "skyblue")

theData3 |>
  assignBoundaries() |>
  plotJourney()

# Perfectly reasonable interpretataion

# Now let's combine them
# first I'll trouble-shoot with ChatGPT

# I could use this method to extract estimates of 
# start-and-stop dates, and then I'm back to 
# using the metrics I already have.

# That's probably the cleanest way.

# How would I do that?

forceFit$change <- c(0, diff(forceFit$force))
forceFit2$change <- c(0, diff(forceFit2$force))
forceFit3$change <- c(0, diff(forceFit3$force))

# I want to start the prior day so I get that "entry" change

starts1 <- forceFit$EFFDT[forceFit$change == 1]
stops1  <- forceFit$EFFDT[forceFit$change == -1]

starts2 <- forceFit2$EFFDT[forceFit2$change == 1]
stops2  <- forceFit2$EFFDT[forceFit2$change == -1]

starts3 <- forceFit3$EFFDT[forceFit3$change == 1]
stops3 <- forceFit3$EFFDT[forceFit3$change == -1]

# first day
if (forceFit$force[1] == 1) {
  starts1 <- c(forceFit$EFFDT[1], starts1)
}

if (forceFit2$force[1] == 1) {
  starts2 <- c(forceFit2$EFFDT[1], starts2)
}

if (forceFit3$force[1] == 1) {
  starts3 <- c(forceFit3$EFFDT[1], starts3)
}

emplid1 <- data.frame(
  emplid = ,
  start = starts,
  stop = stops
)

# Should I create a new dataframe, or
# add a new column in the old dataframe with these dates?
# Call that new column "university"?

# I'd need to dig into how my "calculateMetrics" works

# This is honestly a promising approach.

# When I come back--

#   - The new graphic of the force fit to display above my prior
#      individual journey plot as the new individua journey plot
#   - New functions to create, or modify the previous one
#   - Figure out how to use the force fit column --
#      - Extract the start/stop dates?
#      - Or create the large daily matrix of 1/0's?

###############################
## COMING BACK ON 10/10/2025 ##
###############################

# So now I have start/stops 1 thru 3....
# I am going to plot these on my plotJourney graphics and see what I've got
# Looks very reasonable.

# I'm pretty sure I want the start/stop dates per EMPLID
# I'm not sure what to do with them or how to use them
# ...but I'm going to start by extracting them for my list cj_diff



par(mfrow =c(2,1), mar = c(2.5,2,1,1) )

plot(y = forceFit[,"delta.cum"],
     x = forceFit[,"EFFDT"],
     type = "b",cex = 0.75, lty = 1, col = "brown")
lines(y = forceFit[,"force"], 
      x = forceFit[,"EFFDT"],
      type = "b", cex = 0.35, lty = 1, col = "skyblue")

abline( v = starts1,
        lwd = 2,
        col = "green")

abline( v = stops1,
        lwd = 2,
        col = "red")

theData |>
  assignBoundaries() |>
  plotJourney()



##
par(mfrow =c(2,1), mar = c(2.5,2,1,1) )

plot(y = forceFit2[,"delta.cum"],
     x = forceFit2[,"EFFDT"],
     type = "b",cex = 0.75, lty = 1, col = "brown")
lines(y = forceFit2[,"force"], 
      x = forceFit2[,"EFFDT"],
      type = "b", cex = 0.35, lty = 1, col = "skyblue")

abline( v = starts2,
        lwd = 2,
        col = "green")

abline( v = stops2,
        lwd = 2,
        col = "red")

theData2 |>
  assignBoundaries() |>
  plotJourney()

##
par(mfrow =c(2,1), mar = c(2.5,2,1,1) )

plot(y = forceFit3[,"delta.cum"],
     x = forceFit3[,"EFFDT"],
     type = "b",cex = 0.75, lty = 1, col = "brown")
lines(y = forceFit3[,"force"], 
      x = forceFit3[,"EFFDT"],
      type = "b", cex = 0.35, lty = 1, col = "skyblue")

abline( v = starts3,
        lwd = 2,
        col = "green")

abline( v = stops3,
        lwd = 2,
        col = "red")

theData3 |>
  assignBoundaries() |>
  plotJourney()

# I like those plots and they were a nice review.

# I have developed a function "extractUniversityBoundaries" (you can find it in the sandbox)
# and now I need to use this to calculate deltaHeadcount.

# FIRST, recombine cj_diff into one data frame per employee

# Extract the unique emplids

emplids <- names(cj_diff) |>
  (\(x){
    gsub("\\.[[:digit:]]+$",
         "",
         x)
  })() |> 
  unique()


# This takes a few minutes
cjEmplids <- lapply(emplids, function(emplid) {
  
  list_positions <- grep(emplid, names(cj_diff))
  
  full_frame <- do.call(rbind, cj_diff[list_positions])  
  
  return(full_frame)
  
}  )
names(cjEmplids) <- emplids

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

testData <- do.call(rbind, cjEmplids[1:10])

source(here::here("Functions", "Turnover Functions.R"))

testData |>
  assignBoundaries() |>
  deltaHeadCount(
    minDate = min(testData$EFFDT),
    maxDate = max(testData$EFFDT),
    calendar = "day",
    initial_count = 0
) |>
  dim()

# ok, nice enough
# looks like where it needs work is in "assignBoundaries"

testData |>
  assignBoundaries() |>
  calculateMetrics() |>
  plotMetrics()

# man, why is it being so difficult?


testBoundaries <- testData |>
  assignBoundaries() 

testMetrics <- testData |>
  assignBoundaries() |>
  (\(x){ 
  calculateMetrics(data = x, minDate = min(testData$EFFDT))
  })()

# ugh
# At this point I just want SOMETHING to work

testDelta <- testData |>
  assignBoundaries() |>
  (\(x){ 
  deltaHeadCount(data = x,
                 minDate = min(testData$EFFDT),
                 maxDate = max(testData$EFFDT))
  })()

deltaPlot(testDelta) # AT LEAST THAT WORKS !
 
# I think I want an "assignUniversityBoundaries" function
#  that.... hold on ....

# I have two choices---
# I can either modify my DATA or I can modify my FUNCTION
# and if I modify my DATA, I'll need a function that does that

# This is going to take a little thinking.

# I think I'll just append "university" to the existing boundary types
# I guess

# that will happen after "assignBoundaries"


modifyBoundaries <- function(data, university_dates_list){
  
  # where data is the output from "assignBoundaries"
  # for developing the function
  # data <- testBoundaries
  # university_dates_list <- universityBoundaries
  
  # ok, this is some fun data manipulation
  # maybe I turn that list of vectors into a data frame?
  
  
  
  
  
}
   

> momo <-data.frame(start = universityBoundaries[[1]]["starts"],
                    +            stop = universityBoundaries[[1]]["stops"])
Error in data.frame(start = universityBoundaries[[1]]["starts"], stop = universityBoundaries[[1]]["stops"]) : 
  arguments imply differing number of rows: 4, 3

> # yeah
  
momo <- data.frame(EFFDT = c(
  universityBoundaries[[1]][["starts"]],
  universityBoundaries[[1]][["stops"]]),
  univ_boundary = c(rep("start", length (universityBoundaries[[1]][["starts"]] )),
               rep("stop", length(universityBoundaries[[1]][["stops"]]))   )
)  |>
  (\(x){x[order(x$EFFDT),]})()
momo$EMPLID <- rep(names(universityBoundaries)[1], nrow(momo))

# o.k., nice
# nice, nice

# a little clunky, but I can probably clean that up

# o.k.
# now I think we'd merge that into the Boundaries data frame
# and it's a new column, "univ_boundary"

##########################
## UPTAKE on 10.13.2025 ##
##########################

##########
## LOAD ##
##########

cj_diff <- readRDS(here::here("Data", "concurrentJourney_timeDiff.rds") )

###############
## FUNCTIONS ##
###############

source(here::here("Functions", "Brute Force Functions.R"))

emplids <- names(cj_diff) |>
  (\(x){
    gsub("\\.[[:digit:]]+$",
         "",
         x)
  })() |> 
  unique()

# THIS ONE TAKES ABOUT 10min --- and I could probably find
# whre I broke out "cj_diff" instead of re-combining it here.

cjEmplids <- lapply(emplids, function(emplid) {
  
  list_positions <- grep(emplid, names(cj_diff))
  
  full_frame <- do.call(rbind, cj_diff[list_positions])  
  
  return(full_frame)
  
}  )
names(cjEmplids) <- emplids

universityBoundaries <- lapply(cjEmplids[1:10], extractUniversityBoundaries)
names(universityBoundaries) <- names(cjEmplids[1:10])

# This is awkward.  I should pull in the name in the "extract" function with an 
# additional argument or something

names_vector <- names(universityBoundaries)

universityBoundaries <- lapply(names_vector, function(nm) {
  df <- universityBoundaries[[nm]]
  df$EMPLID <- nm
  df
})
names(universityBoundaries) <- names_vector  # keep original names


univBound <- do.call(rbind, universityBoundaries)

testData <- do.call(rbind, cjEmplids[1:10])

source(here::here("Functions", "Turnover Functions.R"))

testBoundaries <- testData |>
  assignBoundaries() |>
  (\(x){merge(x, univBound, by = c("EFFDT","EMPLID"), all.x = TRUE)})()

# ok, great
# Now---- what?
# I need to modify calculateMetrics to use this new field,
# is what!

# let's try deltaHeadCount_univ to this

testDelta <- testBoundaries |>
  (\(x){ 
    deltaHeadCount_univ(data = x,
                   minDate = min(testData$EFFDT),
                   maxDate = max(testData$EFFDT))
  })()

source(here::here("Functions", "Turnover Functions.R"))
deltaPlot(testDelta) # works great!  Huh

# let's try "calculateMetrics"

testCalc <- testBoundaries |> 
  (\(x){ 
    calculateMetrics_univ(data = x,
                        minDate = min(x$EFFDT),
                        maxDate = max(x$EFFDT))
  })()

# debugging this
deltaHeadCount_univ(
  minDate = ymd("1995-02-21"),  # initial_date,
  maxDate = ymd("1995-02-20"),   # initial_max, # HUH?
  calendar =  "day",
  data =  # data
) 

# So I'm supposed to pass in larger data sets

# rather than fix that, let's do this

##############################
## ALL CONCURRENT EMPLOYEES ##
##############################

universityBoundaries <- lapply(cjEmplids, extractUniversityBoundaries)
names(universityBoundaries) <- names(cjEmplids)

# several of these have zero rows for some reason
zeroRow <- sapply(universityBoundaries, nrow) == 0
# -which(names_vector %in% c("00076345", "00091371", "00722429" )) 

names_vector <- names(universityBoundaries)
universityBoundaries <- lapply(names_vector[!zeroRow], function(nm) {
  df <- universityBoundaries[[nm]]
  df$EMPLID <- nm
  df
})
names(universityBoundaries) <- names_vector[!zeroRow]  # keep original names

univBound <- do.call(rbind, universityBoundaries)

cjData <- do.call(rbind, cjEmplids[!zeroRow])

cjBoundaries <- cjData |>
  assignBoundaries() |>
  (\(x){merge(x, univBound, by = c("EFFDT","EMPLID"), all.x = TRUE)})()


cjCalc <- cjBoundaries |> 
  (\(x){ 
    calculateMetrics_univ(data = x,
                          minDate = min(x$EFFDT),
                          maxDate = max(x$EFFDT))
  })()

cjCalc <- cjBoundaries |>
  (\(x){ 
    calculateMetrics_univ(data = x)
  })()

plotMetrics_univ(cjCalc)

# well, it looks like something.

# the big problem is that the head count exceeds 40,000
# when my unique count of emplids is only 32,000.

# So I know I have an error

# Plotting a few more, because why not

cjBoundaries |>
  (\(x){ 
    calculateMetrics_univ(data = x,
                          minDate = ymd("2015-01-01") # "1960-01-01"
                          
                          )
  })() |>
  plotMetrics_univ()

# o.k., let's do some trouble-shooting.

# View(cjEmplids[[1]])
# well isn't that weird
# no data after 2020-06-16, but no termination either 

# I am going to look into a different data source and see what I find

prepData <- readRDS(here::here("Data", "prepData17Apr2025.rds") )
cleanData <- readRDS(here::here("Data", "cleanData17Apr2025.rds") )

jPop <- readRDS(here::here("Data", "journeyPopulation.rds")) 

# maybe I'll just need to query it directly

################
## CONNECTION ##
################

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), 
                         Driver = "Oracle in OraClient19Home1", 
                         # Host = "ocm-campus01.it.utah.edu", 
                         # SVC = "biprodusr.sys.utah.edu",
                         DBQ = "//ocm-campus01.it.utah.edu:2080/biprodusr.sys.utah.edu",
                         UID = Sys.getenv("userid"),
                         PWD = Sys.getenv("pwd"),
                         Port = 2080)


###########
## QUERY ##
###########

emplidQuery <- "
 SELECT *
 FROM ds_hr.EMPL_AGE_RANGE_ACTION_MV_V
 WHERE EMPLID = '00000006'"


startTime <- Sys.time()
emplidJourney <- dbGetQuery(con.ds, emplidQuery)
endTime <- Sys.time()
print(paste("emplidJourney:", endTime-startTime)) 

####

# So--- yeah, that's the data I have on '00000006'
# No data after 2020, when s/he was last an adjunct professor
# and no termination

# This still doesn't explain how I got a headcount higher
# than the unique EMPLID's.

# who is my HR contact again?  -- text message sent to Brian K Gelsinger

# next, let's iterate through the EMPLID's and see who has a delta-cum greater than 1

# I guess I'm looking for more starts than stops
checkFrame <- lapply(universityBoundaries, function(x) {table(x$univ_boundary)})

theDiff <- unlist(sapply(checkFrame, diff))

> summary(theDiff)
Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
-1.0000  0.0000  0.0000 -0.1785  0.0000  0.0000 
> # max of ZERO.  Z.E.R.O.

# names(theDiff) <- sub("\\.stop$", "", names(theDiff))

# Error is happening in the merge,
# when they have multiple actions on a day.
# DUH.
  
# that'll take a little thinking to get through.  
  
##
# Or not that much thinking.
# Why "assignBoundaries", and why merge?
# Maybe I can do.call(rbind, universityBoundaries) and just calculate metrics
# and plot that.
  
univCalc <- univBound |>
  (\(x){ 
    calculateMetrics_univ(data = x)
  })()

plotMetrics_univ(univCalc)

# wow, ok, that's simple  

# wow, o.k., ... I guess we're good!



