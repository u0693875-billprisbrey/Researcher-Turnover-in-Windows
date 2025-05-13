# calculateTurnover PART 3 CHECK sandbox


calculateTurnover(data = retData,
                  calendar = "day") |>
  View()

# looks fine

calculateTurnover(data = retData,
                  calendar = "week") |>
  View()

# headcount_mean is off --- how is it less than the sums for every week?

calculateTurnover(data = retData,
                  calendar = "month") |>
  View()

# this looks good

calculateTurnover(data = retData,
                  minDate = ymd("2020-04-01"),
                  maxDate = ymd("2025-03-31"),
                  calendar = "quarter") |>
  View()

# mostly o.k. -- I guess if the head count dips and recovers during a period, then the mean
# won't quite align with the trend


calculateTurnover(data = retData,
                  minDate = ymd("2020-01-01"),
                  maxDate = ymd("2024-12-31"),
                  calendar = "year") |>
  View()


# let's double-check some of these

turn_day <- calculateTurnover(data = retData,
                              calendar = "day")

turn_week <- calculateTurnover(data = retData,
                  calendar = "week")


week_check <- aggregate(delta.cum ~ paste(year(actionDate), isoweek(actionDate), sep = "-W"), data = turn_day, mean)
names(week_check)[grepl("actionDate", names(week_check))] <- "adjDate"

week_merge <- merge(turn_week, week_check, by = "adjDate", sort = FALSE)


all(week_check$delta.cum == turn_week$headcount_mean) # not the same length

all(week_merge$headcount_mean == week_merge$delta.cum.y) # TRUE

# So it's calculating correctly
# the question, then, is whether it's useful

# let's look at the week with the widest split

# or let's commit to Git and catch the bus

# essentially I think we're .... really, for the accuracy levels we're dealing with, I think we're fine.


which(turn_week$headcount_mean - turn_week$delta.cum == max(turn_week$headcount_mean - turn_week$delta.cum))

turn_week[4,]

"2020-W5"

w5_filter <- turn_day$actionDate >= ymd("2025-01-27") & turn_day$actionDate < ymd("2025-02-02")

turn_day[w5_filter,]

mean(turn_day$delta.cum[w5_filter]) #3014.33
turn_week[3:5,]

# just a little off
# yeah  . . . why?

plot(turn_day$delta.cum, x = turn_day$actionDate)
points(turn_week$delta.cum, x = turn_week$actionDate, col ="dodgerblue")
# that's a pretty big shift to the right
# maybe I got the "initial_count" a little off?

# let's see this in the deltaHeadCount

# and I should similarly plot days vs weeks, months, quarters, years
# for calculateTurnOver

# I suspect some kind of shift in what period gets aggregated and how it's merged.


# ok, and now that I see it it's obvious---

# I think the problem is when I set the initial count, I use minDate-1.
# But when I am calculating per week, month, quarter, year etc ---- I am probably double-counting 
# a week as both my last period of the initial count and then again as the first period of my new count.

# I'll experiment with moving the maximum date backwards from minDate-1 to one period backwards.

# didn't work. 
# Darn it!

turn_day <- calculateTurnover(data = retData,
                              calendar = "day")

turn_week <- calculateTurnover(data = retData,
                               calendar = "week")

turn_month <- calculateTurnover(data = retData,
                              calendar = "month")

turn_quarter <- calculateTurnover(data = retData,
                               calendar = "quarter")

turn_year <- calculateTurnover(data = retData,
                                  calendar = "year")

plot(turn_day$delta.cum, x = turn_day$actionDate, type = "l", col = "sienna")
points(turn_week$delta.cum, x = turn_week$actionDate, col ="dodgerblue")
points(turn_month$delta.cum, x = turn_month$actionDate, col ="seagreen3")
points(turn_quarter$delta.cum, x = turn_quarter$actionDate, col ="pink2")
points(turn_year$delta.cum, x = turn_year$actionDate, col ="darkorange3")

# for month/quarter/year, it plots the actionDate at the start of the period, and the value at the 
# END of the period.  Kinda confusing.
# How much do I care?  

# "week" is still just simply off

# I'm shifting backwards in time and ...yeah, that's not it.
plot(turn_day$delta.cum, 
     x = turn_day$actionDate, 
     type = "l", 
     col = "sienna", 
     ylim = c(min(turn_day$delta.cum, na.rm=TRUE),max(turn_week$delta.cum, na.rm = TRUE)),
     xlim = c(min(turn_day$actionDate - 30), max(turn_day$actionDate)+30)
     )
points(turn_week$delta.cum, x = turn_week$actionDate, col ="dodgerblue")
points(turn_week$delta.cum, x = turn_week$actionDate-7, col ="skyblue", type = "l")
points(turn_week$delta.cum, x = turn_week$actionDate-14, col ="cyan", type = "l")
points(turn_week$delta.cum, x = turn_week$actionDate-21, col ="darkblue", type = "l")
points(turn_week$delta.cum, x = turn_week$actionDate-28, col ="red", type = "l")



plot(turn_day$delta.cum, 
     x = turn_day$actionDate, 
     type = "l", 
     col = "sienna", 
     ylim = c(min(turn_day$delta.cum, na.rm=TRUE)-10,max(turn_week$delta.cum, na.rm = TRUE)+10),
     xlim = c(min(turn_day$actionDate - 30), max(turn_day$actionDate)+30)
)
points(turn_week$delta.cum, x = turn_week$actionDate, col ="dodgerblue")
points(turn_week$delta.cum-7, x = turn_week$actionDate, col ="skyblue", type = "l")
# so it's seven ahead, or subtracting 7 and it looks about perfect
points(turn_week$delta.cum-7, x = turn_week$actionDate+7, col ="cyan", type = "l")
# there's the exact match.
# so it's plotting at the start of the period, and that's kinda confusing.
# and it's adding roughly a week to the initial count.

# I'd like to figure this out.

plot(turn_day$delta.cum, 
     x = turn_day$actionDate, 
     type = "l", 
     col = "sienna", 
     ylim = c(min(turn_day$delta.cum, na.rm=TRUE)-10,max(turn_week$delta.cum, na.rm = TRUE)+10),
     xlim = c(min(turn_day$actionDate), max(turn_day$actionDate)+90)
)
points(turn_month$delta.cum, x = turn_month$actionDate+30, col ="seagreen3", pch=16)
points(turn_quarter$delta.cum, x = turn_quarter$actionDate+90, col ="pink2", pch=16)
points(turn_year$delta.cum, x = turn_year$actionDate+365, col ="orange4",pch=16)



# Decision point....

# I kinda like having my "actionDate" at the start of the period
# ...but it's also, well, wrong---because all the numbers are at the END of that period.

# Should I mess with "deltaHeadCount" ?  
# The problem is that the start is a neat "-01" for month, quarter, and year.
# I think I'll add a column.  
# Change "actionDate" to "periodStart"
# Add a column called "periodEnd"
# ...or maybe just, for simplicity, yeah add that column right now.

# And then mess with weeks (so confusing!)

# after adding "periodEnd" to deltaHeadCount

turn_day <- calculateTurnover(data = retData,
                              calendar = "day")

turn_week <- calculateTurnover(data = retData,
                               calendar = "week")

turn_month <- calculateTurnover(data = retData,
                                calendar = "month")

turn_quarter <- calculateTurnover(data = retData,
                                  calendar = "quarter")

turn_year <- calculateTurnover(data = retData,
                               calendar = "year")

plot(turn_day_old$delta.cum, x = turn_day$periodEnd, type = "l", col = "sienna")
points(turn_day$delta.cum, x = turn_day$periodEnd, col ="firebrick", type = "l", lwd = "2")
points(turn_week$delta.cum, x = turn_week$periodEnd, col ="dodgerblue", pch = 16)
points(turn_month$delta.cum, x = turn_month$periodEnd, col ="seagreen3", pch = 16)
points(turn_quarter$delta.cum, x = turn_quarter$periodEnd, col ="pink2", pch = 16)
points(turn_year$delta.cum, x = turn_year$periodEnd, col ="darkorange3", pch = 16)

# This is the way.
# Now I should mess with deltaPlot to use this.

# ...and I messed with them and something stopped working.
# ...nope, works great, I just over-write "calculateTurnover" function when sourcing "Turnover Functions".
# Now I need to figure out what is going on with the WEEKS.
# Seriously.
# WHAT IS GOING ON WITH THE WEEKS

thaDays <- deltaHeadCount(minDate = ymd("1958-01-01"), maxDate = today(), calendar = "day", data = retData)


# I should compare calculateTurnover for week with deltaHeadCount for week.
# That would be informative.

# Re-calculating the spans from deltaHeadCount plot sandbox
# doing them for calculateTurnover as well

###############
## FULL SPAN ##
###############

calendarPeriods <- c("day","week","month","quarter","year")

fullSpan <- lapply(calendarPeriods,
                   function(x){
                     
                     deltaHeadCount(
                       minDate = as.Date(min(retData$HIRE_DT, na.rm = TRUE)-1),
                       maxDate = today(),
                       calendar = x,
                       data = retData
                     )
                   })
names(fullSpan) <- calendarPeriods

fullSpan_to <- lapply(calendarPeriods,
                   function(x){
                     
                     calculateTurnover(
                       minDate = as.Date(min(retData$HIRE_DT, na.rm = TRUE))+365,
                       maxDate = today(),
                       calendar = x,
                       data = retData
                     )
                   })
names(fullSpan_to) <- calendarPeriods


############################
## EARLY SPAN 2013<x<2020 ##
############################

earlySpan <- lapply(calendarPeriods,
                    function(x){
                      
                      deltaHeadCount(
                        minDate = ymd("2013-01-01"),
                        maxDate = ymd("2019-12-31"),
                        calendar = x,
                        data = retData
                      )
                    })
names(earlySpan) <- calendarPeriods


earlySpan_to <- lapply(calendarPeriods,
                    function(x){
                      
                      calculateTurnover(
                        minDate = ymd("2013-01-01"),
                        maxDate = ymd("2019-12-31"),
                        calendar = x,
                        data = retData
                      )
                    })
names(earlySpan_to) <- calendarPeriods

######################
## LATE SPAN >=2020 ##
######################

lateSpan <- lapply(calendarPeriods,
                   function(x){
                     
                     deltaHeadCount(
                       minDate = ymd("2020-01-01"),
                       maxDate = today(),
                       calendar = x,
                       data = retData
                     )
                   })
names(lateSpan) <- calendarPeriods


lateSpan_to <- lapply(calendarPeriods,
                   function(x){
                     
                     calculateTurnover(
                       minDate = ymd("2020-01-01"),
                       maxDate = today(),
                       calendar = x,
                       data = retData
                     )
                   })
names(lateSpan_to) <- calendarPeriods

#################
## BRIEF SPAN  ##
#################

briefSpan <- lapply(calendarPeriods,
                    function(x){
                      
                      deltaHeadCount(
                        minDate = ymd("2023-07-01"),
                        maxDate = ymd("2024-10-31"),
                        calendar = x,
                        data = retData
                      )
                    })
names(briefSpan) <- calendarPeriods

briefSpan_to <- lapply(calendarPeriods,
                    function(x){
                      
                      calculateTurnover(
                        minDate = ymd("2023-07-01"),
                        maxDate = ymd("2024-10-31"),
                        calendar = x,
                        data = retData
                      )
                    })
names(briefSpan_to) <- calendarPeriods

###################
## COMPARE SPANS ##
###################

# Let's see how these compare

sapply(fullSpan, function(x){ x[nrow(x),"delta.cum"]} ) / 
sapply(fullSpan_to, function(x){ x[nrow(x),"delta.cum"]} )

# good

theDeltas <- list(fullSpan, earlySpan, lateSpan, briefSpan)
names(theDeltas) <- 
theTOs <- list(fullSpan_to, earlySpan_to, lateSpan_to, briefSpan_to)

sapply(earlySpan, function(x){ x[nrow(x),"delta.cum"]} ) - 
  sapply(earlySpan_to, function(x){ x[nrow(x),"delta.cum"]} )

# good

sapply(lateSpan, function(x){ x[nrow(x),"delta.cum"]} ) - 
  sapply(lateSpan_to, function(x){ x[nrow(x),"delta.cum"]} )

# good

sapply(briefSpan, function(x){ x[nrow(x),"delta.cum"]} ) - 
  sapply(briefSpan_to, function(x){ x[nrow(x),"delta.cum"]} )

# mostly good. Week and Year are a little off

# let's compare days and weeks for delta and turnover


plot(y = theDeltas[[1]][["day"]][,"delta.cum"], 
     x = theDeltas[[1]][["day"]][,"periodEnd"],
     col = "sienna", type = "l")

points(y=theTOs[[1]][["week"]][,"delta.cum"], 
       x=theTOs[[1]][["week"]][,"periodEnd"],
       col = "dodgerblue", type = "l", lwd = 0.5)

# it's a little off. Not a lot; not crazy.  But a little.

lowerDate <-ymd("2010-01-23")
upperDate <- ymd("2020-02-23")

deltasFilter <- theDeltas[[1]][["day"]][,"periodEnd"] >= lowerDate & 
  theDeltas[[1]][["day"]][,"periodEnd"] < upperDate
plot(y = theDeltas[[1]][["day"]][deltasFilter,"delta.cum"], 
     x = theDeltas[[1]][["day"]][deltasFilter,"periodEnd"],
     col = "sienna", type = "l")


tosFilter <-  theTOs[[1]][["week"]][,"periodEnd"] >= lowerDate & 
  theTOs[[1]][["week"]][,"periodEnd"] < upperDate
points(y=theTOs[[1]][["week"]][tosFilter,"delta.cum"], 
       x=theTOs[[1]][["week"]][tosFilter,"periodEnd"],
       col = "dodgerblue", type = "l", lwd = 1)

# some kind of weird week traceback in weeks at about 2012 and again at 2018
# Why?

# and there's a clear shift. Week (blue line) exaclty mirrors but just a little lower

# let's do some more comparisons


lowerDate <-ymd("2010-01-23")
upperDate <- ymd("2020-02-23")

deltasDayFilter <- theDeltas[[1]][["day"]][,"periodEnd"] >= lowerDate & 
  theDeltas[[1]][["day"]][,"periodEnd"] < upperDate

deltasWeekFilter <- theDeltas[[1]][["week"]][,"periodEnd"] >= lowerDate & 
  theDeltas[[1]][["week"]][,"periodEnd"] < upperDate

plot(y = theDeltas[[1]][["day"]][deltasDayFilter,"delta.cum"], 
     x = theDeltas[[1]][["day"]][deltasDayFilter,"periodEnd"],
     col = "sienna", type = "l")

points(y=theDeltas[[1]][["week"]][deltasWeekFilter,"delta.cum"], 
       x=theDeltas[[1]][["week"]][deltasWeekFilter,"periodEnd"],
       col = "cyan", type = "l", lwd = 1)


tosWeekFilter <-  theTOs[[1]][["week"]][,"periodEnd"] >= lowerDate & 
  theTOs[[1]][["week"]][,"periodEnd"] < upperDate
points(y=theTOs[[1]][["week"]][tosWeekFilter,"delta.cum"], 
       x=theTOs[[1]][["week"]][tosWeekFilter,"periodEnd"],
       col = "dodgerblue", type = "l", lwd = 1)

# so the gap happens in delta
# turnover overlaps delta[["week"]] --- except for that weird jump-back

# let's see how big that gap is.


theDeltas[[1]][["day"]][deltasDayFilter,"delta.cum"] - theDeltas[[1]][["week"]][deltasWeekFilter,"delta.cum"]

# yeah that's silly

checkMerge <- merge(theDeltas[[1]][["week"]][deltasWeekFilter,],
                    theDeltas[[1]][["day"]],
                    by = "periodEnd",
                    all.x = TRUE
                    )
par(mfrow = c(2,1))
plot(y = checkMerge$delta.cum.y,
     x = checkMerge$periodEnd,
     type = "l",
     col = "sienna"
     )

points(y = checkMerge$delta.cum.x,
     x = checkMerge$periodEnd,
     type = "l",
     col = "dodgerblue"
)

summary(checkMerge$delta.cum.y - checkMerge$delta.cum.x) # huh, that's interesting
plot(checkMerge$delta.cum.y - checkMerge$delta.cum.x)

# why is week under-counting?
# it perfectly matches the "day" line --- it's just low by a median of 27
# does that change over time?

checkMerge <- merge(theDeltas[[1]][["week"]][,],
                    theDeltas[[1]][["day"]],
                    by = "periodEnd",
                    all.x = TRUE
)

summary(checkMerge$delta.cum.y - checkMerge$delta.cum.x) # huh, that's interesting
plot(checkMerge$delta.cum.y - checkMerge$delta.cum.x)
# I've got that lagging or leading problem

plot(y = scale(checkMerge$delta.cum.y),
     x = checkMerge$periodEnd,
     type = "l",
     col = "sienna"
)

points(y = scale(checkMerge$delta.cum.x),
       x = checkMerge$periodEnd,
       type = "l",
       col = "dodgerblue"
)

points(checkMerge$delta.cum.x - checkMerge$delta.cum.y,
       x= checkMerge$periodEnd,
       type = "l",
       col = "firebrick")

# that's not what I expected, that's fer sure

plot(y = scale(checkMerge$delta.cum.y[deltasWeekFilter]),
     x = checkMerge$periodEnd[deltasWeekFilter],
     type = "l",
     col = "sienna"
)

points(y = scale(checkMerge$delta.cum.x[deltasWeekFilter]),
       x = checkMerge$periodEnd[deltasWeekFilter],
       type = "l",
       col = "dodgerblue"
)

points(scale(checkMerge$delta.cum.x[deltasWeekFilter] - checkMerge$delta.cum.y[deltasWeekFilter]),
       x= checkMerge$periodEnd[deltasWeekFilter],
       type = "l",
       col = "firebrick")

# time
# for

# I should compare days to months, quarters, and years
# and then come back to this.
# I think I just, like, over-corrected or double-corrected the lag
# It should be obvious how to fix this I think

##################################
## DELTA DAYS AND DELTA PERIODS ##
##################################

checkMerge <- merge(theDeltas[[1]][["week"]][,],
                    theDeltas[[1]][["day"]],
                    by = "periodEnd",
                    all.x = TRUE
)

summary(checkMerge$delta.cum.y - checkMerge$delta.cum.x) 
plot(checkMerge$delta.cum.y - checkMerge$delta.cum.x)

# Delta days and months is all zero
# Delta days and quarters is all zero
# Delta days and years is all zero

# It's delta days and weeks that is off

####################
## TOS AND DELTAS ##
####################

checkMerge <- merge(theTOs[[1]][["week"]][,],
                    theDeltas[[1]][["week"]],
                    by = "periodEnd",
                    all.x = TRUE
)

summary(checkMerge$delta.cum.y - checkMerge$delta.cum.x) 
plot(checkMerge$delta.cum.y - checkMerge$delta.cum.x)

# so theTOs and theDeltas are all identical to each other for all calendar periods

##############################
## DELTA DAY AND DELTA WEEK ##
##############################

checkMerge <- merge(theDeltas[[1]][["week"]][,],
                    theDeltas[[1]][["day"]],
                    by = "periodEnd",
                    all.x = TRUE
)

summary(checkMerge$delta.cum.y - checkMerge$delta.cum.x) 
plot(checkMerge$delta.cum.y - checkMerge$delta.cum.x)

checkMerge <- merge(theDeltas[[1]][["week"]][,],
                    theDeltas[[1]][["day"]],
                    by = "actionDate",
                    all.x = TRUE
)

summary(checkMerge$delta.cum.y - checkMerge$delta.cum.x) 
plot(checkMerge$delta.cum.y - checkMerge$delta.cum.x)

which(checkMerge$delta.cum.y - checkMerge$delta.cum.x == max(checkMerge$delta.cum.y - checkMerge$delta.cum.x, na.rm = TRUE))
# 2851 2862 2880 2884

checkMerge[c(2851, 2862, 2880,2884),c("periodEnd", "actionDate.x")]

# periodEnd         actionDate.x
# 2851 2013-04-13   2013-04-08
# 2862 2013-06-29   2013-06-24
# 2880 2013-11-02   2013-10-28
# 2884 2013-11-30   2013-11-25

# recall that periodEnd == actionDate.y (the actionDate for the days)

summary(as.numeric(checkMerge$actionDate.x - checkMerge$actionDate.y)) # -5

# why is it always five day shift?

# seems like I should be able to step through this pretty easily

# and let's check a different span


checkMerge <- merge(theDeltas[[1]][["week"]][,],
                    theDeltas[[1]][["day"]],
                    by = "periodEnd",
                    all.x = TRUE
)

summary(checkMerge$delta.cum.y - checkMerge$delta.cum.x) 
plot(checkMerge$delta.cum.y - checkMerge$delta.cum.x)
range(checkMerge$delta.cum.y - checkMerge$delta.cum.x, na.rm = TRUE)
# full span has a range of -24, 31
# early span has a range difference of c(-7,9)
# late span has a range of c(-15, -2)
# brief span has a range of c(5,13)


# let's walk through the month of April in 2013

weekApril <- deltaHeadCount(minDate = mdy("04-01-2013"),
               maxDate = mdy("04-30-2013"),
               calendar = "week",
               data = retData
               )

dayApril <- deltaHeadCount(minDate = mdy("04-01-2013"),
                           maxDate = mdy("04-30-2013"),
                           calendar = "day",
                           data = retData
)

aprilCheck <- merge(dayApril, weekApril, by = "periodEnd", all.x = TRUE)

# wow... did I fix it by fixing the periodEnd adjustment for week?
# was that it?


debugonce(deltaHeadCount)

deltaHeadCount(minDate = mdy("04-01-2013"),
               maxDate = mdy("04-30-2013"),
               calendar = "week",
               data = retData
)


# wow... did I fix it by fixing the periodEnd adjustment for week? from week_start =7 to =1 ?
# was that it?


# let's re-calculate and check

checkMerge <- merge(theDeltas[[1]][["week"]][,],
                    theDeltas[[1]][["day"]],
                    by = "periodEnd",
                    all.x = TRUE
)

summary(checkMerge$delta.cum.y - checkMerge$delta.cum.x) 
plot(checkMerge$delta.cum.y - checkMerge$delta.cum.x)
range(checkMerge$delta.cum.y - checkMerge$delta.cum.x, na.rm = TRUE)
# -24, 31 # as before 

fullSpan <- lapply(calendarPeriods,
                   function(x){
                     
                     deltaHeadCount(
                       minDate = as.Date(min(retData$HIRE_DT, na.rm = TRUE)-1),
                       maxDate = today(),
                       calendar = x,
                       data = retData
                     )
                   })
names(fullSpan) <- calendarPeriods

fullSpan_to <- lapply(calendarPeriods,
                      function(x){
                        
                        calculateTurnover(
                          minDate = as.Date(min(retData$HIRE_DT, na.rm = TRUE))+365,
                          maxDate = today(),
                          calendar = x,
                          data = retData
                        )
                      })
names(fullSpan_to) <- calendarPeriods

# checking improved deltaHeadCount

checkMerge <- merge(fullSpan[["week"]],
                    fullSpan[["day"]],
                    by = "periodEnd",
                    all.x = TRUE
)

summary(checkMerge$delta.cum.y - checkMerge$delta.cum.x) 
plot(checkMerge$delta.cum.y - checkMerge$delta.cum.x)
range(checkMerge$delta.cum.y - checkMerge$delta.cum.x, na.rm = TRUE)
# -3, 30 # wow, still so bad?

fullSpanCheck <- merge(fullSpan[["day"]],
                       fullSpan[["week"]],
                       by = "periodEnd",
                       all.x = TRUE
)

fullSpanCheck$diff <- fullSpanCheck$delta.cum.y - fullSpanCheck$delta.cum.x

# looks like it peaks in June 2013, so let's take a closer look


juneFilter <- fullSpanCheck$periodEnd > ymd("2013-03-15") & 
  fullSpanCheck$periodEnd <= ymd("2013-08-31")   

View(fullSpanCheck[juneFilter,])
# These all have a diff of 30
# I need a span where the diff changes

# and man I'm getting tired of this

View(fullSpanCheck[18000:22000,])

# Big jumps at:

# 2009-12-27 # big jump
# 2010-12-26 # decent jump
# 2011-12-26 (little jump)
# 2012-12-24 # this one is VERY interesting; every week is off
# 2013-12-30 
# 2015-12-28

# that's a clear pattern.
# That makes the "steps" on the graphic make more sense

# And so it scrambles at every new year?  How do I fix that?



# let's walk through the year end of 2009

dec2009day <- deltaHeadCount(minDate = ymd("2009-11-01"),
                            maxDate = ymd("2010-02-01"),
                            calendar = "day",
                            data = retData
)

dec2009week <- deltaHeadCount(minDate = ymd("2009-11-01"),
                           maxDate = ymd("2010-02-01"),
                           calendar = "week",
                           data = retData
)

dec2009check <- merge(dec2009day, dec2009week, by = "periodEnd", all.x = TRUE)

dec2009check$diff <- dec2009check$delta.cum.y -  dec2009check$delta.cum.x

# it's really easy.  I'm missing all Jan 1st activity when calendar == week

# let's shorten the time frame

lowerDate <- ymd("2009-12-20")
upperDate <- ymd("2010-01-10")

dec2009day <- deltaHeadCount(minDate = lowerDate,
                             maxDate = upperDate,
                             calendar = "day",
                             data = retData
)

dec2009week <- deltaHeadCount(minDate = lowerDate,
                              maxDate = upperDate,
                              calendar = "week",
                              data = retData
)

dec2009check <- merge(dec2009day, dec2009week, by = "periodEnd", all.x = TRUE)

dec2009check$diff <- dec2009check$delta.cum.y -  dec2009check$delta.cum.x

#ok, NOW let's step through my equation

debugonce(deltaHeadCount)

deltaHeadCount(minDate = lowerDate,
               maxDate = upperDate,
               calendar = "week",
               data = retData
)

# ok, I have attempted to fix it.

# let's try again


# check after correction

lowerDate <- ymd("2009-12-20")
upperDate <- ymd("2010-01-10")

dec2009day <- deltaHeadCount(minDate = lowerDate,
                             maxDate = upperDate,
                             calendar = "day",
                             data = retData
)

dec2009week <- deltaHeadCount(minDate = lowerDate,
                              maxDate = upperDate,
                              calendar = "week",
                              data = retData
)

dec2009check <- merge(dec2009day, dec2009week, by = "periodEnd", all.x = TRUE)

dec2009check$diff <- dec2009check$delta.cum.y -  dec2009check$delta.cum.x

# NO! # YES!

# let's debug again

debugonce(deltaHeadCount)

deltaHeadCount(minDate = lowerDate,
               maxDate = upperDate,
               calendar = "week",
               data = retData
)

# ok, found the problem and attempting again

# ok, I think that completes the fix!

# let's look at the fullSpan again


fullSpan <- lapply(calendarPeriods,
                   function(x){
                     
                     deltaHeadCount(
                       minDate = as.Date(min(retData$HIRE_DT, na.rm = TRUE)-1),
                       maxDate = today(),
                       calendar = x,
                       data = retData
                     )
                   })
names(fullSpan) <- calendarPeriods

fullSpan_to <- lapply(calendarPeriods,
                      function(x){
                        
                        calculateTurnover(
                          minDate = as.Date(min(retData$HIRE_DT, na.rm = TRUE))+365,
                          maxDate = today(),
                          calendar = x,
                          data = retData
                        )
                      })
names(fullSpan_to) <- calendarPeriods

fullSpanCheck <- merge(fullSpan[["day"]],
                       fullSpan[["week"]],
                       by = "periodEnd",
                       all.x = TRUE
)

fullSpanCheck$diff <- fullSpanCheck$delta.cum.y - fullSpanCheck$delta.cum.x

summary(fullSpanCheck$diff)
# YES!  THAT DID IT!

# man that was alotta days of debugging.

# BUT
# IT.
# IS.
# FIXED.

# now let's plot and confirm

plot(y = fullSpan[["day"]][,"delta.cum"],
     x = fullSpan[["day"]][,"periodEnd"],
     type = "l",
     col = "sienna"
    )

points(y = fullSpan[["week"]][,"delta.cum"],
     x = fullSpan[["week"]][,"periodEnd"],
     type = "l",
     col = "dodgerblue"
)

# PERFECT!

plot(y = fullSpan_to[["day"]][,"delta.cum"],
     x = fullSpan_to[["day"]][,"periodEnd"],
     type = "l",
     col = "cyan"
)

points(y = fullSpan_to[["week"]][,"delta.cum"],
       x = fullSpan_to[["week"]][,"periodEnd"],
       type = "l",
       col = "dodgerblue"
)

# man am I glad THAT is fixed!
# ok, let's update the functions and push to git !



