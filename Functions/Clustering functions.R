# Clustering functions
# 11.5.2024

# This is my repository of functions that deal with clustering,
# especially different visualizations.

##################
## SCATTERPLOTS ##
##################

plotClusterScatter <- function(whichClusters = "all",
                               clusterFrame,
                               clusterCol,
                               theData, 
                               type="amt", ...) {
  
  
  # Define plot layout
  oldPar <- par(mfrow = c(2, 2), mar = c(4,4,3,1)) # default is c(5.1,4.1,4.1,2.1)
  on.exit(par(oldPar))
  
  if("all" %in% whichClusters) {whichClusters <- unique(clusterFrame[,clusterCol]) }
  
  # Create a filter
  
  clusterPopulation <- row.names(clusterFrame)[clusterFrame[,clusterCol] %in% whichClusters]
  
  clusterFilter <- row.names(theData) %in% clusterPopulation
  
  # Identify the correct color scheme
  
  clusterColorName <- paste0(clusterCol,"_colr")
  
  
  # Merge the cluster set
  
  theData <- merge(theData, clusterFrame[,c(clusterCol, clusterColorName) , drop=FALSE], by = "row.names")
  
  # Define the prefixes for each comparison type
  comparisons <- c("total", "median", "min", "max")
  
  # Loop over each comparison type
  for (comp in comparisons) {
    # Define column names for win and loss
    
    
    
    if(type == "count"){
      win_col <- paste0("win.", "count.", comp)
      loss_col <- paste0("loss.", "count.", comp)
      
      #nonZero <- theData[[win_col]] > 0 & theData[[loss_col]] > 0
      #allFilter <- nonZero & clusterFilter
      
      # Define plot limits based on non-zero data
      xLim <- range((theData[[loss_col]]))
      yLim <- range((theData[[win_col]]))
      
      # Plot the data with filtered clusters and log-transformed values
      plot(y = (theData[[win_col]][clusterFilter]),
           x = (theData[[loss_col]][clusterFilter]),
           xlim = xLim,
           ylim = yLim,
           main = toupper(substring(comp, 1, 1)) %>% paste0(tolower(substring(comp, 2))),
           xlab = "Loss",
           ylab = "Win",
           col = theData[clusterFilter, clusterColorName],
           ...)
    }
    
    if(type == "amt"){
      win_col <- paste0(comp, ".win")
      loss_col <- paste0(comp, ".loss")
      
      # Ensure non-zero values for log transformation
      nonZero <- theData[[win_col]] > 0 & theData[[loss_col]] > 0
      allFilter <- nonZero & clusterFilter
      
      # Define plot limits based on non-zero data
      xLim <- range(log(theData[[loss_col]][nonZero]))
      yLim <- range(log(theData[[win_col]][nonZero]))
      
      # Plot the data with filtered clusters and log-transformed values
      plot(y = log(theData[[win_col]][allFilter]),
           x = log(theData[[loss_col]][allFilter]),
           xlim = xLim,
           ylim = yLim,
           main = toupper(substring(comp, 1, 1)) %>% paste0(tolower(substring(comp, 2))),
           xlab = "Loss",
           ylab = "Win",
           col = theData[allFilter, clusterColorName],
           ...)
    }
  }
}


##############
## BOXPLOTS ##
##############

plotClusterBox <- function(
    clusterFrame,
    clusterCol,
    whichClusters = 
      "all",
    theData,
    type = "amt",
    comparison = "total",
    log = TRUE,
    ...) {
  
  # where clusterFrame is the matrix output from "Developing clusters of principal investigators by submission history."
  # where clusterCol is which column you are using (as described in "Developing clusters")
  # where whichClusters are which clusters in that column you want to display, including "all"
  # where theData is  ??? what is it?
  # where "type" is one of either "count" or "amt" referring to either submission counts or budget amounts
  # where comparisons is one of c("total", "median", "min", "max") referring to the different columns
  
  # To do:
  #  Rather than plot 2x2, choose whether you want log or not
  #  Mess with margins #o.k.
  #  Mess with labels # DONE
  #  Mess with colors
  # This doesn't have an ability to share the count totals -- just the count totals by win/loss
  
  # Define plot layout
  oldPar <- par(mfrow = c(1, 2))
  on.exit(par(oldPar))
  
  if("all" %in% whichClusters) {whichClusters <- unique(clusterFrame[,clusterCol]) }
  
  # Create a filter
  
  clusterPopulation <- row.names(clusterFrame)[clusterFrame[,clusterCol] %in% whichClusters]
  
  clusterFilter <- row.names(theData) %in% clusterPopulation
  
  # Define colors
  
  clusterColorName <- paste0(clusterCol,"_colr")
  
  # Ensure cluster column is treated as a factor for grouping
  clusterFrame[,clusterCol] <- as.factor(clusterFrame[,clusterCol])
  
  # Extract unique colors for each group in the order of the levels
  clusterColors <- unique(clusterFrame[clusterFilter,clusterColorName][order(clusterFrame[clusterFilter,clusterCol])])
  
  
  # Merge the cluster set
  
  theData <- merge(theData, clusterFrame[,c(clusterCol,clusterColorName), drop=FALSE], by = "row.names")
  
  # Define column names for win and loss
  
  if(type == "count"){
    win_col <- paste0("win.", "count.", comparison)
    loss_col <- paste0("loss.", "count.", comparison)
  }
  
  if(type == "amt"){
    win_col <- paste0(comparison, ".win")
    loss_col <- paste0(comparison, ".loss")
  }
  
  # Define plot limits based on non-zero data
  xLim <- range((theData[[loss_col]]))
  yLim <- range((theData[[win_col]]))
  
  
  if(log == TRUE) {
    # Plot the data with filtered clusters and log-transformed values
    boxplot(log(get(win_col)) ~ get(clusterCol), #comboCluster, 
            data = theData[clusterFilter,], 
            horizontal = TRUE, 
            outline = FALSE,
            col = clusterColors, #theData[clusterFilter,clusterColorName],
            #yaxt = "n",
            ylab = "cluster",
            xlab = "log win",
            las = 1,
            ...)
    
    boxplot(log(get(loss_col)) ~ get(clusterCol), # comboCluster, 
            data = theData[clusterFilter,], 
            horizontal = TRUE, 
            outline = FALSE,
            col = clusterColors, 
            ylab = "cluster",
            xlab = "log loss",
            las = 1,
            ...
    )
    
    
  }
  
  if(log == FALSE){
    # Now show the boxplot on actual values
    
    boxplot(get(win_col) ~ get(clusterCol), #comboCluster, 
            data = theData[clusterFilter,], 
            horizontal = TRUE, 
            outline = FALSE,
            col = clusterColors,
            ylab = "cluster",
            xlab = "win",
            las = 1,
            ...)
    
    boxplot(get(loss_col) ~ get(clusterCol), #comboCluster, 
            data = theData[clusterFilter,], 
            horizontal = TRUE, 
            outline = FALSE,
            col = clusterColors, 
            ylab = "cluster",
            xlab = "loss",
            las = 1,
            ...
    )
  }
  
}



