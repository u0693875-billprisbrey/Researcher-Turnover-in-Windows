# Flowchart Sandbox

# The purpose of this is to develop a flowchart of
# how EMPLID's are divided to calculate headcount

library(flowchart)

safo |> 
  as_fc(label = "Patients assessed for eligibility") |>
  fc_filter(!is.na(group), label = "Randomized", show_exc = TRUE) |>
  fc_split(group) |> 
  fc_split(itt) |>
#  fc_filter(itt == "Yes", label = "Included in intention-to-treat\n population") |>
#  fc_filter(pp == "Yes", label = "Included in per-protocol\n population") |> 
  fc_draw()

# ok, shouldn't be too crazy.

# I need one row per EMPLID
# I need a column that describes whether they have concurrent jobs or not
# I need a column that describes whether they are a PI or not
# If they have a leave event
# If they have a work break even
# If they have a rehire event

# Almost tempted to do this right from the query

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

recordsPerEMPLID <- aggregate(EMPL_RCD ~ EMPLID, data = journeyData, function(x){length(unique(x))})
actionsPerEMPLID <- aggregate(ACTION ~ EMPLID, data = journeyData, function(x)(paste(unique(x), collapse = ", ")) )

dupeRCD <- recordsPerEMPLID |> (\(x){x[x$EMPL_RCD > 1, "EMPLID", drop = TRUE]})()  
singleRCD <- unique(journeyData$EMPLID)[!unique(journeyData$EMPLID) %in% dupeRCD]

# proportions(c(length(dupeRCD),length(singleRCD))) # 0.181 0.819

journeySingleFilter <- journeyData$EMPLID %in% singleRCD & journeyData$EMPL_RCD == 0 & (!journeyData$ACTION_REASON %in% "HCJ")

# this filter actually sux, because it's per-row filtering out HCJ.  It's not filtering out
# employees who have never had an HCJ action.

hcjEMPLIDs <- actionsPerEMPLID$EMPLID[grepl("HCJ", actionsPerEMPLID$ACTION)] 
breakEMPLIDs <- actionsPerEMPLID$EMPLID[grepl("SWB|RWB", actionsPerEMPLID$ACTION)]
leaveEMPLIDs <- actionsPerEMPLID$EMPLID[grepl("RFL|LOA|LTO|PLA", actionsPerEMPLID$ACTION)]

journeyPopulation <- merge(recordsPerEMPLID, actionsPerEMPLID, by = "EMPLID")

journeyPopulation$hcj <- grepl("HCJ|RCJ", actionsPerEMPLID$ACTION)
journeyPopulation$singleRCD <- journeyPopulation$EMPL_RCD == 1
journeyPopulation$singleJob <- !journeyPopulation$hcj & journeyPopulation$singleRCD
journeyPopulation$workbreak <- grepl("SWB|RWB", actionsPerEMPLID$ACTION)
journeyPopulation$leave <- grepl("RFL|LOA|LTO|PLA", actionsPerEMPLID$ACTION)

journeyPopulation |>
  as_fc(label = "Workforce population") |>
#  fc_filter(!is.na(group), label = "Randomized", show_exc = TRUE) |> # should be PI population
#  fc_filter(!singleJob, label = "Concurrent jobs", show_exc = TRUE) |>
  fc_split(singleJob, label = "No concurrent jobs") |> 
  fc_split(workbreak, label = "work break") |>
  fc_split(leave, label = "leave") |>
  #  fc_filter(itt == "Yes", label = "Included in intention-to-treat\n population") |>
  #  fc_filter(pp == "Yes", label = "Included in per-protocol\n population") |> 
  fc_draw()


journeyPopulation |>
  as_fc(label = "Workforce population") |>
  fc_split(singleJob, label = c("Concurrent jobs", "No concurrent jobs"), bg_fill = "ivory") |> 
  fc_split(workbreak, label = c("No work break", "Work break"), bg_fill = "mintcream") |>
  fc_split(leave, label = c("No leave", "leave"), bg_fill = "plum1") |>
  fc_draw()

# it's beautiful
# I should color coordinate with the other graphics
# And I'm really going to need to see the PI population
# And I need consistency in my actions that are used to define leave and stuff





