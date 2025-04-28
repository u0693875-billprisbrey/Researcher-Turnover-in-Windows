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

source(here::here("Prep scripts","Adjusting prepData and loading things.R"))

####################
## HIRE TO REHIRE ##
####################

library(lubridate)

# This is the time between "hire date" and "re-hire date"
retData$initial <- time_length(interval(retData$HIRE_DT, retData$REHIRE_DT), unit = "year")

hist(retData$initial) # how do I includ NA values?

# column for no rehire date
rect(xleft = 50, ybottom = 0, xright= 52.5, ytop = sum(is.na(retData$initial)), col = "tomato")
# It needs a label because it shoots 
# off the graph

# This is the time from initial hire to termination date

retData$full <- time_length(interval(retData$HIRE_DT, retData$TERMINATION_DT), unit = "year")

hist(retData$full) 

retData$secondary <- time_length(interval(retData$REHIRE_DT, retData$TERMINATION_DT), unit = "year")

hist(retData$secondary)

sum(is.na(retData$secondary)) # maybe put this in text in upper right?

# observations

# We have negative values for "secondary"
# This should be investigated

# I need to discover the active period when they are publishing
# ...is it during the initial, or secondary?
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

# ok, now--- how do I determine active count?  

# can I do that by month?
# can I do that by quarter?

activePI <- function(time.period=NA, 
                     time.date=NA,
                     data){
  
  if(!is.na(time.date))
  activeCondition <- time.date >= data$HIRE_DT &
    time.date <= data$TERMINATION_DT
  
  return(activeCondition)
  
}

activePI(time.date = as.POSIXct("2010-01-01"),
                data = retData) |> table()

# o.k., there's something.
# it's definitely something


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





