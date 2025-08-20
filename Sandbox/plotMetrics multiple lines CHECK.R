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
  x[filter, c("termCount.x","termCount.y", "delta.x","delta.y", "headcount_mean.x", "headcount_mean.y")] # c("termCount.x","termCount.y")
  
})

# so there's a very tiny difference in a couple of clusters in 2015
# that's interesting.

# I gotta get to the bottom of that.


lapply(compareMetrics, function(x){
  
  filter <- x[,"adjDate"] %in% c(2013:2015)
  apply(x[filter, c("headcount_mean.x", "headcount_mean.y")], 1, function(y){y[2]-y[1]}) # c("termCount.x","termCount.y")
  
})


# so it looks like the mean is calculated differently in 2015

# how much do I care?
# let's try it again for months

# it probably has to do with the starting date.

# let's try this --


complexMetrics31 <- lapply(complexPIs, function(x){
  
  calculateMetrics(data=retData[retData$PI_EMPLID %in% x,],
                   minDate = ymd("2012-12-31"),
                   maxDate = today(), 
                   calendar = "year")
  
})


lapply(complexMetrics, function(x) {x[,"headcount_mean"]})
lapply(complexMetrics31, function(x) {x[,"headcount_mean"]})

compareMetrics <- Map(function(x, y) merge(x, y, by = "adjDate", all = TRUE), complexMetrics, complexMetrics31)
lapply(compareMetrics, function(x){
  
  filter <- x[,"adjDate"] %in% c(2013:2015)
  apply(x[filter, c("headcount_mean.x", "headcount_mean.y")], 1, function(y){y[2]-y[1]}) # c("termCount.x","termCount.y")
  
})


lapply(compareMetrics, function(x){
  x[,c("headcount_mean.x","headcount_mean.y", "hireRate.x","hireRate.y","termRate.x", "termRate.y")]
  
})

lapply(compareMetrics, function(x){
  x[,c("adjDate", "headcount_mean.x","headcount_mean.y")]
  
})

lapply(compareMetrics, function(x){
  x[,c("adjDate", "hireRate.x","hireRate.y")]
  
})

lapply(compareMetrics, function(x){
  x[,c("adjDate", "termRate.x", "termRate.y")]
  
})

# I think it's just a caution to be aware of start and end date effects

# I could compare staring on May 13, for example, and probably see this disappear

# And I could just look for whether I used > or >=

# as it is I'll not worry about it.

complexMetricsDay <- lapply(complexPIs, function(x){
  
  calculateMetrics(data=retData[retData$PI_EMPLID %in% x,],
                   minDate = ymd("2014-12-25"),
                   maxDate = ymd("2015-01-05"), 
                   calendar = "day")
  
})

lapply(complexMetricsDay, function(x){
  x[,c("adjDate", "delta" )]
  
})


# But wait --- did I really have zero terminations in 2013?


calculateMetrics(data=retData[retData$PI_EMPLID %in% x,],
                 minDate = ymd("2014-12-25"),
                 maxDate = ymd("2015-01-05"), 
                 calendar = "day") |>
  plotMetrics()


# I have 62 terminations in 2013 per earlySpan[["year"]]
# if I sum the terminations for all clusters, do I get 62?

# also, given:
plotMetrics(earlySpan[["year"]], hire_points_params = list(type = "n"), metric_plot_params=list(ylim = c(0,5)))
# Warning message:
#  In (function (..., no.readonly = FALSE)  :
#        "ylim" is not a graphical parameter


# ylim is established based on the presence of hire points line.
# even if I don't show it, the y axis range is way off
# I'm not sure how much I care

# I could fix it with an "if" condition when I set the ylim
# another day, I think, as I have bigger fish to fry.


lapply(complexMetrics, function(x){x[x$adjDate == 2013,"termCount"]})

lapply(complexMetrics, function(x){x[,c("adjDate", "termCount")]})


# OK, WE HAVE A DISCREPANCY!
# I gotta figure this one out
# ugh

# I'm hoping it's just a Jan 1st thing.  Gee whiz.

complexMetrics_Dec31 <- lapply(complexPIs, function(x){
  
  calculateMetrics(data=retData[retData$PI_EMPLID %in% x,],
                   minDate = ymd("2012-12-31"),
                   maxDate = today(), 
                   calendar = "year")
  
})

sapply(complexMetrics_Dec31, function(x){x[x$adjDate == 2013,"termCount"]}) |> sum() # 2

lapply(complexMetrics_Dec31, function(x){x[,c("adjDate", "termCount")]})

# Uh oh.

# ok, let's get the PI's of all the folks terminated in 2013
# and see what cluster they are in

PI2013Term <- retData$PI_EMPLID[year(retData$TERMINATION_DT) == 2013 & !is.na(retData$TERMINATION_DT)] # pi's terminated in 2013

length(PI2013Term) # 62 # good, check

any(PI2013Term %in% piEmplid$emplid) # FALSE

# whoa, really? !! Wow!

# well o.k. then

# I guess these aren't comparable due to different filters

all(piEmplid$emplid %in% retData$PI_EMPLID) # TRUE (good)
all(prepData$PROPOSAL_PI_EMPLID %in% retData$PI_EMPLID) # TRUE (good)

table(retData$PI_EMPLID %in% prepData$PROPOSAL_PI_EMPLID)
FALSE  TRUE 
1538  2937 

# This is a good thing to describe in the report
# Presumably these are people who published BEFORE 2013 (my cut-off date)

plotMetrics(complexMetrics, plotList = "metric", hire_points_params = list(type = "n"))

# Why isn't this working?
# Oh.  New error message added

plotMetrics(complexMetrics, plotList = "rate", 
            metric_plot_params = list(oma = c(0,0,2,0)),
            hire_points_params = list(type = "n"),
            featureMap = complexClusterColors)

plotMetrics(complexMetrics, plotList = c("rate", "frank","beans"), 
        #    metric_plot_params = list(oma = c(0,0,2,0)),
            hire_points_params = list(type = "n"),
            featureMap = complexClusterColors)


# let's look at complexMetrics (hiring and firing) over the entire life


complexMetrics_fullspan <- lapply(complexPIs, function(x){
  
  calculateMetrics(data=retData[retData$PI_EMPLID %in% x,],
                   minDate = ymd("1960-01-01"),
                   maxDate = today(), 
                   calendar = "year")
  
})

plotMetrics(complexMetrics_fullspan,
            plotList = "all",
            featureMap = complexClusterColors)

# looks like it can't handle a 0/0, or rate values of NaN

# Is this really the first time that's come up?

# Yes, because a "headcount_mean" value of zero or near-zero is useless.
# I need to tighten my time frame to give that some meaning.

plotMetrics(complexMetrics_fullspan[[1]],
            plotList = "all",
            featureMap = complexClusterColors
            )

plotMetrics(complexMetrics_fullspan[[1]],
            plotList = "count",
            metric_legend2_params = list(plot = FALSE),
            featureMap = complexClusterColors
)



complexMetrics_2000 <- lapply(complexPIs, function(x){
  
  calculateMetrics(data=retData[retData$PI_EMPLID %in% x,],
                   minDate = ymd("2000-01-01"),
                   maxDate = today(), 
                   calendar = "year")
  
})

plotMetrics(complexMetrics_2000,
            plotList = "all",
            featureMap = complexClusterColors
)

# ok, interesting.
# do I care?

plotMetrics(complexMetrics_2000,
            plotList = c("rate"),
            
            featureMap = complexClusterColors
)

# this looks like it explains how the data was collectd,
# or the filters that define this data set, than anything else.

# Rather than plot a line-per-cluster, here's some ideas:
# double-check that everyone in prepData is assigned a cluster value (including "unassigned")
# create a single line that only includes this population

# so I have a single line that does the full population in the view
# then I do another sinlge line that does the population in the view that is found in prepData



calculateMetrics(data=retData[retData$PI_EMPLID %in% prepData$PROPOSAL_PI_EMPLID,],
                 minDate = ymd("2000-01-01"),
                 maxDate = today(), 
                 calendar = "year") |>
  plotMetrics()


calculateMetrics(data=retData,
                 minDate = ymd("2000-01-01"),
                 maxDate = today(), 
                 calendar = "year") |>
  plotMetrics()

# both of these have a termination rate of essentially zero
# until it turns on at one point.

# I'd like to prosaically explain that.

# is it because we aren't pulling in the old-timers that are retiring
# during a given period, but selecting the people who are active later,
# therefore hired at this earlier time (high hire rate)
# ..and then are terminated?


# I think I'm looking at a definitional problem.  It's not a good cross-section.

# Except it's fine if I can keep the denominator correct
# if I can define "this" group of people out of "that"

# As in, my data should be all of retData, and my subset is the population
# of a cluster.

# This will take some thinking.  I might have my denominator that defines my rates
# mis-calculated.

compList <- list(complete = calculateMetrics(data=retData,
                             minDate = ymd("2010-01-01"),
                             maxDate = today(), 
                             calendar = "year"),
    active = calculateMetrics(data=retData[retData$PI_EMPLID %in% prepData$PROPOSAL_PI_EMPLID,],
                         minDate = ymd("2010-01-01"),
                         maxDate = today(), 
                         calendar = "year"),
    inactive = calculateMetrics(data=retData[!retData$PI_EMPLID %in% prepData$PROPOSAL_PI_EMPLID,],
                                minDate = ymd("2010-01-01"),
                                maxDate = today(), 
                                calendar = "year")
     )

plotMetrics(compList)

# some fascinating things happening here.

# I guess I have this full data set, with some unknown definitions defining the population,
# and it makes sense that 
# that the termination rate would start out at near zero if I am defining the population
# as being active as of some date.  They would be active headcount on Day 1 of the period,
# and wouldn't have had time to quit yet.
# Similarly, "hiring" rate would start out really high as I grew the population.
# But neither is a very accurate snapshot of the actual active population.

# I've got some interesting population dynamics to consider here.

# And, as far as improving the graphics,
# I can define things like yLim -after- modifying the list of parameters
# that would make the plot more accurate to what I am trying to represent.






