# plot Turnover sandbox
# 5.13.2025

# This will modify deltaPlot to accept the output of 
# calculateTurnover to plot the turnover.

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
                      turnover_plot_params = list(),
                      turnover_points_params = list(),
                      turnover_mtext_params = list(),
                      turnover_upper_rect_args = list(),
                      turnover_lower_rect_args = list(),
                      turnover_grid_args = list(),
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
  
  if("turnover" %in% colnames(data)) {
    
    layout(matrix(1:3, nrow = 3), heights = c(0.456, 0.281, 0.263))
      
  } else {
  
  layout(matrix(1:2, nrow = 2), heights = c(0.618, 0.382))
  
  }
    
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
       x = data[,"periodEnd"],
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
  grid_x <- pretty(data[,"periodEnd"], n = 5)
  
  do.call(abline, c(list(h=grid_y), cumulative_grid_args))
  do.call(abline, c(list(v=grid_x), cumulative_grid_args))
  
  # Cumulative line
  default_cumulative_points_params <- list(
    y = data[,"delta.cum"],
    x = data[,"periodEnd"],
    type = "l",
    col = "sienna"
  )
  
  cumulative_points_params <- modifyList(default_cumulative_points_params, cumulative_points_params)
  
  do.call(points, cumulative_points_params)
  
  if("turnover" %in% colnames(data)){ 

    default_cumulative_mtext_params <- list(
      side = 2,
      line = 3,
      text = "head count")
    
    } else {
  
  default_cumulative_mtext_params <- list(
    side = 2,
    line = 3,
    text = "cumulative")
  
    }
  
  cumulative_mtext_params <- modifyList(default_cumulative_mtext_params, 
                                        cumulative_mtext_params)
  
  do.call(mtext, cumulative_mtext_params)
  
  
  ###################
  ## TURNOVER PLOT ##
  ###################
  
  if("turnover" %in% colnames(data)) {
    
    default_turnover_plot_params <- list(mar = c(0,4,0,1))
    
    turnover_plot_params <- modifyList(default_turnover_plot_params,
                                       turnover_plot_params)
    
    do.call(par, turnover_plot_params)
    
    
    plot(y= 100*data[,"turnover"],
         x= data[,"periodEnd"],
         type = "n",
         xlab = "",
         xaxt = "n",
         # col = "seagreen3",
         las = 2,
         ylab = "" # "delta"
    )
    
    # Rectangle (plot color) (Establish after plot is drawn)
    
    default_turnover_upper_rect_args <- list(
      xleft = par("usr")[1], 
      ybottom = 0, #par("usr")[3], 
      xright = par("usr")[2], 
      ytop = par("usr")[4],
      col = adjustcolor("palegreen3", alpha.f = 0.1), 
      border = NA
    )
    
    turnover_upper_rect_args <- modifyList(default_turnover_upper_rect_args, turnover_upper_rect_args)
    
    default_turnover_lower_rect_args <- list(
      xleft = par("usr")[1], 
      ybottom = par("usr")[3], 
      xright = par("usr")[2], 
      ytop = 0, #par("usr")[4],
      col = adjustcolor("pink", alpha.f = 0.5), 
      border = NA
    )
    
    turnover_lower_rect_args <- modifyList(default_turnover_lower_rect_args, turnover_lower_rect_args)
    
    
    # Grid (Establish after the plot is drawn)
    
    default_turnover_grid_args <- list(col = "lightgray", lwd = 1, lty = "dotted")
    turnover_grid_args <- modifyList(default_turnover_grid_args, turnover_grid_args)
    
    # Draw rectangle and grid
    do.call("rect", turnover_upper_rect_args)
    do.call("rect", turnover_lower_rect_args)
    # do.call("grid", turnover_grid_args)
    
    # experimenting with the grid
    grid_y <- axTicks(2)
    grid_x <- pretty(data[,"periodEnd"], n = 5)
    
    do.call(abline, c(list(h=grid_y), turnover_grid_args))
    do.call(abline, c(list(v=grid_x), turnover_grid_args))
    
    # Draw the points  
    default_turnover_points_params <- list(y= 100*data[,"turnover"],
                                           x= data[,"periodEnd"],
                                           type = "l",
                                           col = "seagreen"
    )
    
    turnover_points_params <- modifyList(default_turnover_points_params, turnover_points_params)
    
    do.call(points, turnover_points_params)
    
    default_turnover_mtext_params <- list(side = 2,
                                          line = 3,
                                          text = "turnover (%)"
    )
    turnover_mtext_params <- modifyList(default_turnover_mtext_params, 
                                        turnover_mtext_params)
    
    do.call(mtext, turnover_mtext_params)
    
  }
  
  ################
  ## DELTA PLOT ##
  ################
  
  default_delta_plot_params <- list(mar = c(4,4,0,1))
  
  delta_plot_params <- modifyList(default_delta_plot_params,
                                  delta_plot_params)
  
  do.call(par, delta_plot_params)
  
  
  plot(y= data[,"delta"],
       x= data[,"periodEnd"],
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
  grid_x <- pretty(data[,"periodEnd"], n = 5)
  
  do.call(abline, c(list(h=grid_y), delta_grid_args))
  do.call(abline, c(list(v=grid_x), delta_grid_args))
  
  # Draw the points  
  default_delta_points_params <- list(y= data[,"delta"],
                                      x= data[,"periodEnd"],
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
  
  if("turnover" %in% colnames(data)) {
  default_title_mtext_params <- list(text = "PI Headcount", 
                                     side = 3,
                                     line = 0.3,
                                     font =2, 
                                     cex = 1.3, 
                                     outer = TRUE)
  } else {
    default_title_mtext_params <- list(text = "Delta PI Headcount", 
                                       side = 3,
                                       line = 0.3,
                                       font =2, 
                                       cex = 1.3, 
                                       outer = TRUE)
    
  }
  
  
  title_mtext_params <- modifyList(default_title_mtext_params, title_mtext_params)
  
  do.call(mtext, title_mtext_params)
  
}