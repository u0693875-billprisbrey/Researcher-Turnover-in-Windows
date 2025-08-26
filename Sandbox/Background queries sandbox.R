# Background queries sandbox
# 8.25.2025


# PURPOSE:  This experiments with running queries as background jobs.

################
## CONNECTION ##
################

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), 
                         Driver = "Oracle in OraClient19Home1", 
                         # Host = "ocm-campus01.it.utah.edu", 
                         # SVC = "biprodusr.sys.utah.edu",
                         DBQ = "//ocm-campus01.it.utah.edu:2080/biprodusr.sys.utah.edu",
                         UID = Sys.getenv("userid"),
                         PWD = Sys.getenv("pwd"),
                         Port = 2080)

####################
## ACTION REASONS ##
####################

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

saveRDS(actionReasonFrame, here::here("Data","actionReasonFrame.rds"))