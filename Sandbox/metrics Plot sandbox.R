# metrics Plot sandbox
# 5.14.2025

# This will modify deltaPlot to accept the output of calculateMetrics.
# I will call it "metricsPlot".

metricsPlot <- function(data,
                        plotList = "all",
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
                      rate_plot_params = list(),
                      hire_points_params = list(),
                      term_points_params = list(),
                      rate_legend_params = list(),
                      rate_mtext_params = list(),
                      rate_rect_args = list(),
                      rate_grid_args = list(),
                      title_mtext_params = list()
){
  
  # This accepts the output of "deltaHeadCount" or "calculateMetrics" 
  # and creates several graphics of different metrics over time.
  
  # NOTES FOR USING:
  # If I don't want to show both hire and term rate lines, then I can set the argument "type="n""
  #  in the appropriate params list (but it would still show up in the legend.  Hmm.)
  
  # Values for plotList are c("all", "headcount", "cumulative", "rate", "count", "delta", "delta.count", "delta.rate")
  
  # overall the default title doesn't describe the plot as well as I'd like
  
  
  # POSSIBLE ADJUSTMENTS:
  #  The biggest problem is that it has to have a delta plot, or there's no x-axis.
  #      Plots for cumulative/headcount and the rates have no x-axis, and no way to add them.
  #      Only the delta count or delta rate graphic has the x-axis.

  #  I could explicitly label things like starting date and concluding headcount values 
  #    with text on the graphic
  
  # NEXT STEPS:
  #  I'd like a plot that has multiple lines, for example per-cluster.
  #  Maybe as a different graphic using "plotly" to un-tangle the lines.  

  
  ############
  ## LAYOUT ##
  ############
  
  if(any(grepl("rate", tolower(colnames(data)))) # has the necessary columns
     & ("all" %in% plotList | # if all plots are being shown
        any(c("headcount", "cumulative") %in% plotList) &&
        all(c("rate", "delta") %in% plotList)
        )
     ) {
    
    layout(matrix(1:3, nrow = 3), heights = c(0.456, 0.281, 0.263))
    
  } else {
    
    layout(matrix(1:2, nrow = 2), heights = c(0.618, 0.382))
    
  }
  
  default_cumulative_plot_params <- list(oma = c(0,0,2,0),
                                         mar = c(0,6,0,1),
                                         bg="ivory",
                                         fg = "grey10")
  
  cumulative_plot_params <- modifyList(default_cumulative_plot_params,
                                       cumulative_plot_params)
  
  incoming.par <- do.call(par, cumulative_plot_params)
  on.exit(par(incoming.par))
  
  #####################
  ## CUMULATIVE PLOT ##
  #####################
  
  if( any(c("all", "cumulative", "headcount") %in% plotList)  ){
  
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
  
  if(any(grepl("rate", tolower(colnames(data))))){ 
    
    default_cumulative_mtext_params <- list(
      side = 2,
      line = 4,
      text = "head count")
    
  } else {
    
    default_cumulative_mtext_params <- list(
      side = 2,
      line = 4,
      text = "cumulative")
    
  }
  
  cumulative_mtext_params <- modifyList(default_cumulative_mtext_params, 
                                        cumulative_mtext_params)
  
  do.call(mtext, cumulative_mtext_params)
  
  }
  
  ##################
  ## METRICS PLOT ##
  ##################
  
  if(any(grepl("rate", tolower(colnames(data)))) &
     any(c("all", "rate", "count") %in% plotList)
     ) {
    
    if(any(c("rate","all") %in% plotList) ) {
      hireVal <- 100*data[,"hireRate"]
      termVal <- 100*data[,"termRate"]
      
      yLim <- c(100*min(apply(data[,c("hireRate","termRate")],1,min, na.rm=TRUE)),
                100*max(apply(data[,c("hireRate","termRate")],1,max, na.rm=TRUE))
      )
      
      y_label <- "rates (%)"
      
    }
    if("count" %in% plotList ) {
      hireVal <- data[,"hireCount"]
      termVal <- data[,"termCount"] 
      
      yLim <- c(min(apply(data[,c("hireCount","termCount")],1,min, na.rm=TRUE)),
                max(apply(data[,c("hireCount","termCount")],1,max, na.rm=TRUE))
      )
      
      y_label <- "count"
      
      }
    
    default_rate_plot_params <- list(mar = c(0,6,0,1))
    
    rate_plot_params <- modifyList(default_rate_plot_params,
                                       rate_plot_params)
    
    do.call(par, rate_plot_params)
    
    # empty plot

    
    plot(y= hireVal, #100*data[,"hireRate"],
         x= data[,"periodEnd"],
         ylim = yLim,
         type = "n",
         xlab = "",
         xaxt = "n",
         # col = "seagreen3",
         las = 2,
         ylab = "" # "delta"
    )
    
    # Rectangle (plot color) (Establish after plot is drawn)
    
    default_rate_rect_args <- list(
      xleft = par("usr")[1], 
      ybottom = par("usr")[3], 
      xright = par("usr")[2], 
      ytop = par("usr")[4],
      col = "gray95", 
      border = NA
    )
    
    rate_rect_args <- modifyList(default_rate_rect_args, rate_rect_args)
    
    # Grid (Establish after the plot is drawn)
    
    default_rate_grid_args <- list(col = "gray100", lwd = 2, lty = "dotted")
    rate_grid_args <- modifyList(default_rate_grid_args, rate_grid_args)
    
    # Draw rectangle
    do.call("rect", rate_rect_args)

    # Draw the grid
    grid_y <- axTicks(2)
    grid_x <- pretty(data[,"periodEnd"], n = 5)
    
    do.call(abline, c(list(h=grid_y), rate_grid_args))
    do.call(abline, c(list(v=grid_x), rate_grid_args))
    
    # Draw the hire points  
    default_hire_points_params <- list(y= hireVal, #100*data[,"hireRate"],
                                           x= data[,"periodEnd"],
                                           type = "l",
                                           col = "darkcyan"
    )
    
    hire_points_params <- modifyList(default_hire_points_params, hire_points_params)
    
    do.call(points, hire_points_params)
    
    # Draw the termination points  
    default_term_points_params <- list(y= termVal, # 100*data[,"termRate"],
                                       x= data[,"periodEnd"],
                                       type = "l",
                                       col = "coral"
    )
    
    term_points_params <- modifyList(default_term_points_params, term_points_params)
    
    do.call(points, term_points_params)
    
    
    # Margin text
    
    default_rate_mtext_params <- list(side = 2,
                                          line = 4,
                                          text = y_label #"rates (%)"
    )
    rate_mtext_params <- modifyList(default_rate_mtext_params, 
                                        rate_mtext_params)
    
    do.call(mtext, rate_mtext_params)
   
    # legend
    
    default_rate_legend_params <- list(
      x = "topleft",
      legend = c("Hire rate", "Departure rate"),
      col = c("darkcyan","coral"),
      pch = 15, 
        pt.cex = 2
    )
    
    rate_legend_params <- modifyList(default_rate_legend_params, rate_legend_params)
    
    do.call(legend, rate_legend_params)
    
     
  }
  
  
  ################
  ## DELTA PLOT ##
  ################
  
  if(any(c("delta.count","all") %in% plotList) ) {yVal <- data[,"delta"]; y_label <- "delta count" }
  if("delta.rate" %in% plotList ) {yVal <- 100*data[,"deltaRate"]; y_label <- "delta (%)" }

  if(any(c("all", "delta.count","delta.rate") %in% plotList)) {
    
  default_delta_plot_params <- list(mar = c(4,6,0,1))
  
  delta_plot_params <- modifyList(default_delta_plot_params,
                                  delta_plot_params)
  
  do.call(par, delta_plot_params)
  
  
  plot(y= yVal, #data[,"delta"],
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
  default_delta_points_params <- list(y= yVal, # data[,"delta"],
                                      x= data[,"periodEnd"],
                                      type = "l",
                                      col = "seagreen"
  )
  
  delta_points_params <- modifyList(default_delta_points_params, delta_points_params)
  
  do.call(points, delta_points_params)
  
  default_delta_mtext_params <- list(side = 2,
                                     line = 4,
                                     text = y_label #"delta"
  )
  delta_mtext_params <- modifyList(default_delta_mtext_params, 
                                   delta_mtext_params)
  
  do.call(mtext, delta_mtext_params)
  
  }
  
  
  ################
  ## OUTER TEXT ##
  ################
  
  if(any(grepl("rate", tolower(colnames(data)))) &
     any(c("all","headcount") %in% plotList )
     ) {
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