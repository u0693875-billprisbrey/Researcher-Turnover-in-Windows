# Brute Force Functions

# assignBoundaries and plotJourney was taken from the individual journey app
# deltaHeadCount was originally from "Turnover Functions"

assignBoundaries <- function(data) {
  
  # where data is "actionReasonFrame"
  
  # This takes the "data" and assigns entry/exit boundaries.
  # It also assigns plotting parameters.
  
  # I might have to do this in waves or sections to manage current and non-concurrent jobs; 
  # it may need another function to merge this with
  # the journeyData using some more complicated logic than just a join
  
  # I need complete flexibility around plot values
  
  ###############
  ## DATA PREP ##
  ###############
  
  data$boundary <- NA
  data$boundary_type <- NA
  data$shape_color <- NA
  data$shape_shape <- NA
  data$shape_size <- NA
  
  ########################
  ## NO CONCURRENT JOBS ##
  ########################
  
  primeEntryFilter <- data$ACTION %in% c("HIR", "REH")
  primeExitFilter <- data$ACTION %in% c("TER", "RET", "RWP")
  
  data$boundary[primeEntryFilter] <- "entry"
  data$boundary[primeExitFilter] <- "exit"
  data$boundary_type[primeEntryFilter|primeExitFilter] <- "primary"
  
  # Break entry or exit
  
  breakEntryFilter <- data$ACTION %in% c("RWB")
  breakExitFilter <- data$ACTION %in% c("SWB")
  
  data$boundary[breakEntryFilter] <- "entry"
  data$boundary[breakExitFilter] <- "exit"
  data$boundary_type[breakEntryFilter|breakExitFilter] <- "break"
  
  # Leave entry or exit
  
  leaveEntryFilter <- data$ACTION %in% c("RFL")
  leaveExitFilter <- data$ACTION %in% c("LOA","LTO", "PLA") & !(data$ACTION_REASON %in% c("EXT"))
  
  data$boundary[leaveEntryFilter] <- "entry"
  data$boundary[leaveExitFilter] <- "exit"
  data$boundary_type[leaveEntryFilter|leaveExitFilter] <- "leave"  
  
  #################
  ## PLOT VALUES ##
  #################
  
  # COLOR
  
  data$shape_color[is.na(data$boundary_type)] <- "plum1"
  data$shape_color[data$boundary_type == "primary" & !is.na(data$boundary_type)] <- "chocolate"
  data$shape_color[data$boundary_type == "break" & !is.na(data$boundary_type)] <- "steelblue"
  data$shape_color[data$boundary_type == "leave" & !is.na(data$boundary_type)] <- "coral"
  data$shape_color[data$ACTION == "REH"] <- "chocolate4"
  data$shape_color[data$ACTION_REASON == "HCJ"] <- "mediumorchid1"
  
  # SHAPE
  
  data$shape_shape[is.na(data$boundary)] <- 1
  data$shape_shape[data$boundary == "entry" & !is.na(data$boundary)] <- 13
  data$shape_shape[data$boundary == "exit" & !is.na(data$boundary)] <- 19
  data$shape_shape[data$ACTION == "REH"] <- 10
  
  
  # SIZE
  
  data$shape_size[is.na(data$boundary_type)] <- 0.75
  data$shape_size[data$boundary_type == "primary" & !is.na(data$boundary_type)] <- 2
  data$shape_size[data$boundary_type == "break" & !is.na(data$boundary_type)] <- 1.5
  data$shape_size[data$boundary_type == "leave" & !is.na(data$boundary_type)] <- 1.5  
  
  return(data)
}

plotJourney <- function(data, plotMap){
  
  # where data is the journeyData for a single EMPLID
  # where plotMap is the actionFrame or actionReasonFrame with color, shape, and size specified
  
  # merge plotMap if necessary
  
  if(!all(c("shape_color", "shape_shape", "shape_size") %in% colnames(data))) {
    timeLine <- merge(data, plotMap, by = c("ACTION", "ACTION_REASON") , all.x = TRUE)
  } else {timeLine <- data}
  
  # create jitter
  yPos <- ave(as.numeric(timeLine$EFFDT), timeLine$EFFDT, FUN = function(dates) {
    n <- length(dates)
    if (n == 1) {
      return(1)  # single point: no jitter
    } else {
      # Evenly spaced jitter around y = 1
      jitter_values <- seq(0.9, 1.1, length.out = n)
      return(jitter_values)
    }
  })
  
  # draw the plot
  
  plot(y = yPos + timeLine$EMPL_RCD,
       x = as.Date(timeLine$EFFDT),
       ylab = "Concurrent jobs (EMPL_RCD)",
       xlab = "Date [EFFDT]",
       pch = timeLine[,"shape_shape"],
       col = timeLine[,"shape_color"],
       cex = timeLine[,"shape_size"]
  )
  
  # legend
  # Legend might need to be an entire separate graphic
  # legend("topright",
  #       title = "Boundary type (size)",
  #       legend = c("primary, university", "primary" , "break", "leave" ),
  #       pch = c(1, 1, 1,1),
  #       cex = c(2, 0.75, 1,1)
  #        )
  
  
  
}

deltaHeadCount <- function(minDate, 
                           maxDate,
                           calendar = "day",
                           initial_count = 0,
                           data) {
  
  # where data is journeyData or retData
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
    hrDates <- data.frame(EFFDT = seq(from = minDate, to = maxDate, by = calendar)) 
    
    # maintain consistency with the other time periods
    hrDates$adjDate <- hrDates$EFFDT
    
    # Aggregate hire and termination actions
    theActions <- aggregate(one ~ boundary+EFFDT, data = data, sum)
    
    # prepare for merge
    # theActions$EFFDT <- as.Date(theActions$EFFDT)
    # names(theActions)[names(theActions) == "EFFDT"] <- "adjDate"
    theActions$adjDate <- as.Date(theActions$EFFDT)
    
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
    hrDates <- data.frame(EFFDT = seq(from = weekMin, to = weekMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$adjDate <- paste(isoyear(hrDates$EFFDT), sprintf("%02d", isoweek(hrDates$EFFDT)), sep = "-W")
    
    # aggregate
    theActions <- aggregate(one ~ boundary+paste(isoyear(EFFDT), sprintf("%02d", isoweek(EFFDT)), sep = "-W"), data = data, sum)
    names(theActions)[!names(theActions) %in% c("boundary", "one")] <- "adjDate"
    
  }
  
  if(calendar == "month") {
    
    monthMin <- ymd(paste(year(minDate), month(minDate),"01", sep = "-") )
    monthMax <- ymd(paste(year(maxDate), month(maxDate),"01", sep = "-") )
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(EFFDT = seq(from = monthMin, to = monthMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$adjDate <- format(hrDates$EFFDT, "%Y-%m") 
    
    
    # aggregate
    theActions <- aggregate(one ~ boundary + format(EFFDT, "%Y-%m"), data = data, sum)
    names(theActions)[!names(theActions) %in% c("boundary", "one")] <- "adjDate"
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
    hrDates <- data.frame(EFFDT = seq(from = quarterMin, to = quarterMax, by = calendar)) 
    
    # convert to quarter format
    hrDates$adjDate <- paste(year(hrDates$EFFDT), quarter(hrDates$EFFDT), sep = "-Q")
    
    # aggregate
    theActions <- aggregate(one ~ boundary+paste(year(EFFDT), quarter(EFFDT), sep = "-Q"), data = data, sum)
    names(theActions)[!names(theActions) %in% c("boundary", "one")] <- "adjDate"
    
  }
  
  if(calendar == "year") {
    
    yearMin <- ymd(paste(year(minDate), "01","01", sep = "-") )
    yearMax <- ymd(paste(year(maxDate), "12","31", sep = "-") )
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(EFFDT = seq(from = yearMin, to = yearMax, by = calendar)) 
    
    # convert to desired format
    hrDates$adjDate <- year(hrDates$EFFDT) 
    
    # aggregate
    theActions <- aggregate(one ~ boundary+year(EFFDT), data = data, sum)
    names(theActions)[!names(theActions) %in% c("boundary", "one")] <- "adjDate"
  }
  
  # merge 
  
  hrDates <- merge(hrDates, theActions[theActions$boundary == "exit",-which(colnames(theActions) %in% c("boundary", "EFFDT"))], by = "adjDate", all.x = TRUE, sort=FALSE)
  names(hrDates)[names(hrDates) == "one"] <- "exit"
  hrDates <- merge(hrDates, theActions[theActions$boundary == "entry",-which(colnames(theActions) %in% c("boundary", "EFFDT"))], by = "adjDate", all.x = TRUE, sort=FALSE)
  names(hrDates)[names(hrDates) == "one"] <- "entry"
  
  # restore chronological order 
  hrDates <- hrDates[order(hrDates$adjDate),] # uh oh.  I need to keep the EFFDT,  I guess
  
  # convert NA values to zero
  hrDates[is.na(hrDates)] <- 0
  
  # calculate delta
  hrDates$delta <- hrDates$entry - hrDates$exit
  
  # calculate delta cumulative
  hrDates$delta.cum <- cumsum(hrDates$delta) + initial_count
  
  # add a "periodEnd" column for clarity in plotting
  if(calendar == "week"){ 
    hrDates$periodEnd <- ceiling_date(hrDates$EFFDT, unit = calendar, week_start = 1) - days(1)
  } else {
    hrDates$periodEnd <- ceiling_date(hrDates$EFFDT, unit = calendar) - days(1)
  }
  
  
  return(hrDates)
  
  
  ###############
  ## OLD LOGIC ##
  ###############
  
  # old logic for backwards compatibility:
  
  if(!("EFFDT" %in% colnames(data)) & all(c("HIRE_DT","TERMINATION_DT") %in% colnames(data))) {
    
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
  
}

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
  # return(list(starts = starts, stops = stops))
  
  # return as a dataframe
  as.Frame <- data.frame(EFFDT = c(starts,
                                   stops),
                         univ_boundary = c(rep("start", length(starts)),
                                           rep("stop", length(stops)))
  ) |>
    (\(x){x[order(x$EFFDT),]})()
  
  # I'm going to have to find a way to add the EMPLID
  # Maybe as a second argument?
  # Or in a separate function? ?? Awkward! 
  # as.Frame$EMPLID <- rep("jollyGood", nrow(as.Frame))
  # momo$EMPLID <- rep(names(universityBoundaries)[1], nrow(momo))
  
  return(as.Frame)
}

# From "Extract University Boundaries using Brute Force sandbox.R
# universityBoundaries <- lapply(cjEmplids[1:10], extractUniversityBoundaries)
# names(universityBoundaries) <- names(cjEmplids[1:10])

forceFitPlot <- function(data, fitLine = TRUE) {
  
  forceFit <- data |>
    assignBoundaries() |>
    (\(x){deltaHeadCount(data = x,
                         minDate = min(x$EFFDT),
                         maxDate = max(x$EFFDT)
    )})()
  
  forceFit$force <- pmax(0, pmin(1, forceFit$delta.cum))
  
  plot(y = forceFit[,"delta.cum"],
       x = forceFit[,"EFFDT"],
       ylab = "cumulative headcount",
       xlab = "",
       type = "b",cex = 0.75, lty = 1, col = "brown")
  if(fitLine) {
    lines(y = forceFit[,"force"], 
          x = forceFit[,"EFFDT"],
          type = "b", cex = 0.35, lty = 1, col = "skyblue")
  }
  
  legend("topleft",
         legend = c("cum headcount","force fit"),
         lty = 1,
         lwd = 3,
         col = c("brown","skyblue"),
         inset = c(0,-0.5),
         xpd = TRUE
         )
  
}

addVerticals <- function(data){
  
  # This adds vertical lines to the plot from "plotJourney" from the 
  # starts and stops of the university boundaries as determined by the 
  # brute force fit approximation
  
  # Call "plotJourney" first.
  
  # where data is from univBound, or the data frame with the brute force
  # starts and stops
  
  # This can be used to filter the data appropriately
  # plotFilter <- grepl("00810875", row.names(univBound))
  
  abline(v = data$EFFDT[data$univ_boundary == "start"],
         lwd = 2,
         lty = "dotted",
         col = brewer.pal(3, "Dark2")[1] #   "green"
  )
  abline(v = data$EFFDT[data$univ_boundary == "stop"],
         lwd = 2,
         lty = "solid",
         col = brewer.pal(3, "Dark2")[2] # "red"
  )
  
  
}



plotMetrics_univ <- function(data,
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
  # If you don't want to show both start and stop lines, then set the argument "type='n'"
  #  in the appropriate params list (but it would still show up in the legend.  Hmm.)
  # If you don't want to show a particular legend, then set the argument "plot = FALSE"
  #  in the appropriate params list.
  
  # If you don't want to show the headcount or cumulative graphic, you may need to
  # set oma = c(0,0,2,0) in metric_plot_params or delta_plot_params to provide space
  # for the title.
  
  # Values for plotList are c("all", "headcount", "cumulative", "rate", "count", "delta.count", "delta.rate")
  
  # Don't forget you can change the name displayed in the legends, which is especially useful
  # if you are entering a single data frame that doesn't have a name:
  # cumulative_legend_params = list(legend = "Frankfurt")
  
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
  
  ################################
  ## MANAGE INCOMING PARAMETERS ##
  ################################
  
  incoming.par <- par(fg="red") # dummy adjustment for ease of coding because par() likes adjustments
  on.exit(layout(matrix(1,1,1)))
  on.exit(par(incoming.par), add = TRUE)
  
  
  ###############################
  ## MANAGE INCOMING ARGUMENTS ##
  ###############################
  
  if(is.data.frame(data)) {data <- list(data)} # convert to a data frame
  
  if(is.null(names(data))) {  # assign default names
    
    names(data) <- paste("data", 1:length(data), sep = " ")
    
  }
  
  if(length(data) > 10 && all(is.na(featureMap))  ) { 
    stop("Add featureMap or reduce list length to <=10")
  }  
  
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
  
  # Filter out unknown metrics
  plotList <- plotList[plotList %in% c("all", "headcount", "cumulative", "rate", "count", "delta.count", "delta.rate")]
  if(length(plotList) == 0) { plotList <- "all"}
  
  if("all" %in% plotList){ plotList <- c("cumulative", "rate", "delta.rate")  }
  
  if(all(c("rate","count") %in% plotList )) { 
    stop("Select 'rate' or 'count' in plotList argument.")
  }
  
  if(all(c("delta.rate","delta.count") %in% plotList )) { 
    stop("Select 'delta.rate' or 'delta.count' in plotList argument.")
  }
  
  if(!any(c("all", "headcount", "cumulative", "rate", "count", "delta.count", "delta.rate") %in% plotList )) { 
    stop("Select some of c('all', 'headcount', 'cumulative', 'rate', 'count', 'delta.count', 'delta.rate') in plotList argument.")
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
    
    do.call(par, cumulative_plot_params)
    
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
      
      hireVal <- 100*data[[1]][,"startRate"]
      termVal <- 100*data[[1]][,"stopRate"]
      
      
      yLim <- range(unlist(
        lapply(data, function(df) {
          apply(df[, c("startRate", "stopRate")], 1, range, na.rm = TRUE)
        })
      ), na.rm = TRUE) * 100
      
      y_label <- "rates (%)"
      legendText <- c("start", "stop")
      
    }
    
    if("count" %in% plotList && !("rate" %in% plotList) ) {
      hireVal <- data[[1]][,"start"]
      termVal <- data[[1]][,"stop"] 
      
      yLim <- range(unlist(
        lapply(data, function(df) {
          apply(df[, c("start", "stop")], 1, range, na.rm = TRUE)
        })
      ), na.rm = TRUE)    
      
      y_label <- "count"
      legendText <- c("start", "stop")
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
    
    plot(y= hireVal, #100*data[,"startRate"],
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
            y = 100*df[,"startRate"],
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
            y = 100*df[,"stopRate"],
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
            y = df[,"start"],
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
            y = df[,"stop"],
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


calculateMetrics_univ <- function(initial_count=NA, 
                                  initial_date=NA,
                                  calendar = "day",
                                  minDate = ymd(paste(year(today()), "01","01", sep = "-")),
                                  maxDate = today(),
                                  data
){
  
  # This calculates various HR metrics: the counts and rates of people entering, stoping, and the net change
  # (called "delta" here.)
  
  # It uses deltaHeadCount_univ.  Because deltaHeadCount_univ always starts at a value of zero, this function
  # accepts or creates an initial value to result in an accurate current head count.
  
  # It accepts either an initial_count, or an initial_date.
  
  # If neither is provided, then it finds the earliest date in the data set as the initial_date.
  
  # If the initial_count is provided, then it uses that. If it is not provided, then a value for 
  # initial_count is calculated using initial_date in deltaHeadCount_univ.  It uses the initial_date as the value for the 
  # minDate argument and the maximum date before the start of the desired period as 
  # the maxDate argument.  The final "delta.cum" result is used as the initial_count.
  
  # Then, either accepting the provided initial_count or calculating it, it uses deltaHeadCount_univ 
  # to calculate the counts of people entering, stoping, and the net change (called "delta" here.)
  
  # What makes this an interesting wrapper to deltaHeadCount_univ is that it will count the daily change,
  # and then aggregate that to a mean value over the desired period.  This mean is the denominator
  # for the rate calculations.
  
  #  calculateTurnover (or calculateMetrics) and deltaHeadCount_univ will provide identical results if the minDate used
  #  for deltaHeadCount_univ is the same as the initial_date used in calculateTurnover, and the other arguments
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
    
    intermediate <- deltaHeadCount_univ(
      minDate = initial_date,
      maxDate = initial_max,
      calendar = "day",
      data = data
    ) 
    
    initial_count <-  intermediate |>
      (\(x){tail(x[,"delta.cum"],1) })()
    
  }
  
  # Calculate the foundation deltaHeadCount_univ
  
  foundation <- deltaHeadCount_univ(minDate = minDate,
                                    maxDate = maxDate,
                                    calendar = calendar,
                                    initial_count = initial_count,
                                    data = data)
  
  
  # Calculate mean headcount by first repeating deltaHeadCount_univ by day
  
  meanHeadCount <- deltaHeadCount_univ(minDate = minDate,
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
    periodHeadCountMean <- aggregate(delta.cum ~ paste(year(EFFDT), sprintf("%02d", isoweek(EFFDT)), sep = "-W"), data = meanHeadCount, mean)
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
  foundation$startRate <- foundation$start/foundation$headcount_mean
  foundation$stopRate <- foundation$stop/foundation$headcount_mean
  foundation$deltaRate <- foundation$delta/foundation$headcount_mean
  
  
  return(foundation)  
  
}

deltaHeadCount_univ <- function(minDate, 
                                maxDate,
                                calendar = "day",
                                initial_count = 0,
                                data) {
  
  # where data is journeyData or retData
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
    hrDates <- data.frame(EFFDT = seq(from = minDate, to = maxDate, by = calendar)) 
    
    # maintain consistency with the other time periods
    hrDates$adjDate <- hrDates$EFFDT
    
    # Aggregate hire and termination actions
    theActions <- aggregate(one ~ univ_boundary+EFFDT, data = data, sum)
    
    # prepare for merge
    # theActions$EFFDT <- as.Date(theActions$EFFDT)
    # names(theActions)[names(theActions) == "EFFDT"] <- "adjDate"
    theActions$adjDate <- as.Date(theActions$EFFDT)
    
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
    hrDates <- data.frame(EFFDT = seq(from = weekMin, to = weekMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$adjDate <- paste(isoyear(hrDates$EFFDT), sprintf("%02d", isoweek(hrDates$EFFDT)), sep = "-W")
    
    # aggregate
    theActions <- aggregate(one ~ univ_boundary+paste(isoyear(EFFDT), sprintf("%02d", isoweek(EFFDT)), sep = "-W"), data = data, sum)
    names(theActions)[!names(theActions) %in% c("univ_boundary", "one")] <- "adjDate"
    
  }
  
  if(calendar == "month") {
    
    monthMin <- ymd(paste(year(minDate), month(minDate),"01", sep = "-") )
    monthMax <- ymd(paste(year(maxDate), month(maxDate),"01", sep = "-") )
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(EFFDT = seq(from = monthMin, to = monthMax, by = calendar)) 
    
    # convert to ISO standard format
    hrDates$adjDate <- format(hrDates$EFFDT, "%Y-%m") 
    
    
    # aggregate
    theActions <- aggregate(one ~ univ_boundary + format(EFFDT, "%Y-%m"), data = data, sum)
    names(theActions)[!names(theActions) %in% c("univ_boundary", "one")] <- "adjDate"
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
    hrDates <- data.frame(EFFDT = seq(from = quarterMin, to = quarterMax, by = calendar)) 
    
    # convert to quarter format
    hrDates$adjDate <- paste(year(hrDates$EFFDT), quarter(hrDates$EFFDT), sep = "-Q")
    
    # aggregate
    theActions <- aggregate(one ~ univ_boundary+paste(year(EFFDT), quarter(EFFDT), sep = "-Q"), data = data, sum)
    names(theActions)[!names(theActions) %in% c("univ_boundary", "one")] <- "adjDate"
    
  }
  
  if(calendar == "year") {
    
    yearMin <- ymd(paste(year(minDate), "01","01", sep = "-") )
    yearMax <- ymd(paste(year(maxDate), "12","31", sep = "-") )
    
    # create data frame with one row per calendar period
    hrDates <- data.frame(EFFDT = seq(from = yearMin, to = yearMax, by = calendar)) 
    
    # convert to desired format
    hrDates$adjDate <- year(hrDates$EFFDT) 
    
    # aggregate
    theActions <- aggregate(one ~ univ_boundary+year(EFFDT), data = data, sum)
    names(theActions)[!names(theActions) %in% c("univ_boundary", "one")] <- "adjDate"
  }
  
  # merge 
  
  hrDates <- merge(hrDates, theActions[theActions$univ_boundary == "stop",-which(colnames(theActions) %in% c("univ_boundary", "EFFDT"))], by = "adjDate", all.x = TRUE, sort=FALSE)
  names(hrDates)[names(hrDates) == "one"] <- "stop"
  hrDates <- merge(hrDates, theActions[theActions$univ_boundary == "start",-which(colnames(theActions) %in% c("univ_boundary", "EFFDT"))], by = "adjDate", all.x = TRUE, sort=FALSE)
  names(hrDates)[names(hrDates) == "one"] <- "start"
  
  # restore chronological order 
  hrDates <- hrDates[order(hrDates$adjDate),] # uh oh.  I need to keep the EFFDT,  I guess
  
  # convert NA values to zero
  hrDates[is.na(hrDates)] <- 0
  
  # calculate delta
  hrDates$delta <- hrDates$start - hrDates$stop
  
  # calculate delta cumulative
  hrDates$delta.cum <- cumsum(hrDates$delta) + initial_count
  
  # add a "periodEnd" column for clarity in plotting
  if(calendar == "week"){ 
    hrDates$periodEnd <- ceiling_date(hrDates$EFFDT, unit = calendar, week_start = 1) - days(1)
  } else {
    hrDates$periodEnd <- ceiling_date(hrDates$EFFDT, unit = calendar) - days(1)
  }
  
  
  return(hrDates)
  
  
  ###############
  ## OLD LOGIC ##
  ###############
  
  # old logic for backwards compatibility:
  
  if(!("EFFDT" %in% colnames(data)) & all(c("HIRE_DT","TERMINATION_DT") %in% colnames(data))) {
    
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
  
}

