# calculateMetrics CHECK
# 5.14.2025

# This needs "retData" loaded.


bilbo <- calculateMetrics(data = retData)




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

fullSpan_m <- lapply(calendarPeriods,
                      function(x){
                        
                        calculateMetrics(
                          minDate = as.Date(min(retData$HIRE_DT, na.rm = TRUE))+365,
                          maxDate = today(),
                          calendar = x,
                          data = retData
                        )
                      })
names(fullSpan_m) <- calendarPeriods


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


earlySpan_m <- lapply(calendarPeriods,
                       function(x){
                         
                         calculateMetrics(
                           minDate = ymd("2013-01-01"),
                           maxDate = ymd("2019-12-31"),
                           calendar = x,
                           data = retData
                         )
                       })
names(earlySpan_m) <- calendarPeriods

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


lateSpan_m <- lapply(calendarPeriods,
                      function(x){
                        
                        calculateMetrics(
                          minDate = ymd("2020-01-01"),
                          maxDate = today(),
                          calendar = x,
                          data = retData
                        )
                      })
names(lateSpan_m) <- calendarPeriods

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

briefSpan_m <- lapply(calendarPeriods,
                       function(x){
                         
                         calculateMetrics(
                           minDate = ymd("2023-07-01"),
                           maxDate = ymd("2024-10-31"),
                           calendar = x,
                           data = retData
                         )
                       })
names(briefSpan_m) <- calendarPeriods


#####################
## MID SPAN >=2013 ##
#####################

midSpan <- lapply(calendarPeriods,
                   function(x){
                     
                     deltaHeadCount(
                       minDate = ymd("2013-01-01"),
                       maxDate = today(),
                       calendar = x,
                       data = retData
                     )
                   })
names(midSpan) <- calendarPeriods


midSpan_m <- lapply(calendarPeriods,
                      function(x){
                        
                        calculateMetrics(
                          minDate = ymd("2013-01-01"),
                          maxDate = today(),
                          calendar = x,
                          data = retData
                        )
                      })
names(midSpan_m) <- calendarPeriods

#############
#############
##
#############
#############

# Let's plot the delta.cum over the headcount mean

plot(y = midSpan_m[["quarter"]][,"delta.cum"],
     x = midSpan_m[["quarter"]][,"periodEnd"],
     type = "l",
     col = "sienna")

points(y = midSpan_m[["quarter"]][,"headcount_mean"],
     x = midSpan_m[["quarter"]][,"periodEnd"],
     col = "dodgerblue")

# let's plot the rates

# empty plot
yLim <- c(100*min(apply(midSpan_m[["year"]][,c("hireRate","termRate","deltaRate")],1,min, na.rm=TRUE)),
          100*max(apply(midSpan_m[["year"]][,c("hireRate","termRate","deltaRate")],1,max, na.rm=TRUE))
)
          
plot(y=100*midSpan_m[["year"]][,"hireRate"],
     x = midSpan_m[["year"]][,"periodEnd"],
  type = "n",
  ylim = yLim,
  xlab = "",
  ylab = "")

points(y = 100*midSpan_m[["year"]][,"hireRate"],
     x = midSpan_m[["year"]][,"periodEnd"],
     type = "l",
     col = "darkcyan")

points(y = 100*midSpan_m[["year"]][,"termRate"],
       x = midSpan_m[["year"]][,"periodEnd"],
       type = "l",
       col = "coral")

points(y = 100*midSpan_m[["year"]][,"deltaRate"],
       x = midSpan_m[["year"]][,"periodEnd"],
       type = "l",
       col = "forestgreen")

# this is a great graphic

# really great.  So great.

# I need three contrasting colors acceptable for colorblindness.
# purple?  yellow?

# also, because deltaRate can go negative it doesn't make as much sense on the same graphic
# so that makes four graphs.  Let's just put them all on one.

# I'll do the hire and term rates on the same plot, with a gray background.
# Option to show either one, or none.
# I'll make an option to show delta count or delta rate, on the green/pink background
# Max of three plots shown.





