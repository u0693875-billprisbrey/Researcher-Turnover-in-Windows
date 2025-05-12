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


# ok, and now that I see it it's obvious---

# I think the problem is when I set the initial count, I use minDate-1.
# But when I am calculating per week, month, quarter, year etc ---- I am probably double-counting 
# a week as both my last period of the initial count and then again as the first period of my new count.

# I'll experiment with moving the maximum date backwards from minDate-1 to one period backwards.

# didn't work. 
# Darn it!

turn_day <- calculateTurnover(data = retData,
                              calendar = "day")

turn_week <- calculateTurnover(data = retData,
                               calendar = "week")

turn_month <- calculateTurnover(data = retData,
                              calendar = "month")

turn_quarter <- calculateTurnover(data = retData,
                               calendar = "quarter")

turn_year <- calculateTurnover(data = retData,
                                  calendar = "year")

plot(turn_day$delta.cum, x = turn_day$actionDate, type = "l", col = "sienna")
points(turn_week$delta.cum, x = turn_week$actionDate, col ="dodgerblue")
points(turn_month$delta.cum, x = turn_month$actionDate, col ="seagreen3")
points(turn_quarter$delta.cum, x = turn_quarter$actionDate, col ="pink2")
points(turn_year$delta.cum, x = turn_year$actionDate, col ="darkorange3")

# for month/quarter/year, it plots the actionDate at the start of the period, and the value at the 
# END of the period.  Kinda confusing.
# How much do I care?  

# "week" is still just simply off

# I'm shifting backwards in time and ...yeah, that's not it.
plot(turn_day$delta.cum, 
     x = turn_day$actionDate, 
     type = "l", 
     col = "sienna", 
     ylim = c(min(turn_day$delta.cum, na.rm=TRUE),max(turn_week$delta.cum, na.rm = TRUE)),
     xlim = c(min(turn_day$actionDate - 30), max(turn_day$actionDate)+30)
     )
points(turn_week$delta.cum, x = turn_week$actionDate, col ="dodgerblue")
points(turn_week$delta.cum, x = turn_week$actionDate-7, col ="skyblue", type = "l")
points(turn_week$delta.cum, x = turn_week$actionDate-14, col ="cyan", type = "l")
points(turn_week$delta.cum, x = turn_week$actionDate-21, col ="darkblue", type = "l")
points(turn_week$delta.cum, x = turn_week$actionDate-28, col ="red", type = "l")



plot(turn_day$delta.cum, 
     x = turn_day$actionDate, 
     type = "l", 
     col = "sienna", 
     ylim = c(min(turn_day$delta.cum, na.rm=TRUE)-10,max(turn_week$delta.cum, na.rm = TRUE)+10),
     xlim = c(min(turn_day$actionDate - 30), max(turn_day$actionDate)+30)
)
points(turn_week$delta.cum, x = turn_week$actionDate, col ="dodgerblue")
points(turn_week$delta.cum-7, x = turn_week$actionDate, col ="skyblue", type = "l")
# so it's seven ahead, or subtracting 7 and it looks about perfect
points(turn_week$delta.cum-7, x = turn_week$actionDate+7, col ="cyan", type = "l")
# there's the exact match.
# so it's plotting at the start of the period, and that's kinda confusing.
# and it's adding roughly a week to the initial count.

# I'd like to figure this out.

plot(turn_day$delta.cum, 
     x = turn_day$actionDate, 
     type = "l", 
     col = "sienna", 
     ylim = c(min(turn_day$delta.cum, na.rm=TRUE)-10,max(turn_week$delta.cum, na.rm = TRUE)+10),
     xlim = c(min(turn_day$actionDate), max(turn_day$actionDate)+90)
)
points(turn_month$delta.cum, x = turn_month$actionDate+30, col ="seagreen3", pch=16)
points(turn_quarter$delta.cum, x = turn_quarter$actionDate+90, col ="pink2", pch=16)
points(turn_year$delta.cum, x = turn_year$actionDate+365, col ="orange4",pch=16)



# Decision point....

# I kinda like having my "actionDate" at the start of the period
# ...but it's also, well, wrong---because all the numbers are at the END of that period.

# Should I mess with "deltaHeadCount" ?  
# The problem is that the start is a neat "-01" for month, quarter, and year.
# I think I'll add a column.  
# Change "actionDate" to "periodStart"
# Add a column called "periodEnd"
# ...or maybe just, for simplicity, yeah add that column right now.

# And then mess with weeks (so confusing!)


