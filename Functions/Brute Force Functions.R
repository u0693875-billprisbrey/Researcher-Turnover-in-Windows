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
  data$shape_size[data$boundary_type == "break" & !is.na(data$boundary_type)] <- 1
  data$shape_size[data$boundary_type == "leave" & !is.na(data$boundary_type)] <- 1  
  
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
       pch = timeLine[,"shape_shape"],
       col = timeLine[,"shape_color"],
       cex = timeLine[,"shape_size"]
  )
  
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