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

# here is how college lines were calculated

colleges <- unique(prepData$college)
collegePIs <- lapply(colleges, function(x) unique(prepData$PROPOSAL_PI_EMPLID[prepData$college == x]))
names(collegePIs) <- colleges

collegeMetrics <- lapply(collegePIs, function(x){
  
  calculateMetrics(data=retData[retData$PI_EMPLID %in% x,],
                   minDate = ymd("2013-01-01"),
                   maxDate = today(), 
                   calendar = "year")
  
})

plotMetrics(collegeMetrics[1:10])


complex_clusters <- levels(prepData$complex_cluster)

complexPIs <- lapply(complex_clusters, function(x) unique(prepData$PROPOSAL_PI_EMPLID[prepData$complex_cluster == x & !is.na(prepData$complex_cluster)]))
names(complexPIs) <- complex_clusters

# add the unassigned PI's, or NA values for prepData$complex_cluster

complexPIs[["unassigned"]] <- unique(prepData$PROPOSAL_PI_EMPLID[is.na(prepData$complex_cluster)])

complexMetrics <- lapply(complexPIs, function(x){
  
  calculateMetrics(data=retData[retData$PI_EMPLID %in% x,],
                   minDate = ymd("2013-01-01"),
                   maxDate = today(), 
                   calendar = "year")
  
})

plotMetrics(complexMetrics, hire_points_params = list(type = "n"))

lapply(complexMetrics, head)
# lots of zero term rates
# let's see if it holds with a different selection


complexMetrics5 <- lapply(complexPIs, function(x){
  
  calculateMetrics(data=retData[retData$PI_EMPLID %in% x,],
                   minDate = ymd("2010-01-01"),
                   maxDate = ymd("2015-01-01"), 
                   calendar = "year")
  
})


lapply(complexMetrics5, head)

compareMetrics <- Map(function(x, y) merge(x, y, by = "adjDate", all = TRUE), complexMetrics, complexMetrics5)

lapply(compareMetrics, function(x){
  
  filter <- x[,"adjDate"] %in% c(2013:2015)
  x[filter,c("termRate.x","termRate.y")]
  
})

# so there's a very tiny difference in a couple of clusters in 2015
# that's interesting.

# I gotta get to the bottom of that.
