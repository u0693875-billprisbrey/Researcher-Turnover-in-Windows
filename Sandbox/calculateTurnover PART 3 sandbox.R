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
