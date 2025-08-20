# Functions to support Exploring Grants
# 10.1.2024

# This is my first time adjusting one of these with GitHub.
# Before, I knew that a certain family of functions would work in a report
# because I "sourced" the proper version.

# Now I have to worry about backwards compatibility (I guess?)

# Initial functions are copied and pasted from "PI Investigation vA0.Rmd"
# I don't have much to say about how much I like these, or 


# color scheme
colorMapping <- c("win" = "orange", "loss" = "steelblue")

overlapHist <- function(data, colname, logScale = TRUE) {
  
  if(logScale == TRUE){
    lossData <- log(data[,colname][data$win == "loss"])
    winData <- log(data[,colname][data$win == "win"]) 
  } else {
    lossData <- (data[,colname][data$win == "loss"])
    winData <- (data[,colname][data$win == "win"])
  }
  
  hist(lossData,
       col = rgb(0,0,1,0.5), # Purple with 50% transparency
       main = colname,
       xlab = paste("Log of", colname),
       ylab = "Frequency",
       xlim = c(0,ceiling(max(c(lossData, winData)))),
       #ylim = c(0, 10), # Adjust as needed
       breaks = 20
  )
  
  # Add the second histogram with transparency
  hist(winData,
       col = rgb(1,0,0,0.5), # Peach with 50% transparency
       add = TRUE,
       breaks = 20 # Use the same number of breaks to match
  )
  
  # Add a legend
  legend("topleft", legend = c("Loss", "Win"), fill = c(rgb(0,0,1,0.5), rgb(1,0,0,0.5)), bty = "n")
  
  
}



overlapHistPlotly <- function(data, colname, logScale = TRUE) {
  
  if(logScale == TRUE){
    lossData <- log(data[, colname][data$win == "loss"])
    winData <- log(data[, colname][data$win == "win"])
  } else {
    lossData <- data[, colname][data$win == "loss"]
    winData <- data[, colname][data$win == "win"]
  }
  
  p1 <- plot_ly(x = lossData, type = "histogram", name = "Loss", opacity = 1, marker = list(color = 'rgba(128,0,128,0.5)'))
  p2 <- add_histogram(p1, x = winData, name = "Win", opacity = 1, marker = list(color = 'rgba(255,127,0,0.5)'))
  
  p2 %>%
    layout(title = colname,
           xaxis = list(title = paste("Log of", colname)),
           yaxis = list(title = "Frequency"))
}


categoryWins <- function(data, category, plotTitle = NA, ...) {
  
  colorMapping <- c("win" = "orange", "loss" = adjustcolor("steelblue", alpha.f = 0.5))
  
  if(is.na(plotTitle)) {plotTitle <- category}
  
  incoming.par <- par(no.readonly = TRUE) # default is c(5.1,4.1,4.1,2.1)
  
  plotTable <-table(data[, c(category, "win")]) %>% 
    as.matrix() %>%
    "["(order(rowSums(.), decreasing = TRUE),)
  
  if(nrow(plotTable)>11){
    
    plotTable <- rbind(plotTable[1:10,], other= colSums(plotTable[11:(nrow(plotTable)),]))
    
  }
  
  par(mfrow = c(1,2), mar = c(5.1,3.1,6.1,2.1))
  
  thePlot <- plotTable %>% 
    t %>% 
    barplot(., 
            col = colorMapping, # (brewer.pal(7, "Dark2")[c(1,7)]),
            #main = "Win count",
            xaxt = "n",
            ...)
  
  mtext("Count by wins", side = 3, line = 1, outer = FALSE, cex = 1.5)
  
  text(x = thePlot,
       y = par("usr")[3] - 0.5,
       labels = row.names(plotTable),
       adj = 1,
       srt = 30,
       xpd = TRUE,
       ...)
  
  # let's push that legend off to the side
  legend("topright",
         #inset = c(-0.5,0),
         legend = rev(colnames(plotTable)), 
         fill = rev(colorMapping),
         bty = "n",
         border = NA,
         cex = 1.2,
         #pch =1,
         pt.cex = 1.5,
         xpd = TRUE
  )
  
  plotTable %>%
    apply(.,1,proportions) %>%
    "*"(100) %>%
    barplot(.,
            col = (colorMapping),
            las=1,
            #main = "Percent win",
            xaxt = "n")
  
  mtext("Percent win", side = 3, line = 1, outer = FALSE, cex = 1.5)
  
  text(x = thePlot,
       y = par("usr")[3] - 0.5,
       labels = row.names(plotTable),
       adj = 1,
       srt = 30,
       xpd = TRUE,
       ...)
  
  mtext(plotTitle, side = 3, line = -2, outer = TRUE, cex = 1.5)
  
  
  par(incoming.par) # restore whatever the parameters were coming in
  
}


overlapDensity <- function(data, colname, logScale = TRUE, ...) {
  
  colorMapping <- c("win" = "orange", "loss" = "steelblue")
  
  if(logScale == TRUE){
    allData <- density(log(data[,colname]))
    lossData <- density(log(data[,colname][data$win == "loss"]))
    winData <- density(log(data[,colname][data$win == "win"])) 
    xAxisType <- "n"
  } else {
    allData <- density((data[,colname]))
    lossData <- density(data[,colname][data$win == "loss"])
    winData <- density(data[,colname][data$win == "win"])
    xAxisType <- "s"
  }
  
  
  # extract range
  yMax <- max(c(allData$y, lossData$y, winData$y))
  
  # plot it
  plot(allData,
       ylim = c(0,yMax),
       lwd = 4,
       col = "grey80",
       xaxt = xAxisType,
       #main = colname,
       ...)
  
  lines(lossData, col = colorMapping[["loss"]], lwd = 2)
  lines(winData, col = colorMapping[["win"]], lwd = 2.5)

  if(logScale == TRUE){
  xTicks <- seq(from = 0, by = floor(diff(range(allData$x))/5), to = ceiling(max(allData$x))) 
  axis(side = 1, at = xTicks, labels = format(exp(xTicks), scientific = TRUE, digits = 2))  
  }
  
  # Add a legend
  legend("topleft", legend = c("All", "Win", "Loss"), fill = c("grey80",colorMapping, bty = "n"))
  
  
}


stackedHist <- function(data, targetColumn, logScale = TRUE, breaks = NA,...){
  
  
  # Establish colors
  colorMapping <- c("win" = "orange", "loss" = adjustcolor("steelblue", alpha.f = 0.5) )
  
  # capture and restore incoming graphical parameters
  incoming_par <- par("mar")
  #incoming_par$mfrow <- NULL
  on.exit(par(incoming_par))
  
  # establish histogram breaks
  if(any(is.na(breaks))) {histBreaks <- 20} else {histBreaks <- breaks}
  
  if(logScale) {
    
    # Calculate breaks for finite values
    if(length(histBreaks) == 1 & any(is.infinite(data[,targetColumn])|data[,targetColumn] ==0)){
      finite_range <- range(log(data[data[,targetColumn] !=0 ,targetColumn])) # Exclude 0 to avoide -Inf and Inf
      finalBreaks <- c(-Inf, seq(finite_range[1], finite_range[2], length.out = histBreaks-1), Inf) } else {
        finalBreaks <- histBreaks 
      }
    
    # Create cuts on the log values
    data$cut <- log(data[,targetColumn]) |>
      cut(breaks = finalBreaks, include.lowest=TRUE)
    
    # establish values that are overwritten if negative values are being represented
    linePlacement <- -2
    positiveTitle <- ""
    
    # If they exist, represent negative values as absolute values in a separate graph``
    if( any(data[,targetColumn] < 0 )){
      
      # Represent a log of negative values by showing the absolute values in a separate graphic
      
      # Create two plots
      negPar <- par(mfrow = c(1,2), mar = c(5.1,3.1,3.1,0), oma=c(0,0,2,0)) #c(5.1,4.1,4.1,2.1)
      
      # Create log of absolute values  
      negativeFilter <- data[,targetColumn] < 0 & !is.na(data[,targetColumn]) & !is.nan(data[,targetColumn])
      
      intermediate <- data[negativeFilter,targetColumn] |>
        abs() |> 
        log() |>
        cut(breaks = finalBreaks, include.lowest = TRUE)
      
      data[negativeFilter,"cut.neg"] <- as.character(intermediate)
      
      # Make the first plot of negative values in reverse order
      
      table(data[,c("cut.neg","win")])[nrow(table(data[, c("cut.neg", "win")])):1, ] |> t() |>
        barplot(col = colorMapping,
                main = "Log absolute negative values",
                font.main = 1,
                cex.main = 1.2,
                las = 2
        )
      
      # Establish values for titles
      positiveTitle <- "Log positive values"
      linePlacement <- -2
      
    }
    
    # plot the positive values
    
    table(data[,c("cut","win")]) |> t() |>
      barplot(col = colorMapping,
              main = positiveTitle,
              font.main = 1,
              cex.main = 1.2,
              las = 2)
    
    legend("topleft",
           legend = c("win","loss"),
           fill = colorMapping)
    
    mtext(targetColumn, side = 3, line = linePlacement, outer = TRUE, cex = 1.2, font = 2)
    
    
    
  }
  
}



plotBoxes <- function(data, targetColumn = "PROPOSAL_TOTAL_SPONSOR_BUDGET", logScale = TRUE, categoryColumn = "PROPOSAL_COLLEGE",...){
  
  # Establish colors
  colorMapping <- c("win" = "orange", "loss" = adjustcolor("steelblue", alpha.f = 0.5) )
  
  # capture and restore incoming graphical parameters
  incoming.par <- par(par(mar=c(10,4,4,2)))
  on.exit(par(incoming.par))
  
  
  if(logScale == TRUE){
    boxplot(log(get(targetColumn)) ~ win + get(categoryColumn), data = droplevels(data), 
            notch = TRUE, 
            col = colorMapping, 
            xlab = "", 
            ylab = paste0(targetColumn, "\n(log)"), 
            outline = FALSE,
            las = 2,
            horizontal = FALSE,
            ...)
    return(invisible())
  }
  
  boxplot(get(targetColumn) ~ win + get(categoryColumn), data = droplevels(data), 
          notch = TRUE, 
          col = colorMapping, 
          xlab = "", 
          ylab = targetColumn, 
          outline = FALSE,
          las = 2,
          horizontal = FALSE,
          ...)
}


# This one is developed in "Visualizations Sandbox"

timeDiff <- function(period = "week",
                     dateColumn = "PROPOSAL_UPLOAD_DATE", 
                     data,
                     semester = TRUE,
                     type = "difference",
                     ...) {
  
  # where "type" does different plot
  # "difference" is the difference shown by vertical lines
  # "raw" is a line plot of the raw counts
  
  # suggest main = "Difference between winning and losing proposals\nby 'project start' week of the year"
  # suggest main = "Count of proposals uploaded per day of year",
  
  # improve this by floating the legend to the right
  # improve this by adding an argument to include "Vertical lines show semester beginnings" phrase
  
  colorMapping <- c("win" = "orange", "loss" = "steelblue")
  
  if (type == "difference"){
    
    # aggregate to the target period
    
    if (period == "week") {
      theAgg <- aggregate(win ~ isoweek(get(dateColumn)), data = data, table)
    }
    
    if (period == "month") {
      theAgg <- aggregate(win ~ month(get(dateColumn)), data = data, table)
    }
    
    # Convert the table results into separate columns for wins and losses
    theAgg <- data.frame(as.data.frame.matrix(theAgg$win))
    
    theAgg$diff <- theAgg$win - theAgg$loss
    
    # Set up an empty plot (line color doesn't matter here)
    plot(theAgg$diff, 
         type = "l", 
         col = "gray", 
         ylab = "Difference", 
         xlab = period,
         ...)
    
    # Add vertical lines at each point
    for (i in 1:length(theAgg$diff)) {
      # Determine the color for the vertical line
      segment_color <- ifelse(theAgg$diff[i] > 0, adjustcolor(colorMapping[["win"]], alpha.f = 0.5), adjustcolor(colorMapping[["loss"]], alpha.f = 0.5))
      
      # Draw a vertical line from the x-axis (y=0) to the data point
      segments(i, 0, i, theAgg$diff[i], col = segment_color, lwd = 2)  # 'lwd' controls line width
    }
    
    legend("bottomright",
           fill = c(adjustcolor(colorMapping[["win"]], alpha.f = 0.5), adjustcolor(colorMapping[["loss"]], alpha.f = 0.5)),
           legend = c("win","loss"))
  }
  
  if(type == "raw") {
    
    data[,dateColumn][data[,"win"] == "loss"] |>
      isoweek() |>
      table() |>
      plot(#main = "Count of proposals uploaded per day of year",
        ylab = "Uploads count",
        type = "l",
        col = adjustcolor(colorMapping[["loss"]], alpha.f = 0.7),
        ...)
    
    data[,dateColumn][data[,"win"] == "win"] |>
      isoweek() |>
      table() |>
      points(col = colorMapping[["win"]],
             lwd = 4,
             type = "l")
    
    legend("topleft",
           fill = c(colorMapping[["win"]], adjustcolor(colorMapping[["loss"]], alpha.f = 0.7)),
           legend = c("win","loss"))
    
  }
  
  # Add vertical semester lines
  
  if(semester == TRUE & period == "week") {
    
    semesterSchedule <- data.frame(term = c("Fall 2023", "Spring 2024", "Summer 2024"), 
                                   begin = ymd(c("2023-08-21", "2024-01-08", "2024-05-13")), 
                                   end = ymd(c("2023-12-15", "2024-05-01", "2024-08-02")))
    
    semesterSchedule$week.end <- isoweek(semesterSchedule$end)
    semesterSchedule$week.begin <- isoweek(semesterSchedule$begin)
    
    abline(v = semesterSchedule$week.begin,
           lwd = 4,
           lty = "solid",
           col = "grey80")
    
  #  legend("topright",
  #         bty = "n",
  #         legend = "",
  #         xpd = TRUE,
  #         inset = c(0,-0.2),
  #         title = "Vertical lines show semester beginnings",
  #         title.font = 3)
    
    #mtext("Vertical lines show semester beginnings",
    #      1,
    #      line = 2,
    #      font = 3,
    #      cex = 0.9)
    
  }
  
  
}


calculateWinRate <- function(data, targetColumn = "PROPOSAL_TOTAL_SPONSOR_BUDGET",  categoryColumn = "PROPOSAL_COLLEGE"){
  
  # NOTE:  THIS IS SUPERSEDED BY "calculateWinRates" (notice the extra 's').)
  # This older version is kept for backwards compatibility (but I should probably just 
  # delete it to avoid confusion.)
  
  # Calculates a win rate per whatever your target column is
  # This both counts and sums the target financial/numerical column by the category column
  # I wonder if I could modify it to also include mean or median?
  
  print("Are you sure you don't mean 'calculateWinRates'?")
  
  aggregate(get(targetColumn)~win + get(categoryColumn), 
            data = data,
            function(x){c(sum = sum(x, na.rm=TRUE), count = length(x))} ) |>
    reshape(timevar = "win", 
            idvar = "get(categoryColumn)", 
            direction = "wide") |>
    (\(x){ 
      
      keepNames <-  gsub("get\\(targetColumn\\).", "", colnames(x)[2:3])
      expanded <- cbind(x[,1], as.data.frame.matrix(x[,2]), as.data.frame.matrix(x[,3]))
      row.names(expanded) <- expanded[,1]
      expanded[,1] <- NULL
      colnames(expanded) <- paste0(rep(keepNames, each = 2) , "." , colnames(expanded))
      return(expanded)
      
    })() |> # expand columns
    (\(x){x[,"sum.rate"] <- x[,"win.sum"]/(x[,"win.sum"]+x[,"loss.sum"] );
    x[,"count.rate"] <- x[,"win.count"]/(x[,"win.count"]+x[,"loss.count"]);
    return(x)})() |>
    (\(x){x[is.na(x)] <- 0; return(x)})() # replace NA with zero
  
}

calculateWinRates <- function(data, 
                              targetColumn = "PROPOSAL_TOTAL_SPONSOR_BUDGET",  
                              categoryColumn = "PROPOSAL_COLLEGE", functionList = list()){
  
  # This is a wrapper function for "aggregate."
  # It aggregates the targetColumn according to the categoryColumn plus "win" column.
  # It will always return "count" and "sum" functions, and is extensible to additional
  # summary functions (like mean, median, or RMS = sqrt(mean(x^2))).
  
  # It returns a list with the aggregation, and the function call arguments
  # The aggregation is a data frame sorted in descending order by the total count
  
  # Capture the function call
  argsCall <- match.call()
  
  # Ensure the custom functions are named
  if (length(functionList) > 0 && is.null(names(functionList))) {
    stop("Custom functions in 'functionList' must be named.")
  }
  
  
  # define a summary function to use in the aggregate call
  
  if(length(functionList) > 0 ) {
    
    summaryFunction <- function(x, functionList){c(sum = sum(x, na.rm=TRUE), 
                                                   count = length(x),
                                                   sapply(functionList, function(f){f(x)}))}
  } else {
    
    summaryFunction <- function(x, functionList){c(sum = sum(x, na.rm=TRUE), 
                                                   count = length(x))}
    
  }
  
  
  theAgg <-  aggregate(get(targetColumn)~win + get(categoryColumn), 
                       data = data,
                       FUN = function(x) {summaryFunction(x, functionList)} )  |>
    reshape(   timevar = "win", 
               idvar = "get(categoryColumn)", 
               direction = "wide")  |>
    (\(x){
      keepNames <-  gsub("get\\(targetColumn\\).", "", colnames(x)[2:3])
      expanded <- cbind(x[,1], as.data.frame.matrix(x[,2]), as.data.frame.matrix(x[,3]))
      row.names(expanded) <- expanded[,1]
      expanded[,1] <- NULL
      colnames(expanded) <- paste0(rep(keepNames, each = ncol(x[, 2])) , "." , colnames(expanded))
      #  colnames(expanded) <- paste0(targetColumn, ".", colnames(expanded))
      return(expanded)
    })()   |> # expand columns
    (\(x){x[is.na(x)] <- 0; return(x)})()  |> # replace NA with zero
    (\(x){x[,"sum.rate"] <- x[,"win.sum"]/(x[,"win.sum"]+x[,"loss.sum"] );
    x[,"count.rate"] <- x[,"win.count"]/(x[,"win.count"]+x[,"loss.count"]);
    return(x)})() |> # calculate win rates by both sum and count
    (\(x){x[order(rowSums(x[,c("win.count","loss.count")]), decreasing = TRUE),]})() # Descending order of total count
  
  
  return(
    list(summary = theAgg,
         call = argsCall)
  )
  
  
}

plotWinRates <- function(data,
                         style = "bar",
                         agg = "count", 
                         line = NA, 
                         log = FALSE,
                         labelMatrix = NA,
                         colorMapping = NA, 
                         pchMapping=NA, 
                         cexMapping_rate = NA, 
                         cexMapping_sum = NA,
                         
                         #row.filter=NA, 
                         win.filter=NA,
                         
                         bar_params = list(),
                         rect_args = list(),
                         bar_args = list(),
                         bar_mtext_args = list(),
                         bar_points_args = list(),
                         bar_points_axis_args = list(),
                         bar_points_mtext_args = list(),
                         bar_legend_args = list(),
                         
                         scatter_params = list(),
                         scatter1_args = list(), 
                         scatter1_text_args = list(),
                         scatter1_mtext_args = list(),
                         
                         scatter2_args = list(),
                         scatter2_text_args = list(),
                         scatter2_mtext_args = list(),
                         
                         scatter_title_args = list(),
                         
                         ...) {
  
  # where data is the result of "calculateWinRates"
  # where "style" is either "bar" or "scatter" and describes what plot will be shown
  #       "scatter" is replaced with "yBYx()" function.
  # where "agg" is "count" or "sum" and refers to different columns
  # where "line" describes whether a line is drawn over the bar plot describing the win rates,
  # where "line" can have a value of "count" or "sum" and it plots it over the graphic with that rate
  # where "log" is TRUE or FALSE and designates if the plots are shown on a log scale
  # where labelMatrix is two columns:  the first column is the row names as the appear in the data,
  #       and the second column is the labels as I'd like them to appear  
  # where the various  mapping is a vector with the specific color or pch value with the row names
  #   (or labelMatrix values if I am using labelMatrix)
  # where win.filter applies only to the barplot.  It has values of "win" or "loss", and shows only those bars 
  
  # where the "_args" lists pass through arguments as indicated.
  
  
  
  # TO DO:
  # Add some red actual values on the axis if I am using log scales
  # Add legends to the scatter plots (center them between the titles?)
  # rather than scale the cex size continuously from 0.5 to 3, maybe I should make three groups?
  # Change the color scheme: # DONE
  #   where "orange" and "steelblue" signify "count" by bars # DONE
  #   where "darkorange" and "steelblue" signify "sum" or "dollar" by bars
  #   where for lines: # DONE
  #      "darkslategray" is an overlay line for non-count or sum lines
  #      "firebrick" indicates "sum" or dollar
  #      "darkorange4" indicates count
  # Shift the line y-axis to the right to make space for the label text # MAYBE O.K.
  
  # THOUGHTS:
  #   Modify calculateWinRate to add aggregations (mean, median, quantiles) and modify this to plot them # DONE
  #   Incorporate pchMapping and colorMapping into the labelMatrix
  #   The line doesn't work on the bar if "beside = TRUE" # FIXED
  #   rather than scale the cex size continuously from 0.5 to 3, maybe I should make three groups?
  #   Manage this as a main function and turn the sections into helper functions
  #   Should I create an ability to write just the lines by themselves? -- also I can manage this by 
  #    lightening/fading/whitening the bars behind the line
  #   Now that I have added an ability to turn any column into a line-- should I add an ability
  #    to do multiple lines? 
  #   Rather than put in a "labelMatrix", I should just re-name the rows of the data before I put it in.
  #   I wonder if I could make the floating line as a stand-alone function?
  
  # Should I add a legend?
  # Should I make a version that is just the win rate line?
  # Should I make a version that is the win/loss amounts by lines instead of by bars?
  # Should I add an ability to do multiple lines?
  # Should I convert to accept a "detailMapping" --> Why would bars need this?
  
  if(style == "bar") {
    
    # capture and restore incoming graphical parameters
    
    default_bar_params <- list(
      mar = c(5,5,3,5),
      bg = "ivory",
      fg = "gray10"
    )
    
    bar_params <- modifyList(default_bar_params, bar_params)
    incoming.par <- do.call(par, bar_params)
    on.exit(par(incoming.par))
    
    # Default color map
    if(any(is.na(colorMapping))) {
      
      if(grepl("count",agg)){
        colorMapping <- c(win = "orange", loss = adjustcolor("steelblue", alpha.f = 0.5) )
      } else if(grepl("sum",agg)) {
        colorMapping <- c(win = "darkorange", loss = adjustcolor("steelblue", alpha.f = 0.75) )  
      } else {
        colorMapping <- c(win = "goldenrod1", loss = adjustcolor("steelblue", alpha.f = 0.4) )
      }
      
      
      
    }
    
    
    plotMatrix <- t(as.matrix(data[,c(paste("win", agg, sep ="."),paste("loss", agg, sep ="."))]))
    
    # if(agg == "count") {plotMatrix <- t(as.matrix(data[,c("win.count","loss.count")]))}
    # if(agg == "sum") {plotMatrix <- t(as.matrix(data[,c("win.sum","loss.sum")]))}
    
    # log capability
    if(log == TRUE) { plotMatrix <- log(plotMatrix)}
    
    # apply labels
    if(any(!is.na(labelMatrix))) { colnames(plotMatrix) <- labelMatrix[match(colnames(plotMatrix), labelMatrix[,1],),2] }
    
    
    # apply filters
    # if(any(!is.na(row.filter))) { plotMatrix <- plotMatrix[,grep(paste(row.filter, collapse = "|"), colnames(plotMatrix))]}
    if(any(!is.na(win.filter))) { plotMatrix <- plotMatrix[grep(paste(win.filter, collapse = "|"), row.names(plotMatrix)), drop=FALSE,];}
    
    
    default_bar <- list(las = 2,
                        col = colorMapping[gsub("\\..*", "", rownames(plotMatrix))]
    )
    
    bar_args <- modifyList(default_bar, bar_args)
    
    # draw an empty plot
    barplot(plotMatrix,
            bty = "n",
            xaxt = "n",
            yaxt = "n",
            xlab = "",
            ylab = "")
    
    # now define the proper par("usr") values
    default_rect_args <- list(
      xleft = par("usr")[1], 
      ybottom = par("usr")[3], 
      xright = par("usr")[2], 
      ytop = par("usr")[4],
      col = "gray95",
      border = NA
    )
    
    # draw background color
    rect_args <- modifyList(default_rect_args, rect_args)
    do.call("rect", rect_args)
    
    # add the barplot
    par(new = TRUE)
    
    theBar <- do.call("barplot", c(list(plotMatrix),
                                   bar_args))
    
    default_bar_mtext_args <- list(
      text = "",
      side = 3,
      line = 1.25,
      cex = 2,
      font = 2
    )
    
    bar_mtext_args <- modifyList(default_bar_mtext_args, bar_mtext_args)
    
    do.call("mtext", bar_mtext_args)
    
    if(!is.na(line)) {
      
      if(grepl("rate",line)){ # draw a rate line
        
        textLabel <- paste("Win rate (", sub(".rate","", line) ,")", sep = "")  
        
      } else {textLabel <- line}
      
      if(grepl("count",line)){ 
        
        lineColor <- "darkorange4"
        
      } else if (grepl("sum", line)) {
        
        lineColor <- "firebrick"
        
      } else {lineColor <- "darkslategray"}
      
      
      if(is.null(dim(plotMatrix))){scaleValue <- max(plotMatrix, na.rm=TRUE)} else if("beside" %in% names(bar_args)){ 
        
        if(bar_args[["beside"]]) {scaleValue <- max(plotMatrix, na.rm=TRUE); lineX <- apply(theBar,2, mean)}
        
      } else {
        scaleValue <- max(apply(plotMatrix, 2, sum), na.rm=TRUE);
        lineX <- theBar
      }
      
      plotLine <- ((data[,line] - min(data[,line], na.rm=TRUE))/(max(data[,line], na.rm=TRUE) - min(data[,line], na.rm=TRUE)))*(0.9*scaleValue-0.1*scaleValue) + 0.1*scaleValue
      
      tickLabels <- pretty(range(data[!is.na(data[,line]),line]), n = 5)
      tickMarks <- ((tickLabels - min(data[,line], na.rm=TRUE))/(max(data[,line], na.rm=TRUE) - min(data[,line], na.rm=TRUE)))*(0.9*scaleValue-0.1*scaleValue) + 0.1*scaleValue
      
      default_bar_points_args <- list(
        type = "b",
        pch = 5,
        cex = 1.5,
        lwd = 2,
        col = lineColor
      )
      
      bar_points_args <- modifyList(default_bar_points_args, bar_points_args)
      
      do.call("points", c(list(y = plotLine, x = lineX), bar_points_args))
      
      default_bar_points_axis_args <- list(
        side = 4,
        at = tickMarks,   # seq(from = 0, to = 1, by = 0.2) * scaleValue,
        labels = tickLabels, # paste(seq(from = 0, to = 100, by = 20), "%"),
        las = 2,
        lwd = 2,
        col = lineColor,
        col.axis = lineColor,
        font.axis =2,
        xpd = TRUE
      )
      
      bar_points_axis_args <- modifyList(default_bar_points_axis_args, bar_points_axis_args)
      
      do.call("axis", bar_points_axis_args)
      
      default_bar_points_mtext_args <- list(
        side = 4, 
        text = textLabel, 
        col = lineColor, 
        line = -1.2, 
        font = 2
      )
      
      bar_points_mtext_args <- modifyList(default_bar_points_mtext_args, bar_points_mtext_args)
      
      do.call("mtext", bar_points_mtext_args)
      
      # mtext(side = 4, textLabel, col = "darkslategray", line = -1.2, font = 2)
      
    }
    
    
    default_legend_args <- list(
      x = "topright",
      bty = "n",
      legend = rev(c("win","loss")),
      pch = 15,
      cex = 1.2,
      pt.cex = 1.5,
      col = rev(colorMapping)
    )
    
    #  if() { 
    #    default_legend_args <- modifyList(default_legend_args, list(col = rev(c("orange",adjustcolor("steelblue", alpha.f = 0.5))) ))
    #    }
    
    bar_legend_args <- modifyList(default_legend_args, bar_legend_args)
    do.call("legend", bar_legend_args)
    
  }
  
  
  if(style == "scatter") {
    
    # capture and restore incoming graphical parameters
    
    default_scatter_params <- list(
      mfrow = c(1,2), 
      oma = c(0, 0, 3, 0),
      mar= c(5, 6, 3, 0.5),
      bg = "ivory",
      fg = "gray10"
    )
    
    scatter_params <- modifyList(default_scatter_params, scatter_params)
    incoming.par <- do.call(par, scatter_params)
    on.exit(par(incoming.par))
    
    ####################
    ## COUNT BY FUNDS ##
    ####################
    
    fundsMatrix <- cbind(apply(data[,c("win.count", "loss.count")], 1, sum),
                         apply(data[,c("win.sum", "loss.sum")], 1, sum))
    
    # log capability
    if(log == TRUE) { fundsMatrix <- log(fundsMatrix)}
    
    # apply labels
    if(any(!is.na(labelMatrix))) { row.names(fundsMatrix) <- labelMatrix[match(row.names(fundsMatrix), labelMatrix[,1],),2] }
    
    # colorMapping applies to the rows for the scatter
    if(any(is.na(colorMapping))) {
      
      
      # Manually specify 24 unique colors
      if(nrow(data) <= 24){
        
        colorMapping <- c(
          "red", "blue", "green", "lightslategray", "purple", "orange", 
          "cyan", "hotpink", "brown", "darkgoldenrod", "gold", "navy", 
          "magenta", "olivedrab4", "chartreuse", "salmon", "darkgreen", "yellowgreen", 
          "chocolate", "coral", "turquoise", "violet", "darkmagenta", "khaki"
        )[1:nrow(data)]
        
        # colorMapping <- brewer.pal(nrow(data), "Dark2")
        
      } else {
        
        colorMapping <- sample(colors()[-grep("grey|gray", colors())], nrow(data), replace = FALSE)
        
      }
      
      names(colorMapping) <- row.names(fundsMatrix) 
      
    }
    
    # pchMapping applies to the rows for the scatter
    if(any(is.na(pchMapping))){
      
      if(nrow(data) <= 19){
        
        pchMapping <- 0:18
        
      } else { pchMapping <- rep(19, nrow(data))}
      
      names(pchMapping) <- row.names(fundsMatrix)
    }
    
    # cexMapping applies to the rows for the scatter
    if(any(is.na(cexMapping_rate))){
      
      cexMapping_rate <- 0.5 + (data[,"count.rate"] -  min(data[,"count.rate"], na.rm=TRUE)) / (max(data[,"count.rate"], na.rm=TRUE)-min(data[,"count.rate"], na.rm=TRUE)) * (3-0.5)
      
      names(cexMapping_rate) <- row.names(fundsMatrix)
      
    }
    
    if(any(is.na(cexMapping_sum))){
      
      sizeVector <- apply(data[,c("win.sum", "loss.sum")], 1, sum)
      
      cexMapping_sum <- 0.5 + (sizeVector -  min(sizeVector, na.rm=TRUE)) / (max(sizeVector, na.rm=TRUE)-min(sizeVector, na.rm=TRUE)) * (3-0.5)
      
      names(cexMapping_sum) <- row.names(fundsMatrix)
      
    }    
    
    default_scatter1 <- list(las = 1,
                             col = colorMapping[gsub("\\..*", "", rownames(fundsMatrix))],
                             pch = pchMapping[gsub("\\..*", "", rownames(fundsMatrix))],
                             cex = cexMapping_rate[gsub("\\..*", "", rownames(fundsMatrix))],
                             xlab = "",
                             ylab = "")
    
    scatter1_args <- modifyList(default_scatter1, scatter1_args)
    
    do.call("plot", c(list(fundsMatrix),
                      scatter1_args))
    
    default_scatter1_text_args <- list(
      labels = rownames(fundsMatrix),
      pos = sample(1:4, size= nrow(fundsMatrix), replace = TRUE),
      xpd = TRUE,
      col = colorMapping[gsub("\\..*", "", rownames(fundsMatrix))]      
    )
    scatter1_text_args <- modifyList(default_scatter1_text_args, scatter1_text_args)
    
    do.call("text", c(list(fundsMatrix), scatter1_text_args))   
    
    default_scatter1_mtext_args <- list(
      side = c(3, 1, 2),
      text = c("Volume", "Count of proposals", "Total requested funds"),
      line = c(1.25,3.5,4),
      cex = c(1.2,1,1),
      font = c(2,1,1),
      col = "grey10"
      
    ) 
    scatter1_mtext_args <- modifyList(default_scatter1_mtext_args, scatter1_mtext_args)
    
    do.call("mtext", scatter1_mtext_args)
    
    #######################
    ## COUNT BY WIN RATE ##
    #######################
    
    countMatrix <- cbind(apply(data[,c("win.count", "loss.count")], 1, sum),
                         data[,c("count.rate")])
    
    # log capability
    if(log == TRUE) { countMatrix[,1] <- log(countMatrix[,1])}
    
    # apply labels
    if(any(!is.na(labelMatrix))) { row.names(countMatrix) <- labelMatrix[match(row.names(countMatrix), labelMatrix[,1],),2] }
    
    default_scatter2 <- list(las = 1,
                             col = colorMapping[gsub("\\..*", "", rownames(countMatrix))],
                             pch = pchMapping[gsub("\\..*", "", rownames(countMatrix))],
                             cex = cexMapping_sum[gsub("\\..*", "", rownames(countMatrix))],
                             xlab = "",
                             ylab = "")
    
    scatter2_args <- modifyList(default_scatter2, scatter2_args)
    
    do.call("plot", c(list(countMatrix),
                      scatter2_args))
    
    default_scatter2_text_args <- list(
      labels = rownames(countMatrix),
      pos = sample(c(2,4), size= nrow(fundsMatrix), replace = TRUE),
      xpd = TRUE,
      col = colorMapping[rownames(countMatrix)]      
    )
    scatter2_text_args <- modifyList(default_scatter2_text_args, scatter2_text_args)
    
    do.call("text", c(list(countMatrix), scatter2_text_args))   
    
    default_scatter2_mtext_args <- list(
      side = c(3, 1, 2),
      text = c("Count vs win rate", "Count of proposals", "Fraction of proposals won"),
      line = c(1.25,3.5,3.5),
      cex = c(1.2,1,1),
      font = c(2,1,1),
      col = "grey10"
      
    ) 
    scatter2_mtext_args <- modifyList(default_scatter2_mtext_args, scatter2_mtext_args)
    
    do.call("mtext", scatter2_mtext_args)
    
    ## Full title
    
    default_scatter_title_args <- list(
      side = 3,
      text = "Two plots",
      line = 1.25,
      cex = 2,
      font = 2,
      outer = TRUE
    )
    
    scatter_title_args <- modifyList(default_scatter_title_args, scatter_title_args)
    
    do.call("mtext", scatter_title_args)
    
  }
  
}



yBYx <- function(data,
                 axes = "rate.by.sum",
                 x_axis = NA,
                 y_axis = NA,
                 detailMapping=data.frame(college = NA, abbrv = NA, color = NA, pch = NA, cex = NA),
                 log = FALSE,
                 scatter_params = list(),
                 scatter_args = list(),
                 rect_args = list(), 
                 grid_args = list(),
                 scatter_text_args = list(),
                 scatter_mtext_args = list()) {
  
  # "log" function accepts arguments of "x", "y", or c("x","y")
  #    depending on the axis to apply the log transformation
  
  
  
  ###################
  ## CREATE MATRIX ##
  ###################
  
  if(!is.na(x_axis) & !is.na(y_axis)) { axes <- NA} # re-set axes value if x_axis and y_axis are supplied
  
  if(!is.na(axes)){
    
    if(axes == "sum.by.count") { 
      
      plotMatrix <- cbind(apply(data[,c("win.count", "loss.count"), drop = FALSE], 1, sum),
                          apply(data[,c("win.sum", "loss.sum"), drop = FALSE], 1, sum))
      
      
    } else if (axes == "rate.by.count"){
      
      plotMatrix <- cbind(apply(data[,c("win.count", "loss.count"), drop = FALSE], 1, sum),
                          apply(data[,c("count.rate"), drop = FALSE], 1, sum))
      
      
    } else if (axes == "rate.by.sum"){
      
      plotMatrix <- cbind(apply(data[,c("win.sum", "loss.sum"), drop = FALSE], 1, sum),
                          apply(data[,c("sum.rate"), drop = FALSE], 1, sum))
      
    } 
    
  } else { 
    
    plotMatrix <- cbind(apply(data[,x_axis, drop = FALSE], 1, sum),
                        apply(data[,y_axis, drop = FALSE], 1, sum))
    
  }
  
  # log capability
  if(identical(log,"x")) {
    
    plotMatrix[,1] <- log(plotMatrix[,1]) |> (\(x){x[is.infinite(x)] <- 0; return(x)})()
    
  } else if (identical(log,"y")) {
    
    plotMatrix[,2] <- log(plotMatrix[,2]) |> (\(x){x[is.infinite(x)] <- 0; return(x)})()
    
  } else if (all(log %in% c("x","y"))) { plotMatrix <- log(plotMatrix)} 
  
  
  ###################
  ## APPLY MAPPING ##
  ###################
  
  # create mapping if not supplied
  
  if(all(is.na(detailMapping))){
    
    detailMapping <- data.frame(row.names = row.names(data), college = rep(NA, nrow(data)), abbrv = rep(NA, nrow(data)), color = rep(NA, nrow(data)), pch = rep(NA, nrow(data)), cex = rep(NA, nrow(data)))
    
  }
  
  
  # apply labels
  
  if(all(!is.na(detailMapping[,"abbrv"]))) {
    
    row.names(plotMatrix) <- detailMapping[match(row.names(plotMatrix), detailMapping[,"college"],),"abbrv"]
    
  }
  
  # colorMapping applies to the rows for the scatter
  if(all(is.na(detailMapping[,"color"]))) {
    
    
    # Manually specify 24 unique colors
    if(nrow(data) <= 24){
      
      detailMapping[,"color"] <- c(
        "red", "blue", "green", "lightslategray", "purple", "orange", 
        "cyan", "hotpink", "brown", "darkgoldenrod", "gold", "navy", 
        "magenta", "olivedrab4", "chartreuse", "salmon", "darkgreen", "yellowgreen", 
        "chocolate", "coral", "turquoise", "violet", "darkmagenta", "khaki"
      )[1:nrow(data)]
      
      
    } else {
      
      detailMapping[,"color"] <- sample(colors()[-grep("grey|gray", colors())], nrow(data), replace = FALSE)
      
    }
    
  }
  
  # pchMapping applies to the rows for the scatter
  if(all(is.na(detailMapping[,"pch"]))){
    
    if(nrow(data) <= 19){
      
      detailMapping[,"pch"] <- 0:18
      
    } else { detailMapping[,"pch"] <- rep(19, nrow(data))}
    
  }
  
  # cexMapping applies to the rows for the scatter
  if(all(is.na(detailMapping[,"cex"]))){
    
    detailMapping[,"cex"] <- 0.5 + (data[,"count.rate"] -  min(data[,"count.rate"], na.rm=TRUE)) / (max(data[,"count.rate"], na.rm=TRUE)-min(data[,"count.rate"], na.rm=TRUE)) * (3-0.5)
    
    
  }
  
  # Align matrix and mapping if necessary
  
  if(!identical(row.names(plotMatrix), row.names(detailMapping))) {
    
    detailMapping <- detailMapping[match(row.names(plotMatrix),detailMapping[,"abbrv"]),]
    
  }
  
  ####################
  ## PLOT ARGUMENTS ##
  ####################  
  
  # Parameters
  
  default_scatter_params <- list(bg = "ivory",
                                 fg = "gray10"
  )
  
  scatter_params <- modifyList(default_scatter_params, scatter_params)
  incoming.par <- do.call(par, scatter_params)
  on.exit(par(incoming.par))
  
  
  # Plot arguments
  
  default_scatter <- list(las = 1,
                          col = detailMapping[,"color"],
                          pch = as.numeric(detailMapping[,"pch"]),
                          cex = as.numeric(detailMapping[,"cex"]),
                          xlab = "",
                          ylab = "")
  
  default_scatter_text_args <- list(
    labels = rownames(plotMatrix),
    pos = sample(1:4, size= nrow(plotMatrix), replace = TRUE),
    xpd = TRUE,
    col = detailMapping[,"color"]      
  )
  
  if(!is.na(axes)){
    
    if(axes == "sum.by.count") {
      
      default_scatter_mtext_args <- list(
        side = c(3, 1, 2),
        text = c("Total funds requested\nv. count", "Count of proposals", "Total requested funds"),
        line = c(1.25,3.5,4),
        cex = c(1.2,1,1),
        font = c(2,1,1),
        col = "grey10"
        
      )   
      
    } else if (axes == "rate.by.count"){
      
      
      default_scatter_mtext_args <- list(
        side = c(3, 1, 2),
        text = c("Win rate vs count", "Count of proposals", "Fraction of proposals won"),
        line = c(1.25,3.5,3.5),
        cex = c(1.2,1,1),
        font = c(2,1,1),
        col = "grey10"
        
      )  
      
    } else if (axes == "rate.by.sum"){
      
      default_scatter_mtext_args <- list(
        side = c(3, 1, 2),
        text = c("Win rate vs sum", "Sum of funds requested", "Fraction of funds requested won"),
        line = c(1.25,3.5,3.5),
        cex = c(1.2,1,1),
        font = c(2,1,1),
        col = "grey10"
      )
      
    } 
    
  } else {
    
    default_scatter_mtext_args <- list(
      side = c(3, 1, 2),
      text = c("Enter title", "Enter x-label", "Enter y-label"),
      line = c(1.25,3.5,3.5),
      cex = c(1.2,1,1),
      font = c(2,1,1),
      col = "grey10"
    )
    
    
  }
  
  
  
  ###############
  ## DRAW PLOT ##
  ###############
  
  # draw an empty plot
  plot(plotMatrix,
       type = "n",
       bty = "n",
       xaxt = "n",
       yaxt = "n",
       xlab = "",
       ylab = "")
  
  # Rectangle (plot color) (Establish after plot is drawn)
  
  default_rect_args <- list(
    xleft = par("usr")[1], 
    ybottom = par("usr")[3], 
    xright = par("usr")[2], 
    ytop = par("usr")[4],
    col = "gray95", 
    border = NA
  )
  
  rect_args <- modifyList(default_rect_args, rect_args)
  
  # Grid (Establish after the plot is drawn)
  
  default_grid_args <- list(col = "gray100", lwd = 2, lty = "dotted")
  grid_args <- modifyList(default_grid_args, grid_args)
  
  
  # Draw rectangle and grid
  do.call("rect", rect_args)
  do.call("grid", grid_args)
  
  # Modify the default scatter arguments
  scatter_args <- modifyList(default_scatter, scatter_args)
  
  par(new = TRUE) # In order not to call a new plot in the next argument
  
  # Draw the plot
  do.call("plot", c(list(plotMatrix),
                    scatter_args))
  
  
  #####################
  ## WRITE PLOT TEXT ##
  #####################
  
  scatter_text_args <- modifyList(default_scatter_text_args, scatter_text_args)
  
  do.call("text", c(list(plotMatrix), scatter_text_args))   
  
  
  
  #######################
  ## WRITE MARGIN TEXT ##
  #######################
  
  scatter_mtext_args <- modifyList(default_scatter_mtext_args, scatter_mtext_args)
  
  do.call("mtext", scatter_mtext_args)
  
  
}

listNames <- function(data, 
                      new = FALSE,
                      text_args = list(),
                      textSize = 0.1,
                      yPos = 0.617,
                      xPos = 0.2
){
  
  # This function is helper to list the college names per cluster 
  # next to a scatterplot from "plotWinRates".
  
  # See "Graphics Sandbox" that uses this to make a ppt slide.
  
  # where data is clusterMapping[clusterMapping[,"color"] == plotColors[3],]
  #   and plotColors is plotColors <- unique(clusterMapping[,"color"])
  
  incoming.par <- par(mar = c(0,0,0,0))
  on.exit(par(incoming.par))
  
  if(new){plot.new()}
  
  default_text_args <- list(x = rep(xPos, nrow(data)) ,
                            y = seq(from = yPos, by = -textSize, length.out = nrow(data)),
                            labels = data[,"abbrv"],
                            col = data[,"color"],
                            cex = 2,
                            xpd = TRUE
  )
  
  text_args <- modifyList(default_text_args, text_args)
  
  do.call("text", c(text_args))   
  
  
  
  #  boxX <- rep(0.2, nrow(data))
  #  textSize <- 0.1
  #  boxY <- seq(from = 0.8, by = -textSize, length.out = nrow(data))
  
  #  text(boxX, boxY, col = data[,"color"], labels = data[,"abbrv"] )
  
}

############
## TRENDS ##
############

# This enables me to extract any column from a list of "calculateWinRates", put it into a frame,
# cluster them, then plot them.

# Each function has maximum flexibility


extractColumn <- function(data, target, ...) {
  
  # where "data" is a list of results of calculateWinRates,
  # like "college_by_year"
  # I'll probably almost always want to use "drop = FALSE" when calling
  
  lapply(data, function(x){x[,target, ...]})
  
}

createFrame <- function(list, targetColumn = "year", ...){
  
  # accept a list output from extractColumn
  # where "targetColumn" is the row names from the list, often "year"
  
  # create a column based on the row names to use for merging
  
  
  updatedList <- lapply(list, function(x){
    
    x[,targetColumn] <- rownames(x)
    #rownames(x) <- NULL  # Remove row names
    return(x)
    
  })
  
  theFrame <- Reduce(function(x, y) merge(x, y, by = targetColumn, all = TRUE), updatedList)
  
  colnames(theFrame) <- c(targetColumn, names(list))
  
  return(theFrame)
  
  
}


extractTrendClusters <- function(data, k = 5, type = "slope", dist_params = list(), hclust_params = list()){
  # This accepts the output from "createFrame"
  # "type" is one of c("slope","all")
  # if type is "slope"--
  #    It calculates a linear model per column and extracts the slope
  #    Then it clusters the slopes
  #    It returns a frame with the column name, slope, and cluster assignment
  # if type is "all" --
  #    It calculates the cluster directly on the values
  #    It returns a frame with the column name and cluster assignment
    
  default_dist_params <- list(method = "euclidean")
  dist_params <- modifyList(default_dist_params, dist_params)
  
  
  default_hclust_params <- list(method = "ward")
  hclust_params <- modifyList(default_hclust_params, hclust_params)
  
  
  if(type == "slope") {
    
    # This creates clusters based on just the slopes  
    
    rowCount <- 1:nrow(data) # Typically the rows are years; linear model is against rows 
    
    theFrame <- apply(data[,-1], 2, function(x) { model <- lm(x ~ rowCount); return(coef(model)[2])   }  ) |>
      (\(x){
        
        theClust <- do.call(dist, c(list(x), dist_params)) |>
          (\(x){ do.call(hclust, list(x,hclust_params)) })() |>
          cutree(k=k)
        
        theFrame <- data.frame(slope = x, cluster = theClust)
        
        return(theFrame[order(theFrame$slope),])
        
      })()
    
    
  }
  
  if(type == "all") {
    
    theClust <- do.call(dist, list(t(data[,-1]), dist_params)) |> #dist(t(data[,-1])) |>
      (\(x){ do.call(hclust, list(x,hclust_params))   })() |>
      cutree(k=k)
    
    theFrame <- data.frame(cluster = theClust)
    
  }
  
  
  return(list(input = data, trendClusters = theFrame))
  
}

plotTrends <- function(incoming,
                       detailMapping,
                       plot_order = "cluster.number",
                       plot_params = list(),
                       legend_params = list(),
                       bottom_axis_params = list(),
                       right_axis_params = list(),
                       mtext_params = list(),
                       main_params = list()) {
  
  # extract list items
  
  data <- incoming[["input"]]
  trendClusters <- incoming[["trendClusters"]]
  
  
  # define plot layouts
  
  breaks <- c(0, 1, 2, 3, 4, 6, 9, 16, 25, Inf)
  
  mfrow_layouts <- list(
    c(1,1),  # 1 cluster
    c(2,1),  # 2
    c(3,1),  # 3
    c(2,2),  # 4
    c(3,2),  # 5 to 6 clusters
    c(3,3),  # 7 to 9 clusters
    c(4,4),  # 10 to 16 clusters
    c(5,5),  # 17 to 25 clusters
    NULL      # More than 25 clusters
  )
  
  
  # Find appropriate layout
  cluster_count <- max(trendClusters[,"cluster"])
  
  index <- findInterval(cluster_count, breaks, left.open = TRUE)
  
  if (index > length(mfrow_layouts) || is.null(mfrow_layouts[[index]])) {
    return("Reduce the number of clusters")
  }
  
  # Define default plotting parameters
  default_params <- list(mfrow = mfrow_layouts[[index]], mar = c(0,5,0,0))
  
  plot_params <- modifyList(default_params, plot_params)
  incoming.par <- do.call(par, plot_params)
  on.exit(par(incoming.par))
  
  # determine ranges
  xRange <- c(1,nrow(data))
  yRange <- range(data[,-1], na.rm=TRUE)
  
  # establish y range and right axis ticks and labels if it is rates that vary between 0 and 1
  
  rightTicks <- seq(from = 0.2*(max(yRange) - min(yRange))+min(yRange), to = 0.8*(max(yRange) - min(yRange))+min(yRange), by =0.2*(max(yRange) - min(yRange)))
  
  
  if(min(yRange) >= 0 & max(yRange) <= 1) {    
    rightLabels <- paste0(round(rightTicks*100,0) ,"%")
    
  } else rightLabels <- round(rightTicks,0)
  
  
  # create the individual plots
  
  if(plot_order == "slope.increasing" ) { 
    
    plotOrder <- aggregate(slope ~ cluster, data = trendClusters, mean, na.rm = TRUE) |>
      (\(x){ order(x[,"slope"]) })() |>
      (\(x){  
        match(unique(trendClusters[,"cluster"]), x)
      })()
    
    #  aggregate(slope ~ cluster, data = trendClusters, mean, na.rm = TRUE) |>
    #    (\(x){ x[order(x[,"slope"]) ,"cluster"]  })()
    
    
  } else {
    
    plotOrder <- order(unique(trendClusters[,"cluster"]))
    
  }
  
  
  invisible(
    lapply(unique(trendClusters[,"cluster"])[plotOrder], function(y) {
      
      # write a new plot
      
      plot(1,
           type ="n",
           xlim= xRange,  #c(1,10), #range(as.numeric(rownames(medianWins[["Arch"]]))),
           ylim = yRange, #c(0, 1),
           xaxt = "n",
           yaxt = "n",
           ylab = "",
           xlab = "",
           las =2)
      
      # draw the lines
      
      invisible(
        lapply(colnames(data)[colnames(data) %in% row.names(trendClusters)[trendClusters[,"cluster"] == y]],
               
               function(x){
                 
                 points(data[,x],
                        type = "l",
                        col = detailMapping[detailMapping[,"abbrv"] == x,"color"])
                 
                 
               })
        
      )
      
      # Add the legend
      
      filter <- detailMapping[,"abbrv"] %in% row.names(trendClusters)[trendClusters[,"cluster"] == y]
      default_legend_params <- list(x = "topleft",
                                    inset = c(-0.35,0),
                                    legend = detailMapping[filter, "abbrv"],
                                    text.col = detailMapping[filter,"color"],
                                    cex = 2,
                                    xpd = TRUE,
                                    bty = "n"
      )
      
      legend_params <- modifyList(default_legend_params, legend_params)
      do.call(legend, legend_params)
      
      # Add bottom tick marks
      tickLabels <- data[,1]
      tickLabels[c(2:3,5:6,8:9)] <- NA
      default_bottom_axis_params <- list(
        side = 1,
        at = 1:nrow(data),
        labels = tickLabels, #data[,1],
        las = 2
      )
      
      default_mtext_params <- list(
        text = paste0("Cluster ", y),
        side = 3,
        line = -2,
        font = 2
      )
      
      
      
      mtext_params <- modifyList(default_mtext_params, mtext_params)
      do.call(mtext, mtext_params)
      
      
      if(y %% 2 == 0) {
        bottom_axis_params <- modifyList(default_bottom_axis_params, bottom_axis_params)
        do.call(axis, bottom_axis_params)
      }
      
      
      default_right_axis_params <- list(
        side = 4,
        at = rightTicks,
        labels = rightLabels,
        las = 1
      )
      
      if(y %% 2 == 1) {
        right_axis_params <- modifyList(default_right_axis_params, right_axis_params)
        do.call(axis, right_axis_params)
      }
      
      # axis(side = 4, at = seq(from = 0.2, to = 0.8, by =0.2))
      
    })
    
    
    
    
    
  )
  
  
  default_main_params <- list(
    text = "Big Title",
    line = 0.617,
    side = 3,
    cex = 2,
    font = 2,
    outer = TRUE
  )
  
  main_params <- modifyList(default_main_params, main_params)
  
  do.call(mtext, main_params)
  
}


drawProposalsGuide <- function(type = "amount",
                               plot_params = list(),
                               legend1_params = list(),
                               legend2_params = list(),
                               legend3_params = list(),
                               legend4_params = list(),
                               mtext_params = list(),
                               title_params = list(),
                               axis1_params = list(),
                               axis2_params = list(),
                               axis4_params = list()
){
  
  # This highly flexible function is meant to replace
  # the legends and labels for my "plotWinRate" graphics
  # as they are already too crowded.
  # Type is one of "amount" or c("year", "trend")
  
  
  # capture and restore incoming graphical parameters
  
  default_plot_params <- list(
    oma = c(1,1,1,1),
    mar = c(3,4,3,4)
  )
  
  plot_params <- modifyList(default_plot_params, plot_params)
  
  incoming.par <- do.call(par, plot_params)
  on.exit(par(incoming.par))
  
  plot(1,
       type ="n",
       xlim= c(0,1),
       ylim = c(0, 1),
       xaxt = "n",
       yaxt = "n",
       ylab = "",
       xlab = "",
       las =2)
  
  default_legend1_params <- list(
    x = 0,
    y = 0.8,
    bty = "n",
    title = "Count of\nproposals",
    legend = c("win","loss"),
    pch = 15,
    cex = 2,
    pt.cex = 4,
    col = c("orange",adjustcolor("steelblue", alpha.f = 0.5) )
  )
  
  legend1_params <- modifyList(default_legend1_params, legend1_params)
  do.call(legend, legend1_params)
  
  
  default_legend2_params <- list(
    x = 0.24,
    y = 0.7,
    bty = "n",
    title = "Win rate\n(count)",
    legend = "",
    pch = 5,
    lwd = 4,
    cex = 1.8,
    pt.cex = 4,
    col = "darkorange4"
    
  )
  
  legend2_params <- modifyList(default_legend2_params, legend2_params)
  do.call(legend, legend2_params)
  
  default_legend3_params <- list(
    x = 0.5,
    y = 0.8,
    bty = "n",
    title = "Sum of\nfunds requested",
    legend = c("win","loss"),
    pch = 15,
    cex = 2,
    pt.cex = 4,
    col = c("darkorange", adjustcolor("steelblue", alpha.f = 0.75) )
  )
  
  legend3_params <- modifyList(default_legend3_params, legend3_params)
  do.call(legend, legend3_params)
  
  default_legend4_params <- list(
    x = 0.85,
    y = 0.7,
    bty = "n",
    title = "Win rate\n(sum)",
    legend = "",
    pch = 5,
    lwd = 4,
    cex = 1.8,
    pt.cex = 4,
    col = "firebrick"
  )
  
  legend4_params <- modifyList(default_legend4_params, legend4_params)
  do.call(legend, legend4_params)
  
  if(type %in% c("amount")) {
    
    default_title_params <- list(
      side = c(3,3),
      text = c("Guide for","Win rates by Amounts Requested"),
      line = c(2.1, 0.4),
      cex = c(1.5, 2),
      font = c(2,2)
    )
    
    default_mtext_params <- list(
      side =  c(1,2,4),
      text = c("Natural log of amount requested per proposal",
               "Count of proposals\nor\nSum of funds requested",
               "Win rate\nby count or sum"
      ),
      line = c(2, 1.2, 2.5),
      cex = c(1.2,1.2,1.2)
    )
    
  }
  
  if(type %in% c("year","trend")) {
    
    default_title_params <- list(
      side = c(3,3),
      text = c("Guide for","Win rates by Fiscal Year"),
      line = c(2.1, 0.4),
      cex = c(1.5, 2),
      font = c(2,2)
    )
    
    default_mtext_params <- list(
      side =  c(1,2,4),
      text = c("Fiscal Year",
               "Count of proposals\nor\nSum of funds requested",
               "Win rate\nby count or sum"
      ),
      line = c(2, 1.2, 2.5),
      cex = c(1.2,1.2,1.2)
    )
    
  }
  
  
  title_params <- modifyList(default_title_params, title_params)
  do.call(mtext, title_params)
  
  mtext_params <- modifyList(default_mtext_params, mtext_params)
  do.call(mtext, mtext_params)
  
  default_axis1_params <- list(
    side = 1,
    at = seq(from=0, to = 1, by = 0.1),
    labels = FALSE,
    tick = TRUE
  )
  
  default_axis2_params <- list(
    side = 2,
    at = seq(from=0, to = 1, by = 0.1),
    labels = FALSE,
    tick = TRUE
  )
  
  default_axis4_params <- list(
    side = 4,
    at = seq(from=0, to = 1, by = 0.1),
    labels = FALSE,
    tick = TRUE
  )
  
  
  axis1_params <- modifyList(default_axis1_params, axis1_params)
  do.call(axis, axis1_params)
  
  axis2_params <- modifyList(default_axis2_params, axis2_params)
  do.call(axis, axis2_params)
  
  axis4_params <- modifyList(default_axis4_params, axis4_params)
  do.call(axis, axis4_params)
  
  
  
}
