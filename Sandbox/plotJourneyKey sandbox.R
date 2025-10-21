# Plot journey key sandbox

# PURPOSE: The purpose of this script is to create a key for the symbols used in "plotJourney"
# that are provided in "assignBoundaries".

plotJourneyKey <- function(legendMap = NA) {
  
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
  
  legend(title = "Colors",
    "left",
         legend = legendMap[["color"]][["explanation"]], 
         col = legendMap[["color"]][["color"]],
         pt.cex = 2.5,
         pch = rep(15, nrow(legendMap[["color"]])),
         inset = c(0.1,0)
         )
  
  legend(title = "Shapes",
         "center",
         legend = legendMap[["shape"]][["explanation"]], 
         pch = legendMap[["shape"]][["shape"]],
         pt.cex = 2.5,
         col = rep("grey30", nrow(legendMap[["shape"]]))
         )
  
  legend(title = "Sizes",
         "right",
         legend = legendMap[["size"]][["explanation"]], 
         pt.cex = legendMap[["size"]][["size"]],
         pch = 19,
         col = rep("grey30", nrow(legendMap[["shape"]])),
         inset = c(0.1,0)
  )
  
  
  legend(title = "Special",
         "bottom",
         legend = c("Rehire", "Hire concurrent job"),
         pt.cex = c(2, 2),
         pch = c(10, 13),
         col = c("chocolate4", "mediumorchid1")
  )
  
  legend(title = "University boundaries",
         "bottomleft",
         legend = c("start", "stop"),
         lty = c("dotted","solid"),
         col = brewer.pal(3, "Dark2")[1:2],
         lwd = 3
         )
  
mtext("Journey key",
      side = 3,
      line = 1.5,
      font = 2,
      cex = 1.5)  
  
}