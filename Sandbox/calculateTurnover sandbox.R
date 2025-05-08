# calculateTurnover sandbox
# 5.2.2023

# This is developed in conjunction with Retention Exploratory Data Analysis

activePI <- function(investigation.date,
                     target = "HIRE_DT",
                     data){
  
  # this uses "retData" which is the view of hire and termination dates.
  # it returns a count of people who are "active" on a certain date
  # where active is defined as a date between hire and termination dates,
  # or after the hire date and the termination date is NA
  
  intervalCondition <- investigation.date >= data[,target] & investigation.date < data[,"TERMINATION_DT"]
  naCondition <- investigation.date >= data[,target] & is.na(data[,"TERMINATION_DT"])   
  
  
  activeCondition <- intervalCondition|naCondition
  
  
  
  return(activeCondition)
  
}


calculateTurnover <- function(data, interval = "week") {
  
  # This function returns a dataframe with the count of people 
  # active, in the re-hire period, or exiting, and 
  # calculates the turn-over as the count of people exiting divided
  # by the count of active researchers in the "hire" period.
  
  # This was an original function that has been re-written by chatGPT.
  # It needs some double-checking and comparison to confirm 
  # how it's aggregating per period.
  
  
  
  # Ensure TERMINATION_DT is properly formatted
  term_dates <- data[,"TERMINATION_DT"]
  
  # Choose the floor and ceiling functions based on interval
  if (interval == "week") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "week", week_start = 1)
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "week", week_start = 1)
    by_seq     <- "1 week"
  } else if (interval == "month") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "month")
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "month")
    by_seq     <- "1 month"
  } else if (interval == "quarter") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "quarter")
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "quarter")
    by_seq     <- "3 months"
  } else if (interval == "semester") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "6 months")
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "6 months")
    by_seq     <- "6 months"
  } else if (interval == "year") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "year")
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "year")
    by_seq     <- "1 year"
  } else {
    stop("Unsupported interval. Choose from: 'week', 'month', 'quarter', 'semester', 'year'.")
  }
  
  # Sequence of investigation dates
  turnover <- data.frame(termDT = seq(from = start_date, to = end_date, by = by_seq))
  
  # Helper to count hires or rehires
  countActive <- function(date, target) {
    activePI(investigation.date = date, target = target, data = data) |> 
      table() |> 
      (\(x) if ("TRUE" %in% names(x)) x["TRUE"] else 0)()
  }
  
  # Populate hires and rehires
  turnover$hire   <- sapply(turnover$termDT, countActive, target = "HIRE_DT")
  turnover$rehire <- sapply(turnover$termDT, countActive, target = "REHIRE_DT")
  
  # --- Exit calculation ---
  # Create interval labels for each termination date
  makeLabel <- function(dates) {
    if (interval == "week") {
      paste(year(dates), week(dates), sep = "-W")
    } else if (interval == "month") {
      paste(year(dates), month(dates), sep = "-M")
    } else if (interval == "quarter") {
      paste(year(dates), quarter(dates), sep = "-Q")
    } else if (interval == "semester") {
      sem <- ifelse(month(dates) <= 6, 1, 2)
      paste(year(dates), sem, sep = "-S")
    } else if (interval == "year") {
      as.character(year(dates))
    }
  }
  
  exit_labels <- makeLabel(term_dates)
  exit_table <- table(exit_labels)
  exit_df <- as.data.frame(exit_table, stringsAsFactors = FALSE)
  
  # Build labels for turnover sequence
  turnover$label <- makeLabel(turnover$termDT)
  
  # Merge exits into turnover
  turnover <- merge(turnover, exit_df, by.x = "label", by.y = "exit_labels", all.x = TRUE)
  names(turnover)[names(turnover) == "Freq"] <- "exit"
  
  # Replace NA exits with 0
  turnover$exit[is.na(turnover$exit)] <- 0
  
  # Calculate turnover
  turnover$to <- turnover[,"exit"]/turnover[,"hire"]
  
  return(turnover)
}

# let's pick a section to work with

minDate <- as.Date("2018-12-01")
maxDate <- as.Date("2020-06-01")
by_seq <- "day"

termFilter <- retData$TERMINATION_DT > minDate & 
  retData$TERMINATION_DT <= maxDate & 
  !is.na(retData$TERMINATION_DT)
hireFilter <- retData$HIRE_DT > minDate & 
  retData$HIRE_DT <= maxDate & 
  !is.na(retData$HIRE_DT)

dim(retData[termFilter,])
dim(retData[hireFilter,])
dim(retData[hireFilter|termFilter,])

# Let's do a day-by-day approach

turnover <- data.frame(termDT = seq(from = minDate, to = maxDate, by = by_seq))

turnover$headcount <- sapply(turnover$termDT, function(x) table(activePI(investigation.date = x, data = retData[termFilter,]))[2])

# why am I getting NA values?

plot(turnover$headcount, type = "l")

# I'd like a "start date."
# Problem with this, is, I don't know head count at day zero, whichever day I define it.
# Also, it's not good to pass in the entire data set into the function.
# If I can filter on the way in, it goes faster.

# So I can consider this, maybe more accurately, "delta head count"

# Also, in the example above, I have filtered to termination dates.
# In the first place, I should include hire dates in the same date range.
# And, seems like I could use the same logic, and tabulate hire dates.

turnover$hire_filter <- sapply(turnover$termDT, function(x) table(activePI(investigation.date = x, data = retData[hireFilter,]))[2])

plot(turnover$hire_filter, type = "l")

# huh, not what I expected.  That's interesting.
# I guess that simultaneous cliff in both graphs is July 1st.

# I need to see what's going on in the combined data

turnover$headcount_combined <- sapply(turnover$termDT, function(x) table(activePI(investigation.date = x, data = retData[hireFilter|termFilter,]))[2])

plot(turnover$headcount_combined, type = "l")

# I think I'm getting closer
# These still don't quite align how I'd expect.
# The "combined" doesn't register the cliff, and ...it should, right?

# let's plot them over-lapping

# ...I still think I got problems with my under-lying logic.
# I should be able to tally the hires and terms per day, and the delta "headcount" should be
# that combined amount.

# Working on the tallying the hires and the terms per day

# Man it's so hard to get back into this on a Monday morning.  Where was I, and what the freak was I doing?


####################
####################
## BRAIN RE-START ##
####################
####################


theDates <- data.frame(actionDate = seq(from = minDate, to = maxDate, by = by_seq))

hireActions <- table(retData$HIRE_DT[hireFilter])

plot(hireActions, type = "l")

hireActions <- data.frame(hireDate = names(hireActions), hireCount = as.numeric(hireActions))


# and clearly this will never work, because I am missing the term date aligned with the re-hire date
# I am double-counting the re-hires, because I have no record of them leaving.
# This whole effort is kinda doomed, then, isn't it?
# the only option is to ignore the re-hires
# ...or make an extreme assumption that they were terminated the day before they were re-hired.
#    It would work, but it's just ... weird.



termActions <- table(retData$TERMINATION_DT[termFilter])

plot(termActions, type = "l", col = "red")

termActions <- data.frame(termDate = names(termActions), termCount = as.numeric(termActions))

hrDates <- merge(theDates, hireActions, by.x = "actionDate", by.y = "hireDate", all.x = TRUE)
hrDates <- merge(hrDates, termActions, by.x = "actionDate", by.y = "termDate", all.x = TRUE)

plot(hrDates$hireCount, col = "darkblue")
points(hrDates$termCount, col = "firebrick")

# that's clear as mud

hrDates[is.na(hrDates)] <- 0 

# now I need a cumulative sum
# I guess I can do a net per week

hrDates$delta <- hrDates$hireCount - hrDates$termCount

plot(hrDates$delta, col = "darkblue", type = "l")

# looks like a net gain during this period

# hrDates$delta.cum <- cumsum(ifelse(is.na(hrDates$delta),0,hrDates$delta))
hrDates$delta.cum <- cumsum(hrDates$delta)
  
plot(hrDates$delta.cum, ylim = c(min(hrDates$delta), max(hrDates$delta.cum)))  

# o.k., this seems like a very realistic thing to have

points(hrDates$delta, col = ifelse(hrDates$delta >= 0, "darkgreen","firebrick" ))
#plot(hrDates$delta, col = "red")  

plot(hrDates$hireCount, col = "green")
plot(hrDates$termCount, col = "red")


# Let's compare

plot(hrDates$delta.cum, x = hrDates$actionDate,  ylim = c(min(hrDates$delta), max(hrDates$delta.cum)))  
points(y=hrDates$delta[hrDates$delta !=0], 
       x=hrDates$actionDate[hrDates$delta !=0],
       col = ifelse(hrDates$delta[hrDates$delta !=0] > 0, "darkgreen","firebrick" )
       )
#plot(hrDates$delta, col = "red")  

# plot(turnover$headcount_combined, type = "l") # wildly different
# plot(turnover$hire_filter, type = "l")        # wildly different
# plot(turnover$headcount, type = "l")          # wildly different

# I don't know what I was thinking.  I'm lost.

# and what should I do?  
# Move forward with the new logic, or carefully compare with the old?

# good thing I compared with the old.  I caught a big error.

#############
## COMPARE ##
#############

plot(hrDates$delta.cum, x = hrDates$actionDate,  ylim = c(min(hrDates$delta), max(hrDates$delta.cum)), type = "l")  
points(y=hrDates$delta[hrDates$delta !=0], 
       x=hrDates$actionDate[hrDates$delta !=0],
       col = ifelse(hrDates$delta[hrDates$delta !=0] > 0, "darkgreen","firebrick" )
)

plot(turnover$headcount_combined, type = "l")


# ok, this is great, and a relief--
# The two lines match!  Perfectly!

# the "delta" starts at zero,
# and the headcount_combined starts at !120

# So here's some ideas--
#    - Figure out how to confirm the !120 headcount starting point
#    - Always calculate the delta alongside (why? - because a check is nice, and the explicit "delta" is nice)
#    - Accept that my turnover is correct and move on
#    - Check another time span
#    - Use this same time frame, and aggregate to wewks/months/quarters/years

#####################
## HEADCOUNT DELTA ##
#####################

headCountDelta <- function(minDate, 
                           maxDate,
                           calendar = "day",
                           data) {
  
  # Add a dummy column for aggregation
  
  data[,"one"] <- 1 # because there is one PI per row
  
  # where data is retData, all of it
  # Do I want a "calendar" argument?
  
  if(calendar == "day") {
  hrDates <- data.frame(actionDate = seq(from = minDate, to = maxDate, by = calendar)) # create data frame with one row per calendar period
  }
  
  if(calendar == "week") {
    
    # discover the first date of the isoweek
    
    #targetWeek <- isoweek(minDate)
    #targetYear <- isoyear(minDate)
    
    weekMin <- minDate
    while(isoweek(weekMin) == isoweek(minDate) ) {weekMin <- weekMin - 1 }
    weekMin <- weekMin+1
    
    weekMax <- maxDate
    while(isoweek(weekMax) == isoweek(maxDate) ) {weekMax <- weekMax + 1 }
    weekMax <- weekMax-1
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(actionDate = seq(from = weekMin, to = weekMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$isoDate <- paste(isoyear(hrDates$actionDate), isoweek(hrDates$actionDate), sep = "-W")
    
    
  }
  
  # Aggregate hire and termination actions
  
  if(calendar == "day") {
  hireActions <- aggregate(one ~ HIRE_DT, data = data, sum)
  termActions <- aggregate(one ~ TERMINATION_DT, data = data, sum)
  }
  
  if(calendar == "week") {
    hireActions <- aggregate(one ~ paste(isoyear(HIRE_DT), isoweek(HIRE_DT), sep = "-W"), data = data, sum)
    names(hireActions) <- c("isoDate","one")
    termActions <- aggregate(one ~ paste(isoyear(TERMINATION_DT), isoweek(TERMINATION_DT), sep = "-W"), data = data, sum)
    names(termActions) <- c("isoDate","one")
  }
  
  if(calendar == "month") {
    hireActions <- aggregate(one ~ month(HIRE_DT), data = data, sum)
    termActions <- aggregate(one ~ month(TERMINATION_DT), data = data, sum)
  }
  
  if(calendar == "quarter") {
    hireActions <- aggregate(one ~ quarter(HIRE_DT), data = data, sum)
    termActions <- aggregate(one ~ quarter(TERMINATION_DT), data = data, sum)
  }
  
  if(calendar == "year") {
    hireActions <- aggregate(one ~ isoyear(HIRE_DT), data = data, sum)
    termActions <- aggregate(one ~ isoyear(TERMINATION_DT), data = data, sum)
  }
  
  # merge
  
  if(calendar == "day") {
  # prepare for merge
  hireActions$HIRE_DT <- as.Date(hireActions$HIRE_DT)
  termActions$TERMINATION_DT <- as.Date(termActions$TERMINATION_DT)
  
  # merge
  hrDates <- merge(hrDates, hireActions, by.x = "actionDate", by.y = "HIRE_DT", all.x = TRUE)
  hrDates <- merge(hrDates, termActions, by.x = "actionDate", by.y = "TERMINATION_DT", all.x = TRUE)
  
  # post-merge clean-up
  names(hrDates) <- c("actionDate", "hireCount", "termCount")
  }
  
  if(calendar == "week"){
  
    # merge
    hrDates <- merge(hrDates, hireActions, by = "isoDate", all.x = TRUE)
    names(hrDates)[names(hrDates) == "one"] <- "hireCount"
    hrDates <- merge(hrDates, termActions, by = "isoDate", all.x = TRUE)
    names(hrDates)[names(hrDates) == "one"] <- "termCount"
  }
  
  
  # convert NA to zero
  hrDates[is.na(hrDates)] <- 0
  
  # calculate delta
  hrDates$delta <- hrDates$hireCount - hrDates$termCount
  
  # calculate delta cumulative
  hrDates$delta.cum <- cumsum(hrDates$delta)
  
  # put in chronological order
  hrDates <- hrDates[order(hrDates[,"actionDate"]),]
  
  return(hrDates)
  
}


# re-doing the flow

deltaHeadCount <- function(minDate, 
                           maxDate,
                           calendar = "day",
                           data) {
  
  # where data is retData
  
  # Add a dummy column for aggregation
  
  data[,"one"] <- 1 # because there is one PI per row
  
  if(calendar == "day") {
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(actionDate = seq(from = minDate, to = maxDate, by = calendar)) 
    
    # duplicate column name to parallel other calendar periods
    hrDates$adjDate <- hrDates$actionDate
    
    # Aggregate hire and termination actions
    hireActions <- aggregate(one ~ HIRE_DT, data = data, sum)
    names(hireActions) <- c("adjDate","one")
    termActions <- aggregate(one ~ TERMINATION_DT, data = data, sum)
    names(termActions) <- c("adjDate","one")
    
    # prepare for merge
    hireActions$adjDate <- as.Date(hireActions$adjDate)
    termActions$adjDate <- as.Date(termActions$adjDate)
    
    
#    # merge
#    hrDates <- merge(hrDates, hireActions, by.x = "actionDate", by.y = "HIRE_DT", all.x = TRUE)
#    names(hrDates)[names(hrDates) == "one"] <- "hireCount"
#    hrDates <- merge(hrDates, termActions, by.x = "actionDate", by.y = "TERMINATION_DT", all.x = TRUE)
#    names(hrDates)[names(hrDates) == "one"] <- "termCount"
    
  }
  
  if(calendar == "week") {
    
    # discover the extreme dates of the isoweek
    weekMin <- minDate
    while(isoweek(weekMin) == isoweek(minDate) ) {weekMin <- weekMin - 1 }
    weekMin <- weekMin+1
    
    weekMax <- maxDate
    while(isoweek(weekMax) == isoweek(maxDate) ) {weekMax <- weekMax + 1 }
    weekMax <- weekMax-1
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(actionDate = seq(from = weekMin, to = weekMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$adjDate <- paste(year(hrDates$actionDate), isoweek(hrDates$actionDate), sep = "-W")
    
    # aggregate
    hireActions <- aggregate(one ~ paste(year(HIRE_DT), isoweek(HIRE_DT), sep = "-W"), data = data, sum)
    names(hireActions) <- c("adjDate","one")
    termActions <- aggregate(one ~ paste(year(TERMINATION_DT), isoweek(TERMINATION_DT), sep = "-W"), data = data, sum)
    names(termActions) <- c("adjDate","one")
    
#    # merge
#    hrDates <- merge(hrDates, hireActions, by = "adjDate", all.x = TRUE)
#    names(hrDates)[names(hrDates) == "one"] <- "hireCount"
#    hrDates <- merge(hrDates, termActions, by = "adjDate", all.x = TRUE)
#    names(hrDates)[names(hrDates) == "one"] <- "termCount"
    
  }
  
  if(calendar == "month") {
    
    monthMin <- ymd(paste(year(minDate), month(minDate),"01", sep = "-") )
    monthMax <- ymd(paste(year(maxDate), month(maxDate),"01", sep = "-") )
    
    # this converts to a character string
    #monthMin <- format(minDate, "%Y-%m")
    #monthMax <- format(maxDate, "%Y-%m")
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(actionDate = seq(from = monthMin, to = monthMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$adjDate <- format(hrDates$actionDate, "%Y-%m") 
    
    # aggregate
    hireActions <- aggregate(one ~ format(HIRE_DT, "%Y-%m"), data = data, sum)
    names(hireActions) <- c("adjDate","one")
    termActions <- aggregate(one ~ format(TERMINATION_DT, "%Y-%m"), data = data, sum)
    names(termActions) <- c("adjDate","one")
    
#    # merge
#    hrDates <- merge(hrDates, hireActions, by = "adjDate", all.x = TRUE)
#    names(hrDates)[names(hrDates) == "one"] <- "hireCount"
#    hrDates <- merge(hrDates, termActions, by = "adjDate", all.x = TRUE)
#    names(hrDates)[names(hrDates) == "one"] <- "termCount"
    
  }
  
  if(calendar == "quarter"){
    
    # discover the extreme dates of the quarter
    quarterMin <- minDate
    while(quarter(quarterMin) == quarter(minDate) ) {quarterMin <- quarterMin - 1 }
    quarterMin <- quarterMin+1
    
    quarterMax <- maxDate
    while(quarter(quarterMax) == quarter(maxDate) ) {quarterMax <- quarterMax + 1 }
    quarterMax <- quarterMax-1    
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(actionDate = seq(from = quarterMin, to = quarterMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$adjDate <- paste(year(hrDates$actionDate), quarter(hrDates$actionDate), sep = "-Q")
    
    # aggregate
    hireActions <- aggregate(one ~ paste(year(HIRE_DT), quarter(HIRE_DT), sep = "-Q"), data = data, sum)
    names(hireActions) <- c("adjDate","one")
    termActions <- aggregate(one ~ paste(year(TERMINATION_DT), quarter(TERMINATION_DT), sep = "-Q"), data = data, sum)
    names(termActions) <- c("adjDate","one")
    
#    # merge
#    hrDates <- merge(hrDates, hireActions, by = "adjDate", all.x = TRUE)
#    names(hrDates)[names(hrDates) == "one"] <- "hireCount"
#    hrDates <- merge(hrDates, termActions, by = "adjDate", all.x = TRUE)
#    names(hrDates)[names(hrDates) == "one"] <- "termCount"
    
    
  }
  
  if(calendar == "year") {
    
    # force rounding in case minDate or maxDate is in Jan or Dec
    # This should avoid isoyear confusion of a minDate of, say, 2019-12-31 is chosen
    
    #if(month(minDate)| month(maxDate) %in% c(1,12)){ 
      
    #    minDate <- ymd(paste(year(minDate), month(minDate),"15", sep = "-"))

    #  }
    
    
    yearMin <- ymd(paste(year(minDate), "01","01", sep = "-") )
    yearMax <- ymd(paste(year(maxDate), "12","31", sep = "-") )
    
  #  # discover the extreme dates of the isoyear, as Jan 1st floats between years
  #  # weekMin <- minDate
  #  while(isoyear(yearMin) == year(minDate) ) {yearMin <- yearMin - 1 }
  #  yearMin <- yearMin+1
    
  #  # weekMax <- maxDate
  #  while(isoyear(yearMax) == year(maxDate) ) {yearMax <- yearMax + 1 }
  #  yearMax <- yearMax-1
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(actionDate = seq(from = yearMin, to = yearMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$adjDate <- year(hrDates$actionDate) 
        
    # aggregate
    hireActions <- aggregate(one ~ year(HIRE_DT), data = data, sum)
    names(hireActions) <- c("adjDate","one")
    termActions <- aggregate(one ~ year(TERMINATION_DT), data = data, sum)
    names(termActions) <- c("adjDate","one")
    
  }
  
  # merge
  hrDates <- merge(hrDates, hireActions, by = "adjDate", all.x = TRUE, sort=FALSE)
  names(hrDates)[names(hrDates) == "one"] <- "hireCount"
  hrDates <- merge(hrDates, termActions, by = "adjDate", all.x = TRUE, sort= FALSE)
  names(hrDates)[names(hrDates) == "one"] <- "termCount"
  
  # restore chronological order 
  # (although I've fixed it be setting sort=FALSE in merge, I'll double-correct)
  hrDates <- hrDates[order(hrDates$actionDate),]
  
  # Calculate delta
  
  # convert NA to zero
  hrDates[is.na(hrDates)] <- 0
  
  # calculate delta
  hrDates$delta <- hrDates$hireCount - hrDates$termCount
  
  # calculate delta cumulative
  hrDates$delta.cum <- cumsum(hrDates$delta)
  
  return(hrDates)
  
}


# find the beginning of the time period
checkDate <- minDate
while(isoweek(checkDate) == targetWeek ) {checkDate <- checkDate - 1 }
checkDate <- checkDate+1 # because it decrements once too many


plotHeadCount <- function(data){ 
  
plot(data$delta.cum, 
     x = data$actionDate,  
     ylim = c(10*min(data$delta), 10*max(data$delta.cum)), 
     type = "l",
     lwd = 3,
     col = "darkorange2")  
points(y=data$delta[data$delta !=0], 
       x=data$actionDate[data$delta !=0],
       col = ifelse(data$delta[data$delta !=0] > 0, "darkgreen","firebrick" )
) 
} 

span_day <- headCountDelta(minDate = minDate,
                           maxDate = maxDate,
                           data = retData)

span_week <- headCountDelta(minDate = minDate,
                           maxDate = maxDate,
                           calendar = "week",
                           data = retData)

span_month <- headCountDelta(minDate = minDate,
                            maxDate = maxDate,
                            calendar = "month",
                            data = retData)

span_quarter <- headCountDelta(minDate = minDate,
                            maxDate = maxDate,
                            calendar = "quarter",
                            data = retData)

span_year <- headCountDelta(minDate = minDate,
                            maxDate = maxDate,
                            calendar = "year",
                            data = retData)

par(mfrow = c(5,1),
    mar = c(3,4,1,0),
    fg = "blue",
    bg = "ivory")

lapply(list(span_day, 
            span_week[order(span_week$actionDate),], 
            span_month, 
            span_quarter, 
            span_year
            ),
       plotHeadCount)

# something goofy when plotting span_week

# possibly a merge error? # FIXED (it sorted by isoDate when merging, throwing 
# the subsequent "cumsum" off)

# I still have the "period starting" instead of "period ending" thing happening

# let's pick different periods

bottomDate <- ymd("2020-08-01") # "2007-08-01"
topDate <- today() #ymd("2025-12-31")

par(mfrow = c(5,1),
    mar = c(3,4,1,0),
    fg = "sienna",
    bg = "ivory")

invisible(
lapply(list("day","week","month","quarter","year"), function(x){
  plotHeadCount(headCountDelta(minDate = bottomDate,
                               maxDate = topDate,
                               calendar = x,
                               data = retData))
  
  
})
)

# I like this graphic.
# When I am running from 2020 to today, and it shows a decline,
# the plot line bottoms out along the bottom axis.  
# how can I toggle the limits so the line doesn't overlap the bottom axis?
# I'm messing with my simple graphic, and it's leaving quite a bit to be desired.
# Should I resist the urge to fix it?  Or dive in and make it a nice graphic?

# Can I show that the decliners/leavers are the longest-serving?

# rather than create and immediately consume, I'm going to run two lapply's

bottomDate <- ymd("2019-12-31") # "2007-08-01" # "2020-08-01"
topDate <- today() #ymd("2025-12-31")

snippet <-  lapply(list("day","week","month","quarter","year"), function(x){
    deltaHeadCount(minDate = bottomDate,
                                 maxDate = topDate,
                                 calendar = x,
                                 data = retData)
    
    
  })
names(snippet) <- paste("snippet", c("day","week","month","quarter","year"), sep = "_" )

invisible(
  lapply(snippet, plotHeadCount)
  
)

# so when I use a bottomDate of "2020-08-01" and a topDate of today,
# I get different values for delta.cum
# I think it's because it expands to the start of the year/quarter.
# let's see if  I get the same values when I start on Jan 1st

# ok, if I can figure out why these are slightly different, I think I'm there

# snippet_year isoDates are wrong

headCountDelta(minDate = bottomDate,
               maxDate = topDate,
               calendar = "year",
               data = retData)

# It turns out that Jan 1, 2021 is in isoyear 2020 (as is Jan 1, 2020) 
# Now that's wild
# I'll need to use the same day-by-day iteration as I use elsewhere
# Nope, I'm just going to force it to Jan 15th or Dec 15th

lapply(snippet, function(x){x[c(1,nrow(x)),]})

# the "year" is still way, way off the others.

filter2019 <- snippet[["snippet_day"]][["actionDate"]] == ymd("2019-12-31")
snippet[["snippet_day"]][filter2019,] # 0

filter2020 <- snippet[["snippet_day"]][["actionDate"]] == ymd("2020-12-31")
snippet[["snippet_day"]][filter2020,] # 1

filterJan <- month(snippet[["snippet_day"]][["actionDate"]]) == 1 
filterOne <- day(snippet[["snippet_day"]][["actionDate"]]) == 1              

snippet[["snippet_day"]][filterJan & filterOne,]

# let's do this year by year

#> snippet[["snippet_year"]]
#isoDate actionDate hireCount termCount delta delta.cum
#1    2019 2019-01-15       170        99    71        71
#2    2020 2020-01-15       119       119     0        71
#3    2021 2021-01-15       101       137   -36        35
#4    2022 2022-01-15       117       132   -15        20
#5    2023 2023-01-15       110       133   -23        -3
#6    2024 2024-01-15        68       174  -106      -109
#7    2025 2025-01-15         6        35   -29      -138

# > snippet[["snippet_year"]]
# adjDate actionDate hireCount termCount delta delta.cum
# 1    2019 2019-01-01       170        99    71        71
# 2    2020 2020-01-01       110       109     1        72
# 3    2021 2021-01-01       106       134   -28        44
# 4    2022 2022-01-01       115       135   -20        24
# 5    2023 2023-01-01       116       143   -27        -3
# 6    2024 2024-01-01        68       174  -106      -109
# 7    2025 2025-01-01         6        35   -29      -138

yearByYear <- lapply(c(2019:2026), function(x){
  
  deltaHeadCount(minDate = ymd(paste(x,"01-01", sep = "-")),
                 maxDate = ymd(paste(x,"12-31", sep = "-")),
                 calendar = "day",
                 data = retData
                 )
  
})

lapply(yearByYear, tail)

# some years match and some don't
# I'm gonna need to look at this closer.

# And I should do the same logic for weeks, months, and quarters.
# And I think I'm just going to strip this of "isoyears".

c(71,1,-28, -20, -27, -106,-29,0)

# ok, it matches!  

# let's look at weeks, months, and quarters now

yearByYear <- lapply(c(2019:2026), function(x){
  
  deltaHeadCount(minDate = ymd(paste(x,"01-01", sep = "-")),
                 maxDate = ymd(paste(x,"12-31", sep = "-")),
                 calendar = "day",
                 data = retData
  )
  
})

lapply(yearByYear, tail)


intervalCheck <- lapply(c("day","week","month","quarter","year"), function(y){
  
  lapply(c(2019:2026), function(x){
    
    deltaHeadCount(minDate = ymd(paste(x,"01-01", sep = "-")),
                   maxDate = ymd(paste(x,"12-31", sep = "-")),
                   calendar = y,
                   data = retData
    )
    
  })
  
})

names(intervalCheck) <- c("day","week","month","quarter","year")

# that's not quite what I want

# let's think this through and come back to it.

# I"m honestly really burned out on it.  It's hard to get into it.

# let's check days vs weeks

weekByWeek <- lapply(c(2019:2026), function(x){
  
  deltaHeadCount(minDate = ymd(paste(x,"01-01", sep = "-")),
                 maxDate = ymd(paste(x,"12-31", sep = "-")),
                 calendar = "day",
                 data = retData
  )
  
})

# let's check my original minDate to maxDate
# call this one "section

# bottomDate <- ymd("2019-12-31") # "2007-08-01" # "2020-08-01"
# topDate <- today() #ymd("2025-12-31")

minDate <- as.Date("2018-12-01")
maxDate <- as.Date("2020-06-01")

section <-  lapply(list("day","week","month","quarter","year"), function(x){
  deltaHeadCount(minDate = minDate,
                 maxDate = maxDate,
                 calendar = x,
                 data = retData)
  
  
})
names(section) <- paste("section", c("day","week","month","quarter","year"), sep = "_" )

lapply(section, tail)

# man I am so burned up on this.

# let's just do day vs week for two months
# 


  deltaHeadCount(minDate = ymd("2019-12-01"),
                 maxDate = ymd("2020-01-31"),
                 calendar = "day",
                 data = retData
  )
  
  deltaHeadCount(minDate = ymd("2019-12-01"),
                 maxDate = ymd("2020-01-31"),
                 calendar = "week",
                 data = retData
  ) # this uses isoweeks, so it's not the same as the days and months
    # it expands to the start of the week and the end of the week to 
    # contain or "bound" the dates

  deltaHeadCount(minDate = ymd("2019-12-01"),
                 maxDate = ymd("2020-01-31"),
                 calendar = "month",
                 data = retData
  ) # this checks with the days
  
  deltaHeadCount(minDate = ymd("2019-12-01"),
                 maxDate = ymd("2020-01-31"),
                 calendar = "quarter",
                 data = retData
  )
  
  
# ok, I think I"m happy
  
  
# but I should compare to the activePI
  
  