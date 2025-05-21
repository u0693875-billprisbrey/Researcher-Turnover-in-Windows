# plotMetrics
# muliple lines sandbox
# 5.19.2025



# The idea here is to plot multiple lines on my plotMetrics base function.
# Either I modify this function, or I create a new function.

# For things like "head count" or "delta count" I need an option to scale it 
# "Rates" are already scaled

# it will need to accept the color mapping

# it will need a legend

# Because it is a complex graphic,  I won't be using the three vertical graphs
# scaled per golden ratio format.

# It will accept a list (I guess)

# maybe it will use plotMetrics internally?

#ok, this is working great
# I need to do "delta"
# and have default colors if featureMap (colorMap?) is NA
# I need legends, then delta
# and I hate that I lost my beautiful color scheme for just one


plotMetrics <- function(data,
                        plotList = "all",
                        featureMap = NA,
                        cumulative_plot_params = list(),
                        cumulative_points_params = list(),
                        cumulative_legend_params = list(),
                        cumulative_mtext_params = list(),
                        cumulative_rect_args = list(),
                        cumulative_grid_args = list(),
                        delta_plot_params = list(),
                        delta_points_params = list(),
                        delta_mtext_params = list(),
                        delta_upper_rect_args = list(),
                        delta_lower_rect_args = list(),
                        delta_grid_args = list(),
                        delta_legend_params = list(),
                        metric_plot_params = list(),
                        hire_points_params = list(),
                        term_points_params = list(),
                        metric_legend_params = list(),
                        metric2_legend_params = list(),
                        metric_mtext_params = list(),
                        metric_rect_args = list(),
                        metric_grid_args = list(),
                        title_mtext_params = list()
){
  
  # This accepts the output of "deltaHeadCount" or "calculateMetrics" 
  # and creates several graphics of different metrics over time.
  
  # NOTES FOR USING:
  # If I don't want to show both hire and term rate lines, then I can set the argument "type='n'"
  #  in the appropriate params list (but it would still show up in the legend.  Hmm.)
  
  # If you don't want to show the headcount or cumulative graphic, you may need to
  # set oma = c(0,0,2,0) in metric_plot_params or delta_plot_params to provide space
  # for the title.
  
  # Values for plotList are c("all", "headcount", "cumulative", "rate", "count", "delta.count", "delta.rate")
  
  # POSSIBLE ADJUSTMENTS:
  # Only the "delta" plot has an x-axis.
  #  The other two plots could have an adjustment to create an x-axis. # FIXED
  # Only the "cumulative" (or "headcount") plot has a color legend for multiple lines.
  #  The other two plots could have an adjustment to create a legend.
  # I could explicitly label points like starting date and concluding headcount values 
  #    with text on the graphic
  
  
  ###############################
  ## MANAGE INCOMING ARGUMENTS ##
  ###############################
  
  if(is.data.frame(data)) {data <- list(data)}
  
  if("all" %in% plotList){ plotList <- c("cumulative", "rate", "delta.rate")  }
  
  if(all(c("rate","count") %in% plotList )) { 
    stop("Select 'rate' or 'count' in plotList argument.")
  }
  
  if(all(c("delta.rate","delta.count") %in% plotList )) { 
    stop("Select 'delta.rate' or 'delta.count' in plotList argument.")
  }
  
  ############
  ## LAYOUT ##
  ############
  
  if(any(grepl("rate", tolower(colnames(data[[1]])))) # has the necessary columns
     & (
       any(c("headcount", "cumulative") %in% plotList) &&
       any(c("rate", "count") %in% plotList) &&
       any(c("delta",  "delta.rate", "delta.count") %in% plotList)
     )
  ) {
    
    layout(matrix(1:3, nrow = 3), heights = c(0.456, 0.281, 0.263))
    
  } else {
    
    layout(matrix(1:2, nrow = 2), heights = c(0.618, 0.382))
    
  }

  
  #####################
  ## CUMULATIVE PLOT ##
  #####################
  
  if( any(c("cumulative", "headcount") %in% plotList)  ){
    
    
    if(any(c("rate", "count", "delta.rate","delta.count") %in% plotList)){ # include the x axis if there's no metrics or delta plot
      
      xAxt <- "n"
      default_cumulative_plot_params <- list(
                                         oma = c(0,0,2,0),
                                         mar = c(0,6,0,1),
                                         bg = "ivory",
                                         fg = "grey30")
      
    } else { 
      
      xAxt <- "s" 
      default_cumulative_plot_params <- list(
                                         oma = c(0,0,2,0),
                                         mar = c(4,6,0,1),
                                         bg = "ivory",
                                         fg = "grey30")
    } 
    
  cumulative_plot_params <- modifyList(default_cumulative_plot_params,
                                       cumulative_plot_params)
  
  incoming.par <- do.call(par, cumulative_plot_params)
  on.exit(par(incoming.par))
  
    # set yLim
    yLim <- range(sapply(data, function(x){range(x[,"delta.cum"])}))
    
    plot(y = data[[1]][,"delta.cum"],
         x = data[[1]][,"periodEnd"],
         ylim = yLim,
         type = "n",
         xlab = "",
         xaxt = xAxt, #"n",
         las = 1,
         ylab = ""
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
    
    # experimenting with the grid
    grid_y <- axTicks(2)
    grid_x <- pretty(data[[1]][,"periodEnd"], n = 5)
    
    do.call(abline, c(list(h=grid_y), cumulative_grid_args))
    do.call(abline, c(list(v=grid_x), cumulative_grid_args))
    
    # draw the lines using Map
    invisible(Map(function(df, col) {
      do.call(points, modifyList(
        list(
          y = df[,"delta.cum"],
          x = df[,"periodEnd"],
          type = "l",
          col = ifelse(length(data) == 1, "sienna",col)
        ),
        cumulative_points_params
      ))
    }, data, featureMap[names(data)]))
    
    # margin text
    
    if(any(grepl("rate", tolower(colnames(data[[1]]))))){ 
      
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
    
    # legend
    
    default_cumulative_legend_params <- list(
      x = "topleft",
      legend = names(data),
      col = featureMap[names(data)],
      pch = 15, 
      pt.cex = 2
    )
    
    cumulative_legend_params <- modifyList(default_cumulative_legend_params, cumulative_legend_params)
    
    if(length(data) >1 ) {
      do.call(legend, cumulative_legend_params)
    }
    
    
  }
  
  
  
  ##################
  ## METRICS PLOT ##
  ##################
  
  if(any(grepl("rate", tolower(colnames(data[[1]])))) &
     any(c("rate", "count") %in% plotList)
  ) {
    
    if("rate" %in% plotList && !("count" %in% plotList) ) {
      
      hireVal <- 100*data[[1]][,"hireRate"]
      termVal <- 100*data[[1]][,"termRate"]
      
      
      yLim <- range(unlist(
        lapply(data, function(df) {
          apply(df[, c("hireRate", "termRate")], 1, range, na.rm = TRUE)
        })
      ), na.rm = TRUE) * 100
      
      y_label <- "rates (%)"
      legendText <- c("Hire", "Departure")
      
    }
    
    if("count" %in% plotList && !("rate" %in% plotList) ) {
      hireVal <- data[[1]][,"hireCount"]
      termVal <- data[[1]][,"termCount"] 
      
      yLim <- range(unlist(
        lapply(data, function(df) {
          apply(df[, c("hireCount", "termCount")], 1, range, na.rm = TRUE)
        })
      ), na.rm = TRUE)    
      
      y_label <- "count"
      legendText <- c("Hire", "Departure")
    }
    
    if(any(c("delta.rate","delta.count") %in% plotList)){ # include the x axis if there's no delta plot
      
      xAxt <- "n"
      default_metric_plot_params <- list(
                                        # oma = c(0,0,2,0),
                                         mar = c(0,6,0,1),
                                         bg = "ivory",
                                         fg = "grey30")
      
    } else { 
      
      xAxt <- "s" 
      default_metric_plot_params <- list(
                                        # oma = c(0,0,2,0),
                                         mar = c(4,6,0,1),
                                         bg = "ivory",
                                         fg = "grey30")
      } 
    
  
    
    metric_plot_params <- modifyList(default_metric_plot_params,
                                     metric_plot_params)
    
    do.call(par, metric_plot_params)
    
    # empty plot
    
    plot(y= hireVal, #100*data[,"hireRate"],
         x= data[[1]][,"periodEnd"],
         ylim = yLim,
         type = "n",
         xlab = "",
         xaxt = xAxt, # "n",
         # col = "seagreen3",
         las = 2,
         ylab = "" # "delta"
    )
    
    # Rectangle (plot color) (Establish after plot is drawn)
    
    default_metric_rect_args <- list(
      xleft = par("usr")[1], 
      ybottom = par("usr")[3], 
      xright = par("usr")[2], 
      ytop = par("usr")[4],
      col = "gray95", 
      border = NA
    )
    
    metric_rect_args <- modifyList(default_metric_rect_args, metric_rect_args)
    
    # Grid (Establish after the plot is drawn)
    
    default_metric_grid_args <- list(col = "gray100", lwd = 2, lty = "dotted")
    metric_grid_args <- modifyList(default_metric_grid_args, metric_grid_args)
    
    # Draw rectangle
    do.call("rect", metric_rect_args)
    
    # Draw the grid
    grid_y <- axTicks(2)
    grid_x <- pretty(data[[1]][,"periodEnd"], n = 5)
    
    do.call(abline, c(list(h=grid_y), metric_grid_args))
    do.call(abline, c(list(v=grid_x), metric_grid_args))
    
    # Draw the points  
    
    if("rate" %in% plotList && !("count" %in% plotList)  ) {
      
      # draw the hire points using Map
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = 100*df[,"hireRate"],
            x = df[,"periodEnd"],
            type = "l",
            lty =3,
            col = ifelse(length(data) == 1, "darkcyan",col)
          ),
          hire_points_params
        ))
      }, data, featureMap[names(data)]))  
      
      # draw the termination points using Map
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = 100*df[,"termRate"],
            x = df[,"periodEnd"],
            type = "l",
            col = ifelse(length(data) == 1, "coral",col)
          ),
          term_points_params
        ))
      }, data, featureMap[names(data)]))  
      
    }
    
    if("count" %in% plotList && !("rate" %in% plotList) ) {
      
      # draw the hire lines using Map
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = df[,"hireCount"],
            x = df[,"periodEnd"],
            type = "l",
            lty = 3,
            col = ifelse(length(data) == 1, "darkcyan",col)
          ),
          hire_points_params
        ))
      }, data, featureMap[names(data)]))
      
      # draw the termination lines using Map
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = df[,"termCount"],
            x = df[,"periodEnd"],
            type = "l",
            col = ifelse(length(data) == 1, "coral",col)
          ),
          term_points_params
        ))
      }, data, featureMap[names(data)]))
      
    }
    
    
    # Margin text
    
    default_metric_mtext_params <- list(side = 2,
                                        line = 4,
                                        text = y_label 
    )
    metric_mtext_params <- modifyList(default_metric_mtext_params, 
                                      metric_mtext_params)
    
    do.call(mtext, metric_mtext_params)
    
    # legend
    
    if (length(data) == 1) {
      default_metric_legend_params <- list(
        x = "topleft",
        legend = legendText, 
        col = c("darkcyan","coral"),
        lty = c(3,1),
        lwd = c(1.5,3)
      )
    } else {
      
      default_metric_legend_params <- list(
        x = "topleft",
        legend = legendText, 
        col = c("gray50","gray50"),
        lty = c(3,1),
        lwd = c(1.5,3)
      ) 
      
    }
    
    metric_legend_params <- modifyList(default_metric_legend_params, metric_legend_params)
    
    do.call(legend, metric_legend_params)
    
    
    # Display legend of colors per featuremap on the right
    
    if(!any(c("cumulative","headount") %in% plotList )) {
    
    default_metric2_legend_params <- list(
      x = "topright",
      legend = names(data),
      col = featureMap[names(data)],
      pch = 15, 
      pt.cex = 2
    )
    
    } else {
     
      default_metric2_legend_params <- list(
        x = "topright",
        legend = ifelse(length(data) == 1, "", names(data)), 
        col = ifelse(length(data) == 1, "seagreen",featureMap[names(data)]),
        pch = 15, 
        pt.cex = 2,
        plot = FALSE
      ) 
    }
    
    
    metric2_legend_params <- modifyList(default_metric2_legend_params, metric2_legend_params)
    
    #if(length(data) >1 ) {
      do.call(legend, metric2_legend_params)
    #}
    
  }
  
  
  ################
  ## DELTA PLOT ##
  ################
  
  # browser()
  
  if("delta.count" %in% plotList && !("delta.rate" %in% plotList) ) {
    yVal <- data[[1]][,"delta"]; 
    y_label <- "delta count"
    yLim <- range(sapply(data, function(x){range(x[,"delta"])}))
    
  }
  
  if("delta.rate" %in% plotList && !("delta.count" %in% plotList) ) {
    
    yVal <- 100*data[[1]][,"deltaRate"]; 
    y_label <- "delta (%)"
    yLim <- 100*range(sapply(data, function(x){range(x[,"deltaRate"])}))
    
  }
  
  if(any(c("delta.count","delta.rate") %in% plotList)) {
    
    default_delta_plot_params <- list(mar = c(4,6,0,1),
                                      #bg = "ivory",
                                      fg = "grey30")
    
    delta_plot_params <- modifyList(default_delta_plot_params,
                                    delta_plot_params)
    
    do.call(par, delta_plot_params)
    
    # Empty plot
    
    plot(y= yVal, 
         x= data[[1]][,"periodEnd"],
         type = "n",
         ylim = yLim,
         xlab = "",
         las = 2,
         ylab = "" 
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
    
    # Making grid work
    grid_y <- axTicks(2)
    grid_x <- pretty(data[[1]][,"periodEnd"], n = 5)
    
    do.call(abline, c(list(h=grid_y), delta_grid_args))
    do.call(abline, c(list(v=grid_x), delta_grid_args))
    
    
    # draw the delta lines using Map
    
    if("delta.count" %in% plotList && !("delta.rate" %in% plotList) ) {
      
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = df[,"delta"],
            x = df[,"periodEnd"],
            type = "l",
            col = ifelse(length(data) == 1, "seagreen",col)
          ),
          term_points_params
        ))
      }, data, featureMap[names(data)]))
      
    }
    
    
    if("delta.rate" %in% plotList && !("delta.count" %in% plotList) ) {
      
      invisible(Map(function(df, col) {
        do.call(points, modifyList(
          list(
            y = 100*df[,"deltaRate"],
            x = df[,"periodEnd"],
            type = "l",
            col = ifelse(length(data) == 1, "seagreen",col)
          ),
          delta_points_params
        ))
      }, data, featureMap[names(data)]))
      
    }
    
    # Margin text
    
    default_delta_mtext_params <- list(side = 2,
                                       line = 4,
                                       text = y_label
    )
    delta_mtext_params <- modifyList(default_delta_mtext_params, 
                                     delta_mtext_params)
    
    do.call(mtext, delta_mtext_params)
    
  }
  
  # As a a default display the legend on the right if 
  # not displaying in the other two graphics
  
  # I'm not sure I like how the legend handles
  # a single value when only the delta is being plotted.
  
  # I've got some confusing defaults set up.
  
  if(!any(c("cumulative","headount", "rate","count") %in% plotList )) {
    
    default_delta_legend_params <- list(
      x = "topright",
      legend = names(data),
      col = ifelse(length(data) == 1, "seagreen",featureMap[names(data)]),
      pch = 15, 
      pt.cex = 2
    )
    
  } else {
    
    default_delta_legend_params <- list(
      x = "topright",
      legend = ifelse(length(data) == 1, "",names(data)), 
      col = ifelse(length(data) == 1, "seagreen",featureMap[names(data)]),
      pch = 15, 
      pt.cex = 2,
      plot = FALSE
    )
    
  }

  delta_legend_params <- modifyList(default_delta_legend_params, delta_legend_params)

#  if(length(data) >1 ) {
    do.call(legend, delta_legend_params)
#  }  
  
  ################
  ## OUTER TEXT ##
  ################
  
  titleText <- "Head count metrics"
  
  default_title_mtext_params <- list(text = titleText, 
                                     side = 3,
                                     line = 0.3,
                                     font =2, 
                                     cex = 1.3, 
                                     outer = TRUE)
  
  
  title_mtext_params <- modifyList(default_title_mtext_params, title_mtext_params)
  
  do.call(mtext, title_mtext_params)
  
}

