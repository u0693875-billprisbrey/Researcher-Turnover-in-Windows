# Percentile sandbox
# 4.23.2025

# ORIGINAL FROM IDENTIFYING LOW PERFORMERS FROM CLUSTERS

filter <- piEmplid$rate_cluster == 1 & piEmplid$complex_cluster == 5
plot(log(piEmplid[filter, "win.sum"]),
     piEmplid[filter, "sum.rate"],
     col = percentileMapping[filter,"color"],
     xlab = "",
     ylab = "",
     xaxt = "n",
     yaxt = "n",
     plot = FALSE
)


plotBreaks <-
  piEmplid$win.sum |>
  (\(x){split(x,
              cut(piEmplid$win.sum_percentile, breaks = c(0,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1), include.lowest=TRUE)
              
              # cut(piEmplid$win.sum_percentile, breaks = seq(0.2,1,by=0.1))
  )})() |>
  (\(x){ 
    sapply(x, max, na.rm=TRUE)
  })() |>
  log() |>
  (\(x){
    c(0,x)
  })()

invisible(
  lapply(1:(length(plotBreaks) - 1), function(i) {
    rect(plotBreaks[i], par("usr")[3], plotBreaks[i + 1], par("usr")[4], col = adjustcolor(percentileColors[i], alpha.f= 0.1 ) , border = NA)
  })
)

par(new=TRUE)
plot(log(piEmplid[filter, "win.sum"]),
     piEmplid[filter, "sum.rate"],
     col = percentileMapping[filter,"color"],
     xlab = "",
     ylab = "",
     las = 1,
)

legend("topleft",
       title = "Percentile ranges",
       col = percentileColors,
       #legend = names(plotBreaks[-1]),
       legend = paste0("<=",seq(from =0.3, to = 1, by = 0.1)),
       pch = 15,
       pt.cex = 3
)

mtext(text = c("Some PI's with a low win rate\nare in the top 20% of funds requested won",
               "Win rate",
               "Total funds requested won (log)"),
      side = c(3,2,1) ,
      font = c(2,1,1) ,
      line = c(0,3,4),
      cex = c(1.5,1,1)
)
