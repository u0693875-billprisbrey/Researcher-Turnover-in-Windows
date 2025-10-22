# Plot journey key sandbox

# PURPOSE: The purpose of this script is to create a key for the symbols used in "plotJourney"
# that are provided in "assignBoundaries".

plotJourneyKey <- function(legendMap = NA) {
  
  incoming.par <- par(mar = c(0,0,3,0), oma = c(0,0,0,0)) # fig = c(0, 1, 0, 0.33), 
  on.exit(par(incoming.par))

  if(is.na(legendMap)) {
    
    legendMap <- list(color = data.frame(color = c("plum1",
                                                   "chocolate",
                                                   "steelblue",
                                                   "coral"
                                                #   "chocolate4",
                                                #   "mediumorchid1"
                                                   ),
                                         explanation = c(
                                           "not boundary",
                                           "primary",
                                           "break",
                                           "leave"
                                        #   "re-hire",
                                        #   "hire concurrent job"
                                         )),
                      shape = data.frame(shape = c(
                        1,
                        13,
                        19
                      ),
                      explanation = c(
                        "not boundary",
                        "entry",
                        "exit"
                      )
                      ),
                      size = data.frame(size = c(
                        0.75,
                        2,
                        1.5,
                        1.5
                      ),
                      explanation = c(
                        "not boundary",
                        "primary",
                        "break",
                        "leave"
                      )
                      
                      )
    )
    
  }
  
  # Create empty plot
  
  plot(x = 0.5,
       xlim = c(0,1),
       ylim = c(0,1),
       xlab = "",
       ylab = "",
       xaxt ="n",
       yaxt = "n",
       type = "n",
       bty = "n"
       )
  
colorLegend <- legend(title = "Colors",
    x =0, y =1,
         legend = legendMap[["color"]][["explanation"]], 
         col = legendMap[["color"]][["color"]],
         pt.cex = 2.5,
         pch = rep(15, nrow(legendMap[["color"]])),
         inset = c(0.1,0)
         )
  
shapeLegend <-  legend(title = "Shapes",
         # x =0.2, y =1,
         x = colorLegend$rect$left + colorLegend$rect$w + 0.02,  
         y = 1, # leg1$rect$top,
         legend = legendMap[["shape"]][["explanation"]], 
         pch = legendMap[["shape"]][["shape"]],
         pt.cex = 2.5,
         col = rep("grey30", nrow(legendMap[["shape"]]))
         )
  
sizeLegend <-  legend(title = "Sizes",
         # x =0.33, y =1,
         x = shapeLegend$rect$left + shapeLegend$rect$w + 0.02,  
         y = 1, 
         legend = legendMap[["size"]][["explanation"]], 
         pt.cex = legendMap[["size"]][["size"]],
         pch = 19,
         col = rep("grey30", nrow(legendMap[["shape"]])),
         inset = c(0.1,0)
  )

univLegend <- legend(title = "University boundaries",
       x = sizeLegend$rect$left + sizeLegend$rect$w + 0.02,
       y = 1,
       # x =0.5, y =1,
       legend = c("start", "stop"),
       lty = c("dotted","solid"),
       col = brewer.pal(3, "Dark2")[1:2],
       lwd = 3
)
  
  
  legend(title = "Special",
        #  x =0.66, y =1,
        x = univLegend$rect$left + univLegend$rect$w + 0.02,
        y=1,
         legend = c("Rehire", "Hire concurrent job"),
         pt.cex = c(2, 2),
         pch = c(10, 13),
         col = c("chocolate4", "mediumorchid1")
  )
  

  
mtext("Journey key",
      side = 3,
      line = 1.5,
      font = 2,
      cex = 1.5)  
  
}