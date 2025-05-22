# Turnover Functions
# 4.29.2025

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
    hrDates$adjDate <- paste(isoyear(hrDates$actionDate), sprintf("%02d", isoweek(hrDates$actionDate)), sep = "-W")
    # hrDates$adjDate <- paste(year(hrDates$actionDate), isoweek(hrDates$actionDate), sep = "-W")
    
    # aggregate
    hireActions <- aggregate(one ~ paste(isoyear(HIRE_DT), sprintf("%02d", isoweek(HIRE_DT)), sep = "-W"), data = data, sum)
    names(hireActions) <- c("adjDate","one")
    termActions <- aggregate(one ~ paste(isoyear(TERMINATION_DT), sprintf("%02d", isoweek(TERMINATION_DT)), sep = "-W"), data = data, sum)
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
  if(calendar == "week"){ 
    hrDates$periodEnd <- ceiling_date(hrDates$actionDate, unit = calendar, week_start = 1) - days(1)
  } else {
    hrDates$periodEnd <- ceiling_date(hrDates$actionDate, unit = calendar) - days(1)
  }
  
  return(hrDates)
  
}

deltaPlot <- function(data,
                      cumulative_plot_params = list(),
                      cumulative_points_params = list(),
                      cumulative_mtext_params = list(),
                      cumulative_rect_args = list(),
                      cumulative_grid_args = list(),
                      delta_plot_params = list(),
                      delta_points_params = list(),
                      delta_mtext_params = list(),
                      delta_upper_rect_args = list(),
                      delta_lower_rect_args = list(),
                      delta_grid_args = list(),
                      title_mtext_params = list()
){
  
  # This accepts the output of "deltaHeadCount" and creates a nice little graphic
  
  # POSSIBLE ADJUSTMENTS:
  #  explicitly call out the starting date (and ending date and delta cum?)
  
  # ADJUSTMENTS DONE:
  #  shade the "delta" for above-and-below zero # DONE, looks great.
  #  add advanced details, like plot shading and the "list" flexibility # DONE
  #  the bottom margin is too big if the time frame is large and it shows years;
  #  it's just right if it's showing weeks # NOW MANUALLY ADJUSTABLE
  
  ############
  ## LAYOUT ##
  ############
  
  layout(matrix(1:2, nrow = 2), heights = c(0.618, 0.382))
  
  default_cumulative_plot_params <- list(oma = c(0,0,2,0),
                                         mar = c(0,4,0,1),
                                         bg="ivory",
                                         fg = "grey10")
  
  cumulative_plot_params <- modifyList(default_cumulative_plot_params,
                                       cumulative_plot_params)
  
  incoming.par <- do.call(par, cumulative_plot_params)
  on.exit(par(incoming.par))
  
  #####################
  ## CUMULATIVE PLOT ##
  #####################
  
  plot(y = data[,"delta.cum"],
       x = data[,"periodEnd"],
       type = "n",
       xlab = "",
       xaxt = "n",
       # col = "sienna",
       las = 1,
       ylab = ""# "headcount\ncumulative"
  )
  
  # Rectangle (plot color) (Establish after plot is drawn)
  
  default_cumulative_rect_args <- list(
    xleft = par("usr")[1], 
    ybottom = par("usr")[3], 
    xright = par("usr")[2], 
    ytop = par("usr")[4],
    col = "gray95", 
    border = NA
  )
  
  cumulative_rect_args <- modifyList(default_cumulative_rect_args, cumulative_rect_args)
  
  # Grid (Establish after the plot is drawn)
  
  default_cumulative_grid_args <- list(col = "gray100", lwd = 2, lty = "dotted")
  cumulative_grid_args <- modifyList(default_cumulative_grid_args, cumulative_grid_args)
  
  # Draw rectangle and grid
  do.call("rect", cumulative_rect_args)
  #  do.call("grid", cumulative_grid_args)
  
  # experimenting with the grid
  grid_y <- axTicks(2)
  grid_x <- pretty(data[,"periodEnd"], n = 5)
  
  do.call(abline, c(list(h=grid_y), cumulative_grid_args))
  do.call(abline, c(list(v=grid_x), cumulative_grid_args))
  
  # Cumulative line
  default_cumulative_points_params <- list(
    y = data[,"delta.cum"],
    x = data[,"periodEnd"],
    type = "l",
    col = "sienna"
  )
  
  cumulative_points_params <- modifyList(default_cumulative_points_params, cumulative_points_params)
  
  do.call(points, cumulative_points_params)
  
  default_cumulative_mtext_params <- list(
    side = 2,
    line = 3,
    text = "cumulative")
  cumulative_mtext_params <- modifyList(default_cumulative_mtext_params, 
                                        cumulative_mtext_params)
  
  do.call(mtext, cumulative_mtext_params)
  
  ################
  ## DELTA PLOT ##
  ################
  
  default_delta_plot_params <- list(mar = c(4,4,0,1))
  
  delta_plot_params <- modifyList(default_delta_plot_params,
                                  delta_plot_params)
  
  do.call(par, delta_plot_params)
  
  
  plot(y= data[,"delta"],
       x= data[,"periodEnd"],
       type = "n",
       xlab = "",
       # col = "seagreen3",
       las = 2,
       ylab = "" # "delta"
  )
  
  # Rectangle (plot color) (Establish after plot is drawn)
  
  default_delta_upper_rect_args <- list(
    xleft = par("usr")[1], 
    ybottom = 0, #par("usr")[3], 
    xright = par("usr")[2], 
    ytop = par("usr")[4],
    col = adjustcolor("palegreen3", alpha.f = 0.1), 
    border = NA
  )
  
  delta_upper_rect_args <- modifyList(default_delta_upper_rect_args, delta_upper_rect_args)
  
  default_delta_lower_rect_args <- list(
    xleft = par("usr")[1], 
    ybottom = par("usr")[3], 
    xright = par("usr")[2], 
    ytop = 0, #par("usr")[4],
    col = adjustcolor("pink", alpha.f = 0.5), 
    border = NA
  )
  
  delta_lower_rect_args <- modifyList(default_delta_lower_rect_args, delta_lower_rect_args)
  
  
  # Grid (Establish after the plot is drawn)
  
  default_delta_grid_args <- list(col = "lightgray", lwd = 1, lty = "dotted")
  delta_grid_args <- modifyList(default_delta_grid_args, delta_grid_args)
  
  # Draw rectangle and grid
  do.call("rect", delta_upper_rect_args)
  do.call("rect", delta_lower_rect_args)
  # do.call("grid", delta_grid_args)
  
  # experimenting with the grid
  grid_y <- axTicks(2)
  grid_x <- pretty(data[,"periodEnd"], n = 5)
  
  do.call(abline, c(list(h=grid_y), delta_grid_args))
  do.call(abline, c(list(v=grid_x), delta_grid_args))
  
  # Draw the points  
  default_delta_points_params <- list(y= data[,"delta"],
                                      x= data[,"periodEnd"],
                                      type = "l",
                                      col = "seagreen"
  )
  
  delta_points_params <- modifyList(default_delta_points_params, delta_points_params)
  
  do.call(points, delta_points_params)
  
  default_delta_mtext_params <- list(side = 2,
                                     line = 3,
                                     text = "delta"
  )
  delta_mtext_params <- modifyList(default_delta_mtext_params, 
                                   delta_mtext_params)
  
  do.call(mtext, delta_mtext_params)
  
  ################
  ## OUTER TEXT ##
  ################
  
  default_title_mtext_params <- list(text = "Delta Headcount", 
                                     side = 3,
                                     line = 0.3,
                                     font =2, 
                                     cex = 1.3, 
                                     outer = TRUE)
  
  title_mtext_params <- modifyList(default_title_mtext_params, title_mtext_params)
  
  do.call(mtext, title_mtext_params)
  
}


calculateMetrics <- function(initial_count=NA, 
                             initial_date=NA,
                             calendar = "day",
                             minDate = ymd(paste(year(today()), "01","01", sep = "-")),
                             maxDate = today(),
                             data
){
  
  # This calculates various HR metrics: the counts and rates of people hired, terminated, and the net change
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
  # to calculate the counts of people hired, terminated, and the net change (called "delta" here.)
  
  # What makes this an interesting wrapper to deltaHeadCount is that it will count the daily change,
  # and then aggregate that to a mean value over the desired period.  This mean is the denominator
  # for the rate calculations.
  
  #  calculateTurnover (or calculateMetrics) and deltaHeadCount will provide identical results if the minDate used
  #  for deltaHeadCount is the same as the initial_date used in calculateTurnover, and the other arguments
  #  are identical.
  
  
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
  
  
  # Calculate mean headcount by first repeating deltaHeadCount by day
  
  meanHeadCount <- deltaHeadCount(minDate = minDate,
                                  maxDate = maxDate,
                                  calendar = "day",
                                  initial_count = initial_count,
                                  data = data)  
  
  # aggregate the mean headcount per period
  
  if(calendar == "day") {
    
    # for consistency in flow; these should essentially do nothing
    periodHeadCountMean <- aggregate(delta.cum ~ actionDate, data = meanHeadCount, mean)
  }
  
  if(calendar == "week") {
    periodHeadCountMean <- aggregate(delta.cum ~ paste(year(actionDate), isoweek(actionDate), sep = "-W"), data = meanHeadCount, mean)
  }
  
  if(calendar == "month") {
    periodHeadCountMean <- aggregate(delta.cum ~ format(actionDate, "%Y-%m"), data = meanHeadCount, mean)
  }
  
  if(calendar == "quarter") {
    periodHeadCountMean <- aggregate(delta.cum ~ paste(year(actionDate), quarter(actionDate), sep = "-Q"), data = meanHeadCount, mean)
  }
  
  if(calendar == "year") {
    periodHeadCountMean <- aggregate(delta.cum ~ year(actionDate), data = meanHeadCount, mean)
  }
  
  
  # fix names
  names(periodHeadCountMean)[grepl("actionDate", names(periodHeadCountMean))] <- "adjDate"
  names(periodHeadCountMean)[names(periodHeadCountMean) == "delta.cum"] <- "headcount_mean"
  
  # merge mean headcount back into the foundation
  foundation <- merge(foundation, periodHeadCountMean, by = "adjDate", sort = FALSE)
  
  # calculate metrics
  foundation$hireRate <- foundation$hireCount/foundation$headcount_mean
  foundation$termRate <- foundation$termCount/foundation$headcount_mean
  foundation$deltaRate <- foundation$delta/foundation$headcount_mean
  
  
  return(foundation)  
  
}

plotMetrics <- function(data,
                        plotList = "all",
                        featureMap = NA,
                        cumulative_plot_params = list(),
                        cumulative_points_params = list(),
                        cumulative_legend_params = list(),
                        cumulative_mtext_params = list(),
                        cumulative_rect_args = list(),
                        cumulative_grid_args = list(),
                        delta_plot_params = list(),
                        delta_points_params = list(),
                        delta_mtext_params = list(),
                        delta_upper_rect_args = list(),
                        delta_lower_rect_args = list(),
                        delta_grid_args = list(),
                        delta_legend_params = list(),
                        metric_plot_params = list(),
                        hire_points_params = list(),
                        term_points_params = list(),
                        metric_legend_params = list(),
                        metric_legend2_params = list(),
                        metric_mtext_params = list(),
                        metric_rect_args = list(),
                        metric_grid_args = list(),
                        title_mtext_params = list()
){
  
  # This accepts the output of "deltaHeadCount" or "calculateMetrics" 
  # and creates several graphics of different metrics over time.
  
  # NOTES FOR USING:
  # If you don't want to show both hire and term rate lines, then set the argument "type='n'"
  #  in the appropriate params list (but it would still show up in the legend.  Hmm.)
  # If you don't want to show a particular legend, then set the argument "plot = FALSE"
  #  in the appropriate params list.
  
  # If you don't want to show the headcount or cumulative graphic, you may need to
  # set oma = c(0,0,2,0) in metric_plot_params or delta_plot_params to provide space
  # for the title.
  
  # Values for plotList are c("all", "headcount", "cumulative", "rate", "count", "delta.count", "delta.rate")
  
  # Here are some example calls:
  # plotMetrics(complexMetrics[c("unassigned")], 
  #             plotList = c("count", "delta.count"), 
  #             delta_legend_params = list(plot = FALSE), 
  #             term_points_params = list(type = "b", lty = 2), 
  #             featureMap = complexClusterColors, 
  #             metric_plot_params = list(oma=c(0,0,2,0)), 
  #             metric_legend_params = list(x="bottom", pch = c(NA,1),  lty = c(3,3), pt.cex = 1.2))
  # plotMetrics(complexMetrics[c(2,4)], 
  #              plotList = c("headcount", "rate", "delta.rate"), 
  #              delta_legend_params = list(plot = FALSE), 
  #              term_points_params = list(type = "b", lty = 2), 
  #              featureMap = complexClusterColors, 
  #              metric_legend_params = list(x="top", pch = c(NA,1),  lty = c(3,3), pt.cex = 1.2))
  
  #  plotMetrics(collegeMetrics[c("Med", "Engr", "Hunt","Science")], 
  #                             plotList = c("rate", "delta.rate"), 
  #                             metric_plot_params = list(oma = c(0,0,2,0)),
  #                             delta_legend_params = list(plot = FALSE), 
  #                             term_points_params = list(type = "b", lty = 2), 
  #                             featureMap = NA, 
  #                             metric_legend_params = list(x="top", pch = c(NA,1),  lty = c(3,3), pt.cex = 1.2))
  
  #  plotMetrics(collegeMetrics[2:11], 
  #                             plotList = c("count", "delta.count"), 
  #                             metric_plot_params = list(oma = c(0,0,2,0)),
  #                             delta_legend_params = list(plot = FALSE), 
  #                             term_points_params = list(type = "b", lty = 2),
  #                             hire_points_params = list(type = "n"),
  #                             featureMap = NA, 
  #                             metric_legend_params = list(x="top", pch = c(NA,1),  lty = c(3,3), pt.cex = 1.2), 
  #                             metric_legend2_params = list(x="topleft"))
  
  # POSSIBLE ADJUSTMENTS:
  # I could explicitly label points like starting date and concluding headcount values 
  #    with text on the graphic
  
  
  ###############################
  ## MANAGE INCOMING ARGUMENTS ##
  ###############################
  
  if(is.data.frame(data)) {data <- list(data)}
  
  if(all(is.na(featureMap))) {
    featureMap <- c("sienna",
                    "forestgreen",
                    "deepskyblue",
                    "goldenrod",
                    "firebrick",
                    "darkslategray",
                    "chartreuse",
                    "slateblue",
                    "darkkhaki",
                    "coral")
    
    if(all(!is.na(names(data)))){
      names(featureMap) <- names(data)
    }
    
  }
  
  if("all" %in% plotList){ plotList <- c("cumulative", "rate", "delta.rate")  }
  
  if(all(c("rate","count") %in% plotList )) { 
    stop("Select 'rate' or 'count' in plotList argument.")
  }
  
  if(all(c("delta.rate","delta.count") %in% plotList )) { 
    stop("Select 'delta.rate' or 'delta.count' in plotList argument.")
  }
  
  ############
  ## LAYOUT ##
  ############
  
  if(any(grepl("rate", tolower(colnames(data[[1]])))) # has the necessary columns
     & (
       any(c("headcount", "cumulative") %in% plotList) &&
       any(c("rate", "count") %in% plotList) &&
       any(c("delta.rate", "delta.count") %in% plotList)
     )
  ) {
    
    layout(matrix(1:3, nrow = 3), heights = c(0.456, 0.281, 0.263))
    
  } else if( 
    length(plotList) > 1  # if there's more than one plot
  ) {
    
    layout(matrix(1:2, nrow = 2), heights = c(0.618, 0.382))
    
  } else {
    
    layout(matrix(1:1, nrow = 1), heights = c(1))
    
  }
  
  
  #####################
  ## CUMULATIVE PLOT ##
  #####################
  
  if( any(c("cumulative", "headcount") %in% plotList)  ){
    
    
    if(any(c("rate", "count", "delta.rate","delta.count") %in% plotList)){ # include the x axis if there's no metrics or delta plot
      
      xAxt <- "n"
      default_cumulative_plot_params <- list(
        oma = c(0,0,2,0),
        mar = c(0,6,0,1),
        bg = "ivory",
        fg = "grey30")
      
    } else { 
      
      xAxt <- "s" 
      default_cumulative_plot_params <- list(
        oma = c(0,0,2,0),
        mar = c(4,6,0,1),
        bg = "ivory",
        fg = "grey30")
    } 
    
    cumulative_plot_params <- modifyList(default_cumulative_plot_params,
                                         cumulative_plot_params)
    
    incoming.par <- do.call(par, cumulative_plot_params)
    on.exit(par(incoming.par))
    
    # set yLim
    yLim <- range(sapply(data, function(x){range(x[,"delta.cum"])}))
    
    plot(y = data[[1]][,"delta.cum"],
         x = data[[1]][,"periodEnd"],
         ylim = yLim,
         type = "n",
         xlab = "",
         xaxt = xAxt, #"n",
         las = 1,
         ylab = ""
    )
    
    # Rectangle (plot color) (Establish after plot is drawn)
    
    default_cumulative_rect_args <- list(
      xleft = par("usr")[1], 
      ybottom = par("usr")[3], 
      xright = par("usr")[2], 
      ytop = par("usr")[4],
      col = "gray95", 
      border = NA
    )
    
    cumulative_rect_args <- modifyList(default_cumulative_rect_args, cumulative_rect_args)
    
    # Grid (Establish after the plot is drawn)
    
    default_cumulative_grid_args <- list(col = "gray100", lwd = 2, lty = "dotted")
    cumulative_grid_args <- modifyList(default_cumulative_grid_args, cumulative_grid_args)
    
    # Draw rectangle and grid
    do.call("rect", cumulative_rect_args)
    
    # experimenting with the grid
    grid_y <- axTicks(2)
    grid_x <- pretty(data[[1]][,"periodEnd"], n = 5)
    
    do.call(abline, c(list(h=grid_y), cumulative_grid_args))
    do.call(abline, c(list(v=grid_x), cumulative_grid_args))
    
    # draw the lines using Map
    invisible(Map(function(df, col) {
      do.call(points, modifyList(
        list(
          y = df[,"delta.cum"],
          x = df[,"periodEnd"],
          type = "l",
          col =col
          #col = ifelse(length(data) == 1, "sienna",col)
        ),
        cumulative_points_params
      ))
    }, data, featureMap[names(data)]))
    
    # margin text
    
    if(any(grepl("rate", tolower(colnames(data[[1]]))))){ 
      
      default_cumulative_mtext_params <- list(
        side = 2,
        line = 4,
        text = "head count")
      
    } else {
      
      default_cumulative_mtext_params <- list(
        side = 2,
        line = 4,
        text = "cumulative")
      
    }
    
    cumulative_mtext_params <- modifyList(default_cumulative_mtext_params, 
                                          cumulative_mtext_params)
    
    do.call(mtext, cumulative_mtext_params)
    
    # legend
    
    default_cumulative_legend_params <- list(
      x = "topleft",
      legend = names(data),
      col = featureMap[names(data)],
      pch = 15, 
      pt.cex = 2
    )
    
    cumulative_legend_params <- modifyList(default_cumulative_legend_params, cumulative_legend_params)
    
    do.call(legend, cumulative_legend_params)
    
    
  }
  
  
  
  ##################
  ## METRICS PLOT ##
  ##################
  
  if(any(grepl("rate", tolower(colnames(data[[1]])))) &
     any(c("rate", "count") %in% plotList)
  ) {
    
    if("rate" %in% plotList && !("count" %in% plotList) ) {
      
      hireVal <- 100*data[[1]][,"hireRate"]
      termVal <- 100*data[[1]][,"termRate"]
      
      
      yLim <- range(unlist(
        lapply(data, function(df) {
          apply(df[, c("hireRate", "termRate")], 1, range, na.rm = TRUE)
        })
      ), na.rm = TRUE) * 100
      
      y_label <- "rates (%)"
      legendText <- c("Hire", "Departure")
      
    }
    
    if("count" %in% plotList && !("rate" %in% plotList) ) {
      hireVal <- data[[1]][,"hireCount"]
      termVal <- data[[1]][,"termCount"] 
      
      yLim <- range(unlist(
        lapply(data, function(df) {
          apply(df[, c("hireCount", "termCount")], 1, range, na.rm = TRUE)
        })
      ), na.rm = TRUE)    
      
      y_label <- "count"
      legendText <- c("Hire", "Departure")
    }
    
    if(any(c("delta.rate","delta.count") %in% plotList)){ # include the x axis if there's no delta plot
      
      xAxt <- "n"
      default_metric_plot_params <- list(
        # oma = c(0,0,2,0),
        mar = c(0,6,0,1),
        bg = "ivory",
        fg = "grey30")
      
    } else { 
      
      xAxt <- "s" 
      default_metric_plot_params <- list(
        # oma = c(0,0,2,0),
        mar = c(4,6,0,1),
        bg = "ivory",
        fg = "grey30")
    } 
    
    
    
    metric_plot_params <- modifyList(default_metric_plot_params,
                                     metric_plot_params)
    
    do.call(par, metric_plot_params)
    
    # empty plot
    
    plot(y= hireVal, #100*data[,"hireRate"],
         x= data[[1]][,"periodEnd"],
         ylim = yLim,
         type = "n",
         xlab = "",
         xaxt = xAxt, # "n",
         # col = "seagreen3",
         las = 2,
         ylab = "" # "delta"
    )
    
    # Rectangle (plot color) (Establish after plot is drawn)
    
    default_metric_rect_args <- list(
      xleft = par("usr")[1], 
      ybottom = par("usr")[3], 
      xright = par("usr")[2], 
      ytop = par("usr")[4],
      col = "gray95", 
      border = NA
    )
    
    metric_rect_args <- modifyList(default_metric_rect_args, metric_rect_args)
    
    # Grid (Establish after the plot is drawn)
    
    default_metric_grid_args <- list(col = "gray100", lwd = 2, lty = "dotted")
    metric_grid_args <- modifyList(default_metric_grid_args, metric_grid_args)
    
    # Draw rectangle
    do.call("rect", metric_rect_args)
    
    # Draw the grid
    grid_y <- axTicks(2)
    grid_x <- pretty(data[[1]][,"periodEnd"], n = 5)
    
    do.call(abline, c(list(h=grid_y), metric_grid_args))
    do.call(abline, c(list(v=grid_x), metric_grid_args))
    
    # Draw the points  
    
    if("rate" %in% plotList && !("count" %in% plotList)  ) {
      
      # draw the hire points using Map
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = 100*df[,"hireRate"],
            x = df[,"periodEnd"],
            type = "l",
            lty =3,
            col = ifelse(length(data) == 1, "darkcyan",col)
          ),
          hire_points_params
        ))
      }, data, featureMap[names(data)]))  
      
      # draw the termination points using Map
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = 100*df[,"termRate"],
            x = df[,"periodEnd"],
            type = "l",
            col = ifelse(length(data) == 1, "coral",col)
          ),
          term_points_params
        ))
      }, data, featureMap[names(data)]))  
      
    }
    
    if("count" %in% plotList && !("rate" %in% plotList) ) {
      
      # draw the hire lines using Map
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = df[,"hireCount"],
            x = df[,"periodEnd"],
            type = "l",
            lty = 3,
            col = ifelse(length(data) == 1, "darkcyan",col)
          ),
          hire_points_params
        ))
      }, data, featureMap[names(data)]))
      
      # draw the termination lines using Map
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = df[,"termCount"],
            x = df[,"periodEnd"],
            type = "l",
            col = ifelse(length(data) == 1, "coral",col)
          ),
          term_points_params
        ))
      }, data, featureMap[names(data)]))
      
    }
    
    
    # Margin text
    
    default_metric_mtext_params <- list(side = 2,
                                        line = 4,
                                        text = y_label 
    )
    metric_mtext_params <- modifyList(default_metric_mtext_params, 
                                      metric_mtext_params)
    
    do.call(mtext, metric_mtext_params)
    
    # legend
    
    if (length(data) == 1) {
      default_metric_legend_params <- list(
        x = "topleft",
        legend = legendText, 
        col = c("darkcyan","coral"),
        lty = c(3,1),
        lwd = c(1.5,3)
      )
    } else {
      
      default_metric_legend_params <- list(
        x = "topleft",
        legend = legendText, 
        col = c("gray50","gray50"),
        lty = c(3,1),
        lwd = c(1.5,3)
      ) 
      
    }
    
    metric_legend_params <- modifyList(default_metric_legend_params, metric_legend_params)
    
    do.call(legend, metric_legend_params)
    
    
    # Display legend of colors per featuremap on the right
    
    if(length(data) == 1 ) {
      
      default_metric_legend2_params <- list(
        x = "topright",
        legend = names(data),
        #  col = featureMap[names(data)],
        #  pch = 15, 
        #  pt.cex = 2,
        plot = FALSE
      )
      
    } else {
      
      default_metric_legend2_params <- list(
        x = "topright",
        legend = names(data), 
        col = featureMap[names(data)],
        pch = 15, 
        pt.cex = 2
      ) 
    }
    
    
    metric_legend2_params <- modifyList(default_metric_legend2_params, metric_legend2_params)
    
    do.call(legend, metric_legend2_params)
    
    
  }
  
  
  ################
  ## DELTA PLOT ##
  ################
  
  if("delta.count" %in% plotList && !("delta.rate" %in% plotList) ) {
    yVal <- data[[1]][,"delta"]; 
    y_label <- "delta count"
    yLim <- range(sapply(data, function(x){range(x[,"delta"])}))
    
  }
  
  if("delta.rate" %in% plotList && !("delta.count" %in% plotList) ) {
    
    yVal <- 100*data[[1]][,"deltaRate"]; 
    y_label <- "delta (%)"
    yLim <- 100*range(sapply(data, function(x){range(x[,"deltaRate"])}))
    
  }
  
  if(any(c("delta.count","delta.rate") %in% plotList)) {
    
    default_delta_plot_params <- list(mar = c(4,6,0,1),
                                      #bg = "ivory",
                                      fg = "grey30")
    
    delta_plot_params <- modifyList(default_delta_plot_params,
                                    delta_plot_params)
    
    do.call(par, delta_plot_params)
    
    # Empty plot
    
    plot(y= yVal, 
         x= data[[1]][,"periodEnd"],
         type = "n",
         ylim = yLim,
         xlab = "",
         las = 2,
         ylab = "" 
    )
    
    # Rectangle (plot color) (Establish after plot is drawn)
    
    default_delta_upper_rect_args <- list(
      xleft = par("usr")[1], 
      ybottom = 0, #par("usr")[3], 
      xright = par("usr")[2], 
      ytop = par("usr")[4],
      col = adjustcolor("palegreen3", alpha.f = 0.1), 
      border = NA
    )
    
    delta_upper_rect_args <- modifyList(default_delta_upper_rect_args, delta_upper_rect_args)
    
    default_delta_lower_rect_args <- list(
      xleft = par("usr")[1], 
      ybottom = par("usr")[3], 
      xright = par("usr")[2], 
      ytop = 0, #par("usr")[4],
      col = adjustcolor("pink", alpha.f = 0.5), 
      border = NA
    )
    
    delta_lower_rect_args <- modifyList(default_delta_lower_rect_args, delta_lower_rect_args)
    
    
    # Grid (Establish after the plot is drawn)
    default_delta_grid_args <- list(col = "lightgray", lwd = 1, lty = "dotted")
    delta_grid_args <- modifyList(default_delta_grid_args, delta_grid_args)
    
    # Draw rectangle and grid
    do.call("rect", delta_upper_rect_args)
    do.call("rect", delta_lower_rect_args)
    
    # Making grid work
    grid_y <- axTicks(2)
    grid_x <- pretty(data[[1]][,"periodEnd"], n = 5)
    
    do.call(abline, c(list(h=grid_y), delta_grid_args))
    do.call(abline, c(list(v=grid_x), delta_grid_args))
    
    
    # draw the delta lines using Map
    
    if("delta.count" %in% plotList && !("delta.rate" %in% plotList) ) {
      
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = df[,"delta"],
            x = df[,"periodEnd"],
            type = "l",
            col = col
          ),
          delta_points_params
        ))
      }, data, featureMap[names(data)]))
      
    }
    
    
    if("delta.rate" %in% plotList && !("delta.count" %in% plotList) ) {
      
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = 100*df[,"deltaRate"],
            x = df[,"periodEnd"],
            type = "l",
            col = col
          ),
          delta_points_params
        ))
      }, data, featureMap[names(data)]))
      
    }
    
    # Margin text
    
    default_delta_mtext_params <- list(side = 2,
                                       line = 4,
                                       text = y_label
    )
    delta_mtext_params <- modifyList(default_delta_mtext_params, 
                                     delta_mtext_params)
    
    do.call(mtext, delta_mtext_params)
    
  }
  
  
  default_delta_legend_params <- list(
    x = "topleft",
    legend = names(data),
    col = featureMap[names(data)],
    pch = 15, 
    pt.cex = 2
  )
  
  delta_legend_params <- modifyList(default_delta_legend_params, delta_legend_params)
  
  do.call(legend, delta_legend_params)
  
  ################
  ## OUTER TEXT ##
  ################
  
  titleText <- "Head count metrics"
  
  default_title_mtext_params <- list(text = titleText, 
                                     side = 3,
                                     line = 0.3,
                                     font =2, 
                                     cex = 1.3, 
                                     outer = TRUE)
  
  
  title_mtext_params <- modifyList(default_title_mtext_params, title_mtext_params)
  
  do.call(mtext, title_mtext_params)
  
}
