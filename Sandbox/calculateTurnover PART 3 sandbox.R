# calculateTurnover PART 3 sandbox.R
# 5.9.2025

# Rather than create a new "calculateTurnover" function...
# I think I want to modify my "deltaHeadCount" with a "turnover" argument
# Or I should just plain calculate turnover as an add'l column

# but the general math for turnover is to aggregate by day,
# then take the mean per desired period.

# so.... do I wrap around deltaHeadCount?  Or set it as an argumetn?
# I think I'll wrap around it.


calculateTurnover <- function(initial_count=NA, 
                              initial_date=NA,
                              calendar = "day",
                              minDate = ymd(paste(year(today()), "01","01", sep = "-")),
                              maxDate = today(),
                              data
){
  
  # Turnover is calculated as the percentage of people who leave the organization.
  # To work, it needs both how many people left the organization per interval,
  # and the headcount in the organization during that interval.
  
  # This does not use the average headcount during the period, but the final headcount
  # at the end of the period.  Accuracy could be improved by setting calendar to "day" 
  # and post-processing the resulting data frame to the desired period.
  
  #  deltaHeadCount always starts the clock at zero.  Or, if you prefer,
  #  you can start the clock at an initial head count.
  
  #  calculateTurnover will accept the initial head count as an argument or calculate
  #  an initial head count for you. 
  
  #  It will calculate the initial head count by accepting a date to start at zero, then
  #  calculating the cumulative delta up until the day before the specificed minimum date, and
  #  use this value as the initial head count.
  
  #  Or, if no date is provided, it will use the earliest date in the available data.
  
  
  #  calculateTurnover and deltaHeadCount will provide identical results if the minDate used
  #  for deltaHeadCount is the same as the initial_date used in calculateTurnover (and period  and 
  #   maxDate are the same, and the minDate == initial_date == correct starting day for the period.)
  
  # Setting calendar to "week" is slightly off between calcualteTurnover and deltaHeadCount,
  # even when I set the minDate and initial_date to the start of an isoweek.
  
  # This means that calculateTurnover is dependent on receiving good information,
  # but it can be handy to see the overall change since a particular date.  (Although
  # deltaHeadCount probably provides this more directly.)
  
  
  # calculate initial_count
  
  if(is.na(initial_count) & is.na(initial_date)){
    
    # set initial date to the earliest date in the data set
    initial_date <-  apply(retData[,c("HIRE_DT", "TERMINATION_DT")], 2, min, na.rm = TRUE) |>
      min() |>
      ymd()
    
  }
  
  
  if(is.na(initial_count)){
    
    # Establish maximum date for the period that concludes before the first period of the minDate
    
    
    if(calendar == "day"){initial_max <- minDate-1 }
    
    if(calendar == "week"){
    initial_max <- minDate
    while(isoweek(initial_max) == isoweek(minDate)) {initial_max = initial_max -1} 
    }
    
    if(calendar == "month"){
      initial_max <- minDate
      while(month(initial_max) == month(minDate)) {initial_max = initial_max -1} 
      }
    
    if(calendar == "quarter"){
      initial_max <- minDate
      while(quarter(initial_max) == quarter(minDate)) {initial_max = initial_max -1} 
      }
    
    if(calendar == "year"){
      initial_max <- minDate
      while(year(initial_max) == year(minDate)) {initial_max = initial_max -1} 
      }
    
    # calculate a value for the initial count
    
    intermediate <- deltaHeadCount(
      minDate = initial_date,
      maxDate = initial_max,
      calendar = "day",
      data = data
    ) 
    
    initial_count <-  intermediate |>
      (\(x){tail(x[,"delta.cum"],1) })()
    
  }

  # Calculate the foundation deltaHeadCount
  
  foundation <- deltaHeadCount(minDate = minDate,
                             maxDate = maxDate,
                             calendar = calendar,
                             initial_count = initial_count,
                             data = data)
  
    
  # Calculate turnover by first repeating deltaHeadCount by day
  
  turnOver <- deltaHeadCount(minDate = minDate,
                             maxDate = maxDate,
                             calendar = "day",
                             initial_count = initial_count,
                             data = data)  
  
  # aggregate to the desired period, summing the terminations and taking the avg headcount
 
  if(calendar == "day") {
    
    # for consistency in flow; these should essentially do nothing
    periodHeadCountMean <- aggregate(delta.cum ~ actionDate, data = turnOver, mean)
    names(periodHeadCountMean)[grepl("actionDate", names(periodHeadCountMean))] <- "adjDate"
    periodTerminationsSum <- aggregate(termCount ~ actionDate, data = turnOver, sum)
    names(periodTerminationsSum)[grepl("actionDate", names(periodTerminationsSum))] <- "adjDate"
  }  
  
  if(calendar == "week") {
    periodHeadCountMean <- aggregate(delta.cum ~ paste(year(actionDate), isoweek(actionDate), sep = "-W"), data = turnOver, mean)
    names(periodHeadCountMean)[grepl("actionDate", names(periodHeadCountMean))] <- "adjDate"
    periodTerminationsSum <- aggregate(termCount ~ paste(year(actionDate), isoweek(actionDate), sep = "-W"), data = turnOver, sum)
    names(periodTerminationsSum)[grepl("actionDate", names(periodTerminationsSum))] <- "adjDate"
  }
  
  
  if(calendar == "month") {
    periodHeadCountMean <- aggregate(delta.cum ~ format(actionDate, "%Y-%m"), data = turnOver, mean)
    names(periodHeadCountMean)[grepl("actionDate", names(periodHeadCountMean))] <- "adjDate"
    periodTerminationsSum <- aggregate(termCount ~ format(actionDate, "%Y-%m"), data = turnOver, sum)
    names(periodTerminationsSum)[grepl("actionDate", names(periodTerminationsSum))] <- "adjDate"
  }
  
  if(calendar == "quarter") {
    periodHeadCountMean <- aggregate(delta.cum ~ paste(year(actionDate), quarter(actionDate), sep = "-Q"), data = turnOver, mean)
    names(periodHeadCountMean)[grepl("actionDate", names(periodHeadCountMean))] <- "adjDate"
    periodTerminationsSum <- aggregate(termCount ~ paste(year(actionDate), quarter(actionDate), sep = "-Q"), data = turnOver, sum)
    names(periodTerminationsSum)[grepl("actionDate", names(periodTerminationsSum))] <- "adjDate"
  }
  
  if(calendar == "year") {
  periodHeadCountMean <- aggregate(delta.cum ~ year(actionDate), data = turnOver, mean)
  names(periodHeadCountMean)[grepl("actionDate", names(periodHeadCountMean))] <- "adjDate"
  periodTerminationsSum <- aggregate(termCount ~ year(actionDate), data = turnOver, sum)
  names(periodTerminationsSum)[grepl("actionDate", names(periodTerminationsSum))] <- "adjDate"
  }
  
  # merge mean and sum calculations
  turnOver_intermediate <- merge(periodHeadCountMean, periodTerminationsSum, by = "adjDate", sort = FALSE)
  
  
  # calculate the turnover
  turnOver_intermediate$turnover <- turnOver_intermediate$termCount/turnOver_intermediate$delta.cum
  names(turnOver_intermediate)[names(turnOver_intermediate) == "delta.cum"] <- "headcount_mean"
  
  # merge back into the foundation
  turnOver_final <- merge(foundation, turnOver_intermediate, by = "adjDate", sort = FALSE)
  
  
  return(turnOver_final)  
  
}


# making some adjustments to deltaHeadCount as well

deltaHeadCount <- function(minDate, 
                           maxDate,
                           calendar = "day",
                           initial_count = 0,
                           data) {
  
  # where data is retData
  # where minDate and maxDate are self-explanatory and work best as class "Date", or 
  # as ymd("2021-5-31")
  # where calendar is one of "day", "week", "month", "quarter", and "year".
  # where initial_count is mostly for use with calculateTurnover,
  # and represents the headcount on minDate.
  # if initial_count is zero, then the delta function will always start at zero
  
  # This is not adapted to work in fiscal years.
  
  # Working with dates has some curious behavior.
  # For one, when I have a period other than "day" then I expand
  # the aggregation period to "contain" the date range.
  # For example, if one of my dates is June 7th and the period is "month",
  # then I expand to use all of June.  The adjusted date becomes June 1st if
  # it's the minDate, and June 30th if it's the maxDate.
  
  # For two, I use "isoweek".  If I specify the calendar as "week", then I 
  # bound the minDate-maxDate range with the isoweek that contains the minDate 
  # and the maxDate.
  
  # This has the strange behavior that the isoweek doesn't align with months,
  # or quarters, or years.  This makes direct comparison between weeks and 
  # everything else impossible, as the adjusted start dates and end dates
  # will be different.
  
  # I initially tried using "isoyear", but it got really tricky if my minDate was 2019-12-31, as the isoyear for this
  # was actually 2020.  I tried dealing with this in several ways that were
  # various levels of silly and undesirable.  So I abandoned using isoyears.
  
  
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
    
  }
  
  if(calendar == "month") {
    
    monthMin <- ymd(paste(year(minDate), month(minDate),"01", sep = "-") )
    monthMax <- ymd(paste(year(maxDate), month(maxDate),"01", sep = "-") )
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(actionDate = seq(from = monthMin, to = monthMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$adjDate <- format(hrDates$actionDate, "%Y-%m") 
    
    # aggregate
    hireActions <- aggregate(one ~ format(HIRE_DT, "%Y-%m"), data = data, sum)
    names(hireActions) <- c("adjDate","one")
    termActions <- aggregate(one ~ format(TERMINATION_DT, "%Y-%m"), data = data, sum)
    names(termActions) <- c("adjDate","one")
    
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
    
  }
  
  if(calendar == "year") {
    
    yearMin <- ymd(paste(year(minDate), "01","01", sep = "-") )
    yearMax <- ymd(paste(year(maxDate), "12","31", sep = "-") )
    
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
  hrDates$delta.cum <- cumsum(hrDates$delta) + initial_count
  
  # add a "periodEnd" column for clarity in plotting
  hrDates$periodEnd <- ceiling_date(hrDates$actionDate, unit = calendar) - days(1)
  
  
  return(hrDates)
  
}
