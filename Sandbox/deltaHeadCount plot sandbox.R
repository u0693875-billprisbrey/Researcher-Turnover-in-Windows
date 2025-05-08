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


deltaPlot <- function(data){
  
  # so far this is really pleasing.
  # Nice to have:
  #  shade the "delta" for above-and-below zero
  #  add advanced details, like plot shading and the "list" flexibility
  #  the bottom margin is too big if the time frame is large and it shows years;
  #  it's just right if it's showing weeks
  #  explicitly call out the starting date (and ending date and delta cum?)
  
  layout(matrix(1:2, nrow = 2), heights = c(0.618, 0.382))
  
  par(mar=c(0,4,3,1))
  plot(y = data[,"delta.cum"],
       x = data[,"actionDate"],
       type = "l",
       xlab = "",
       xaxt = "n",
       col = "sienna",
       las = 1,
       ylab = "headcount\ncumulative")
  
  par(mar=c(6,4,0,1))
  plot(y= data[,"delta"],
       x= data[,"actionDate"],
       type = "l",
       xlab = "",
       col = "seagreen3",
       las = 2,
       ylab = "delta")
  
}

plot(y=fullSpan[["day"]][,"delta.cum"],
     x = fullSpan[["day"]][,"actionDate"],
     type = "l",
     col = "sienna"
     )

plot(y=briefSpan[["day"]][,"delta"],
     x = briefSpan[["day"]][,"actionDate"],
     type = "l",
     col = "sienna"
)



deltaHeadCount(
  minDate = ymd("2013-01-01"),
  maxDate = today(),
  calendar = "month",
  data = retData
) |>
  deltaPlot()
