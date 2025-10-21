# Brute Force Fit Plots Sandbox

# PURPOSE:  This develops functions that create visualizations to use with, or that modify, 
# the "plotJourney" function to display the force-fit.

# Several ideas here:
# (1) From the "Brute Force Sandbox", display a "brute force fit" graphic above,
#  and my regular "plot journey" below.

#  (2) Create a new function that plots just the brute force fit

#  (3) Enable the modification of a plotJourney with vertical red/green lines for the univers
# entries/exits

##########
## LOAD ##
##########

cj_diff <- readRDS(here::here("Data", "concurrentJourney_timeDiff.rds") )
univBound <- readRDS(here::here("Data", "Brute Force Fit Approximation for Concurrent Journey Employees.rds") )

source(here::here("Functions", "Turnover Functions.R"))
source(here::here("Functions", "Brute Force Functions.R"))

library(lubridate)

##########
## PREP ##
##########

startTime <- Sys.time()

# Extract unique EMPLIDs

emplids <- names(cj_diff) |>
  (\(x){
    gsub("\\.[[:digit:]]+$",
         "",
         x)
  })() |> 
  unique()

# Re-combine frames into one per EMPLID
cjEmplids <- lapply(emplids, function(emplid) {
  
  list_positions <- grep(emplid, names(cj_diff))
  
  full_frame <- do.call(rbind, cj_diff[list_positions])  
  
  return(full_frame)
  
}  )
names(cjEmplids) <- emplids

endTime <- Sys.time()

cat(rep(paste(round(endTime - startTime,2), "\n", sep = ""),3))


###################
## (1) TWO PLOTS ##
###################

# Calculate the force fit 

forceFit <- cjEmplids[["00810875"]] |>
  assignBoundaries() |>
  (\(x){deltaHeadCount(data = x,
                       minDate = min(x$EFFDT),
                       maxDate = max(x$EFFDT)
  )})()

forceFit$force <- pmax(0, pmin(1, forceFit$delta.cum))

# Plot the two journeys   

par(mfrow =c(2,1), mar = c(2.5,2,1,1) )

plot(y = forceFit[,"delta.cum"],
     x = forceFit[,"EFFDT"],
     type = "b",cex = 0.75, lty = 1, col = "brown")
lines(y = forceFit[,"force"], 
      x = forceFit[,"EFFDT"],
      type = "b", cex = 0.35, lty = 1, col = "skyblue")

abline( v = starts,
        lwd = 2,
        col = "green")

abline( v = stops,
        lwd = 2,
        col = "red")

cjEmplids[["00810875"]] |>
  assignBoundaries() |>
  plotJourney()

######################
## (2) OWN FUNCTION ##
######################

forceFitPlot <- function(data, fitLine = TRUE) {

  forceFit <- data |>
    assignBoundaries() |>
    (\(x){deltaHeadCount(data = x,
                         minDate = min(x$EFFDT),
                         maxDate = max(x$EFFDT)
    )})()
  
  forceFit$force <- pmax(0, pmin(1, forceFit$delta.cum))
  
  plot(y = forceFit[,"delta.cum"],
       x = forceFit[,"EFFDT"],
       type = "b",cex = 0.75, lty = 1, col = "brown")
  if(fitLine) {
  lines(y = forceFit[,"force"], 
        x = forceFit[,"EFFDT"],
        type = "b", cex = 0.35, lty = 1, col = "skyblue")
  }
}

cjEmplids[["00810875"]] |>
  forceFitPlot()

#######################
## (3) ADD VERTICALS ##
#######################

cjEmplids[["00810875"]] |>
  assignBoundaries() |>
  plotJourney()

plotFilter <- grepl("00810875", row.names(univBound))
abline(v = univBound$EFFDT[plotFilter & univBound$univ_boundary == "start"],
        lwd = 2,
       lty = "dotted",
        col = brewer.pal(3, "Dark2")[1] #   "green"
       )
abline(v = univBound$EFFDT[plotFilter & univBound$univ_boundary == "stop"],
       lwd = 2,
       lty = "solid",
       col = brewer.pal(3, "Dark2")[2] # "red"
       )

addVerticals <- function(data){
  
  # This adds vertical lines to the plot from "plotJourney" from the 
  # starts and stops of the university boundaries as determined by the 
  # brute force fit approximation
  
  # Call "plotJourney" first.
  
  # where data is from univBound, or the data frame with the brute force
  # starts and stops
  
  # This can be used to filter the data appropriately
  # plotFilter <- grepl("00810875", row.names(univBound))
  
  abline(v = data$EFFDT[data$univ_boundary == "start"],
         lwd = 2,
         lty = "dotted",
         col = brewer.pal(3, "Dark2")[1] #   "green"
  )
  abline(v = data$EFFDT[data$univ_boundary == "stop"],
         lwd = 2,
         lty = "solid",
         col = brewer.pal(3, "Dark2")[2] # "red"
  )
  
  
}


cjEmplids[["00810875"]] |>
  assignBoundaries() |>
  plotJourney()

addVerticals(univBound[grep("00810875", row.names(univBound)),])

#####################
## CHECKING OTHERS ##
#####################

par(mfrow =c(2,1), mar = c(2.5,2,1,1) )

cjEmplids[["00029655"]] |>
  forceFitPlot()

cjEmplids[["00029655"]] |>
assignBoundaries() |>
  plotJourney()

addVerticals(univBound[grep("00029655", row.names(univBound)),])

# This might becomes its own function, actually

plotJourney_univ <- function(){
  
  print("write me")
  
}

# To do:
#  - Write the key
#  - Add legends
#  - Add titles
#  - Create a report with a half-dozen examples
#  - 





