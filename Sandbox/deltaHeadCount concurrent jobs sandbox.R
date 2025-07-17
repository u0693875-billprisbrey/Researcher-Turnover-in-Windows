# deltaHeadCount for concurrent jobs
# sandbox

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