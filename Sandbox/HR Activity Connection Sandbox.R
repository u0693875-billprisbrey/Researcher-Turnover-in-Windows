# HR Activity Connection Sandbox
# 6.13.2025

# This is a test connection of the HR activity data

###########
## QUERY ##
###########

# Obtain HR data

keyring::keyring_unlock(keyring = "BIPR", password = "Excelsior!")

library(DBI)
con.ds <- DBI::dbConnect(odbc::odbc(), Driver = "oracle", Host = "ocm-campus01.it.utah.edu", 
                         SVC = keyring::key_list(keyring = "BIPR")[1, 1], UID = keyring::key_list(keyring = "BIPR")[1, 
                                                                                                                    2], PWD = keyring::key_get(keyring = "BIPR", service = keyring::key_list(keyring = "BIPR")[1, 
                                                                                                                                                                                                               1]), Port = 2080)

hrQuery <- 


"SELECT A.EMPLID, A.EMPL_RCD, A.EFFDT, A.EFFSEQ
    , A.ACTION, B.ACTION_DESCR
    , A.ACTION_REASON, C.DESCR ACTION_REASON_DESCR
    , Case when A.ACTION ! = 'TER' then ''
        when A.ACTION  = ('TER') 
        AND A.ACTION_REASON not in ('BNK', 'EVW', 'I9', 'INV', 'NER', 'RFN', 'RIF', 'RLS') 
        then 'Voluntary' else 'Involuntary' end VOLUNTARY_FLAG
    , Case    when (SYSDATE-D.BIRTHDATE)/365.25 < 20
        then 'Under 20' 
    when (SYSDATE-D.BIRTHDATE)/365.25 >= 20  and (SYSDATE-D.BIRTHDATE)/365.25 < 30
        then '20s'
    when (SYSDATE-D.BIRTHDATE)/365.25 >= 30  and (SYSDATE-D.BIRTHDATE)/365.25  < 40
        then '30s'
    when (SYSDATE-D.BIRTHDATE)/365.25 >= 40  and (SYSDATE-D.BIRTHDATE)/365.25  < 50
        then '40s'
    when (SYSDATE-D.BIRTHDATE)/365.25 >= 50  and (SYSDATE-D.BIRTHDATE)/365.25 < 60
        then '50s'
    when (SYSDATE-D.BIRTHDATE)/365.25 >= 60  and (SYSDATE-D.BIRTHDATE)/365.25  < 70
        then '60s'
    when (SYSDATE-D.BIRTHDATE)/365.25 >= 70  and (SYSDATE-D.BIRTHDATE)/365.25 < 80
        then '70s'
    when (SYSDATE-D.BIRTHDATE)/365.25 >= 80  and (SYSDATE-D.BIRTHDATE)/365.25 < 90
        then '80s'
    else '90 and Above'
        end Age_Band
        
FROM PS_UU_UNSEC_JOB_VW A
  JOIN PS_ACTION_TBL B
    ON (B.ACTION = A.ACTION
    AND B.EFFDT =
        (SELECT MAX(B_ED.EFFDT) FROM PS_ACTION_TBL B_ED
        WHERE B.ACTION = B_ED.ACTION
          AND B_ED.EFFDT <= SYSDATE))
  JOIN PS_ACTN_REASON_TBL C
    ON (C.ACTION = A.ACTION
     AND C.ACTION_REASON = A.ACTION_REASON
     AND C.EFFDT =
        (SELECT MAX(C_ED.EFFDT) FROM PS_ACTN_REASON_TBL C_ED
        WHERE C.ACTION = C_ED.ACTION
          AND C.ACTION_REASON = C_ED.ACTION_REASON
          AND C_ED.EFFDT <= SYSDATE))
    JOIN ps_personal_dt_fst D
        ON (D.EMPLID = A.EMPLID)
        
WHERE  A.EFFDT > TO_DATE('2010-01-01','YYYY-MM-DD')
    ORDER BY A.EMPLID, A.EMPL_RCD, A.EFFDT"

# testQuery <- "select * from ds_hr.EMPL_AGE_RANGE_ACTION_MV_V"


# hrData <- dbGetQuery(con.ds,
#                      hrQuery) # doesn't work

# testData <- dbGetQuery(con.ds, testQuery)

viewQuery <- "select * from ds_hr.EMPL_AGE_RANGE_ACTION_MV_V" # a view of that same query

hrData <- dbGetQuery(con.ds, viewQuery)


DBI::dbDisconnect(con.ds)


# here's me
hrData[hrData$EMPLID == "00693875",]

plot(table(hrData$ACTION))

unique(hrData[,c("ACTION","ACTION_DESCR")])

> unique(hrData[,c("ACTION","ACTION_DESCR")])
ACTION           ACTION_DESCR
1          HIR                   Hire
7          PLA  Paid Leave of Absence
1807       RET             Retirement
1808       PAY        Pay Rate Change
1874       RWP    Retirement with Pay
1939       JRC   Job Reclassification
14038      XFR               Transfer
14040      REH                 Rehire
14044      RFL      Return from Leave
14047      LOA       Leave of Absence
15134      LTO   Long Term Disability
17334      TER            Termination
66906      DTA            Data Change
123573     SWB       Short Work Break
301470     RWB Return from Work Break
834331     POS        Position Change
1536340    TWP    Terminated with Pay

unique(hrData[,c("ACTION_REASON","ACTION_REASON_DESCR")])

> unique(hrData[,c("ACTION_REASON","ACTION_REASON_DESCR")])
ACTION_REASON            ACTION_REASON_DESCR
1                 NHR                       New Hire
3                 HCJ            Hire Concurrent Job
7                 FML   Family and Medical Leave Act
767               MLA Medical Leave of Absence Opt A
792               PLA                       Paid LOA
849               WPA        Workplace Accomodations
883               EXT                      Extension
1433              MIL               Military Service
1807              RET             Regular Retirement
1808              FYB                FY Budget (SYS)
1811              FYF                    FY Increase
1821              ADJ                     Adjustment
1833              REC           Job Reclassification
1850              MER                    Merit (SYS)
1863              MKT Market Equity Adjustment (SYS)
1873              SRP        Special Retirement Plan
1885              JIN                       Job Info
1888              ERT               Early Retirement
1916              FLS        Pay Adj - FLSA Reg(SYS)
1937              FYR                       FY Raise
1939              JRC           Job Reclassification
2437              FTE                     FTE Change
5118              EMT                       Emeritus
5727              RWP            Retirement With Pay
6717              NER        Not Eligible for Rehire
8937              INT                    Interim Pay
14038             PRO                      Promotion
14039             XFR                       Transfer
14040             REH                         Rehire
14041             LAT               Lateral Transfer
14044             RFL              Return From Leave
14049             RPL         Return from Paid Leave
14051             ROR                 Reorganization
14209             LOA                LOA Without Pay
14255             H2U         Hospital to University
14975             FUR                       Furlough
15134             LTO           Long Term Disability
15172             MLB Medical Leave of Absence Opt B
15834             U2H      Voluntary Xfr to Hospital
16609             AML           Administrative Leave
17334             VOL          Voluntary Resignation
17349             DEV      Development Opportunities
17350             OUC           Other Uncontrollable
17353             ASN      Termination of Assignment
17354             SMR              Summer Assignment
17381             JOB     Separation/Job Abandonment
17389             RLS         Release from Probation
17394             TMP  End PT/Non-BenefitsEmployment
17402             FYS         FYSC Summer Term (SYS)
17422             DEA                          Death
17437             NRC        Non Renewal of Contract
17442              I9             Failure to Meet I9
17445             FYF               FYSC Terms (SYS)
17482             RIF             Reduction in Force
17560             UNS      Separation/Unavailability
17570             EAC       End Employment Agreement
17586             LTD           Long Term Disability
17587             SEP               Separation Other
17592             INV          Involuntary Dismissal
17633             LWF          Leaving the Workforce
17717             FAM                 Family Reasons
17776             HEA           Medical LOA Option B
17824             VMA  Voluntary by Mutual Agreement
17885             CRP            Duplicate EE Record
17924             OCN             Other Controllable
18026             RET               Return to School
18080             HTH          Health-Related Issues
18235             REL                     Relocation
18331             PRM        Promotion Opportunities
18546             HRS                          Hours
18919             TYP                   Type of Work
19727             LOC                       Location
20299             COV                       COVID-19
20438             PAY                   Compensation
23184             WOR Work Conditions or Environment
26968             EES                Fellow Employee
59413             FYA           FYSC Auto Term (SYS)
59871             ICR       Detach from Incorrect ID
61776             EVW            E-Verify Withdrawal
66906             DST      Distribution Change (SYS)
66907             FCA       FICA Status Change (SYS)
66908             OTH              Other Information
66923             JIN                Job Information
66927             BAC            BA Conversion (SYS)
66996             BEC          Ben Elig Change (SYS)
67018             WEC            Well Elig Chg (SYS)
67971             CPR            Correction-Pay Rate
68266             CJC            Correction-Job Code
68288             CDP          Correction-Department
79446             CNT                 Contract (SYS)
123573            SWB               Short Work Break
282071            PHS              Phased Retirement
301470            RWB         Return from Work Break
660013            JCC         Job Code Consolidation
797935            BNK            Employer Bankruptcy
834331            PDU           Position Data Update
834332            STA         Position Status Change
834735            FYB       Fiscal Year Budget (SYS)
834786            NEW                   New Position
838983            HEA Medical(Not protected by FMLA)
1029642            WC     Workers Compensation Leave
1030299           30D                         30 Day
1053972           RCJ          Rehire Concurrent Job
1131745           90D                         90 Day
1136662           VDT    Voluntary Demotion Transfer
1236325           PAR                 Parental Leave
1331443           PSB          Paid Sabbatical Leave
1331552            WC Worker's Comp-Leave Supplement
1339870           RFN                        RIF/NER
1420798           IDT  Involuntary Demotion Transfer
1449028           LTD           Long-Term Disability
1536340           TWP           Termination With Pay

# o.k.

# let's do a pretty quick EDA, and then work on my headcount formulas.

# Because it's time-stamped, I think I'll call this "journey" data.




