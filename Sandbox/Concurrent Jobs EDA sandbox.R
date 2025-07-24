# Concurrent jobs
# Sandbox

# one step at a time

# tempting to do an individual timeline graphic

###########
## QUERY ##
###########

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), 
                         Driver = "oracle", 
                         Host = "ocm-campus01.it.utah.edu", 
                         SVC = "biprodusr.sys.utah.edu",
                         UID = Sys.getenv("userid"),
                         PWD = Sys.getenv("pwd"),
                         Port = 2080)


journeyQuery <- "select * from ds_hr.EMPL_AGE_RANGE_ACTION_MV_V WHERE EFFDT < TO_DATE('2025-08-01', 'YYYY-MM-DD') " # a view of the query

journeyData <- dbGetQuery(con.ds, journeyQuery)


actionReasonQuery <- "
SELECT
  ACTION,
  ACTION_DESCR,
  ACTION_REASON,
  ACTION_REASON_DESCR,
  COUNT(*) AS count
FROM
  ds_hr.EMPL_AGE_RANGE_ACTION_MV_V
WHERE
  EFFDT <= DATE '2025-08-01'
GROUP BY
  ACTION,
  ACTION_DESCR,
  ACTION_REASON,
  ACTION_REASON_DESCR
ORDER BY
  count DESC
"

actionReasonFrame <- dbGetQuery(con.ds, actionReasonQuery)

DBI::dbDisconnect(con.ds)

##########
## PREP ##
##########

# Create factors with levels in the proper order
journeyData$AGE_BAND <- factor(journeyData$AGE_BAND, levels = 
                                 c(
                                   "Under 20",
                                   "20s",
                                   "30s",
                                   "40s",
                                   "50s",
                                   "60s",
                                   "70s",
                                   "80s",
                                   "90 and Above"
                                 )
)

# Identify count of records per EMPLID in order to separate employees with multiple

recordsPerEMPLID <- aggregate(EMPL_RCD ~ EMPLID, data = journeyData, function(x){length(unique(x))})

dupeRCD <- recordsPerEMPLID |> (\(x){x[x$EMPL_RCD > 1, "EMPLID", drop = TRUE]})()  
singleRCD <- unique(journeyData$EMPLID)[!unique(journeyData$EMPLID) %in% dupeRCD]

# proportions(c(length(dupeRCD),length(singleRCD))) # 0.181 0.819

journeySingleFilter <- journeyData$EMPLID %in% singleRCD & journeyData$EMPL_RCD == 0 & (!journeyData$ACTION_REASON %in% "HCJ")

# NEEDS ATTENTION if I want to figure this out.  Not sure I really need this
nonZeroFilter <- (journeyData$EMPLID %in% singleRCD) & journeyData$EMPL_RCD != 0 
nonZeroEmplids <- unique(journeyData$EMPLID[nonZeroFilter])

# holding onto the original data
jData.o <- journeyData

# I should figure out how to incorporate this logic into a query

jData.single <- journeyData[journeySingleFilter,]
jData.concurrent <- journeyData[!journeySingleFilter,]

journeyData <- list(single = jData.single, conc =jData.concurrent)

#########################
## PUT INTO A FUNCTION ##
#########################

# Define boundary actions

actionReasonFrame$boundary <- NA
actionReasonFrame$boundary_type <- NA

# Primary entry or exit

primeEntryFilter <- actionReasonFrame$ACTION %in% c("HIR", "REH")
primeExitFilter <- actionReasonFrame$ACTION %in% c("TER", "RET", "RWP")

actionReasonFrame$boundary[primeEntryFilter] <- "entry"
actionReasonFrame$boundary[primeExitFilter] <- "exit"
actionReasonFrame$boundary_type[primeEntryFilter|primeExitFilter] <- "primary"

# Break entry or exit

breakEntryFilter <- actionReasonFrame$ACTION %in% c("RWB")
breakExitFilter <- actionReasonFrame$ACTION %in% c("SWB")

actionReasonFrame$boundary[breakEntryFilter] <- "entry"
actionReasonFrame$boundary[breakExitFilter] <- "exit"
actionReasonFrame$boundary_type[breakEntryFilter|breakExitFilter] <- "break"

# Leave entry or exit

leaveEntryFilter <- actionReasonFrame$ACTION %in% c("RFL")
leaveExitFilter <- actionReasonFrame$ACTION %in% c("LOA","LTO", "PLA") & !(actionReasonFrame$ACTION_REASON %in% c("EXT"))

actionReasonFrame$boundary[leaveEntryFilter] <- "entry"
actionReasonFrame$boundary[leaveExitFilter] <- "exit"
actionReasonFrame$boundary_type[leaveEntryFilter|leaveExitFilter] <- "leave"

# now I gotta merge this back to the journey data

journeyData <- merge(journeyData, unique(actionReasonFrame[,c("ACTION","boundary","boundary_type")]), by = "ACTION")




# Let's do some EDA

# Action items per PI

eventsPerEmplid <- aggregate(ACTION ~ EMPLID, data = journeyData, length)
names(eventsPerEmplid) <- c("EMPLID", "eventCount")

skim(eventsPerEmplid)
# wow.  That's increcrible.
── Variable type: numeric ──────────────────────────────────────────────
skim_variable n_missing complete_rate mean   sd p0 p25 p50 p75 p100
1 eventCount            0             1 40.5 37.1  1  18  29  51  632
hist 
1 ▇▁▁▁▁

# Huge number of events.

# I guess they are duplicated across jobs.

# Let's ... take a break

# Ok let's look at recods per emplid

skim(recordsPerEMPLID[recordsPerEMPLID$EMPLID %in% dupeRCD,])

── Variable type: numeric ──────────────────────────────────────────────
skim_variable n_missing complete_rate mean    sd p0 p25 p50 p75 p100
1 EMPL_RCD              0             1 2.32 0.691  2   2   2   2   16
hist 
1 ▇▁▁▁▁


# thankfully it's almost always just two concurrent jobs
# that will make life easier
# I'll probably filter out the ones with more than 2

dim(recordsPerEMPLID[recordsPerEMPLID$ EMPL_RCD > 2,]) # 7616
# ok, that's a lot to filter out still

skim(recordsPerEMPLID[recordsPerEMPLID$ EMPL_RCD > 2,])

── Variable type: numeric ──────────────────────────────────────────────
skim_variable n_missing complete_rate mean    sd p0 p25 p50 p75 p100
1 EMPL_RCD              0             1 3.35 0.785  3   3   3   3   16
hist 
1 ▇▁▁▁▁

# ok, and most of these are three

dim(recordsPerEMPLID[recordsPerEMPLID$EMPL_RCD > 3,]) # still 1850

dim(recordsPerEMPLID[recordsPerEMPLID$EMPL_RCD > 4,]) # 487

# let's pick a few EMPLIDs with just two and a small number of events

set.seed(42)
fewPIs <- sample(recordsPerEMPLID$EMPLID[recordsPerEMPLID$EMPL_RCD == 2 & recordsPerEMPLID$EMPLID %in% eventsPerEmplid$EMPLID[eventsPerEmplid$eventCount < 25] ],6)


View(journeyData[journeyData$EMPLID %in% fewPIs[1],])

# I gotta see if the minimum date per person always contains a hire
# I could also look for duplicate actions per date
# and count of actions per date

fewPIs[1] 
# It says there's a duplicate job --- but I only see one
# honestly looks like a mistake
# And this guy is interesting for behing hired/rehired/term of assignment (?) ...
#  ... and then EMPL_RCD =1 , but all activity is for 1 thereafter


fewPIs[3] 
# wow lots happening, including a short work break that only applied to one concurrent job

# lots of positions that look like part-time student jobs

# I honestly wonder how much I trust the "HCJ" action reason.
# I'm also not seeing "SWB" (short work break) applying to both jobs  (fewPIs[3])

# I also see a lot happening on the same day, like a REH and a HIR with HCJ on the same day.


# Are all of these students, so I can somewhat safely ignore them?
# How do I separate part-time and full-time workers?
# How many of my PI's are in this group?
# I should check the first-day HIR last-day TERM thing a bit more
# And seems like the first step is to figure out 2 EMPL_RCD, and then move up to more complicated journeys

# let's looks at the job titles

jobTitle <- table(journeyData$JOB_TITLE) |> (\(x){x[order(x, decreasing = TRUE)]})()

# wow, lots of assoc instructorss, Professor, and Associate Professor.

# first day

dayOne <- aggregate(EFFDT ~ EMPLID, data = journeyData, min)
dayOne_actions <- merge(dayOne, journeyData[,c("EMPLID","EFFDT", "ACTION")], by= c("EMPLID","EFFDT"),  all.x = TRUE)
dayOne_actions <- aggregate(ACTION ~ EMPLID + EFFDT, data = dayOne_actions, function(x) paste(sort(unique(x)), collapse = ", "))

dayOne_actions_table <- table(dayOne_actions$ACTION) |> (\(x){x[order(x, decreasing = TRUE)]})()

> sum(grepl("HIR", dayOne_actions$ACTION))
[1] 32047
> sum(!grepl("HIR", dayOne_actions$ACTION))
[1] 7

# wow, so pretty much "HIR" starts the journey

# last day

dayLast <- aggregate(EFFDT ~ EMPLID, data = journeyData, max)
dayLast_actions <- merge(dayLast, journeyData[,c("EMPLID","EFFDT", "ACTION")], by= c("EMPLID","EFFDT"),  all.x = TRUE)
dayLast_actions <- aggregate(ACTION ~ EMPLID + EFFDT, data = dayLast_actions, function(x) paste(sort(unique(x)), collapse = ", "))

dayLast_actions_table <- table(dayLast_actions$ACTION) |> (\(x){x[order(x, decreasing = TRUE)]})()

sum(grepl("TER", dayLast_actions$ACTION)) 
sum(grepl("RET", dayLast_actions$ACTION))

sum(grepl("TER|RET|RWB", dayLast_actions$ACTION)) # 21405
sum(!grepl("TER|RET|RWB", dayLast_actions$ACTION)) # 10649 # presumably still here

# let's -- man
# how do I do this?

# let's start with deltaHeadCount and work through it step by step

# Man, what do I do . . . . . . .
# Do I treat the person, or the details (like job title and department?)
# Seems like first I'll treat the person
# which means .... you'd think I can ignore EMPL_RCD but sometimes it doesn't go back to zero

fewPIfilter <- journeyData$EMPLID %in% fewPIs

deltaHeadCount(data = journeyData[journeyData$EMPLID %in% fewPIs,], minDate = ymd("2005-07-01"),
               maxDate = ymd("2025-07-01")) |> deltaPlot()

deltaHeadCount(data = journeyData[journeyData$EMPLID %in% fewPIs,], minDate = ymd("2005-07-01"),
               maxDate = ymd("2025-07-01")) |> View()

# well.... that's something, I guess
# except I know it's not right

# What I think I'm going to need to do is ---
# I'll need to adjust the logic of how I assign the "entry" and "exit" statements.
# Here's one thing I"m thinking about:

# Establish that there is only one "HIR" per person, and the rest are "REH"
# Establish the MINIMUM hire date per EMPLID.  Compare that to the current "HIR".
# Don't assign an "ENTRY" if there is an earlier "HIR".

# That's my logic if I don't trust HCJ, and I'm not sure I do.
# I'm also not sure I trust that each EMPLID only has the one HIR.


# So now I'm thinking that I process the data in various passes --
# first I do the no concurrent jobs, as I have already done.
# Then I do only two concurrent jobs, that I am currently working on.

# I like the path I'm walking down, but . . . needs work.

# I need to do something like filter the journey to just the boundary actions per PI.
# then I use a variety of rules to assign "entry" and "exit" and "type"

# Let's get playing with that.


# It's almost like I need to create a function
# for assigning the boundary_type and boundary action.  My headcount functions,
# that use "entry" and "exit", won't be adjusted.


# First, are there multiple HIR per emplid?

action_dates_per_emplid <- aggregate(EFFDT ~ EMPLID+ACTION, data = journeyData, function(x) length(unique(x)))
table(action_dates_per_emplid$ACTION) # HIR is 32054, so that's promising # no, it just means that every EMPLID has been hired

hire_per_emplid <- action_dates_per_emplid[action_dates_per_emplid$ACTION == "HIR",] 
> quantile(hire_per_emplid$EFFDT)
0%  25%  50%  75% 100% 
1    2    2    2   11 

# so there are multiple "HIR" per EMPLID.

rehire_per_emplid <- action_dates_per_emplid[action_dates_per_emplid$ACTION == "REH",] 
quantile(rehire_per_emplid$EFFDT)
0%  25%  50%  75% 100% 
1    1    2    3  102 

# plenty of re-hires too

action_reason_dates_per_emplid <- aggregate(EFFDT ~ EMPLID+ACTION+ACTION_REASON, data = journeyData, function(x) length(unique(x)))

hire_reason_per_emplid <- action_reason_dates_per_emplid[action_reason_dates_per_emplid$ACTION == "HIR",]

# CNV "conversion" what's that?

# should be one and only one HIR NHR (new hire) per emplid

newHireFilter <- hire_reason_per_emplid$ACTION == "HIR" & hire_reason_per_emplid$ACTION_REASON == "NHR"

skim(hire_reason_per_emplid$EFFDT[newHireFilter])
# mean of 1.01
quantile(hire_reason_per_emplid$EFFDT[newHireFilter])
0%  25%  50%  75% 100% 
1    1    1   1    3

# ok, so not perfect but looking really, really good!

# . . . and brain is done for tonight I think.

# So what I'm thinking of doing is developing a function 
# that can handle the full data set.
# It will have several steps and stages to it.

# S



# let's test for NHR

action_reason_dates_per_emplid <- lapply(journeyData, function(y){
  
  aggregate(EFFDT ~ EMPLID+ACTION+ACTION_REASON, data = y, function(x) length(unique(x)))
  
})

hire_reason_per_emplid <- lapply(action_reason_dates_per_emplid, function(x){
  
  x[x$ACTION == "HIR" & x$ACTION_REASON == "NHR",] 
  
})

lapply(hire_reason_per_emplid, function(x){mean(x$EFFDT)})

$single
[1] 1.000149

$conc
[1] 1.005254

# well that looks pretty good actually
# how many are off, actually?

lapply(hire_reason_per_emplid, function(x){nrow(x[x$EFFDT >1,] )})

$single
[1] 18

$conc
[1] 151

# ok, so this is a pretty good universal rule


# Define boundary actions

actionReasonFrame$boundary <- NA
actionReasonFrame$boundary_type <- NA

##################
## INITIAL HIRE ##
##################

initialHireFilter <- actionReasonFrame$ACTION %in% c("HIR") & actionReasonFrame$ACTION_REASON %in% c("NHR")

# o.k., one done
# This is pretty much everybody's start

# Let's look at termination

term_reason_per_emplid <- lapply(action_reason_dates_per_emplid, function(x){
  
  x[x$ACTION == "TER",] 
  
})

lapply(term_reason_per_emplid, function(x){mean(x$EFFDT)})
lapply(term_reason_per_emplid, function(x){nrow(x[x$EFFDT >1,] )})

# This is the wrong way to think about it

# Let's get a few individual timelines drawn out

eventsPerEmplid <- lapply(journeyData, function(x) { aggregate(ACTION ~ EMPLID, data = x, length)})


set.seed(42)
fewPIs <- sample(recordsPerEMPLID$EMPLID[recordsPerEMPLID$EMPL_RCD == 2 & recordsPerEMPLID$EMPLID %in% eventsPerEmplid[[2]]$EMPLID[eventsPerEmplid[[2]]$ACTION < 25] ],6)

> fewPIs
[1] "06012878" "00594544" "00915150" "01379631"
[5] "00435004" "01344487"

View(journeyData[["conc"]][journeyData[["conc"]]$EMPLID == fewPIs[1],])

# fewPIs[[1]] is exasperating.
# This is making my head spin.  Hard to chart this out.
# It's a bit of a mess.
# maybe I will make a timeline graphic --
# or should I do one manually first?

# This guy is hired, terminated, re-hired, and on the same day
# terminated AND hired into a concurrent job.
# And it sticks with empl_rcd = 1; it DOES NOT go back to zero.

timeline1 <- journeyData[["conc"]][journeyData[["conc"]]$EMPLID == fewPIs[1],]
timeline1$ACTION <- factor(timeline1$ACTION)

plot(y = rep(1, nrow(timeline1)),
     x = as.Date(timeline1$EFFDT),
     pch = 19,
     col = c("red","yellow","blue","green")[timeline1$ACTION] )

# ok
# This suggests creating a "map" with shapes and colors,
#   like adding a couple of columns to actionReasonFrame.
# What do I do when I have several on the same day?
#  I could create lanes--- but then where am I putting the 
#  concurrent job?

# thanks Chat -- that was fast!

date_counts <- table(timeline1$EFFDT) # identify multiple events per day

yPos <- ave(as.numeric(timeline1$EFFDT), timeline1$EFFDT, FUN = function(dates) {
  n <- length(dates)
  if (n == 1) {
    return(1)  # single point: no jitter
  } else {
    # Evenly spaced jitter around y = 1
    jitter_values <- seq(0.9, 1.1, length.out = n)
    return(jitter_values)
  }
})

plot(y = yPos,
     x = as.Date(timeline1$EFFDT),
     pch = 19,
     col = c("red","brown","blue","green")[timeline1$ACTION] )


# ok, that's not bad
# I'd like to color- and shape- code it better.

# next I'd like to adjust the timeline based on the EMPL_REC
# It would also be cool -if- the jitter was always in the same order

plot(y = yPos + timeline1$EMPL_RCD,
     x = as.Date(timeline1$EFFDT),
     pch = 19,
     col = c("red","brown","blue","green")[timeline1$ACTION] )


# well, that's some clarity I guess

# let's color code these things, starting with boundary actions

actionFrame <- unique(actionReasonFrame[,c("ACTION", "ACTION_DESCR")])

# boundaries
actionFrame$boundary_type <- NA
actionFrame$boundary <- NA

# color, shape, and size
actionFrame$shape_color <- NA
actionFrame$shape_shape <- NA
actionFrame$shape_size <- NA

# assign
# I think I'll just type it out

actionFrame <- data.frame(ACTION = c("DTA", "PAY", "TER", "HIR", "REH", "SWB", "RWB", "XFR", "POS", "PLA", "RFL", "JRC", "LOA", "RET", "RCL", "RWP", "LTO", "STO", "PRO", "STD", "TWP", "RFD"),
                          boundary = c(NA, NA, "exit", "entry", "entry", "exit", "entry", NA, NA, "exit", "entry", NA, "exit", "exit", NA, "exit", "exit", "exit", NA, "exit", "exit", "entry"),
                          boundary_type = c(NA,  NA, "primary", "primary","primary","break","break",NA, NA, "leave", "leave", NA, "leave", "primary", NA, "primary", "leave", "leave", NA, "leave", "primary", "leave")) #,

# color, shape, and size
actionFrame$shape_color <- NA
actionFrame$shape_shape <- NA
actionFrame$shape_size <- NA

actionFrame$shape_color[actionFrame$boundary_type == "primary"] <- "chocolate"
actionFrame$shape_color[actionFrame$boundary_type == "break" ] <- "steelblue"
actionFrame$shape_color[actionFrame$boundary_type == "leave" ] <- "coral"

actionFrame$shape_color[is.na(actionFrame$boundary_type)] <- "lightgreen"

actionFrame$shape_shape[actionFrame$boundary == "exit"] <- 19   
actionFrame$shape_shape[actionFrame$boundary == "entry"] <- 13   
actionFrame$shape_shape[is.na(actionFrame$boundary)] <- 1

actionFrame$shape_size[actionFrame$ACTION == "HIR" ] <- 2
actionFrame$shape_size[actionFrame$ACTION == "TER" ] <- 2

actionFrame$shape_size[is.na(actionFrame$boundary_type)] <- 0.75

# if otherwise unspecified
actionFrame$shape_size[is.na(actionFrame$shape_size)] <- 1


# now let's plot me some timelines

plotJourney <- function(data, plotMap){
  
  # where plotMap is the actionFrame with color, shape, and size specified
  # where data is the journeyData for a single EMPLID
  
  timeLine <- merge(data, plotMap, by = "ACTION", all.x = TRUE)
  
  # create jitter
  yPos <- ave(as.numeric(timeLine$EFFDT), timeLine$EFFDT, FUN = function(dates) {
    n <- length(dates)
    if (n == 1) {
      return(1)  # single point: no jitter
    } else {
      # Evenly spaced jitter around y = 1
      jitter_values <- seq(0.9, 1.1, length.out = n)
      return(jitter_values)
    }
  })
  
  # draw the plot
  
  plot(y = yPos + timeLine$EMPL_RCD,
       x = as.Date(timeLine$EFFDT),
       pch = timeLine[,"shape_shape"],
       col = timeLine[,"shape_color"],
       cex = timeLine[,"shape_size"]
       )
  
}

# well
# it's something

# let's see a few more

plotJourney(data = journeyData[["conc"]][journeyData[["conc"]]$EMPLID == fewPIs[1],], plotMap = actionFrame)

# fewPIs[3], fewPIs[5], fewPIs[6]  have exits sticking way out there, and no entry against it

# Now I can start getting fancy with my shapes, colors, and sizes

# This isn't a bad graphic.  I should probably just chuck this up in a Shiny app
# so I can reference it easily

# And I thought I had some "break" and "leave" in there?
#   -- I need to specify the shape SIZE !

# I should target the PI's to increase the relevancy

# it's looking good

# this could work great with plotly
# A shiny app with a plotly graphic and hover ability
# and below that, the raw data frame

singlePIs <- sample(journeyData[["single"]][,"EMPLID"], 6 )
plotJourney(data = journeyData[["single"]][journeyData[["single"]]$EMPLID == singlePIs[1],], plotMap = actionFrame)

# I almost want a solid line for some of these durations
# Like a blue line during the break, and a coral line during the leave
# and I guess a solid "chocolate" line during employment ?

# my purpose here isn't to create a graphic, though
# it's to develop "entry" and "exit" rules for concurrent jobs

# Except for that one example, it looks like I can ignore EMPL_RCD == 1
# (?)  How fair of a generalization is that?

# The thing is, that developing the graphic should help me walk through
# the rules and provide a very nice visual check.

# I almost want to make one rule per PI, then just keep iterating until
# they are all covered.

# And it looks like I am going to need to develop a color, shape, size for 
# every actionReason

# And seriously, should I iterate with a Shiny app?

# To Do:
#   Develop entry/exit rules that apply to the actionReasonFrame
#   Develop unique color/shape/size for all 186 actionReasonFrame combos
#   Draw a duration line at the bottom of the graphic
#   Apply the rules and compare to some kind of double-check (?!!!)
#   Some kind of marker for "currently employed"
#   Display the journey data frame
#   I think the duration line is in its own graphic underneath

# man either way my head is kinda spinning.
# I wonder how complex the logic on this is going to be, both for applying
# entry/exit and for plotting?

# let's try the line

timeline2 <- journeyData[["single"]][journeyData[["single"]]$EMPLID == singlePIs[2],]

plotMap <- actionFrame
timeLine2 <- merge(timeline2, plotMap, by = "ACTION", all.x = TRUE)

# create jitter
yPos <- ave(as.numeric(timeLine2$EFFDT), timeLine2$EFFDT, FUN = function(dates) {
  n <- length(dates)
  if (n == 1) {
    return(1)  # single point: no jitter
  } else {
    # Evenly spaced jitter around y = 1
    jitter_values <- seq(0.9, 1.1, length.out = n)
    return(jitter_values)
  }
})

# draw the plot

plot(y = yPos + timeLine2$EMPL_RCD,
     x = as.Date(timeLine2$EFFDT),
     pch = timeLine2[,"shape_shape"],
     col = timeLine2[,"shape_color"],
     cex = timeLine2[,"shape_size"]
)

mtext(side = 3, "Working on it", line = 2)

# filter to the break type

primaryBoundary <- timeLine2[timeLine2$boundary_type == "primary" & !is.na(timeLine2$boundary_type),]

# select the entries in order

entries <- primaryBoundary$EFFDT[primaryBoundary$boundary == "entry" ] |>
  (\(x){ x[order(x)]})()

# select the exits in order

exits <- primaryBoundary$EFFDT[primaryBoundary$boundary == "exit" ] |>
  (\(x){ x[order(x)]})()

lapply(1:length(entries), function(x) {
  
  segments(
    x0 = as.Date(entries[x]), 
    y0 = 1.05,
    x1 = as.Date(exits[x]),
    y1 = 1.05,
    lwd = 1.05,
    col = "pink"
    
    
  )
  
})

segments(x0 = as.Date(entries[1]), 
           y0 = 1.05,
         x1 = as.Date(exits[1]),
           y1 = 1.05,
         lwd = 1.05,
         col = "pink")

# seems like I can use this as a test
# plot the exited lines as well
# look for a continuous duration

# let's do it for all the kinds of breaks

theBoundaries <- lapply(c("primary", "break", "leave"), function(x) {
  
  boundaryData <- timeLine2[timeLine2$boundary_type == x & !is.na(timeLine2$boundary_type),]

  
})
names(theBoundaries) <- c("primary", "break", "leave")

# extract entries and exits in order per boundary

startAndstop <- lapply(theBoundaries, function(theData){ 

returnList <- lapply(c("entry", "exit"), function(x) {
  
  if(x %in% theData$boundary) {
dates <-  theData$EFFDT[theData$boundary == x ] |>
    (\(b){ b[order(b)]})();
return(dates)
} else {
  return(NULL) 
  } 

})

  names(returnList) <-  c("entry", "exit")
  return(returnList)
  
})


# this is a worthwhile output by itself
# I'd want a second function that will plot it

# And, of course, manage concurrent jobs (!)

# time to make this into a
# a
# it's own function

# let's make it as granular as possible -- for a single PI

# and this is a buncha list o'lists

# missing the merge with actionFrame; gotta do it befor or after

piSegments <- function(data, plotMap) {
  
  # This returns a list of break types per PI
  # with the "entry" and "exit" dates
  
  # where "data" is the journeyData of a single PI
  
  
  # first, merge plotMap
  
  data <- merge(data, plotMap, by = "ACTION", all.x = TRUE)
  
  # first, separate into the different boundary types
  
  boundaries <- c("primary","break","leave")
  boundaryEvents <- c("entry","exit")
  
  journeyByBoundary <- lapply(boundaries, function(x) {
    boundaryData <- data[data$boundary_type == x & !is.na(data$boundary_type),]
  })
  names(journeyByBoundary) <- boundaries
  
  # second, extract entry and exit dates
  
  startAndstop <- lapply(journeyByBoundary, function(theData){ 
    
    returnList <- lapply(boundaryEvents, function(x) {
      
      if(x %in% theData$boundary) {
        dates <-  theData$EFFDT[theData$boundary == x ] |>
          (\(b){ b[order(b)]})();
        return(dates)
      } else {
        return(NULL) 
      } 
      
    })
    
    names(returnList) <-  boundaryEvents
    return(returnList)
    
  })
  
  return(startAndstop)
  
}

# so far so good for singlePI's

# let's plot it I guess

plotJourney(data = journeyData[["single"]][journeyData[["single"]]$EMPLID == singlePIs[1],], plotMap = actionFrame)

segment2 <- piSegments(data = journeyData[["single"]][journeyData[["single"]]$EMPLID == singlePIs[2],], plotMap = actionFrame
                    )

segments(x0 = as.Date(segment2[["primary"]][["entry"]][1]),
         y0 = 0.95,
         x1 = as.Date(segment2[["primary"]][["exit"]][1]),
         y1 = 0.95,
         lwd = 0.7,
         col = "red"
)  
  
segments(x0 = as.Date(segment2[["primary"]][["entry"]][2]),
         y0 = 0.95,
         x1 = as.Date(segment2[["primary"]][["exit"]][2]),
         y1 = 0.95,
         lwd = 0.7,
         col = "red"
)    

# well, let's .... shouldn't be too bad

plotJourney(data = journeyData[["single"]][journeyData[["single"]]$EMPLID == singlePIs[2],], plotMap = actionFrame)

lapply(segment2, function(bobble) {lapply(1:length(bobble[["entry"]]), function(line_segment){ 
  
  if(length(bobble[["entry"]])>0 ){
  
  segments(x0 = as.Date(bobble[["entry"]][line_segment]),
           y0 = 0.95,
           x1 = as.Date(bobble[["exit"]][line_segment]),
           y1 = 0.95,
           lwd = 1.2,
           col = "dodgerblue")
  } else {NULL}
  
  })}) 

# maybe I want a loop after all

# man I'm dragging my feet on this one.

# EMPL_RCD

# should 

#####
#####

# Thoughts, 7.22.2025

# So this is what I have:
#  - An internal validity check that compares "entries" to "exits"
#  - A formula that tallies up "entries" and "exits"
#  - A visualization that shows individual actions, including "entries" and "exits"
#  - A formula that extracts "entries" and "exits" per individual

#  - An idea to test whether intervals between entry/exit overlap

# This is the situation I have / the data available:
#  - Many employees have a single job at a time, making headcount calculation straightforward
#  - Many employees have multiple concurrent jobs, indicated by EMPL_RCD,
#    but in a way that is inconsistent
#  - ACTION and ACTION_REASONs that describe these, but again in a way that's inconsistent

# What I'd like to do:
#  - Find a way to test the concurrent jobs for consistency and re-align
#    when the EMPL_RCD shifts meaning

# What I think I'll do:
#  - Iteratively, improving on all of these:
#    - Assign entry/exit to the 184 ACTION/ACTION_REASONS
#    - Examine graphically
#    - Toggle rule assignment
#    - Toggle internal validity checks


# This is what I don't have:
#  - Management of XFR/ transfers or promotions (DO THIS NEXT)

# First, let's assign entry/exit via function

# I might maybe should just go to building a shiny app so I can look through these quicker.

# look at fewPIs[6]
# The termination for the second job (EMPL_RCD ==1) is after the termination for the EMPL_RCD == 0 job.


# So one thing I can do, is, if they ADD a job, then have another column which is a counter.
# The counter starts at 1, and then goes to 2 for the second, or third etc job.  Then it counts down for every
# exit.  And only when it goes to 0 do I get a "primary" exit.

# This is actually kind of complicated logic to do this.
# And it's slow-going to iterate on it.
# Do I simply put all these formulas in one Shiny app and get to work?

# The difficulty is that I have a simple "merge" to the actionReasonFrame
# I'm going to need more complicated logic than that, and fewPIs[6] is a great test case.

extractJourneyIntervals(data = journeyData[["conc"]][journeyData[["conc"]]$EMPLID == fewPIs[6],], plotMap = assignBoundaries(actionReasonFrame) )

# this doesn't break down entry/exits by EMPL_RCD
# but what is crazy is that it kinda doesn't matter because EMPL_RCD
# is not persistent.




data6 <- journeyData[["conc"]][journeyData[["conc"]]$EMPLID == fewPIs[6],]
timeline6 <- merge(data6, assignBoundaries(actionReasonFrame), by = c("ACTION", "ACTION_REASON") , all.x = TRUE)

# ok, let's work on the logic to tally the jobs

# first, journeyData is extracted per EMPLID
# then, +1 for a primary ENTRY and -1 for a primary EXIT
# then... I sum up per EMPLID?

# One goal is to develop a rule than I can ascribe "enter" or "exit"
# to a row


# one thing I can do is fail to note an "entry" if the action_reason is HCJ
# which makes me wonder, do I ever have an HCJ --before-- a rehire?
# similar to how I have a termination in the concurrent job AFTER
# the termination in the 'main' (?) job

# this is where the intervals might get useful

> unique(jData.o[jData.o$ACTION %in% c("HIR","REH") ,c("ACTION","ACTION_REASON", "ACTION_REASON_DESCR")])
ACTION ACTION_REASON            ACTION_REASON_DESCR
8220       REH           REH                         Rehire
8506       REH           ASN Rehire New/Continuing Assignmt
8538       REH           RCJ          Rehire Concurrent Job
8785       REH           FYB                 FY BRASS (SYS)
15439      HIR           HCJ            Hire Concurrent Job
15442      HIR           NHR                       New Hire
15896      HIR           CNV                     Conversion
42705      HIR           REI                         Rehire
1072457    HIR           TRN                        Trainee

> table(jData.o[jData.o$ACTION %in% c("HIR","REH") ,c("ACTION_REASON","ACTION")])
ACTION
ACTION_REASON    HIR    REH
ASN      0  10970
CNV   8694      0
FYB      0   1673
HCJ  42174      0
NHR 150317      0
RCJ      0    667
REH      0  90017
REI      1      0
TRN      1      0

# there's a lot, and it's not just HCJ... you've got an RCJ and an ASN !
# just when I though it was safe to go back in the water!


# Seems like I could pull out the data per EmPL_RCD
# ...but remember, it's not consistent.

View(timeline6[timeline6$EMPL_RCD !=0,])

# I might need to make use of TRANSFER
# so I have an accurate headcount per job title and department

# And this is a pretty big request..
# I need to use the entry/exit boundary actions,
# and then I need to selectively ERASE them


# OK---

# This is going to work in two steps.
# First, I apply the boundaries
# Then, I break each one out by EMPL_RCD
# Then, I assign the new boundary values according
# to logic from the EMPL_RCD break down, where a date is 
# checked to see if it's between the values for the others

timeline6 <- timeline6[order(timeline6$EFFDT),]

timeline6[,c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]


timeline6[timeline6$EMPL_RCD == 0,c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]
timeline6[timeline6$EMPL_RCD == 1,c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]

# I mean, it kinda makes sense as far as logic..
# but hard to break down

timeline6[timeline6$boundary_type == "primary" & !is.na(timeline6$boundary_type),c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]
timeline6[timeline6$boundary_type == "primary" & !is.na(timeline6$boundary_type) & timeline6$EMPL_RCD == 0,c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]
timeline6[timeline6$boundary_type == "primary" & !is.na(timeline6$boundary_type) & timeline6$EMPL_RCD == 1,c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]

# ok, let's see if I can step through this

base_primary <- timeline6[timeline6$boundary_type == "primary" & !is.na(timeline6$boundary_type),c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]
zero_primary <- timeline6[timeline6$boundary_type == "primary" & !is.na(timeline6$boundary_type) & timeline6$EMPL_RCD == 0,c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]
one_primary <- timeline6[timeline6$boundary_type == "primary" & !is.na(timeline6$boundary_type) & timeline6$EMPL_RCD == 1,c("EFFDT","ACTION","ACTION_REASON","boundary_type","boundary")]


base_primary$boundary_type_adj <- NA
base_primary$boundary_adj <- NA

base_primary[1, c("EFFDT")] # This is action_reason NHR ("New Hire"), so it's always safe
compDate <- base_primary[2, c("EFFDT")]

# ugh this is EXHAUSTING
# really wanna make this a graph database

# ok, so this is boundary = "exit"
# so I need to see if it is BETWEEN boundaries for the other EMPL_RCD

# I'm getting really close to making my intervals again

compDate > one_primary$EFFDT[1] FALSE

# man this is eating me up
# In this case, I simply

# nah, I gotta make intervals
# I think it's the only way

# I think "reshape" is the way to go.
# always a fun command.

reshape(data = one_primary,direction = "wide", time.var = "boundary", v.names = "ACTION")


reshape(
  one_primary,
  timevar = "boundary",      # this becomes the new column names
  idvar = "boundary_type",   # this identifies which rows belong together
  direction = "wide"
)

# except I don't have an idvar, so this simply won't work.

oneEvents <- data.frame(entry = one_primary$EFFDT[order(one_primary$EFFDT) & one_primary$boundary == "entry"],  
                            exit = one_primary$EFFDT[order(one_primary$EFFDT) & one_primary$boundary == "exit"]
                            )

zeroEvents <- data.frame(entry = zero_primary$EFFDT[order(zero_primary$EFFDT) & zero_primary$boundary == "entry"],  
                         exit = zero_primary$EFFDT[order(zero_primary$EFFDT) & zero_primary$boundary == "exit"]
)

# ok, starting to feel more optimistic

baseEvents <- data.frame(entry = base_primary$EFFDT[order(base_primary$EFFDT) & base_primary$boundary == "entry"],  
                         exit = base_primary$EFFDT[order(base_primary$EFFDT) & base_primary$boundary == "exit"]
)

# here Chat:

baseEvents$univ_exit <- TRUE
baseEvents$univ_entry <- TRUE

for (i in seq_len(nrow(baseEvents))) {
  this_exit <- baseEvents$exit[i]
  
  # Look for other rows (not the current one) that have:
  #  entry <= this_exit AND exit > this_exit
  active_elsewhere <- baseEvents$entry[-i] <= this_exit & baseEvents$exit[-i] > this_exit
  
  if (any(active_elsewhere)) {
    baseEvents$univ_exit[i] <- FALSE
  }
}

baseEvents$univ_entry <- TRUE

for (i in seq_len(nrow(baseEvents))) {
  this_entry <- baseEvents$entry[i]
  
  # Look for other rows (not the current one) that have:
  #  exit <= this_entry AND entry > this_entry
  active_elsewhere <- baseEvents$exit[-i] <= this_entry & baseEvents$entry[-i] > this_entry
  
  if (any(active_elsewhere)) {
    baseEvents$univ_entry[i] <- FALSE
  }
}

# wow, this might be it.

# Now I need to modify the original or put this information back in

# I don't want to over-write it, so I'll make a new version

theEntry <- merge(base_primary, baseEvents[,c("entry", "univ_entry")], by.x = "EFFDT", by.y = "entry", all.x = TRUE)
theAll <- merge(theEntry, baseEvents[,c("exit","univ_exit")], by.x = "EFFDT", by.y = "exit", all.x = TRUE)

# can't merge; it causes row explosion because of multiple actions on the same date
# and merging by date is bad practice anyway.

# This is what Chat coughed up:

# Start by initializing the columns with NA
base_primary$univ_entry <- NA
base_primary$univ_exit  <- NA

# Assign TRUE for univ_entry when:
# - boundary is "entry"
# - EFFDT is in baseEvents$entry[baseEvents$univ_entry == TRUE]
entry_match <- base_primary$boundary == "entry" & 
  base_primary$EFFDT %in% baseEvents$entry[baseEvents$univ_entry]

base_primary$univ_entry[entry_match] <- TRUE

# Assign TRUE for univ_exit when:
# - boundary is "exit"
# - EFFDT is in baseEvents$exit[baseEvents$univ_exit == TRUE]
exit_match <- base_primary$boundary == "exit" & 
  base_primary$EFFDT %in% baseEvents$exit[baseEvents$univ_exit]

base_primary$univ_exit[exit_match] <- TRUE

# ok, nice!
# now I need to turn these many steps into a formula
# and I'll worry about break and leave another day


