---
title: "Project Issue (Changes in PI Not Tracked)"
author: "Bill Prisbrey"
date: "2025-06-27"
output:
  html_document:
    keep_md: true
---

***STATUS:***  Resolution in progress

***ISSUE NAME:***  Changes in PI not tracked    

***ISSUE ID:*** 001

***DATE IDENTIFIED:***  27 June 2025    

***DESCRIPTION:***  

  The Office of Sponsored Projects does not track changes to the principal investigator in their data warehouse.  This means that past records are changed to align with the present reality, including the principal investigator attached to a proposal or a grant.  This introduces anomalies (where a PI could listed on a proposal before they were hired, for example) and obscures the past (where a PI could be replaced on a winning proposal, for example).
  
  This is a subset of a larger problem of understanding how principal investigators are identified and defined.
  
***IMPACT LEVEL:***   

  High/Critical.  This threatens project viability.    

***PROJECT IMPACT:***   

  The purpose of the project is to investigate turnover of principal investigators in order to improve retention, and consequently improve research spending.   
  
  This requires a clear definition and clean identification of the entire population of principal investigators and potential principal investigators, currently and historically, including employees who have departed the University.   
  
  However, the data warehouse used by the Office of Sponsored Projects does not adequately track all changes over time.  If a principal investigator departs, then their employee identification number is replaced with that of a new principal investigator.  Past records are instantly updated as well, leading to anomalies like a principal investigator attached to a proposal before they were hired.  The former employee would only be identified as a member of the target population if they had their ID's attached to other projects in the database that had already ended.    
  
  This obscures the definition of the target population of principal investigators.  It is possible to fail to identify an employee as a principal investigator, because they departed and were replaced in the tables listing principal investigators.  It could be inflating the contribution of other principal investigators as they inherit or absorb proposals by departing principal investigators.    
  
  A quick query by Dave Howell revealed about 1.5% of the rows have the award change reason identified as a "PI change."  This is large enough to affect the accuracy of conclusions involving turnover.
  
  Because the very phenomena under investigation is being erased, confidence in the analysis will be weakened and could lead to false conclusions and ineffective recommendations.    

***ASSIGNED TO:*** Dave Howell and Kaidon Spencer   

***ACTION PLAN OR RESOLUTION STRATEGY:***     

  - Dave will modify the OSP data warehouse to track changes in principal investigators more thoroughly going forward.   
  - Kaidon will investigate the table "ps_uu_eawd_tbl" as it identifies the PI's over the lifetime of the awards.  It is documented in the wiki [here.](https://wiki.sys.utah.edu/display/UP/eAward%3A+Database+Tables).    

***LOG:***    

*30 June 2025:*  Team meets and discusses the issue and potential solutions.    

*1 July 2025:*  Kaidon provides the following update via Teams:    

  It looks like 901 awards have had a PI Change. I'm going to look at the following table to identify the PIs over the lifetime of an award:
ps_uu_eawd_tbl
This has 640/901 of the awards that have had PI Changes. I'm not sure it is capturing the date of the PI Change itself, but I will check. This table tracks award transactions. Here is some documentation
https://wiki.sys.utah.edu/display/UP/eAward%3A+Database+Tables
 
  This is the base table for the eAward application, and I'm still trying to figure out why only some awards go through the app. But for the ones that did go through eAward, it looks like the PI history is recorded. I can see that a PI for an award has changed from transaction to transaction, and can provide dates for the transaction itself, but that date isn't the PI Change date. It should be in the same ballpark though.

  I haven't been able to find any data sources that track PI Changes on the proposal side, unfortunately. 
