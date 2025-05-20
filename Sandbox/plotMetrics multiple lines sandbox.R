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
  
  ###############################
  ## MANAGE INCOMING ARGUMENTS ##
  ###############################
  
  if(is.data.frame(data)) {data <- list(data)}
  
  if("all" %in% plotList){ plotList <- c("cumulative", "rate", "delta.count")  }
  
  if(all(c("rate","count") %in% plotList )) { 
    stop("Select 'rate' or 'count' in plotList argument.")
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
  
  if( any(c("cumulative", "headcount") %in% plotList)  ){
    
    # set yLim
    yLim <- range(sapply(data, function(x){range(x[,"delta.cum"])}))
    
    plot(y = data[[1]][,"delta.cum"],
         x = data[[1]][,"periodEnd"],
         ylim = yLim,
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
    
    # draw the lines using lapply
    # I need to use the color mapping here
    
#    invisible(lapply(data, function(theLines){
#      
#      # Cumulative line
#      default_cumulative_points_params <- list(
#        y = theLines[,"delta.cum"],
#        x = theLines[,"periodEnd"],
#        type = "l",
#        col = featureMap  #"red"
#      )
      

#      cumulative_points_params <- modifyList(default_cumulative_points_params, cumulative_points_params)
      
#      do.call(points, cumulative_points_params)
      
            
      
#    }
#    )
#    )
    
    # Cumulative line
#    default_cumulative_points_params <- list(
#      y = data[,"delta.cum"],
#      x = data[,"periodEnd"],
#      type = "l",
#      col = "sienna"
#    )
    
#    cumulative_points_params <- modifyList(default_cumulative_points_params, cumulative_points_params)
#    
#    do.call(points, cumulative_points_params)
    
    
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
      #col = ifelse(length(data) == 1, "sienna",featureMap[names(data)]),
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
      
      
#      yLim <- c(100*min(apply(data[[1]][,c("hireRate","termRate")],1,min, na.rm=TRUE)),
#                100*max(apply(data[[1]][,c("hireRate","termRate")],1,max, na.rm=TRUE))
#      )
      
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
      
#      yLim <- c(min(apply(data[[1]][,c("hireCount","termCount")],1,min, na.rm=TRUE)),
#                max(apply(data[[1]][,c("hireCount","termCount")],1,max, na.rm=TRUE))
#      )
      
      y_label <- "count"
      legendText <- c("Hire", "Departure")
    }
    
    default_rate_plot_params <- list(mar = c(0,6,0,1))
    
    rate_plot_params <- modifyList(default_rate_plot_params,
                                   rate_plot_params)
    
    do.call(par, rate_plot_params)
    
    # empty plot
    
    
    plot(y= hireVal, #100*data[,"hireRate"],
         x= data[[1]][,"periodEnd"],
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
    grid_x <- pretty(data[[1]][,"periodEnd"], n = 5)
    
    do.call(abline, c(list(h=grid_y), rate_grid_args))
    do.call(abline, c(list(v=grid_x), rate_grid_args))
    
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
      
      
    # Draw the hire points  
      
#    invisible(
#      lapply(data, function(hireLines){
#        
#        hireVal <- 100*hireLines[,"hireRate"]
#
#        default_hire_points_params <- list(y= hireVal, #100*data[,"hireRate"],
#                                           x= data[[1]][,"periodEnd"],
#                                           type = "l",
#                                           col = "darkcyan"
#        )        
#        
#        hire_points_params <- modifyList(default_hire_points_params, hire_points_params)
#        
#        do.call(points, hire_points_params)
#         
#      }
#      )
#    )
    
#    default_hire_points_params <- list(y= hireVal, #100*data[,"hireRate"],
#                                       x= data[,"periodEnd"],
#                                       type = "l",
#                                       col = "darkcyan"
#    )
    
#    hire_points_params <- modifyList(default_hire_points_params, hire_points_params)
    
#    do.call(points, hire_points_params)
    
    
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
    
    # Draw the termination points  
#    
#    invisible(
#      lapply(data, function(termLines){
#        
#        termVal <- 100*termLines[,"termRate"] 
#        
#        default_term_points_params <- list(y= termVal, # 100*data[,"termRate"],
#                                           x= data[[1]][,"periodEnd"],
#                                           type = "l",
#                                           col = "coral"
#        )
        
#        term_points_params <- modifyList(default_term_points_params, term_points_params)
#        
#        do.call(points, term_points_params)
        
#      }
#      )
#    )
    
#    default_term_points_params <- list(y= termVal, # 100*data[,"termRate"],
#                                       x= data[,"periodEnd"],
#                                       type = "l",
#                                       col = "coral"
#    )
    
#    term_points_params <- modifyList(default_term_points_params, term_points_params)
    
#    do.call(points, term_points_params)

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
      

      # Draw the hire points  
      
#      invisible(
#        lapply(data, function(hireLines){
#          
#          hireVal <- hireLines[,"hireCount"]
#          
#          default_hire_points_params <- list(y= hireVal, #100*data[,"hireRate"],
#                                             x= data[[1]][,"periodEnd"],
#                                             type = "l",
#                                             col = "darkcyan"
#          )        
          
#          hire_points_params <- modifyList(default_hire_points_params, hire_points_params)
#          
#          do.call(points, hire_points_params)
          
#        }
#        )
#      )
      
      #    default_hire_points_params <- list(y= hireVal, #100*data[,"hireRate"],
      #                                       x= data[,"periodEnd"],
      #                                       type = "l",
      #                                       col = "darkcyan"
      #    )
      
      #    hire_points_params <- modifyList(default_hire_points_params, hire_points_params)
      
      #    do.call(points, hire_points_params)
      
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
      
#      # Draw the termination points  
#      
#      invisible(
#        lapply(data, function(termLines){
#          
#          termVal <- termLines[,"termCount"] 
#          
#          default_term_points_params <- list(y= termVal, # 100*data[,"termRate"],
#                                             x= data[[1]][,"periodEnd"],
#                                             type = "l",
#                                             col = "coral"
#          )
#          
#          term_points_params <- modifyList(default_term_points_params, term_points_params)
#          
#          do.call(points, term_points_params)
#          
#        }
#        )
#      )
      
      #    default_term_points_params <- list(y= termVal, # 100*data[,"termRate"],
      #                                       x= data[,"periodEnd"],
      #                                       type = "l",
      #                                       col = "coral"
      #    )
      
      #    term_points_params <- modifyList(default_term_points_params, term_points_params)
      
      #    do.call(points, term_points_params)
      
    }
        
    
    # Margin text
    
    default_rate_mtext_params <- list(side = 2,
                                      line = 4,
                                      text = y_label #"rates (%)"
    )
    rate_mtext_params <- modifyList(default_rate_mtext_params, 
                                    rate_mtext_params)
    
    do.call(mtext, rate_mtext_params)
    
    # legend
    
    # several problems here
    # The legend says "rate" even if it's "count"
    # I've got labels, colors, and dashes mixed up 
    
    if (length(data) == 1) {
    default_rate_legend_params <- list(
      x = "topleft",
      legend = legendText, #c("Hire rate", "Departure rate"),
      col = c("darkcyan","coral"),
      lty = c(3,1),
      lwd = c(1.5,3)
    #  pch = 15, 
    #  pt.cex = 2
    )
    } else {
     
      default_rate_legend_params <- list(
        x = "topleft",
        legend = legendText, #c("Hire rate", "Departure rate"),
        col = c("gray50","gray50"),
        lty = c(3,1),
        lwd = c(1.5,3)
        #  pch = 15, 
        #  pt.cex = 2
      ) 
      
    }
    
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

