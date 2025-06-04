# Annual percentile sandbox
# 6.4.2024

# I.
# Can.
# Do.
# This.

# Given pi_annual_percentile as

pi_by_year <- lapply(pi_by_year, function(fyear){
  
  fyear[,"win.sum_prop"] <- proportions(fyear[,"win.sum"])
  fyear[,"win.sum_rank"] <- rank(-fyear[,"win.sum"], na.last = "keep", ties.method = "min")
  ecdf_fun <- ecdf(fyear[,"win.sum"])
  fyear[,"win.sum_percentile"] <- ecdf_fun(fyear[,"win.sum"])
  
  return(fyear)
  
}) 

# now I want to see the PI's that change percentiles from year to year

pi_annual_percentile <- extractColumn(pi_by_year, "win.sum_percentile", drop = FALSE) |>
  (\(x){ 
    suppressWarnings(createFrame(x)) })()
names(pi_annual_percentile)[names(pi_annual_percentile) %in% "year"] <- "emplid"

pi_annual_percentile$range <- apply(pi_annual_percentile[,-1], 1, function(x){diff(range(x, na.rm = TRUE))})        



plotAnnualPercentiles <- function(data, sequence = NA, lineColor = NA, rangeSpan = NA){
  
  # Create an empty plot
  
  plot(x= 1,
       type = "n",
       ylim = c(0.3,1),
       xlim = c(1,10),
       las = 1,
       ylab = "",
       xlab = "",
       xaxt = "n"
  )
  
  if(is.na(sequence[1])){
  theSequence <- seq(0,0.7, by = 0.05)
  } else {theSequence <- sequence}
  
  if(is.na(lineColor[1])){
  lineColor <- viridis::inferno(length(theSequence), direction = -1) 
  }
  
  if(is.na(rangeSpan)){
    rangeSpan <- 0.05 
  }
  
  # Plot the lines
  
  invisible(
    lapply(theSequence, function(range_value){ 
      
      filter <- data$range > range_value &  data$range <= range_value + rangeSpan
      
      invisible(
        lapply(data[filter,"emplid"], function(pi){
          
          points(as.numeric(data[data$emplid == pi,as.character(2014:2023)]),
                 type = "l",
                 lwd = 0.2,
                 col = lineColor[which(theSequence == range_value)]
          )
          
        })
      )
      
    })
  )
    
  # Axis and texts
  
  axis(side = 1, at = 1:10, labels = 2014:2023)
  mtext(side = 2, "percentile per PI", line = 3)
  mtext(side = 3, text = "Annual percentile per PI", font = 2, cex = 1.619, line = 2)
  
}


plot(x= 1,
     type = "n",
     ylim = c(0.3,1),
     xlim = c(1,10),
     las = 1,
     ylab = "",
     xlab = "",
     xaxt = "n"
)

theSequence <- seq(0,0.7, by = 0.05)

invisible(
  lapply(theSequence, function(range_value){ 
    
    filter <- pi_annual_percentile$range > range_value &  pi_annual_percentile$range <= range_value + 0.05
    
    invisible(
      lapply(pi_annual_percentile[filter,"emplid"], function(pi){
        
        points(as.numeric(pi_annual_percentile[pi_annual_percentile$emplid == pi,as.character(2014:2023)]),
               type = "l",
               lwd = 0.2,
               col = viridis::inferno(length(theSequence), direction = -1)[which(theSequence == range_value)]
        )
        
      })
    )
    
  })
)

axis(side = 1, at = 1:10, labels = 2014:2023)
mtext(side = 2, "percentile per PI", line = 3)
mtext(side = 3, text = "Annual percentile per PI", font = 2, cex = 1.619, line = 2)