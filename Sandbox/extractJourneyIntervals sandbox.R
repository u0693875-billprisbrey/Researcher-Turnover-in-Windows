# extractJourneyIntervals sandbox


extractJourneyIntervals <- function(data, plotMap) {
  
  # where data is the journeyData for a single EMPLID
  # where plotMap is the actionFrame or actionReasonFrame with boundary types, boundaries, and color, shape, and size specified
  
  # This returns a list of "entry" and "exit" dates per boundary type
  
  # it is used to plot solid lines on the plotJourney,
  # and I'll use it to make a validation check on concurrent jobs.  Somehow.
  
  # It needs work on concurrent jobs
  # It needs lots of work, period

  
  # first, merge plotMap
  
  data <- merge(data, plotMap, by = c("ACTION", "ACTION_REASON") , all.x = TRUE)
  
  # first, separate into the different boundary types
  
  boundaries <- c("primary","break","leave")
  boundaryEvents <- c("entry","exit")
  
  journeyByBoundary <- lapply(boundaries, function(x) {
    boundaryData <- data[data$boundary_type == x & !is.na(data$boundary_type),]
  })
  names(journeyByBoundary) <- boundaries
  
  # second, extract entry and exit dates
  
  startAndstop <- lapply(journeyByBoundary, function(theData){ 
    
    returnList <- lapply(boundaryEvents, function(x) {
      
      if(x %in% theData$boundary) {
        dates <-  theData$EFFDT[theData$boundary == x ] |>
          (\(b){ b[order(b)]})();
        return(dates)
      } else {
        return(NULL) 
      } 
      
    })
    
    names(returnList) <-  boundaryEvents
    return(returnList)
    
  })
  
  return(startAndstop)
  
}

