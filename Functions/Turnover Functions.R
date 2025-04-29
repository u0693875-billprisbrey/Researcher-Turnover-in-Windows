# Turnover Functions
# 4.29.2025

activePI <- function(investigation.date,
                     target = "HIRE_DT",
                     data){
  
  # this uses "retData" which is the view of hire and termination dates.
  # it returns a count of people who are "active" on a certain date
  # where active is defined as a date between hire and termination dates,
  # or after the hire date and the termination date is NA
  
  intervalCondition <- investigation.date >= data[,target] & investigation.date <= data[,"TERMINATION_DT"]
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