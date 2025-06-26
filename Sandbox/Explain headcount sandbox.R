# Explain Headcount sandbox
# 6.25.2026

explainHeadCount <- function(breakColors = c("aliceblue", "steelblue"),
                             leaveColors = c("papayawhip", "coral"),
                             primaryColors = c("oldlace","chocolate"),
                             plot_params = list(),
                             plot_args = list(),
                             rect_args = list(),
                             rect_text_args = list(),
                             primary_entry_arrow1_args = list(),
                             primary_entry_arrow2_args = list(),
                             primary_entry_text_args = list(),
                             primary_entry_action_text_args = list(),
                             primary_exit_arrow1_args = list(),
                             primary_exit_arrow2_args = list(),
                             primary_exit_text_args = list(),
                             primary_exit_action_text_args = list(),
                             
                             break_entry_arrow1_args = list(),
                             break_entry_arrow2_args = list(),
                             break_text_args = list(),
                             break_entry_action_text_args = list(),
                             break_exit_arrow1_args = list(),
                             break_exit_arrow2_args = list(),
                             break_exit_action_text_args = list(),
                             
                             leave_entry_arrow1_args = list(),
                             leave_entry_arrow2_args = list(),
                             leave_text_args = list(),
                             leave_entry_action_text_args = list(),
                             leave_exit_arrow1_args = list(),
                             leave_exit_arrow2_args = list(),
                             leave_exit_action_text_args = list()
                             
                             
) {
  
  # color pairs:  c("aliceblue", "steelblue"), c("lavendarblush", "orchid"), 
  # c("mistyrose", "deeppink"), c("lemonchiffon","goldenrod"), c("mintcream","mediumseagreen"),
  # c("papayawhip", "coral"), c("honeydew", "forestgreen"), c("oldlace","chocolate"), c("seashell", "indianred")
  # c("lavender", "mediumorchid")
  
  # by plotting a value of "1", the plot space varies from 0.51 to 1.42
  
  # Default parameters
  
  default_plot_params <- list(oma = c(0,0,2,0),
                              mar = c(0,0,0,0),
                              bg="ivory",
                              fg = "grey10")
  
  plot_params <- modifyList(default_plot_params,
                            plot_params)
  
  incoming.par <- do.call(par, plot_params)
  on.exit(par(incoming.par))
  
  # Empty plot
  
  default_plot_args <- list(x =1,
                            type = "n",
                            xlab = "",
                            ylab = "",
                            xaxt = "n",
                            yaxt = "n",
                            bty = "n"
  )
  
  plot_args <- modifyList(default_plot_args, plot_args)
  do.call("plot", plot_args)
  
  # rectangle
  
  default_rect_args <- list(
    xleft = 0.8,
    ybottom = 0.51+0.22,
    xright = 1.2,
    ytop = 0.51+0.22+0.4,
    col = "mistyrose",
    border = "#BE0000"
  )
  
  rect_args <- modifyList(default_rect_args, rect_args)
  do.call("rect",rect_args)
  
  # rectangle text
  
  default_rect_text_args <- list(
    x = mean(c(rect_args$xleft, rect_args$xright)),
    y = mean(c(rect_args$ybottom, rect_args$ytop)),
    font = 2,
    cex = 3,
    label = "U\nHEADCOUNT",
    col = "#BE0000"
    
  )
  
  rect_text_args <- modifyList(default_rect_text_args, rect_text_args)
  do.call("text", rect_text_args)
  
  # Primary Entry arrows
  
  default_primary_entry_arrow1_args <- list(
    x0 = rect_args$xright*1.1,
    y0 = rect_args$ytop*0.95,
    x1 = rect_args$xright*1.01,
    y1 = rect_args$ytop*0.95,
    col = primaryColors[2],
    lty = 1,
    lwd = 20
  )
  
  primary_entry_arrow1_args <- modifyList(default_primary_entry_arrow1_args, primary_entry_arrow1_args)
  do.call("arrows", primary_entry_arrow1_args)
  
  default_primary_entry_arrow2_args <- list(
    x0 = rect_args$xright*1.1,
    y0 = rect_args$ytop*0.95,
    x1 = rect_args$xright*1.01,
    y1 = rect_args$ytop*0.95,
    col = primaryColors[1],
    lty = 1,
    lwd = 10
  )
  
  primary_entry_arrow2_args <- modifyList(default_primary_entry_arrow2_args, primary_entry_arrow2_args)
  do.call("arrows", primary_entry_arrow2_args)
  
  # Primary entry text  
  default_primary_entry_text_args <- list(
    x = rect_args$xright*1.035,
    y = rect_args$ytop*0.99,
    label = "PRIMARY",
    adj = c(0,0.5),
    col = primaryColors[2],
    font = 2
  )  
  
  primary_entry_text_args <- modifyList(default_primary_entry_text_args, primary_entry_text_args) 
  do.call("text",primary_entry_text_args)
  
  # Primary entry action texts
  
  default_primary_entry_action_text_args <- list(
    x = rect_args$xright*1.07,
    y = rect_args$ytop*0.9,
    label = "HIR\nREH",
    adj = c(0,0.5),
    col = primaryColors[2],
    font = 2
  )  
  
  primary_entry_action_text_args <- modifyList(default_primary_entry_action_text_args, primary_entry_action_text_args) 
  do.call("text",primary_entry_action_text_args)
  
  ####
  ####
  
  # Primary exit arrows
  
  default_primary_exit_arrow1_args <- list(
    x0 = rect_args$xleft*0.99,
    y0 = rect_args$ybottom*1.05,
    x1 = rect_args$xleft*0.99 - abs(primary_entry_arrow1_args$x0 - primary_entry_arrow1_args$x1),
    y1 = rect_args$ybottom*1.05,
    col = primaryColors[2],
    lty = 1,
    lwd = 20
  )
  
  primary_exit_arrow1_args <- modifyList(default_primary_exit_arrow1_args, primary_exit_arrow1_args)
  do.call("arrows", primary_exit_arrow1_args)
  
  default_primary_exit_arrow2_args <- list(
    x0 = rect_args$xleft*0.99,
    y0 = rect_args$ybottom*1.05,
    x1 = rect_args$xleft*0.99 - abs(primary_entry_arrow1_args$x0 - primary_entry_arrow1_args$x1),
    y1 = rect_args$ybottom*1.05,
    col = primaryColors[1],
    lty = 1,
    lwd = 10
  )
  
  primary_exit_arrow2_args <- modifyList(default_primary_exit_arrow2_args, primary_exit_arrow2_args)
  do.call("arrows", primary_exit_arrow2_args)
  
  # Primary exit text  
  default_primary_exit_text_args <- list(
    x = primary_exit_arrow1_args$x1+0.03,
    y = rect_args$ybottom*1.05+0.05,
    label = "PRIMARY",
    adj = c(0,1),
    col = primaryColors[2],
    font = 2
  )  
  
  primary_exit_text_args <- modifyList(default_primary_exit_text_args, primary_exit_text_args) 
  do.call("text",primary_exit_text_args)
  
  # Primary exit action texts
  
  default_primary_exit_action_text_args <- list(
    x = primary_exit_arrow1_args$x1+0.03, #rect_args$xleft,
    y = rect_args$ybottom,
    label = "TER\nRET\nRWP",
    adj = c(0,1),
    col = primaryColors[2],
    font = 2
  )  
  
  # Using the bottom left corner of the rectangle means it's unnaturally positioned against the arrow
  # but it works 
  # I think I'd rather put it below the letter "P" # DONE
  
  primary_exit_action_text_args <- modifyList(default_primary_exit_action_text_args, primary_exit_action_text_args) 
  do.call("text",primary_exit_action_text_args)
  
  ###
  ###
  
  # Break Entry Arrow
  
  default_break_entry_arrow1_args <- list(
    x0 = rect_args$xleft + 0.1,
    y0 = rect_args$ytop + 0.01,
    x1 = rect_args$xleft + 0.1,
    y1 = rect_args$ytop + 0.2,
    col = breakColors[2],
    lty = 1,
    lwd = 20,
    code = 1
  )
  
  break_entry_arrow1_args <- modifyList(default_break_entry_arrow1_args, break_entry_arrow1_args)
  do.call("arrows", break_entry_arrow1_args)
  
  default_break_entry_arrow2_args <- list(
    x0 = rect_args$xleft + 0.1,
    y0 = rect_args$ytop + 0.01,
    x1 = rect_args$xleft + 0.1,
    y1 = rect_args$ytop + 0.2,
    col = breakColors[1],
    lty = 1,
    lwd = 10,
    code = 1
  )
  
  break_entry_arrow2_args <- modifyList(default_break_entry_arrow2_args, break_entry_arrow2_args)
  do.call("arrows", break_entry_arrow2_args)
  
  # Break Exit Arrow
  
  default_break_exit_arrow1_args <- list(
    x0 = rect_args$xleft + 0.075,
    y0 = rect_args$ytop+0.01,
    x1 = rect_args$xleft + 0.075,
    y1 = rect_args$ytop + 0.2,
    col = breakColors[2],
    lty = 1,
    lwd = 20,
    code = 2
  )
  
  break_exit_arrow1_args <- modifyList(default_break_exit_arrow1_args, break_exit_arrow1_args)
  do.call("arrows", break_exit_arrow1_args)
  
  default_break_exit_arrow2_args <- list(
    x0 = rect_args$xleft + 0.075,
    y0 = rect_args$ytop+ 0.01,
    x1 = rect_args$xleft + 0.075,
    y1 = rect_args$ytop + 0.2,
    col = breakColors[1],
    lty = 1,
    lwd = 10,
    code = 2
  )
  
  break_exit_arrow2_args <- modifyList(default_break_exit_arrow2_args, break_exit_arrow2_args)
  do.call("arrows", break_exit_arrow2_args)
  
  # Break text
  
  default_break_text_args <- list(
    x = mean(c(rect_args$xleft + 0.1, rect_args$xleft + 0.075)),
    y = rect_args$ytop + 0.25,
    label = "BREAK",
    adj = c(0.5,0.5),
    col = breakColors[2],
    font = 2
  )
  
  break_text_args <- modifyList(default_break_text_args, break_text_args)
  do.call("text", break_text_args)
  
  # Break exit actions text
  default_break_exit_action_text_args <- list(
    x = break_exit_arrow1_args$x0 - 0.04,
    y = mean(c(break_exit_arrow1_args$y0, break_exit_arrow1_args$y1 )),
    label = "SWB",
    col = breakColors[2],
    font = 2
  )
  
  break_exit_action_text_args <- modifyList(default_break_exit_action_text_args, break_exit_action_text_args)
  do.call("text", break_exit_action_text_args)
  
  # Break entry actions text
  default_break_entry_action_text_args <- list(
    x = break_entry_arrow1_args$x0 + 0.04,
    y = mean(c(break_exit_arrow1_args$y0, break_exit_arrow1_args$y1 )),
    label = "RWB",
    col = breakColors[2],
    font = 2
  )
  
  break_entry_action_text_args <- modifyList(default_break_entry_action_text_args, break_entry_action_text_args)
  do.call("text", break_entry_action_text_args)
  
  ###
  ###
  
  # Leave Entry Arrow
  
  default_leave_entry_arrow1_args <- list(
    x0 = rect_args$xright - 0.075,
    y0 = rect_args$ytop + 0.01,
    x1 = rect_args$xright - 0.075,
    y1 = rect_args$ytop + 0.2,
    col = leaveColors[2],
    lty = 1,
    lwd = 20,
    code = 1
  )
  
  leave_entry_arrow1_args <- modifyList(default_leave_entry_arrow1_args, leave_entry_arrow1_args)
  do.call("arrows", leave_entry_arrow1_args)
  
  default_leave_entry_arrow2_args <- list(
    x0 = rect_args$xright - 0.075,
    y0 = rect_args$ytop + 0.01,
    x1 = rect_args$xright - 0.075,
    y1 = rect_args$ytop + 0.2,
    col = leaveColors[1],
    lty = 1,
    lwd = 10,
    code = 1
  )
  
  leave_entry_arrow2_args <- modifyList(default_leave_entry_arrow2_args, leave_entry_arrow2_args)
  do.call("arrows", leave_entry_arrow2_args)
  
  # Leave Exit Arrow
  
  default_leave_exit_arrow1_args <- list(
    x0 = rect_args$xright - 0.1,
    y0 = rect_args$ytop+0.01,
    x1 = rect_args$xright - 0.1,
    y1 = rect_args$ytop + 0.2,
    col = leaveColors[2],
    lty = 1,
    lwd = 20,
    code = 2
  )
  
  leave_exit_arrow1_args <- modifyList(default_leave_exit_arrow1_args, leave_exit_arrow1_args)
  do.call("arrows", leave_exit_arrow1_args)
  
  default_leave_exit_arrow2_args <- list(
    x0 = rect_args$xright - 0.1,
    y0 = rect_args$ytop+ 0.01,
    x1 = rect_args$xright - 0.1,
    y1 = rect_args$ytop + 0.2,
    col = leaveColors[1],
    lty = 1,
    lwd = 10,
    code = 2
  )
  
  leave_exit_arrow2_args <- modifyList(default_leave_exit_arrow2_args, leave_exit_arrow2_args)
  do.call("arrows", leave_exit_arrow2_args)
  
  # Leave text
  
  default_leave_text_args <- list(
    x = mean(c(rect_args$xright - 0.1, rect_args$xright - 0.075)),
    y = rect_args$ytop + 0.25,
    label = "LEAVE",
    adj = c(0.5,0.5),
    col = leaveColors[2],
    font = 2
  )
  
  leave_text_args <- modifyList(default_leave_text_args, leave_text_args)
  do.call("text", leave_text_args)
  
  # Break exit actions text
  default_leave_exit_action_text_args <- list(
    x = leave_exit_arrow1_args$x0 - 0.04,
    y = mean(c(leave_exit_arrow1_args$y0, leave_exit_arrow1_args$y1 )),
    label = "PLA\nLOA\nLTO",
    col = leaveColors[2],
    font = 2
  )
  
  leave_exit_action_text_args <- modifyList(default_leave_exit_action_text_args, leave_exit_action_text_args)
  do.call("text", leave_exit_action_text_args)
  
  # Break entry actions text
  default_leave_entry_action_text_args <- list(
    x = leave_entry_arrow1_args$x0 + 0.04,
    y = mean(c(leave_exit_arrow1_args$y0, leave_exit_arrow1_args$y1 )),
    label = "RFL",
    col = leaveColors[2],
    font = 2
  )
  
  leave_entry_action_text_args <- modifyList(default_leave_entry_action_text_args, leave_entry_action_text_args)
  do.call("text", leave_entry_action_text_args)
  
  
  
  # Title
  
  mtext("Actions affecting headcount", cex = 2, font = 2, line = 0.319, outer = TRUE)
  
  
}
