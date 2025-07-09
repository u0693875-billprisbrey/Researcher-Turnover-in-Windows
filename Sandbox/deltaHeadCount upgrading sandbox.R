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


