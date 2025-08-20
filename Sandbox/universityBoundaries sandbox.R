universityBoundaries <- function(data) {
  
  # This is meant for employees with multiple concurrent jobs.
  # It determines if an "entry" or "exit" boundary action applies to just the job,
  # or to the entire university.
  
  # it evaluates whether every entry or exit date is bounded by other dates
  # that suggest continuing employment at the U.
  
  # it completely ignores EMPL_RCD by design, as HR informs that EMPL_RCD 
  # is not consistently used or assigned.
  
  # where "data" is the journeyData for a single EMPLID
  
  ###########
  ## MERGE ##
  ###########
  
  # first, identify entry and exit actions by merging with the acionReasonFrame 
  timeline <- merge(data, assignBoundaries(actionReasonFrame), by = c("ACTION", "ACTION_REASON") , all.x = TRUE)
  
  ##########
  ## PREP ##
  ##########
  
  # second, put the data in order
  timeline <- timeline[order(timeline$EFFDT),]
  
  # simplify to just the "primary" boundary type and select columns
  base_primary <- timeline[timeline$boundary_type == "primary" & !is.na(timeline$boundary_type),c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]
  
  #############
  ## EXTRACT ##
  #############
  
  entries <- base_primary$EFFDT[order(base_primary$EFFDT) & base_primary$boundary == "entry"]
  exits <- base_primary$EFFDT[order(base_primary$EFFDT) & base_primary$boundary == "exit"]
  
  if(length(entries) == length(exits)+1) { 
    exits <- c(exits, NA)
  } else if (length(entries) > length(exits+1)) {
      stop("Anomaly")
    }
  
  # extract entry and exit events as pairs
  baseEvents <- data.frame(entry = entries,  
                           exit = exits
  )
  
  # substitute today for the last value if it is NA
  
  if(is.na(baseEvents[nrow(baseEvents),ncol(baseEvents)])) {baseEvents[nrow(baseEvents),ncol(baseEvents)] <- today()}
  
  
  ###########
  ## CHECK ##
  ###########
  
  # I should do a double-check here and kick out "Anomaly" warning
  
  # rows and columns are in chronological order

  forCheck <- baseEvents

  # substitute today for the last value if it is NA
  
  if(is.na(forCheck[nrow(forCheck),ncol(forCheck)])) {forCheck[nrow(forCheck),ncol(forCheck)] <- today()}

  check1 <- apply(forCheck, 1, function(x){ (diff(as.Date(x))) >= 0 }  )
  check2 <- apply(forCheck, 2, function(x){ (diff(as.Date(x))) >= 0  } )
  if(any(c(check1,check2) == FALSE)){ stop("Anomaly")}
  
  
  ##############
  ## EVALUATE ##
  ##############
  
  # Determine if each entry or exit is a university-wide entry or exit,
  # or just applies to a concurrent position
  
  baseEvents$univ_exit <- TRUE
  baseEvents$univ_entry <- TRUE
  
  for (i in seq_len(nrow(baseEvents))) {
    this_exit <- baseEvents$exit[i]
    
    # Look for other rows (not the current one) that have:
    #  entry <= this_exit AND exit > this_exit
    active_elsewhere <- baseEvents$entry[-i] <= this_exit & baseEvents$exit[-i] > this_exit
    
    if (any(active_elsewhere)) {
      baseEvents$univ_exit[i] <- FALSE
    }
  }
  
  baseEvents$univ_entry <- TRUE
  
  for (i in seq_len(nrow(baseEvents))) {
    this_entry <- baseEvents$entry[i]
    
    # Look for other rows (not the current one) that have:
    #  exit <= this_entry AND entry > this_entry
    active_elsewhere <- baseEvents$exit[-i] <= this_entry & baseEvents$entry[-i] > this_entry
    
    if (any(active_elsewhere)) {
      baseEvents$univ_entry[i] <- FALSE
    }
  }
  
  #############
  ## RESTORE ##
  #############
  
  # Move this information back into the simplified data
  
  # Start by initializing the columns with NA
  base_primary$univ_entry <- NA
  base_primary$univ_exit  <- NA
  
  # Assign TRUE for univ_entry when:
  # - boundary is "entry"
  # - EFFDT is in baseEvents$entry[baseEvents$univ_entry == TRUE]
  entry_match <- base_primary$boundary == "entry" & 
    base_primary$EFFDT %in% baseEvents$entry[baseEvents$univ_entry]
  
  base_primary$univ_entry[entry_match] <- TRUE
  
  # Assign TRUE for univ_exit when:
  # - boundary is "exit"
  # - EFFDT is in baseEvents$exit[baseEvents$univ_exit == TRUE]
  exit_match <- base_primary$boundary == "exit" & 
    base_primary$EFFDT %in% baseEvents$exit[baseEvents$univ_exit]
  
  base_primary$univ_exit[exit_match] <- TRUE
  
  # I could combine these into a "university" column
  base_primary$univ_boundary <- ifelse(base_primary$univ_entry|base_primary$univ_exit, TRUE, NA)
  
  # Move this information back to the journey data
  univData <- merge(timeline, base_primary, by = c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary"), all.x = TRUE)
  
  # modify the "primary" column if it's a university-wide action
  universityFilter <- univData$univ_boundary & 
    !is.na(univData$univ_boundary) & 
    !univData$ACTION_REASON %in% c("HCJ")
  univData$boundary_type[universityFilter] <- paste(univData$boundary_type[universityFilter], ", university")
  
  
  
  return(univData)
  
}


