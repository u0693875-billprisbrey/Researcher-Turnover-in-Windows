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




