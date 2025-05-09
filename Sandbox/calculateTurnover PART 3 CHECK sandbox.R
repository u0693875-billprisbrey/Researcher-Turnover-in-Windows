# calculateTurnover PART 3 CHECK sandbox


calculateTurnover(data = retData,
                  calendar = "day") |>
  View()

# looks fine

calculateTurnover(data = retData,
                  calendar = "week") |>
  View()

# headcount_mean is off --- how is it less than the sums for every week?

calculateTurnover(data = retData,
                  calendar = "month") |>
  View()

# this looks good

calculateTurnover(data = retData,
                  minDate = ymd("2020-04-01"),
                  maxDate = ymd("2025-03-31"),
                  calendar = "quarter") |>
  View()

# mostly o.k. -- I guess if the head count dips and recovers during a period, then the mean
# won't quite align with the trend


calculateTurnover(data = retData,
                  minDate = ymd("2020-01-01"),
                  maxDate = ymd("2024-12-31"),
                  calendar = "year") |>
  View()


# let's double-check some of these

turn_day <- calculateTurnover(data = retData,
                              calendar = "day")

turn_week <- calculateTurnover(data = retData,
                  calendar = "week")


week_check <- aggregate(delta.cum ~ paste(year(actionDate), isoweek(actionDate), sep = "-W"), data = turn_day, mean)
names(week_check)[grepl("actionDate", names(week_check))] <- "adjDate"

week_merge <- merge(turn_week, week_check, by = "adjDate", sort = FALSE)


all(week_check$delta.cum == turn_week$headcount_mean) # not the same length

all(week_merge$headcount_mean == week_merge$delta.cum.y) # TRUE

# So it's calculating correctly
# the question, then, is whether it's useful

# let's look at the week with the widest split

# or let's commit to Git and catch the bus

# essentially I think we're .... really, for the accuracy levels we're dealing with, I think we're fine.


which(turn_week$headcount_mean - turn_week$delta.cum == max(turn_week$headcount_mean - turn_week$delta.cum))

turn_week[4,]

"2020-W5"

w5_filter <- turn_day$actionDate >= ymd("2025-01-27") & turn_day$actionDate < ymd("2025-02-02")

turn_day[w5_filter,]

mean(turn_day$delta.cum[w5_filter]) #3014.33
turn_week[3:5,]

# just a little off
# yeah  . . . why?

plot(turn_day$delta.cum, x = turn_day$actionDate)
points(turn_week$delta.cum, x = turn_week$actionDate, col ="dodgerblue")
# that's a pretty big shift to the right
# maybe I got the "initial_count" a little off?

# let's see this in the deltaHeadCount

# and I should similarly plot days vs weeks, months, quarters, years
# for calculateTurnOver

# I suspect some kind of shift in what period gets aggregated and how it's merged.





