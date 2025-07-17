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

actionFrame$shape_shape[actionFrame$boundary == "exit"] <- 13   
actionFrame$shape_shape[actionFrame$boundary == "entry"] <- 19   
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



