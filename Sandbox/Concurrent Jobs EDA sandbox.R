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
jData <- journeyData

# I should figure out how to incorporate this logic into a query

journeyData <- journeyData[!journeySingleFilter,]


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
