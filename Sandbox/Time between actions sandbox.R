# Time between Actions Sandbox
# 9.2.2025

# PURPOSE:  To calculate the time between consecutive actions.
# I can delete anything prior to the maximum entry before 2013.
# Call it "unnecessary" or "forgettable."
# Maybe it's the maximum entry per EMPL_RCD?  I guess so.

# And maybe I can do a consecutive time between actions.

# Which one do I want to do?
# I think I'll do time between actions.

# First sort by EFFDT

concurrentJourney <- concurrentJourney[order(concurrentJourney$EFFDT), ]

# next extract into a list per EmPLID

theEMPLIDs <- unique(concurrentJourney$EMPLID)

perEMPLID <- lapply(theEMPLIDs, function(x) {y <- concurrentJourney[concurrentJourney$EMPLID == x,]; return(y) } )

# should I use "aggregate" to break this downs?

perEMPLID_RCD <- split(concurrentJourney, ~ EMPLID + EMPL_RCD )

# huh, that's a cool function

timeBetweenActions <- lapply(perEMPLID_RCD, function(x) {diff(x$EFFDT)}   )

# seems like I should summarize these now
# maybe an unsplit?

theMedian <- sapply(timeBetweenActions,median)

# > hist(log(unlist(theMedian)))
# > exp(4)
# [1] 54.59815
# > exp(2)
# [1] 7.389056
# > exp(6)
# [1] 403.4288

# roughly the mode of the median is 55 days

