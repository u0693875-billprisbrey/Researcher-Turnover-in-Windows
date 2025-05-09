# calculateTurnover CHECK sandbox
# 5.9.2025

# This checks calculateTurnover PART 2

# it also uses the fullSpan, earlySpan, etc calculated in the deltaHeadCount plot sandbox


calculateTurnover(initial_count = 1000, data = retData) |>
  deltaPlot()


 calculateTurnover(initial_date = ymd("2020-01-01"), data = retData) |>
      # deltaPlot()
       tail()
 
 deltaHeadCount(minDate = ymd("2020-01-01"),
                maxDate = today(),
                data = retData) |>
  # deltaPlot()
   tail()
 
 
 # these both came to the same place, thankfully
 
 # what if I populate initial_count AND initial_date?
 # I want a warning message, I think
 
 # what if initial_date is AFTER minDate?
 # I want an error message, I think
 
 calculateTurnover(initial_date = ymd("2020-01-01"), 
                   calendar = "year",
                   data = retData) |>
  # deltaPlot()
   tail()
 
 deltaHeadCount(minDate = ymd("2020-01-01"),
                maxDate = today(),
                calendar = "year",
                data = retData) |>
   # deltaPlot()
   tail()
 
 
 # so week is a little big off comparing calculateTurnover to deltaHeadCount
 
 # Let's pick a different initial date
 
 calculateTurnover(initial_date = ymd("2019-06-15"), 
                   calendar = "year",
                   data = retData) |>
   # deltaPlot()
   tail()
 
 deltaHeadCount(minDate = ymd("2019-06-15"),
                maxDate = today(),
                calendar = "year",
                data = retData) |>
   # deltaPlot()
   tail()
 
 # day does fine
 # week is a little off
 # month is a little off
 # quarter is quite a bit more off
 # year is about identical to quarter, about same amount off
 
 # Lunch time, I think
 
 # maybe I should just produce a data frame with the headcount on Jan 1 of every year,
 # and make my initialization easier.
 
 # but as it is, it's a flash to tabulate it each time
 
 
 # let's compare initial_dates that correspond to the start of the period (like "01" for month,
 # Apr-01 for quarter, etc)
 
 
 calculateTurnover(initial_date = ymd("2019-06-10"), 
                   calendar = "week",
                   data = retData) |>
   # deltaPlot()
   tail()
 
 deltaHeadCount(minDate = ymd("2019-06-10"),
                maxDate = today(),
                calendar = "week",
                data = retData) |>
   # deltaPlot()
   tail()
 
 # so if I match up the date to the period, it works great
 # except week is still a little off
 
 # I think I'll live with that; probably due to isoweek mis-alignment with the new year (?maybe?)
 
 
 calculateTurnover(initial_date = ymd("2019-06-10"), 
                   calendar = "week",
                   data = retData) |>
   # deltaPlot()
   head()
 
 deltaHeadCount(minDate = ymd("2019-06-10"),
                maxDate = today(),
                calendar = "week",
                data = retData) |>
   # deltaPlot()
   head()
 
 # I'm going to need a little explanatory blurb at the start of each function:
 
 deltaHeadCount always starts the clock at zero.  Or, if you prefer,
 you can start the clock at an initial head count.
 
 calculateTurnover will accept the initial head count as an argument or calculate
 an initial head count for you. 
 
 It will calculate the initial head count by accepting a date to start at zero, then
 calculating the cumulative delta up until the day before the specificed minimum date, and
 use this value as the initial head count.
 
 Or, if no date is provided, it will use the earliest date in the available data.
 
 
 calculateTurnover and deltaHeadCount will provide identical results if the minDate used
 for deltaHeadCount is the same as the iniital_date used in calculateTurnover (and period  and 
 maxDate are the same.)                                                                              )
 
This can mean the calculateTurnover is dependent on receiving good information,
but it can be handy to see the overall change since a particular date.  (Although
deltaHeadCount probably provides this more directly.)
 
 
 
 
 # Let's look at different min and max dates


calculateTurnover(initial_date = ymd("2010-01-01"),
                  minDate = ymd("2019-01-01"),
                  maxDate = ymd("2020-12-31"),
                  calendar = "year",
                  data = retData) |>
  # deltaPlot()
  tail()

deltaHeadCount(minDate = ymd("2010-01-01"),
               maxDate = ymd("2020-12-31"),
               calendar = "year",
               data = retData) |>
  # deltaPlot()
  tail() 
 

# I might need to change my "turnover" to calculate by day, and then 
# take the average per the period.

# or maybe my whole "calculateTurnover" is stupid, and I should
# just modify "deltaHeadCount" with turnover arguments
# (as I've already modified it to accept the initial_count,
# and the current calculateTurnover just repeats deltaHeadCount to calculate 
# the initial_count.


# let's compare the sum and the average

fullSpan[["year"]] |> deltaPlot()

theTKO_day <- calculateTurnover(data = retData,
                                minDate = ymd("2010-01-01"),
                            calendar = "day")

theTKO_year <- calculateTurnover(data = retData,
                                 minDate = ymd("2010-01-01"),
                                calendar = "year")

# now let's aggregate theTKO_day

annual_delta_cum_mean <- aggregate(delta.cum ~ year(actionDate),  data = theTKO_day, mean)
annual_term_sum <- aggregate(termCount ~ year(actionDate),  data = theTKO_day, sum)

annual_TO <- annual_term_sum$termCount / annual_delta_cum_mean$delta.cum

plot(annual_TO, col = "darkblue")
points(theTKO_year$turnover, col = "red", type = "l")

# it's about as identical as you can get

tkoDiff <- (theTKO_year$turnover - annual_TO)/annual_TO
plot(tkoDiff)
# well, it's small, but there's a clear drift to it.

# it's definitely a very small, very small difference

# but ..... why not fix it?  Why not?


