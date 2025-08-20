# Elapsed functions
# 10.29.2024

# These functions deal with changing win and loss counts over time.

# These are copied over from "Exploring Historical Win Rate Visualizations"
# which, in turn, takes functions developed in "Win History.R".

elapsed <- function(target = "PROPOSAL_PI_EMPLID",
                    date = "PROPOSAL_UPLOAD_DATE",
                    period = "years",
                    data) {
  
  # This produces a list of three data frames that contain the proposal history
  # per "target".
  
  # "each" data frame has the year and "interval" time elapsed for each proposal
  # "elapsed" data frame has the total count, win count, and loss count for the
  # interval floor, target, and calendar year.  (So every proposal submitted
  # before the one year anniversary of the first submission is in "Year 0.")
  # "per_wide" pivots "elapsed" to one row per target, with win, loss, and
  # total counts.
  
  # this is used in later visualizations.
  
  # "target" is a categorical  value typically "PROPOSAL_PI_EMPLID",
  # "PROPOSAL_COLLEGE", or "PROPOSAL_ORG".
  
  # "data" is typically "cleanData"
  
  
  
  # first, calculate the minimum for each date and merge it back into the data
  
  theMin <- aggregate(get(date) ~ get(target), data, min, na.rm=TRUE)
  colnames(theMin) <- c(target, "minDate")
  
  minData <- merge(data[,c("PROPOSAL_ID", target, date,"win")], theMin, by= target, all.x = TRUE) 
  
  # calculate the interval
  
  if(period == "quarters") {
    
    period <- "months"
    
    divisor <- 3 } else {divisor = 1}
  
  if(period %in% c("years", "weeks","months")) {
    
    minData[,"interval"] <- interval(minData[, "minDate"], minData[,date]) |>
      as.duration() |>
      (\(x){as.numeric(x,period) / divisor})() 
    
  } else {stop("Select a period value of years, quarters, months, or weeks")}
  
  # Add a year column (as I'll never aggregate by a period greater than a year)
  # maybe I want to add another column that extracts the similar period (month or quarter?)
  
  minData[,"year"] <- year(minData[,date])
  
  # Aggregate it by making a table (counts of win/losses) per interval
  
  elapsed <- aggregate(win ~ floor(interval) + get(target) + year, 
                       data = minData, 
                       FUN = function(x) table(factor(x, levels = c("win", "loss"))))
  
  
  # Convert the table results into separate columns for wins and losses
  elapsed <- data.frame(elapsed[, 1:3], as.data.frame.matrix(elapsed$win))
  
  # sum up a total
  elapsed$count <- rowSums(elapsed[,c("win","loss")])
  
  # fix column names
  colnames(elapsed) <- c("interval", target, "year", "win", "loss", "count") # paste("interval", period, sep=".")
  
  # Enable clustering per category by rotating it
  
  # First, calculate without the calendar year 
  # (because the calendar year and interval don't overlap)
  
  # Aggregate it by making a table (counts of win/losses) per interval
  
  pre <- aggregate(win ~ floor(interval) + get(target), 
                   data = minData, 
                   FUN = function(x) table(factor(x, levels = c("win", "loss"))))
  
  
  # Convert the table results into separate columns for wins and losses
  pre <- data.frame(pre[, 1:2], as.data.frame.matrix(pre$win))
  
  # sum up a total
  pre$count <- rowSums(pre[,c("win","loss")])
  
  # fix column names
  colnames(pre) <- c("interval", target, "win", "loss", "count") # paste("interval", period, sep=".")
  
  horiz <- reshape(pre,
                   direction = "wide",
                   #varying = ,
                   timevar = "interval",
                   idvar = target)
  
  # Re-order the columns
  
  row.names(horiz) <- horiz[,target]
  
  colnames_list <- colnames(horiz) # get column names
  
  extract_number <- function(name) {
    as.numeric(gsub(".*\\.(\\d+)$", "\\1", name))
  } # Create a helper function to extract the numeric part from the column names
  
  
  sorted_columns <- colnames_list[order(extract_number(colnames_list))] # Sort the column names based on the extracted numbers
  
  horiz <- horiz[, sorted_columns] # Reorder the columns in your data frame
  
  # Return as a list
  return(list(each=minData, elapsed = elapsed, per_wide = horiz))
  
}


elapsedCash <- function(target = "PROPOSAL_PI_EMPLID",
                        targetNumber = "PROPOSAL_TOTAL_SPONSOR_BUDGET",
                        date = "PROPOSAL_UPLOAD_DATE",
                        period = "years",
                        data) {
  
  # where targetNumber is usually "PROPOSAL_TOTAL_SPONSOR_BUDGET" but can be another monetary column
  # ie (PROPOSAL_DIRECT_COST, PROPOSAL_FA_COST, PROPOSAL_TOTAL_SPONSOR_BUDGET,  PROPOSAL_UNIVERSITY_COSTSHARE, PROPOSAL_3RD_PARTY_COSTSHARE )
  
  # first, calculate the minimum for each date and merge it back into the data
  
  theMin <- aggregate(get(date) ~ get(target), data, min, na.rm=TRUE)
  colnames(theMin) <- c(target, "minDate")
  
  minData <- merge(data[,c("PROPOSAL_ID", target, targetNumber, date,"win")], theMin, by= target, all.x = TRUE) 
  
  # calculate the interval
  
  if(period == "quarters") {
    
    period <- "months"
    
    divisor <- 3 } else {divisor = 1}
  
  if(period %in% c("years", "weeks","months")) {
    
    minData[,"interval"] <- interval(minData[, "minDate"], minData[,date]) |>
      as.duration() |>
      (\(x){as.numeric(x,period) / divisor})() 
    
  } else {stop("Select a period value of years, quarters, months, or weeks")}
  
  # Add a year column (as I'll never aggregate by a period greater than a year)
  # maybe I want to add another column that extracts the similar period (month or quarter?)
  
  minData[,"year"] <- year(minData[,date])
  
  # Aggregate the number columns 
  
  # If I want to get more complex, I can use this summary
  # This level of extra detail would make more sense for the high rollers,
  # but is extremely duplicative for the majority of small guys
  # and, come to think of it, I could also reduce the interval for more detail
  # and, I could also just cluster on min/max/median/total/count per PI (wouldn't that have been easy!)  
  
  #  numberSummary <- function(x) {
  #    c(min = min(x, na.rm = TRUE), 
  #      median = median(x, na.rm = TRUE), 
  #      max = max(x, na.rm = TRUE), 
  #      total = sum(x, na.rm = TRUE))
  #  }
  
  costElapsed <- aggregate(get(targetNumber) ~ floor(interval) + get(target) + win, 
                           data = minData, 
                           FUN = sum, na.rm = TRUE #numberSummary
  )
  
  # Reshape to separate 'win' and 'loss' into different columns
  costElapsed <- reshape(costElapsed, idvar = c("floor(interval)", "get(target)"), 
                         timevar = "win", direction = "wide")
  
  # Rename columns
  names(costElapsed) <- c("interval", target, paste(targetNumber,"win", sep = "."), paste(targetNumber,"loss", sep = ".") )
  
  
  
  # pivot to wide for clustering
  horiz <- reshape(costElapsed,
                   direction = "wide",
                   #varying = ,
                   timevar = "interval",
                   idvar = target)
  
  # Re-order the columns
  
  row.names(horiz) <- horiz[,target]
  
  colnames_list <- colnames(horiz) # get column names
  
  extract_number <- function(name) {
    as.numeric(gsub(".*\\.(\\d+)$", "\\1", name))
  } # Create a helper function to extract the numeric part from the column names
  
  
  sorted_columns <- colnames_list[order(extract_number(colnames_list))] # Sort the column names based on the extracted numbers
  
  horiz <- horiz[, sorted_columns] # Reorder the columns in your data frame
  
  # ok, looking really good!  Two down!
  
  # now I have to do the "aggregate" again but include the year
  
  
  costElapsedyr <- aggregate(get(targetNumber) ~ floor(interval) + get(target) + win + year, 
                             data = minData, 
                             FUN = sum, na.rm = TRUE #numberSummary
  )
  
  # Reshape to separate 'win' and 'loss' into different columns
  costElapsedyr <- reshape(costElapsedyr, idvar = c("floor(interval)", "get(target)", "year"), 
                           timevar = "win", direction = "wide")
  
  # Rename columns
  names(costElapsedyr) <- c("interval", target, "year", paste(targetNumber,"win", sep = "."), paste(targetNumber,"loss", sep = ".") )
  
  # return a list
  
  # Return as a list
  return(list(each=minData, elapsed = costElapsedyr, per_wide = horiz))
  
}


calculatePriors <- function(data, targetInterval = NA, targetYear = NA) {
  
  # where data is the "elapsed" result of the "elapsed" function
  
  if(is.na(targetInterval) & is.na(targetYear)) {stop("Select target interval or target year")}
  
  # extract unique values
  
  targets <- unique(data[,2]) # 
  
  if (!is.na(targetInterval)) {
    
    priorList <- lapply(targets, function(x) {
      
      subSet <- data[data[,2] == x,]
      # subSet <- subSet[order(subSet[,"interval"], decreasing = FALSE),]
      subAgg <- aggregate(cbind(win, loss, count) ~ 1, data = subSet[subSet$interval < targetInterval,] , sum, na.rm = TRUE)
      # eventually replace " ~ 1" with "~ interval" to get the per-interval results
      
      return(subAgg)
    })
    
    names(priorList) <- targets
    
    priors <- do.call(rbind, priorList)
    
    newCol <- paste("prior",targetInterval, sep = "_")
    priors[,newCol] <- priors$win / priors$count
    
    return(priors)
    
  }
  
  
  if (!is.na(targetYear)) {
    
    priorList <- lapply(targets, function(x) {
      
      print(x)
      
      subSet <- data[data[,2] == x,]
      
      if(nrow(subSet[subSet$year < targetYear,]) < 1) {return(c(NA,NA,NA))}
      
      # subSet <- subSet[order(subSet[,"year"], decreasing = FALSE),]
      subAgg <- aggregate(cbind(win, loss, count) ~ 1, data = subSet[subSet$year < targetYear,] , sum, na.rm = TRUE)
      # eventually replace " ~ 1" with "~ year" to get the per-interval results
      
      return(subAgg)
    })
    
    names(priorList) <- targets
    
    priors <- do.call(rbind, priorList)
    
    newCol <- paste("prior",targetYear, sep = "_")
    priors[,newCol] <- priors$win / priors$count
    
    return(priors)
    
    
    
    
  }
  
}


timeline <- function(data, ...){
  
  # This produces tickmarks along a timeline colored by win/loss
  
  # where data is the "each" output of "elapsed"
  # ... provides pass-through arguments to "plot" function 
  # (typically "main" to create a title)
  
  # capture and restore incoming graphical parameters
  incoming.par <- par(no.readonly = TRUE)
  on.exit(par(incoming.par))
  
  par(mar = c(4,8,2,1))
  
  data[,1] <- droplevels(data[,1])
  
  theCats <- levels(data[,1])
  
  # create an empty plot with the correct limits
  
  plot(1,
       ylim = c(0,length(theCats)+1),
       xlim = range(data[,"interval"]),
       type = "n",
       yaxt = "n",
       ylab = "",
       #xlab = "interval",
       ...
  )
  
  # plot the tick marks
  
  invisible(
    lapply(theCats, function(x){
      
      theLine <- which(x == theCats) 
      x.val <- data[data[,1] == x,"interval"]
      theColors <- data[data[,1] == x,"win"]
      
      colorMapping <- c("win" = "orange", "loss" = "steelblue")
      
      
      x.length <- length(data[data[,1] == x,"interval"])   
      points(x = x.val,
             y = rep(theLine, x.length),
             pch = "|",
             col = colorMapping[as.character(theColors)])  
      
      axis(side = 2, 
           at = theLine, 
           labels = x,
           las = 1) 
      
    })
  )
  
  # plot the legend
  legend("bottomleft",
         fill = c(adjustcolor(colorMapping[["win"]], alpha.f = 0.5), adjustcolor(colorMapping[["loss"]], alpha.f = 0.5)),
         xpd = TRUE,
         inset = c(-0.15,-0.15), #c(-0.3,-0.37), for RStudio plot window
         legend = c("win","loss"))
  
}


timeDots.old <- function(data, target = "PROPOSAL_TOTAL_SPONSOR_BUDGET", ...){
  
  # This produces bubbles along a timeline colored by win/loss and sized by the
  # "target"
  
  # where data is the "each" output of "elapsed"
  # and "target" is a monetary category
  # ... provides pass-through arguments to "plot" function 
  # (typically "main" to create a title)
  
  # capture and restore incoming graphical parameters
  incoming.par <- par(no.readonly = TRUE)
  on.exit(par(incoming.par))
  
  par(mar = c(4,8,2,1))
  
  data <- merge(data, cleanData[,c("PROPOSAL_ID", target)], by = "PROPOSAL_ID", all.x = TRUE)
  
  data[,2] <- droplevels(data[,2])
  
  theCats <- levels(data[,2])
  
  # create an empty plot with the correct limits
  plot(1,
       ylim = c(0,length(theCats)+1),
       xlim = range(data[,"interval"]),
       type = "n",
       yaxt = "n",
       ylab = "",
       #xlab = "interval",
       ...
  )
  
  invisible(
    lapply(theCats, function(x){
      
      theLine <- which(x == theCats) 
      x.val <- data[data[,2] == x,"interval"]
      theColors <- data[data[,2] == x,"win"]
      #radii <- sqrt(log(data[data[,2] == x,target]))
      radii <- sqrt((data[data[,2] == x,target]))
      
      colorMapping <- c("win" = "orange", "loss" = "steelblue")
      
      abline(h = theLine, col = "gray80", lwd = 2.5)
      x.length <- length(x.val)   
      symbols(x = x.val,
              y = rep(theLine, x.length),
              circles = radii,
              inches = 0.2,
              add = TRUE,
              bg = colorMapping[as.character(theColors)])  
      
      axis(side = 2, 
           at = theLine, 
           labels = x,
           las = 1) 
      
    })
  )
  
  # plot the legend
  legend("bottomleft",
         fill = c(adjustcolor("steelblue", alpha.f = 0.5), adjustcolor("orange", alpha.f = 0.5)),
         xpd = TRUE,
         inset =  c(-0.15,-0.15), # c(-0.3,-0.37), for RStudio plot window
         legend = c("win","loss"))  
  
}

timeDots <- function(data, setMax = NA, circleSize = 0.6, ...) { 
  
  # This produces bubbles along a timeline colored by win/loss and sized by the cash amount
  
  # where 
  #  data is the "each" output of "elapsedCash"
  #    it must be filtered to whatever criteria I have
  #  setMax passes through a value to set the scale for the largest circle
  #  circleSize controls the maximum circle size on the graph 
  #    (typically 0.2 to 0.6;
  #    it is passed to the "inch" argument)
  
  # ... provides pass-through arguments to "plot" function 
  # (typically "main" to create a title)
  
  # To Do:  Add a size legend
  #   Possibly incorporate "timeDots.old" in a single function
  
  # capture and restore incoming graphical parameters
  # incoming.par <- par(no.readonly = TRUE)
  incoming.par <- par(mar = c(4,8,2,1)) # in a quirk of R, this both changes and saves the old values
  on.exit(par(incoming.par))
  
  # par(mar = c(4,8,2,1))
  
  # data <- merge(data, cleanData[,c("PROPOSAL_ID", target)], by = "PROPOSAL_ID", all.x = TRUE)
  
  data[,1] <- droplevels(data[,1])
  
  theCats <- levels(data[,1])
  
  # Establish the maximum radius to scale the graph by either passing an argument or calculation
  
  if(!is.na(setMax)) {
    
    maxRadii <- sqrt(setMax)
    
  } else {
    
    maxRadii <- max(sqrt(data[,3]))
    
  }
  
  
  # create an empty plot with the correct limits
  plot(1,
       ylim = c(0,length(theCats)+1),
       xlim = range(data[,"interval"]),
       type = "n",
       yaxt = "n",
       ylab = "",
       #xlab = "interval",
       ...
  )
  
  invisible(
    lapply(theCats, function(x){
      
      theLine <- which(x == theCats) 
      x.val <- data[data[,1] == x,"interval"]
      theColors <- data[data[,1] == x,"win"]
      #radii <- sqrt(log(data[data[,2] == x,target]))
      radii <- sqrt((data[data[,1] == x,3]))
      
      colorMapping <- c("win" = "orange", "loss" = "steelblue")
      
      abline(h = theLine, col = "gray80", lwd = 2.5, xpd = FALSE)
      x.length <- length(x.val)   
      symbols(x = x.val,
              y = rep(theLine, x.length),
              circles = radii,
              inches = (max(radii)/maxRadii) * (circleSize),
              add = TRUE,
              bg = colorMapping[as.character(theColors)])  
      
      axis(side = 2, 
           at = theLine, 
           labels = x,
           las = 1) 
      
    })
  )
  
  # plot the legend
  legend("bottomleft",
         fill = c(adjustcolor("orange", alpha.f = 0.5), adjustcolor("steelblue", alpha.f = 0.5)),
         xpd = TRUE,
         inset =  c(-0.15,-0.15), # c(-0.3,-0.37), for RStudio plot window
         legend = c("win","loss"))  
  
}


perWide <- function(data, target = NA, display = "rate", ...) {
  
  # where data is the "per_wide" output of "elapsed" function
  # where display is "win", "loss", "count", or "win.rate"
  # where "target" is the row name
  # should I add a legend?
  
  # capture and restore incoming graphical parameters
  incoming.par <- par(mar = c(3,5,3,5))
  on.exit(par(incoming.par))
  
  # par(mar = c(3,5,3,5)) # par(mar = c(4,7,1,1))
  
  if(is.na(target)) {stop("Choose a row for 'target' argument")}
  
  if(!is.na(target) & display %in% c("win","loss","count")) {
    
    plot.vector <- unlist(data[row.names(data) == target, grepl(display, colnames(data))])
    
    plot(plot.vector,
         ylab = display,
         las = 1,
         ...)
    
  }
  
  
  # let's make that combo chart
  # This is always fun
  
  if(!is.na(target) & display %in% c("rate")) {
    
    numerator <- unlist(data[row.names(data) == target, grepl("win", colnames(data))])
    denominator <- unlist(data[row.names(data) == target, grepl("count", colnames(data))])
    win_rate <- numerator/denominator
    
  }    
  
  # Adjust the win_rate to the correct range
  
  plot.vector <- win_rate*max(denominator, na.rm=TRUE)
  
  thePlot <- barplot(denominator,
                     # axes = FALSE,
                     axisnames = FALSE,
                     space = 0.7,
                     las = 1,
                     border = NA,
                     ylab = "count \n(blue bar)",
                     col = "aliceblue",
                     ...)
  
  points(y = plot.vector,
         x = thePlot,
         xpd = TRUE,
         pch = 23, # 18
         cex = 1.5,
         col = "darkblue")
  
  axis(side = 1, at = thePlot, labels = (0:(length(plot.vector)-1)) )
  
  # rate tick marks
  
  axis(side = 4, 
       at = seq(0,max(denominator, na.rm=TRUE), 
                length.out = 11), 
       #labels = paste(seq(0,100, by = 10),"%", sep = ""),
       labels = c("0","","20","","40","","60","","80","","100%"),
       las = 1,
       col.axis = "darkblue"
       
  )
  
  mtext("win rate \n(diamond)", 
        side = 4,
        line = 3,
        col = "darkblue")
  
  # return(plot.vector) # no need to return anything
  # esp not plot.vector, which is the y-values of the win rate and only relates to the graph's appearance
  
}

