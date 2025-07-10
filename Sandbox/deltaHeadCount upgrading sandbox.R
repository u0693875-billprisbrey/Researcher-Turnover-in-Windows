# Upgrading delta head count sandox
# 7.9.2025

# The difficulty is that I now have multiple rows per PI
# with all kinds of things happening

# so do I get down to one row per PI with combinations of filtering and re-shaping?

# seems like my first task would be to select a dozen people--

# a half-dozen simple cases (hired/fired)
# three complex cases (hired/break/break/fired)
# three complex cases (hired/fired/rehired/fired)
# three very complex cases (hired/fired/rehired/leave/fired/rehired) etc

# Let's first identify these

# or, I'll start with the "primary" type (looks like I'm walking down filtering and re-shaping)

primaryJourney <- journeyData[journeyData$boundary_type == "primary" & !is.na(journeyData$boundary_type),]

# I don't like the core logic of one PI per row
# or maybe that's o.k. to duplicate a PI, because he's separated by time?

theDupes <- table(primaryJourney$EMPLID)

max(theDupes) # 25 # wow

# complex emplid: 00000651

# from the function

minDate <- ymd("2011-01-01")
maxDate <- ymd("2011-12-31")
calendar <- "day"
data <- primaryJourney

data[,"one"] <- 1

hrDates <- data.frame(EFFDT = seq(from = minDate, to = maxDate, by = calendar))
theActions <- aggregate(one ~ boundary+EFFDT, data = data, sum)

theActions$EFFDT <- as.Date(theActions$EFFDT)

hrDatio <- merge(hrDates, theActions[theActions$boundary == "exit",], by = "EFFDT", all.x = TRUE, sort=FALSE)
hrDatio2 <- merge(hrDatio, theActions[theActions$boundary == "entry",], by = "EFFDT", all.x = TRUE, sort=FALSE)

# Actually, I might have these updated.  I haven't put it through the validation paces but
# ...eh it looks right, right?

oats <- calculateMetrics(data = primaryJourney)

barley <- calculateMetrics(initial_date =ymd("2024-06-30"), data = primaryJourney)
# so this counts the cumulative delta from "2024-06-30" until the day before the min date, which is Jan 1
# of the current year as a default

wheat <- calculateMetrics(initial_count = 0, data = primaryJourney) # this is making more sense as a default


plotMetrics(list(oats = oats, grain = barley, wheat =wheat))

# looking really good

# Now I am -really- tempted to turn this into a Shiny app.  
# Put one more on there

# I wonder how quickly I could put one up.
# And, I wonder how useful it would be for my own exploration.

# Let's create a few graphics

# I could compare a few departments or job titles.
# I could also compare the different break types.

# I could also try to see an individual's path

researchTitles <- c("Research Associate", "UU Student - Research", "Volunteer Faculty")

lapply(researchTitles, function(x){calculateMetrics(initial_count = 0, 
                                                    calendar = "week", 
                                                    data = primaryJourney[primaryJourney$JOB_TITLE == x,]) }) |>
  plotMetrics()

calculateMetrics(initial_count = 0,
                 calendar = "week",
                 data = primaryJourney[primaryJourney$JOB_TITLE == researchTitles[3],]) |>
  plotMetrics()

# looks like I need some kind of a skip in case of an error so it plots everything else

table(primaryJourney$JOB_TITLE) |> (\(x){x[order(x, decreasing = TRUE)]})() |> (\(x){x[1:20]})()

UU Student - Other                      Custodian 
8525                           8071 
Health Care Assistant           Associate Instructor 
7499                           7280 
Graduate Teaching Assist (TA)                    GME Trainee 
6641                           6386 
UU Student - Admin/Clerical             Inpatient Nurse II 
5904                           5767 
Graduate Research Assist (RA)          UU Student - Research 
5703                           5407 
Hrly Research Assistant Grad Assist - Rsrch Focus (GR) 
5191                           4883 
UU Student - Instruction              Volunteer Faculty 
4747                           4688 
Student Research Asst            Medical Assistant I 
3421                           3161 
Patient Relations Specialist              Performing Artist 
2934                           2844 
Associate Instructor - Hourly            Classroom Assistant 
2824                           2744 

# some job families would be nice.

jobTitles <- c(#"Usher", 
               #"Clerk", 
               "Laborer", 
               "Office Assistant", 
               "Cashier", 
               "Administrative Assistant")


lapply(jobTitles, function(x){calculateMetrics(initial_count = 0, 
                                                    calendar = "week", 
                                                    data = primaryJourney[primaryJourney$JOB_TITLE == x,]) }) |>
  setNames(jobTitles) |>
  plotMetrics()

# that Cashier line looks kind of funny

# let's do departments

table(primaryJourney$DEPT_NAME) |> (\(x){x[order(x, decreasing = TRUE)]})() |> (\(x){x[1:50]})()

theDepts <- c("Athletics Department", 
              "Pediatric Administration", 
              "Pioneer Theatre Company", 
              "School of Computing", 
              "University Campus Store")

lapply(theDepts, function(x){calculateMetrics(initial_count = 0, 
                                               calendar = "week", 
                                               minDate = ymd("2015-05-17"),
                                              maxDate = ymd("2025-07-04"),
                                               data = primaryJourney[primaryJourney$DEPT_NAME == x,]) }) |>
  setNames(jobTitles) |>
  plotMetrics()

# unexpected error.  It's really struggling.

calculateMetrics(initial_count = 0,
                 calendar = "week",
                 data = primaryJourney[primaryJourney$DEPT_NAME == theDepts[1],]) |>
  plotMetrics()

# I've got something backwards   The rates (%) and delta (%) graph really don't make sense

calculateMetrics(initial_count = 0, minDate = ymd("2013-01-01"), maxDate = ymd("2025-07-04"), calendar = "quarter", data = primaryJourney) |> plotMetrics()

# and that's insane.  We've added 12,000 people over ten years?  Wow!
# so we've got something that looks just wrong.

# Ok, so what we have is . . .  . wrong.
# Let's take a closer look and walk through this

athleticsDept <- calculateMetrics(initial_count = 0,
                                  calendar = "week",
                                  data = primaryJourney[primaryJourney$DEPT_NAME == theDepts[1],])

dim(primaryJourney[primaryJourney$DEPT_NAME == theDepts[1],]) #5154 17 # that's a lot to look through

athleticsFilter <- primaryJourney$DEPT_NAME == theDepts[1]
ytdFilter <- primaryJourney$EFFDT <= ymd("2025-08-01") & primaryJourney$EFFDT >= ymd("2025-01-01")

length(unique(primaryJourney$EMPLID[athleticsFilter & ytdFilter])) # 296

View(primaryJourney[athleticsFilter & ytdFilter,])

# looks like I've tracked down the inversion ---
# because I am setting the initial amount at zero, then the signs aren't working
# and I often have a negative denominator (if I have a negative headcount)

# that doesn't explain why it doesn't start until March, even if the delta.cum *may* be right

calendar <- c("day","week","month","quarter","year")
athleticsDept <- lapply(calendar, function(x){calculateMetrics(initial_count = 0,
                                                               calendar = x,
                                                               data = primaryJourney[primaryJourney$DEPT_NAME == theDepts[1],])}) |>
  setNames(calendar)


# so the "week" is not wrong -- just incomplete
# weird

# I need to debug "week"


athleticsDept_NA <- lapply(calendar, function(x){calculateMetrics(initial_count = NA,
                                                               calendar = x,
                                                               data = primaryJourney[primaryJourney$DEPT_NAME == theDepts[1],])}) |>
  setNames(calendar)



# week is still correct -- just not showing anything before March
# And now that the denominator is correct, the % values in the bottom two graphs looks great

# not sure how this is handling the "cold start" problem
# and the answer is, not well --- the entire headcount should be shifted upwards because it will
# log exits for people that never were added.

# After I trouble-shoot "week", then I need to play with the expanded data set.

debugonce(calculateMetrics)

athleticsWeek <- calculateMetrics(initial_count = NA,
                                  calendar = "week",
                                  data = primaryJourney[primaryJourney$DEPT_NAME == theDepts[1],])


# I've got my hunch
# WHAMMO!  FIXED!  (And how did I not catch that earlier?  Oh well)

fullTermAthlete <- lapply(calendar, 
                          function(x){
                            calculateMetrics(calendar = x,
                                             minDate = ymd("2011-01-01"),
                                             maxDate = today(),
                                             data = primaryJourney[primaryJourney$DEPT_NAME == theDepts[1],]
                                             )
                          }
                          ) |> setNames(calendar)

# It's struggling to plot thisfor some reason. $ oh-- I didn't set the names!

debugonce(plotMetrics)

plotMetrics(fullTermAthlete[[1]])

# well
# interesting

# I need to look at the other types of boundaries as well

# but let's look at the full data set first

