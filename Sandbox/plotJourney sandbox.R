# plotJourney sandbox
# 7.22.2025

# To do:

# Make ylim that works for no concurrent jobs
# Adjust the y-position jitter so that it is in a repeatable order top-to-bottom
#    Always put  boundary on the main line
# Create light-colored interval lines behind the action shapes
# Add a plot below with the interval lines



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