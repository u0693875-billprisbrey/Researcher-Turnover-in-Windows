
# Test extract of all changed PI's
# This looked at the eAwards data and determined that the proposal ID's don't match

# Conducted before 4 July 2025

###########
## QUERY ##
###########

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

journeyQuery <- "select * from ds_hr.EMPL_AGE_RANGE_ACTION_MV_V WHERE EFFDT < TO_DATE('2025-06-30', 'YYYY-MM-DD') " # a view of that same query

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
  EFFDT <= DATE '2025-06-01'
GROUP BY
  ACTION,
  ACTION_DESCR,
  ACTION_REASON,
  ACTION_REASON_DESCR
ORDER BY
  count DESC
"

actionReasonFrame <- dbGetQuery(con.ds, actionReasonQuery)



piChangeQuery <- "select *
  from vpr.osp_eaward_pi_change_vw 
;
"

piChangeFrame <- dbGetQuery(con.ds, piChangeQuery)

# let's pull in the proposal data
# where was that again?



retentionAwardQuery <- "
SELECT * 
FROM VPR.OSP_AWARDS AWARDS
LEFT JOIN VPR.D_PI_EMP_DT_VW EMP_DATES 
ON EMP_DATES.PI_EMPLID = AWARDS.AWARD_PI_EMPLID
"

retentionProposalQuery <- "
SELECT * 
FROM VPR.OSP_PROPOSALS PROPOSALS
LEFT JOIN VPR.D_PI_EMP_DT_VW EMP_DATES 
ON EMP_DATES.PI_EMPLID = PROPOSALS.PROPOSAL_PI_EMPLID
" 

retentionQuery <- "
SELECT *
FROM VPR.D_PI_EMP_DT_VW EMP_DATES
"

retPropData <- dbGetQuery(con.ds,
                          retentionProposalQuery)

retAwardData <- dbGetQuery(con.ds,
                           retentionAwardQuery)

retData <- dbGetQuery(con.ds,
                      retentionQuery)

propQuery <- "
SELECT * 
FROM VPR.OSP_PROPOSALS PROPOSALS
"
propData <- dbGetQuery(con.ds, propQuery)


blubberQuery <- "SELECT A.EMPLID, A.EMPL_RCD, A.EFFDT, A.EFFSEQ
    , A.ACTION, B.ACTION_DESCR
    , A.ACTION_REASON, C.DESCR ACTION_REASON_DESCR, A.JOBCODE, E.DESCR JOB_TITLE
    , A.DEPTID, F.DESCR DEPT_NAME
    , Case when A.ACTION ! = 'TER' then ''
        when A.ACTION  = ('TER') 
        AND A.ACTION_REASON not in ('BNK', 'EVW', 'I9', 'INV', 'NER', 'RFN', 'RIF', 'RLS') 
        then 'Voluntary' else 'Involuntary' end VOLUNTARY_FLAG
    , Case    when (A.EFFDT-D.BIRTHDATE)/365.25 < 20
        then 'Under 20' 
    when (A.EFFDT-D.BIRTHDATE)/365.25 >= 20  and (A.EFFDT-D.BIRTHDATE)/365.25 < 30
        then '20s'
    when (A.EFFDT-D.BIRTHDATE)/365.25 >= 30  and (A.EFFDT-D.BIRTHDATE)/365.25  < 40
        then '30s'
    when (A.EFFDT-D.BIRTHDATE)/365.25 >= 40  and (A.EFFDT-D.BIRTHDATE)/365.25  < 50
        then '40s'
    when (A.EFFDT-D.BIRTHDATE)/365.25 >= 50  and (A.EFFDT-D.BIRTHDATE)/365.25 < 60
        then '50s'
    when (A.EFFDT-D.BIRTHDATE)/365.25 >= 60  and (A.EFFDT-D.BIRTHDATE)/365.25  < 70
        then '60s'
    when (A.EFFDT-D.BIRTHDATE)/365.25 >= 70  and (A.EFFDT-D.BIRTHDATE)/365.25 < 80
        then '70s'
    when (A.EFFDT-D.BIRTHDATE)/365.25 >= 80  and (A.EFFDT-D.BIRTHDATE)/365.25 < 90
        then '80s'
    else '90 and Above'
        end Age_Band
    , Case when LENGTH(A.JOBCODE) = 6
        AND A.JOBCODE NOT LIKE '7%'
        then 'UCareer Job Code'
        else ''
        end UCAREER_JOBCODE_FLAG
        
FROM PS_UU_UNSEC_JOB_VW A
    JOIN PS_ACTION_TBL B
        ON (B.ACTION = A.ACTION)
    JOIN PS_ACTN_REASON_TBL C
        ON (C.ACTION = A.ACTION
            AND C.ACTION_REASON = A.ACTION_REASON)
    JOIN ps_personal_dt_fst D
        ON (D.EMPLID = A.EMPLID)
    JOIN PS_JOBCODE_TBL E
        ON (E.JOBCODE = A.JOBCODE)
    JOIN PS_DEPT_TBL F
        ON (F.DEPTID = A.DEPTID)
        
WHERE  A.EFFDT > TO_DATE('2010-01-01','YYYY-MM-DD')
    
    AND B.EFFDT = (SELECT MAX(B_ED.EFFDT) 
        FROM PS_ACTION_TBL B_ED
        WHERE B.ACTION = B_ED.ACTION
        AND B_ED.EFFDT <= SYSDATE)
    AND C.EFFDT = (SELECT MAX(C_ED.EFFDT) 
        FROM PS_ACTN_REASON_TBL C_ED
        WHERE C.ACTION = C_ED.ACTION
        AND C.ACTION_REASON = C_ED.ACTION_REASON
        AND C_ED.EFFDT <= SYSDATE)
    AND E.EFFDT = (SELECT MAX(E_ED.EFFDT) 
        FROM PS_JOBCODE_TBL E_ED
        WHERE E.JOBCODE = E_ED.JOBCODE
        AND E_ED.EFFDT <= SYSDATE)         
    AND F.EFFDT = (SELECT MAX(F_ED.EFFDT) 
        FROM PS_DEPT_TBL F_ED
        WHERE F.DEPTID = F_ED.DEPTID
        AND F_ED.EFFDT <= SYSDATE)         

ORDER BY A.EMPLID, A.EMPL_RCD, A.EFFDT, A.EFFSEQ"

blubberData <- dbGetQuery(con.ds, blubberQuery)

# these proposal ID's don't match

clearyQuery <- "select
*
  from uuetl_fs.ps_uu_eawd_tbl_vw
order by proposal_id, transactionid
;"

clearData <- dbGetQuery(con.ds, clearyQuery)



DBI::dbDisconnect(con.ds)

