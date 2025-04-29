# Retention Data Sandbox
# 4.25.2025

# This is a first look and cleaning of the data.

####################
## QUERY AND LOAD ##
####################

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), Driver = "oracle", Host = "ocm-campus01.it.utah.edu", 
                         SVC = keyring::key_list(keyring = "BIPR")[1, 1], UID = keyring::key_list(keyring = "BIPR")[1, 
                                                                                                                    2], PWD = keyring::key_get(keyring = "BIPR", service = keyring::key_list(keyring = "BIPR")[1, 
                                                                                                                                                                                                               1]), Port = 2080)
retentionQuery <- "
SELECT *
FROM VPR.D_PI_EMP_DT_VW EMP_DATES
"

retData <- dbGetQuery(con.ds,
                      retentionQuery)


DBI::dbDisconnect(con.ds)

source(here::here("Prep scripts","Adjusting prepData and loading things.R"))

####################
## HIRE TO REHIRE ##
####################

library(lubridate)

# This is the time between "hire date" and "re-hire date"
retData$hire <- time_length(interval(retData$HIRE_DT, retData$REHIRE_DT), unit = "year")

hist(retData$hire) # how do I include NA values?

# column for no rehire date
rect(xleft = 50, ybottom = 0, xright= 52.5, ytop = sum(is.na(retData$hire)), col = "tomato")
# It needs a label because it shoots 
# off the graph

# This is the time from initial hire to termination date

retData$full <- time_length(interval(retData$HIRE_DT, retData$TERMINATION_DT), unit = "year")

hist(retData$full) 

retData$rehire <- time_length(interval(retData$REHIRE_DT, retData$TERMINATION_DT), unit = "year")

hist(retData$rehire)

sum(is.na(retData$rehire)) # maybe put this in text in upper right?

# observations

# We have negative values for secondary "rehire" period
# This should be investigated

# I need to discover the active period when they are publishing
# ...is it during the initial hire, or secondary re-hire period?
# ...and it's during "full" if REHIRE is NA
# because sometimes the "initial" period looks like student work,
# and other times the "secondary" work looks like coming out of retirement

# So I can compare to the dates of proposing
# Or I can see if there are more columns/data that can align mutliple hire/separation dates

# But I'm just counting the "termination" dates, right?
# That's the only one that matters?

table(year(retData$TERMINATION_DT)) |>
  plot()

# I'd like a line plot

table(month(retData$TERMINATION_DT)) |>
  plot()

table(week(retData$TERMINATION_DT)) |>
  plot()

# Looks like July is a tricky year for academics

table(paste(year(retData$TERMINATION_DT), week(retData$TERMINATION_DT), sep = "-")) |>
  (\(x){ 
    x[names(x) != "NA-NA"]
    })() |>
  plot()


# ok, now--- how do I determine active count?  

# can I do that by month?
# can I do that by quarter?

activePI <- function(investigation.date,
                     target = "HIRE_DT",
                     data){
  
  intervalCondition <- investigation.date >= data[,target] & investigation.date <= data[,"TERMINATION_DT"]
  naCondition <- investigation.date >= data[,target] & is.na(data[,"TERMINATION_DT"])   
    
    
  activeCondition <- intervalCondition|naCondition
    

  
  return(activeCondition)
  
}

activePI(investigation.date = as.POSIXct("2010-01-01"),
                data = retData) |> table()

# o.k., there's something.
# it's definitely something


# let's create a week-by-week data frame over the period,
# then it has three columns-- "hire", "rehire", and "full"
# and each column has the number of active investigators.

# Except there's something about this I don't like.

turnover <- data.frame(termDT = seq(from = floor_date(min(retData$TERMINATION_DT, na.rm=TRUE),
                                                   "week",
                                                   week_start = 1),
                                  to = ceiling_date(
                                                     max(retData$TERMINATION_DT, na.rm=TRUE), "week", week_start = 1), 
                                 by = "1 week" ) )

activePI(investigation.date = turnover[1,1], data = retData) |> table()
activePI(investigation.date = turnover[500,1], data = retData) |> table()

# check
# View(retData[activePI(investigation.date = turnover[500,1], data = retData),])
# View(retData[!activePI(investigation.date = turnover[500,1], data = retData),])
#   In this second example, I should see people hired a long time ago and already terminated         
#   turns out using turnover[1,1] is at the edge of the data, just outside it
#    and using turnover[500,1] checks out.
# The SQL view that I'm pulling from looks like it was limited to people who were terminated 
#   after turnover[1,1]

#investigation.date <- turnover[500,1]
#checkCondition <- retData[,"HIRE_DT"] < investigation.date & investigation.date >= retData[,"TERMINATION_DT"] & !is.na(retData[,"TERMINATION_DT"])
#View(retData[checkCondition,])

turnover$hire <- sapply(turnover[,1], function(x){activePI(investigation.date = x, target = "HIRE_DT", data = retData) |> table() |> (\(x){x[2]})()  } )
turnover$rehire <- sapply(turnover[,1], function(x){activePI(investigation.date = x, target = "REHIRE_DT", data = retData) |> table() |> (\(x){x[2]})()  } )

plot(turnover$hire, ylim = c(0,1.05*max(turnover$hire)), cex=0.3)
points(turnover$rehire, col = "red", pch = 4, cex = 0.3)
# This is looking --- better.
# I'm not sure it's right yet, though


# Calculate and merge turn-over in

turnover$ywk <- paste(year(turnover$termDT), week(turnover$termDT), sep = "-")

terminated <- table(paste(year(retData$TERMINATION_DT), week(retData$TERMINATION_DT), sep = "-")) |>
  (\(x){ 
    x[names(x) != "NA-NA"]
  })() |>
  as.data.frame()
  
turnover <- merge(turnover, terminated, by.x = "ywk", by.y = "Var1", all.x = TRUE)
names(turnover)[names(turnover) == "Freq"] <- "exit"

# Check

investigation.date <- turnover[94,2]
View(retData[activePI(investigation.date = investigation.date, data = retData),])
  
# looks like the investigation.date is the START of the week
# so the day of the termination could happen after that day in that week
# I might want to adjust with this logic so it is week-ending, not week-starting.

# Let's take a look

plot(turnover$hire, ylim = c(0,1.05*max(turnover$hire)), cex=0.3)
points(turnover$rehire, col = "red", pch = 4, cex = 0.3)
points(turnover$exit, col ="blue", pch = 8, cex = 0.1)
  
# this really needs a second axis to plot the exit count

##########################
## CALCULATING TURNOVER ##
##########################

# This is going to be an "aggregation"

hire.mean <- aggregate(hire ~ paste(year(termDT), quarter(termDT), sep = "-"), data = turnover, mean)
exit.sum <- aggregate(exit ~ paste(year(termDT), quarter(termDT), sep = "-"), data = turnover, sum)

turnover_quarterly <- merge(hire.mean, exit.sum)
colnames(turnover_quarterly) <- c("yr.q", "hire_mean","exit_sum")

# I need to make this FISCAL YEAR

turnover_quarterly$to <- turnover_quarterly$exit_sum/turnover_quarterly$hire_mean

# let's get that into one
# aggregate(hire + exit ~ paste(year(termDT), quarter(termDT)), data = turnover, function(x)({c(mean(x),sum(x))}))
# too weird


# let's plot it

turnover_quarterly[,-1] |>
  scale() |>
  plot()

# hardy har
# I need to turn that into lines

turnover_quarterly[,-1] |>
  scale() |>
  (\(x){
    plot(1,
      ylim = c(min(x),max(x)),
    xlim = c(0,nrow(x)),
    type = "n"
    );
    invisible(apply(x, 2, lines))
  })()


# well there we go.
# let's make that graphic a little bit nicer and see
# if it passes the smell test.

# Also compare with my proposal data.

# And, then, y'know,
# I guess I need to create a function that will calculate
# this based on different categories?  Diff't colleges and clusters?


qt_sc <- turnover_quarterly[,-1] |>
  scale()

plot(1,
     ylim = c(min(qt_sc),max(qt_sc)),
     xlim = c(0,nrow(qt_sc)),
     type = "n",
     xaxt = "n",
     xlab = "",
     ylab = ""
)

lines(qt_sc[,1], col = "gray10")
lines(qt_sc[,3], col = "firebrick")

legend("topleft",
       legend = c("Active researchers","Turn-over"),
       col = c("gray10","firebrick"),
       lty = 1,
       lwd = 1.619)

mtext(side = 3,
      "Quarterly PI head-count and turnover\n(scaled)",
      line = 1.33,
      cex=1.3,
      font = 2)

ticks <- seq(from = 0, to = nrow(turnover_quarterly), length.out = 9)
axis(side = 1,
     at = ticks,
     las =2,
     labels = turnover_quarterly[ ,"yr.q"])

# Nice enought for Q&D and EDA.

# Now let's break this up by college and cluster
# And re-calculate by year

# Looks like I need to calculate the turn-over using lapply
# Then I can aggregate to different time intervals.



calculateTurnover <- function(data){
  
  # start with the empty data frame by week
  turnover <- data.frame(termDT = seq(from = floor_date(min(data[,"TERMINATION_DT"], na.rm=TRUE),
                                                        "week",
                                                        week_start = 1),
                                      to = ceiling_date(
                                        max(data[,"TERMINATION_DT"], na.rm=TRUE), "week", week_start = 1), 
                                      by = "1 week" ) )
  
  # populate with hire and re-hire head counts
  turnover$hire <- sapply(turnover[,1], function(x){activePI(investigation.date = x, target = "HIRE_DT", data = data) |> table() |> (\(x){x[2]})()  } )
  turnover$rehire <- sapply(turnover[,1], function(x){activePI(investigation.date = x, target = "REHIRE_DT", data = data) |> table() |> (\(x){x[2]})()  } )
  
  # calculate exits
  terminated <- table(paste(year(data[,"TERMINATION_DT"]), week(data[,"TERMINATION_DT"]), sep = "-")) |>
    (\(x){ 
      x[names(x) != "NA-NA"]
    })() |>
    as.data.frame()
  
  # merge exits into turnover
  turnover$yr.wk <- paste(year(turnover$termDT), week(turnover$termDT), sep = "-") 
  turnover <- merge(turnover, terminated, by.x = "yr.wk", by.y = "Var1", all.x = TRUE)
  names(turnover)[names(turnover) == "Freq"] <- "exit"
  
  # return the frame
  return(turnover)
  
}

# chatGPT version
calculateTurnover2 <- function(data) {
  
  # Ensure TERMINATION_DT is properly formatted
  term_dates <- data[,"TERMINATION_DT"]
  
  # Create the sequence of Mondays
  start_date <- floor_date(min(term_dates, na.rm = TRUE), "week", week_start = 1)
  end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "week", week_start = 1)
  
  turnover <- data.frame(termDT = seq(from = start_date, to = end_date, by = "1 week"))
  
  # Helper to count hires or rehires
  countActive <- function(date, target) {
    activePI(investigation.date = date, target = target, data = data) |> 
      table() |> 
      (\(x) if ("TRUE" %in% names(x)) x["TRUE"] else 0)()
  }
  
  # Populate hires and rehires
  turnover$hire   <- sapply(turnover$termDT, countActive, target = "HIRE_DT")
  turnover$rehire <- sapply(turnover$termDT, countActive, target = "REHIRE_DT")
  
  # Prepare exit counts
  exit_table <- table(paste(year(term_dates), week(term_dates), sep = "-"))
  exit_df <- as.data.frame(exit_table, stringsAsFactors = FALSE)
  exit_df <- exit_df[exit_df$Var1 != "NA-NA", ]  # Drop NA cases
  
  # Merge exits into turnover
  turnover$yr_wk <- paste(year(turnover$termDT), week(turnover$termDT), sep = "-")
  turnover <- merge(turnover, exit_df, by.x = "yr_wk", by.y = "Var1", all.x = TRUE)
  names(turnover)[names(turnover) == "Freq"] <- "exit"
  
  # Replace NA exits with 0
  turnover$exit[is.na(turnover$exit)] <- 0
  
  return(turnover)
}

# modified Chat to accommodate different intervals

calculateTurnover <- function(data, interval = "week") {
  
  # Ensure TERMINATION_DT is properly formatted
  term_dates <- data[,"TERMINATION_DT"]
  
  # Choose the floor and ceiling functions based on interval
  if (interval == "week") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "week", week_start = 1)
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "week", week_start = 1)
    by_seq     <- "1 week"
  } else if (interval == "month") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "month")
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "month")
    by_seq     <- "1 month"
  } else if (interval == "quarter") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "quarter")
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "quarter")
    by_seq     <- "3 months"
  } else if (interval == "semester") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "6 months")
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "6 months")
    by_seq     <- "6 months"
  } else if (interval == "year") {
    start_date <- floor_date(min(term_dates, na.rm = TRUE), "year")
    end_date   <- ceiling_date(max(term_dates, na.rm = TRUE), "year")
    by_seq     <- "1 year"
  } else {
    stop("Unsupported interval. Choose from: 'week', 'month', 'quarter', 'semester', 'year'.")
  }
  
  # Sequence of investigation dates
  turnover <- data.frame(termDT = seq(from = start_date, to = end_date, by = by_seq))
  
  # Helper to count hires or rehires
  countActive <- function(date, target) {
    activePI(investigation.date = date, target = target, data = data) |> 
      table() |> 
      (\(x) if ("TRUE" %in% names(x)) x["TRUE"] else 0)()
  }
  
  # Populate hires and rehires
  turnover$hire   <- sapply(turnover$termDT, countActive, target = "HIRE_DT")
  turnover$rehire <- sapply(turnover$termDT, countActive, target = "REHIRE_DT")
  
  # --- Exit calculation ---
  # Create interval labels for each termination date
  makeLabel <- function(dates) {
    if (interval == "week") {
      paste(year(dates), week(dates), sep = "-W")
    } else if (interval == "month") {
      paste(year(dates), month(dates), sep = "-M")
    } else if (interval == "quarter") {
      paste(year(dates), quarter(dates), sep = "-Q")
    } else if (interval == "semester") {
      sem <- ifelse(month(dates) <= 6, 1, 2)
      paste(year(dates), sem, sep = "-S")
    } else if (interval == "year") {
      as.character(year(dates))
    }
  }
  
  exit_labels <- makeLabel(term_dates)
  exit_table <- table(exit_labels)
  exit_df <- as.data.frame(exit_table, stringsAsFactors = FALSE)
  
  # Build labels for turnover sequence
  turnover$label <- makeLabel(turnover$termDT)
  
  # Merge exits into turnover
  turnover <- merge(turnover, exit_df, by.x = "label", by.y = "exit_labels", all.x = TRUE)
  names(turnover)[names(turnover) == "Freq"] <- "exit"
  
  # Replace NA exits with 0
  turnover$exit[is.na(turnover$exit)] <- 0
  
  # Calculate turnover
  turnover$to <- turnover[,"exit"]/turnover[,"hire"]
  
  return(turnover)
}

# dang that's impressive

# double-check quarterly

turnover_quarterly_check <- calculateTurnover(data = retData, interval = "quarter")

# I should plot these column by column

comparison_column <- c("hire_mean","hire")
plot(1, type = "n", ylim = c(-4,4), xlim = c(1,73))
lines(scale(turnover_quarterly[,comparison_column[1]]), col = "salmon3")
lines(scale(turnover_quarterly_check[,comparison_column[2]]), col = "seagreen2")
# essentially identical

comparison_column <- c("exit_sum","exit")
plot(1, type = "n", ylim = c(-4,4), xlim = c(1,73))
lines(scale(turnover_quarterly[,comparison_column[1]]), col = "salmon3")
lines(scale(turnover_quarterly_check[,comparison_column[2]]), col = "seagreen2")
# some times shifted, some times identical

comparison_column <- c("to","to")
plot(1, type = "n", ylim = c(-4,4), xlim = c(1,73))
lines(scale(turnover_quarterly[,comparison_column[1]]), col = "salmon3")
lines(scale(turnover_quarterly_check[,comparison_column[2]]), col = "seagreen2")
# some times shifted, some times identical

# so I need to re-visit how these interval periods 
# are being aggregated (start or finish of the period?)

# but once I figure that out, the new function looks very...
# functionable





# plot yearly
turnover_yearly <- calculateTurnover(data = retData, interval = "year")

yr_sc <- turnover_yearly[,-(1:2)] |>
  scale()

plot(1,
     ylim = c(min(yr_sc),max(yr_sc)),
     xlim = c(0,nrow(yr_sc)),
     type = "n",
     xaxt = "n",
     xlab = "",
     ylab = ""
)

lines(yr_sc[,1], col = "gray10")
lines(yr_sc[,3], col = "firebrick")

legend("topleft",
       legend = c("Active researchers","Turn-over"),
       col = c("gray10","firebrick"),
       lty = 1,
       lwd = 2.3)

mtext(side = 3,
      "Yearly PI head-count and turnover\n(scaled)",
      line = 1.33,
      cex=1.3,
      font = 2)

ticks <- seq(from = 0, to = nrow(turnover_yearly), by = 2)
axis(side = 1,
     at = ticks+1,
     las =2,
     labels = turnover_yearly[ticks+1 ,"label"])

# that's a rather alarming increase in turn-over
# and interesting that we aren't replacing researchers, 
# but money-per is going up

# and how do I have a value for 2026 somehow?




##########################
## MERGE RETENTION DATA ##
##########################

retData <- merge(prepData, retPropData[,c("PROPOSAL_PI_EMPLID", "HIRE_DT","REHIRE_DT","TERMINATION_DT")], by = "PROPOSAL_PI_EMPLID", all.x = TRUE)



######################
## CALCULATE PER PI ##
######################

piEmplid <- calculateWinRates(data = prepData, categoryColumn = "PROPOSAL_PI_EMPLID", functionList = list(mean = mean, median = median)) |> (\(x){ x[[1]] })()
# really starting to hate the list nature and why do I want "call" ?

piEmplid$count.total <- apply(piEmplid[,c("win.count","loss.count")], 1, sum, na.rm = TRUE )
piEmplid$sum.total <- apply(piEmplid[,c("win.sum","loss.sum")], 1, sum, na.rm = TRUE )





