# calculateTurnover sandbox part 2
# 5.9.2025


# I'd like to revise this function to use the new "deltaHeadCount" function
# Not for any particularly good reason.

# original
calculateTurnover_original <- function(data, interval = "week") {
  
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

# updated

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
    
    # calculate a value for the initial count
    
    intermediate <- deltaHeadCount(
      minDate = initial_date,
      maxDate = minDate-1,
      calendar = "day",
      data = data
    ) 
    
    initial_count <-  intermediate |>
      (\(x){tail(x[,"delta.cum"],1) })()

  }
  
  # prepare the initial delta head count data frame
  turnOver <- deltaHeadCount(minDate = minDate,
                             maxDate = maxDate,
                             calendar = calendar,
                             initial_count = initial_count,
                             data = data)
  
  # calculate the turnover
  turnOver$turnover <- turnOver$termCount/turnOver$delta.cum
  
  return(turnOver)  
  
}


# I mean, that should do it.
# I also think I'm making it more difficult than it needs to be

