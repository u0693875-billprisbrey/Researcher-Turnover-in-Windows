# Query sandbox for regimes
# 8.25.2025

# I'd like to develop different queries for the different regimes.

# In the first place, I'd like to divide--
# "Exclusive" and "Concurrent" employees

# Here's the full queries:

#################
## FUL QUERIES ##
#################

# Obtain journey data

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), 
                         Driver = "Oracle in OraClient19Home1", 
                         # Host = "ocm-campus01.it.utah.edu", 
                         # SVC = "biprodusr.sys.utah.edu",
                         DBQ = "//ocm-campus01.it.utah.edu:2080/biprodusr.sys.utah.edu",
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

# I want to do as much of this logic as I can in SQL

recordsPerEMPLID <- aggregate(EMPL_RCD ~ EMPLID, data = journeyData, function(x){length(unique(x))})
actionsPerEMPLID <- aggregate(ACTION ~ EMPLID, data = journeyData, function(x)(paste(unique(x), collapse = ", ")) )
actionReasonsPerEMPLID <- aggregate(ACTION_REASON ~ EMPLID, data = journeyData, function(x)(paste(unique(x), collapse = ", ")) )

journeyPopulation_pre <- merge(recordsPerEMPLID, actionsPerEMPLID, by = "EMPLID")

journeyPopulation <- merge(journeyPopulation_pre, actionReasonsPerEMPLID, by = "EMPLID")

journeyPopulation_prosaic <- journeyPopulation

# PROSAIC
journeyPopulation_prosaic$PI <- ifelse(journeyPopulation$EMPLID %in% prepData$PROPOSAL_PI_EMPLID,"PI","not_PI")

journeyPopulation_prosaic$hcj <- ifelse(grepl("HCJ|RCJ", journeyPopulation_prosaic$ACTION_REASON), "hcj","not_hcj")

journeyPopulation_prosaic$singleRCD <- ifelse(journeyPopulation_prosaic$EMPL_RCD == 1, "single_rcd","mult_rcd")

journeyPopulation_prosaic$exclusiveJob <- ifelse(journeyPopulation_prosaic$hcj == "not_hcj" & journeyPopulation_prosaic$singleRCD == "single_rcd", "exclusive", "concurrent")

journeyPopulation_prosaic$workbreak <- ifelse(grepl("SWB|RWB", journeyPopulation_prosaic$ACTION), "wb","not_wb")

journeyPopulation_prosaic$leave <- ifelse(grepl("RFL|LOA|LTO|PLA", journeyPopulation_prosaic$ACTION), "leave","not_leave")

########################
## BUILDING THE LOGIC ##
########################

perEmplidQuery <- "
SELECT
EMPLID,
COUNT(DISTINCT EMPL_RCD) AS records_per_emplid,
LISTAGG(DISTINCT ACTION, ', ') WITHIN GROUP (ORDER BY ACTION) AS actions_per_emplid
FROM ds_hr.EMPL_AGE_RANGE_ACTION_MV_V
WHERE EFFDT < DATE '2025-08-01'
GROUP BY EMPLID;
"

startTime <- Sys.time()
perEmplidData <- dbGetQuery(con.ds, perEmplidQuery)
endTime <- Sys.time()
endTime-startTime # 6.8min  # lengthy but bearabple

# that looks pretty good, actually

journeyPopulationQuery <- "
SELECT
    EMPLID,
    COUNT(DISTINCT EMPL_RCD) AS records_per_emplid,
    LISTAGG(DISTINCT ACTION, ', ') WITHIN GROUP (ORDER BY ACTION) AS actions_per_emplid,
    LISTAGG(DISTINCT ACTION_REASON, ', ') WITHIN GROUP (ORDER BY ACTION_REASON) AS action_reasons_per_emplid
FROM ds_hr.EMPL_AGE_RANGE_ACTION_MV_V
WHERE EFFDT < DATE '2025-08-01'
GROUP BY EMPLID;
"

startTime <- Sys.time()
populationData <- dbGetQuery(con.ds, journeyPopulationQuery)
endTime <- Sys.time()
endTime-startTime # Time difference of 13.56063 mins  # long enough to be inconvenient

journeyPopulationQuery <- "
WITH agg AS (
    SELECT
        EMPLID,
        COUNT(DISTINCT EMPL_RCD) AS records_per_emplid,
        LISTAGG(DISTINCT ACTION, ', ') WITHIN GROUP (ORDER BY ACTION) AS actions_per_emplid,
        LISTAGG(DISTINCT ACTION_REASON, ', ') WITHIN GROUP (ORDER BY ACTION_REASON) AS action_reasons_per_emplid
    FROM ds_hr.EMPL_AGE_RANGE_ACTION_MV_V
    WHERE EFFDT < DATE '2025-08-01'
    GROUP BY EMPLID
)
SELECT
    EMPLID,
    records_per_emplid,
    actions_per_emplid,
    action_reasons_per_emplid,

    -- hcj flag
    CASE
        WHEN REGEXP_LIKE(action_reasons_per_emplid, '(HCJ|RCJ)') THEN 'hcj'
        ELSE 'not_hcj'
    END AS hcj,

    -- single vs multiple EMPL_RCDs
    CASE
        WHEN records_per_emplid = 1 THEN 'single_rcd'
        ELSE 'mult_rcd'
    END AS singleRCD,

    -- exclusive vs concurrent
    CASE
        WHEN NOT REGEXP_LIKE(action_reasons_per_emplid, '(HCJ|RCJ)')
             AND records_per_emplid = 1
        THEN 'exclusive'
        ELSE 'concurrent'
    END AS exclusiveJob,

    -- work break flag
    CASE
        WHEN REGEXP_LIKE(actions_per_emplid, '(SWB|RWB)') THEN 'wb'
        ELSE 'not_wb'
    END AS workbreak,

    -- leave flag
    CASE
        WHEN REGEXP_LIKE(actions_per_emplid, '(RFL|LOA|LTO|PLA)') THEN 'leave'
        ELSE 'not_leave'
    END AS leave

FROM agg;
"


startTime <- Sys.time()
journeyPopulationData <- dbGetQuery(con.ds, journeyPopulationQuery)
endTime <- Sys.time()
endTime-startTime # Time difference of 18.39033 mins

# This actually mimics my EDA almost perfectly -- one extra person in the query population for some reason.

# Ok, now let's take the next step -- I only want to query "concurrent" jobs


concurrentJourneyQuery <- "
WITH agg AS (
    SELECT
        EMPLID,
        COUNT(DISTINCT EMPL_RCD) AS records_per_emplid,
        LISTAGG(DISTINCT ACTION, ', ') WITHIN GROUP (ORDER BY ACTION) AS actions_per_emplid,
        LISTAGG(DISTINCT ACTION_REASON, ', ') WITHIN GROUP (ORDER BY ACTION_REASON) AS action_reasons_per_emplid,

        -- derive exclusiveJob here
        CASE
            WHEN NOT REGEXP_LIKE(LISTAGG(DISTINCT ACTION_REASON, ', '), '(HCJ|RCJ)')
                 AND COUNT(DISTINCT EMPL_RCD) = 1
            THEN 'exclusive'
            ELSE 'concurrent'
        END AS exclusiveJob
    FROM ds_hr.EMPL_AGE_RANGE_ACTION_MV_V
    WHERE EFFDT < DATE '2025-08-01'
    GROUP BY EMPLID
)
SELECT j.*
FROM ds_hr.EMPL_AGE_RANGE_ACTION_MV_V j
JOIN agg a
  ON j.EMPLID = a.EMPLID
WHERE j.EFFDT < DATE '2025-08-01'
  AND a.exclusiveJob = 'concurrent';
"

startTime <- Sys.time()
concurrentJourney <- dbGetQuery(con.ds, concurrentJourneyQuery)
endTime <- Sys.time()
endTime-startTime # Time difference of 48.14251 mins

# This should take roughly 18min to define then 40min to run. # Eh, close.
# I should be able to start running these as background jobs so I can use my console.

# I'll need to start experimenting with that.

# I'll create a background job that creates two data sets, concurrentJourney and exclusiveJourney,
# and run these in the background.


# Lets get to there, and then working up dividing my jobs.


