# deltaHeadCount plot sandbox
# 5.8.2025

# I think I should re-name this "plotting turnover sandbox"

# before I even begin--
# I like having a main plot with the cumulative delta, and below it a sub-plot 
# that shows the period delta.
# I wish the period delta lines could change color as they cross zero.
# And I need the x-axis labels to be accurate.
# A question is -- do I need the x-axis labels to align if I'm using different 
# calendar periods?


# And I have two different functions to plot--
# One is the "delta", where the initial headcount is always zero.
# The other is the "caclulateTurnover", which should have the active
# headcount from the beginning.
# deltaHeadCount should align with calculateTurnover if I set it to 
# start with earliest retData date (currently "1958-09-01 UTC").

# I can plot several different periods in a stack (mfrow = c(5,1)).
# I can also plot several different periods as different-colored lines.

# But I think I will focus on plotting just delta, with a cumulative above
# and the period delta below.


# Playing around with my functions, plots, stuff like that.

source(here::here("Functions", "Turnover Functions.R"))

library(lubridate)

###########
## QUERY ##
###########

# Obtain retention data

keyring::keyring_unlock(keyring = "BIPR", password = "Excelsior!")

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), Driver = "oracle", Host = "ocm-campus01.it.utah.edu", 
                         SVC = keyring::key_list(keyring = "BIPR")[1, 1], UID = keyring::key_list(keyring = "BIPR")[1, 
                                                                                                                    2], PWD = keyring::key_get(keyring = "BIPR", service = keyring::key_list(keyring = "BIPR")[1, 
                                                                                                                                                                                                               1]), Port = 2080)
retentionQuery <- "
SELECT *
FROM VPR.D_PI_EMP_DT_VW EMP_DATES
"

retData <- dbGetQuery(con.ds,
                      retentionQuery)


DBI::dbDisconnect(con.ds)

###############
## FULL SPAN ##
###############

calendarPeriods <- c("day","week","month","quarter","year")

fullSpan <- lapply(calendarPeriods,
  function(x){
  
  deltaHeadCount(
  minDate = as.Date(min(retData$HIRE_DT, na.rm = TRUE)-1),
  maxDate = today(),
  calendar = x,
  data = retData
)
})
names(fullSpan) <- calendarPeriods

############################
## EARLY SPAN 2013<x<2020 ##
############################

earlySpan <- lapply(calendarPeriods,
                   function(x){
                     
                     deltaHeadCount(
                       minDate = ymd("2013-01-01"),
                       maxDate = ymd("2019-12-31"),
                       calendar = x,
                       data = retData
                     )
                   })
names(earlySpan) <- calendarPeriods

######################
## LATE SPAN >=2020 ##
######################

lateSpan <- lapply(calendarPeriods,
                    function(x){
                      
                      deltaHeadCount(
                        minDate = ymd("2020-01-01"),
                        maxDate = today(),
                        calendar = x,
                        data = retData
                      )
                    })
names(lateSpan) <- calendarPeriods

#################
## BRIEF SPAN  ##
#################

briefSpan <- lapply(calendarPeriods,
                    function(x){
                      
                      deltaHeadCount(
                        minDate = ymd("2023-07-01"),
                        maxDate = ymd("2024-10-31"),
                        calendar = x,
                        data = retData
                      )
                    })
names(briefSpan) <- calendarPeriods



################
## DELTA PLOT ##
################


deltaPlot <- function(data,
                      cumulative_plot_params = list(),
                      cumulative_points_params = list(),
                      cumulative_mtext_params = list(),
                      cumulative_rect_args = list(),
                      cumulative_grid_args = list(),
                      delta_plot_params = list(),
                      delta_points_params = list(),
                      delta_mtext_params = list(),
                      delta_upper_rect_args = list(),
                      delta_lower_rect_args = list(),
                      delta_grid_args = list(),
                      title_mtext_params = list()
                      ){
  
  # This accepts the output of "deltaHeadCount" and creates a nice little graphic
  
  # POSSIBLE ADJUSTMENTS:
  #  explicitly call out the starting date (and ending date and delta cum?)

  # ADJUSTMENTS DONE:
  #  shade the "delta" for above-and-below zero # DONE, looks great.
  #  add advanced details, like plot shading and the "list" flexibility # DONE
  #  the bottom margin is too big if the time frame is large and it shows years;
  #  it's just right if it's showing weeks # NOW MANUALLY ADJUSTABLE
    
  ############
  ## LAYOUT ##
  ############
  
  layout(matrix(1:2, nrow = 2), heights = c(0.618, 0.382))
  
  default_cumulative_plot_params <- list(oma = c(0,0,2,0),
                                         mar = c(0,4,0,1),
                                         bg="ivory",
                                         fg = "grey10")
  
  cumulative_plot_params <- modifyList(default_cumulative_plot_params,
                                       cumulative_plot_params)
  
  incoming.par <- do.call(par, cumulative_plot_params)
  on.exit(par(incoming.par))

  #####################
  ## CUMULATIVE PLOT ##
  #####################
  
  plot(y = data[,"delta.cum"],
       x = data[,"actionDate"],
       type = "n",
       xlab = "",
       xaxt = "n",
      # col = "sienna",
       las = 1,
       ylab = ""# "headcount\ncumulative"
       )
  
  # Rectangle (plot color) (Establish after plot is drawn)
  
  default_cumulative_rect_args <- list(
    xleft = par("usr")[1], 
    ybottom = par("usr")[3], 
    xright = par("usr")[2], 
    ytop = par("usr")[4],
    col = "gray95", 
    border = NA
  )
  
  cumulative_rect_args <- modifyList(default_cumulative_rect_args, cumulative_rect_args)
  
  # Grid (Establish after the plot is drawn)
  
  default_cumulative_grid_args <- list(col = "gray100", lwd = 2, lty = "dotted")
  cumulative_grid_args <- modifyList(default_cumulative_grid_args, cumulative_grid_args)
  
  # Draw rectangle and grid
  do.call("rect", cumulative_rect_args)
#  do.call("grid", cumulative_grid_args)
  
  # experimenting with the grid
  grid_y <- axTicks(2)
  grid_x <- pretty(data[,"actionDate"], n = 5)
  
  do.call(abline, c(list(h=grid_y), cumulative_grid_args))
  do.call(abline, c(list(v=grid_x), cumulative_grid_args))
  
  # Cumulative line
  default_cumulative_points_params <- list(
                                y = data[,"delta.cum"],
                                x = data[,"actionDate"],
                                type = "l",
                                col = "sienna"
                                )
  
  cumulative_points_params <- modifyList(default_cumulative_points_params, cumulative_points_params)
  
  do.call(points, cumulative_points_params)
  
  default_cumulative_mtext_params <- list(
                                  side = 2,
                                  line = 3,
                                  text = "cumulative")
  cumulative_mtext_params <- modifyList(default_cumulative_mtext_params, 
                                       cumulative_mtext_params)
  
  do.call(mtext, cumulative_mtext_params)
  
  ################
  ## DELTA PLOT ##
  ################

  default_delta_plot_params <- list(mar = c(4,4,0,1))
  
  delta_plot_params <- modifyList(default_delta_plot_params,
                                       delta_plot_params)
  
  do.call(par, delta_plot_params)
  
  
  plot(y= data[,"delta"],
       x= data[,"actionDate"],
       type = "n",
       xlab = "",
      # col = "seagreen3",
       las = 2,
       ylab = "" # "delta"
       )

  # Rectangle (plot color) (Establish after plot is drawn)
  
  default_delta_upper_rect_args <- list(
    xleft = par("usr")[1], 
    ybottom = 0, #par("usr")[3], 
    xright = par("usr")[2], 
    ytop = par("usr")[4],
    col = adjustcolor("palegreen3", alpha.f = 0.1), 
    border = NA
  )
  
  delta_upper_rect_args <- modifyList(default_delta_upper_rect_args, delta_upper_rect_args)
  
  default_delta_lower_rect_args <- list(
    xleft = par("usr")[1], 
    ybottom = par("usr")[3], 
    xright = par("usr")[2], 
    ytop = 0, #par("usr")[4],
    col = adjustcolor("pink", alpha.f = 0.5), 
    border = NA
  )
  
  delta_lower_rect_args <- modifyList(default_delta_lower_rect_args, delta_lower_rect_args)
  
  
  # Grid (Establish after the plot is drawn)
  
  default_delta_grid_args <- list(col = "lightgray", lwd = 1, lty = "dotted")
  delta_grid_args <- modifyList(default_delta_grid_args, delta_grid_args)
  
  # Draw rectangle and grid
  do.call("rect", delta_upper_rect_args)
  do.call("rect", delta_lower_rect_args)
  # do.call("grid", delta_grid_args)
  
  # experimenting with the grid
  grid_y <- axTicks(2)
  grid_x <- pretty(data[,"actionDate"], n = 5)
  
  do.call(abline, c(list(h=grid_y), delta_grid_args))
  do.call(abline, c(list(v=grid_x), delta_grid_args))
  
  # Draw the points  
  default_delta_points_params <- list(y= data[,"delta"],
                                      x= data[,"actionDate"],
                                      type = "l",
                                      col = "seagreen"
                                      )
  
  delta_points_params <- modifyList(default_delta_points_params, delta_points_params)
  
  do.call(points, delta_points_params)
  
  default_delta_mtext_params <- list(side = 2,
                                     line = 3,
                                     text = "delta"
                                     )
  delta_mtext_params <- modifyList(default_delta_mtext_params, 
                                        delta_mtext_params)
  
  do.call(mtext, delta_mtext_params)
  
  ################
  ## OUTER TEXT ##
  ################
  
  default_title_mtext_params <- list(text = "Delta Headcount", 
                                     side = 3,
                                     line = 0.3,
                                     font =2, 
                                     cex = 1.3, 
                                     outer = TRUE)
  
  title_mtext_params <- modifyList(default_title_mtext_params, title_mtext_params)
  
  do.call(mtext, title_mtext_params)
  
}







deltaHeadCount(
  minDate = ymd("2013-01-01"),
  maxDate = today(),
  calendar = "month",
  data = retData
) |>
  deltaPlot()
