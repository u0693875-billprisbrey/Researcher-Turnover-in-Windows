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
