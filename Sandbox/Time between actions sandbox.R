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

# > timeBetweenActions[[20]]
# Time differences in days
# [1]   0 153  31 135  62  76 227  62 122  15 121
# [12]  16   8  22 472 243 533 943   0

# I'd like this as a column in perEMPLID_RCD

# let's try what Chat has

startTime <- Sys.time()
perEMPLID_RCD <- split(concurrentJourney, ~ EMPLID + EMPL_RCD, drop = TRUE)

# add a column per group
perEMPLID_RCD <- lapply(perEMPLID_RCD, function(df) {
  df <- df[order(df$EFFDT), ]  # ensure chronological order
  df$timeBetweenActions <- c(NA, diff(df$EFFDT))
  return(df)
})

# re-combine if you want a single dataframe again:
concurrentJourney_withDiff <- do.call(rbind, perEMPLID_RCD)
endTime <- Sys.time() # 13min

# When I have a "re-hire" with a long time gap -- isn't that interesting?
# Maybe I can use this to define rows I can trim

# I'm going to attempt to re-order

# Extract EMPLID and EMPL_RCD from the names
split_names <- names(perEMPLID_RCD)
emplid_part <- sub("\\..*", "", split_names)      # everything before the dot
rcd_part    <- sub(".*\\.", "", split_names)      # everything after the dot

# Create an order: first by EMPLID, then by EMPL_RCD
ordering <- order(emplid_part, as.numeric(rcd_part))

# Reorder the list
perEMPLID_RCD <- perEMPLID_RCD[ordering]

# I think this is worth saving
# Let's create a script for this, and save the data

# Having to save the data in a separate place from the script that generates it
# is complicating my file schema.

# I guess I have a "Data Creation Script" folder?

# Actually, what I do is add this to the creation of the regimes
# for "concurrentJourney.rds" and "exclusiveJourney.rds"

# and un-wind if I don't like it.

# I guess.



