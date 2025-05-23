# plotMetrics
# multiple lines
# CHECK
# sandbox

# This follows "Retention Exploratory Data Analysis"
# After calculating the list, "complexMetrics"
# This is a list of length 5, but honestly I want a list of length 6
# where the sixth is all of the NA values. -- DONE

data <- complexMetrics[["unassigned"]]

plotMetrics(complexMetrics[["unassigned"]],
            plotList = "headcount",
            cumulative_plot_params = list(ylim = c(0,1000))) # ylim is NOT an argument I can toglge!

# can I juast add points to that?

plotMetrics(complexMetrics[[2]],
            plotList = "delta.rate")

points(y = complexMetrics[[4]][,"deltaRate"], 
       x = complexMetrics[[4]][,"periodEnd"],
       type = "l",
       lwd = 2,
       col = "red")

# O.k., I worked in the function direclty and I'm very happy
# ...except....
# ...one thing...

# The termination is starting at zero in my examples.  So I am going to
# try different cuts of time and see if starting at zero always persists.

calculateMetrics(data = retData) |>
  plotMetrics()

# ...that's not good. # FIXED!
# Well, not fixed as well as I'd like

calculateMetrics(data = retData) |>
  (\(x){list(x)})() |>
  (\(x){setNames(x, "Year-to-date")})() |>
  plotMetrics()

# this worked!

calculateMetrics(data = retData) |>
  #(\(x){list(x)})() |>
  (\(x){setNames(list(x), "Year-to-date")})() |>
  plotMetrics()

# this also worked!

# I should make a note of this in the function

plotMetrics(midSpan[["year"]]) # term did NOT start at zero
# but it also never went to zero.  Ruh roh.

plotMetrics(earlySpan["year"])

# I need to keep looking at this.

# I need to compare the term metrics for my EDA time span,
# other time spans,
# and plotMetrics for multiple groups -- esp for PERCENTILES.



