# Developing queries for HR journey data
# 6.23.2025


# All distinct values

# Obtain age data

keyring::keyring_unlock(keyring = "BIPR", password = "Excelsior!")

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), 
                         Driver = "oracle", 
                         Host = "ocm-campus01.it.utah.edu", 
                         SVC = keyring::key_list(keyring = "BIPR")[1, 1],
                         UID = keyring::key_list(keyring = "BIPR")[1, 2],
                         PWD = keyring::key_get(keyring = "BIPR", 
                                                service = keyring::key_list(keyring = "BIPR")[1,1]),
                         Port = 2080)

journeyQuery <- "select * from ds_hr.EMPL_AGE_RANGE_ACTION_MV_V" # a view of that same query

journeyData <- dbGetQuery(con.ds, journeyQuery)


actionQuery <- "
SELECT DISTINCT 
       ACTION,
       ACTION_DESCR
from ds_hr.EMPL_AGE_RANGE_ACTION_MV_V
"

actionValues <- dbGetQuery(con.ds, actionQuery)

reasonQuery <- "
SELECT DISTINCT
       ACTION_REASON,
       ACTION_REASON_DESCR
FROM
      ds_hr.EMPL_AGE_RANGE_ACTION_MV_V  
"

reasonValues <- dbGetQuery(con.ds, reasonQuery)

actionReasonQuery <- "
SELECT DISTINCT
       ACTION,
       ACTION_DESCR,
       ACTION_REASON,
       ACTION_REASON_DESCR
FROM
      ds_hr.EMPL_AGE_RANGE_ACTION_MV_V 

"


actionReasonValues <- dbGetQuery(con.ds, actionReasonQuery)


actionReasonQuery2 <- "
SELECT
  ACTION,
  ACTION_DESCR,
  ACTION_REASON,
  ACTION_REASON_DESCR,
  COUNT(*) AS count
FROM
  ds_hr.EMPL_AGE_RANGE_ACTION_MV_V
WHERE
  EFFDT <= DATE '2025-06-01'
GROUP BY
  ACTION,
  ACTION_DESCR,
  ACTION_REASON,
  ACTION_REASON_DESCR
ORDER BY
  count DESC
"

actionReasonV2 <- dbGetQuery(con.ds, actionReasonQuery2)

# honestly I kinda like it.

# how do I manage the introduction of a new value?  Seems like I should be able to use
# some kind of double-check.

# Next, I'd like to score each of these myself



