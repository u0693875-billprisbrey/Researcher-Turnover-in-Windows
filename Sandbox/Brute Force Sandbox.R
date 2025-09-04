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


