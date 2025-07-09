# upgrade calculateMetrics sandbox
# 7.09.2025


calculateMetrics <- function(initial_count=NA, 
                             initial_date=NA,
                             calendar = "day",
                             minDate = ymd(paste(year(today()), "01","01", sep = "-")),
                             maxDate = today(),
                             data
){
  
  # This calculates various HR metrics: the counts and rates of people entering, exiting, and the net change
  # (called "delta" here.)
  
  # It uses deltaHeadCount.  Because deltaHeadCount always starts at a value of zero, this function
  # accepts or creates an initial value to result in an accurate current head count.
  
  # It accepts either an initial_count, or an initial_date.
  
  # If neither is provided, then it finds the earliest date in the data set as the initial_date.
  
  # If the initial_count is provided, then it uses that. If it is not provided, then a value for 
  # initial_count is calculated using initial_date in deltaHeadCount.  It uses the initial_date as the value for the 
  # minDate argument and the maximum date before the start of the desired period as 
  # the maxDate argument.  The final "delta.cum" result is used as the initial_count.
  
  # Then, either accepting the provided initial_count or calculating it, it uses deltaHeadCount 
  # to calculate the counts of people entering, exiting, and the net change (called "delta" here.)
  
  # What makes this an interesting wrapper to deltaHeadCount is that it will count the daily change,
  # and then aggregate that to a mean value over the desired period.  This mean is the denominator
  # for the rate calculations.
  
  #  calculateTurnover (or calculateMetrics) and deltaHeadCount will provide identical results if the minDate used
  #  for deltaHeadCount is the same as the initial_date used in calculateTurnover, and the other arguments
  #  are identical.
  
  
  # calculate initial_count
  
  if(is.na(initial_count) & is.na(initial_date)){
    
    # set initial date to the earliest date in the data set
    initial_date <-  data[,"EFFDT"] |>
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
  
  
  # Calculate mean headcount by first repeating deltaHeadCount by day
  
  meanHeadCount <- deltaHeadCount(minDate = minDate,
                                  maxDate = maxDate,
                                  calendar = "day",
                                  initial_count = initial_count,
                                  data = data)  
  
  # aggregate the mean headcount per period
  
  if(calendar == "day") {
    
    # for consistency in flow; these should essentially do nothing
    periodHeadCountMean <- aggregate(delta.cum ~ EFFDT, data = meanHeadCount, mean)
  }
  
  if(calendar == "week") {
    periodHeadCountMean <- aggregate(delta.cum ~ paste(year(EFFDT), isoweek(EFFDT), sep = "-W"), data = meanHeadCount, mean)
  }
  
  if(calendar == "month") {
    periodHeadCountMean <- aggregate(delta.cum ~ format(EFFDT, "%Y-%m"), data = meanHeadCount, mean)
  }
  
  if(calendar == "quarter") {
    periodHeadCountMean <- aggregate(delta.cum ~ paste(year(EFFDT), quarter(EFFDT), sep = "-Q"), data = meanHeadCount, mean)
  }
  
  if(calendar == "year") {
    periodHeadCountMean <- aggregate(delta.cum ~ year(EFFDT), data = meanHeadCount, mean)
  }
  
  
  # fix names
  names(periodHeadCountMean)[grepl("EFFDT", names(periodHeadCountMean))] <- "adjDate"
  names(periodHeadCountMean)[names(periodHeadCountMean) == "delta.cum"] <- "headcount_mean"
  
  # merge mean headcount back into the foundation
  foundation <- merge(foundation, periodHeadCountMean, by = "adjDate", sort = FALSE)
  
  # calculate metrics
  foundation$hireRate <- foundation$hireCount/foundation$headcount_mean
  foundation$termRate <- foundation$termCount/foundation$headcount_mean
  foundation$deltaRate <- foundation$delta/foundation$headcount_mean
  
  
  return(foundation)  
  
}