---
title: "Demonstrating Brute Force Fit"
author: "Bill Prisbrey"
date: "2025-10-21"
output:
  html_document:
    keep_md: true
params:
  showPI: true
  showAll: false
---




  











**PURPOSE:**  The purpose of this report is to describe an effort to accurately calculate University headcount using an algorithm that I am calling a "brute force fit."


**OBJECTIVES:**
  (1)  Describe the problem and the resolution path.  
  (2)  Explain possible next steps.    
  (3)  Show the breakdown of the population by entry and exit actions.  
  (4)  Show examples of individual journeys from various sub-sets of the population with the blue line that is the "force-fit" approximation.  
  (5)  Show the resulting headcount estimation since 2010. 

**MEETING NOTES, 10/23/2025:**

Attendance:  Kirsten Allen, Brian Gelsinger, David Howell, Bill Prisbrey 

Action Items: 

- Brian will provide a SQL query that will provide a list of EMPLIDs and basic fields like department or college on snapshot dates (Jan/July) going back five to ten years.  Estimated completion date of Friday 10/31/2025. 
- Bill will proceed with the next steps, including using the snapshot data as a validation data set, focusing on the chemical engineering department.   


Notes:  

- Bill reviewed this report with the team.  
- The resulting headcount is too high: Brian's dashboard shows ~30,000 current employees while the headcount estimate shows about ~40,000 current employees. 
- Brian will provide snapshot data to guide improving the algorithm.  

### Problem and resolution path explained 

**ISSUE:**  An accurate headcount is critical to analyzing turnover.  Turnover is usually calculated as a rate, or as the number of employees departing divided by the headcount.  

**DIFFICULTY:**  Calculating the headcount for employees who have one job a time is straight-forward:  they are added to the headcount when they are hired and subtracted when they leave.  

However, many employees at the University of Utah hold concurrent positions.  Each position will have its own actions possibly affecting headcount:  one position will be terminated, but not the other; or one will commence a work break and not the other.  This already-complex record may have been further muddied by inconsistent record-keeping over time and across departments.  

These concurrent positions do not have distinct identifiers in the database.  An employee may start with one position, add a second, and then quit the first.  The identifier of the second position will be changed to match the identifier of the first.  

Accurately tallying headcount for these employees is challenging.  They are easily double-counted or double-deducted from the headcount. 

**RESOLUTION:**  

Each employee is considered one at a time, and the following algorithm is applied: 

  - Every "entry" action increases the cumulative headcount.  
  - Every "exit" action decreases the cumulative headcount.  
  - Because an employee is considered one at a time, a headcount value greater than one or less than zero is not allowed.  
  - A "university-level" boundary date can then be extracted per individual. 


### Next steps  

  *(1)  Validate and verify.*   Although this method produces an internally-consistent data set, where the number of entries does not exceed the number of exits for example, additional validation is sought.   
  
  *(2)  Add transfer events.*  Employees frequently transfer between positions, titles, and departments.   Adding transfer events will improve the granularity of the analysis.   
  
  *(3)  Include transfers to unpaid positions as 'exit' boundary events.*  Many employees are never terminated but are transferred to volunteer positions.   It may be desirable to exclude these individuals from a headcount tally.    
  
  

### Population breakdown by journey characteristics 

![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-6-1.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-6-2.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-6-3.png)<!-- -->






### Individual journeys 

#### **EXCLUSIVE JOURNEY**

![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-8-1.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-8-2.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-8-3.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-8-4.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-8-5.png)<!-- -->







#### **CONCURRENT JOURNEY**


![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-10-1.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-10-2.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-10-3.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-10-4.png)<!-- -->![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-10-5.png)<!-- -->







### Headcount Metrics 

#### **EXCLUSIVE JOBS**

![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-12-1.png)<!-- -->







#### **CONCURRENT JOBS**

![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-14-1.png)<!-- -->






#### **FULL POPULATION**

![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-16-1.png)<!-- -->



### Explain HeadCount

![](C:\Users\u0693875\DOCUME~1\Projects\ROTHWELL\RESEAR~1\REPORT~1\DEMONS~3/figure-html/unnamed-chunk-18-1.png)<!-- -->

'Exit' condition needs to be modified to accommodate the transfer to volunteer positions

*Per Brian Gelsinger, Teams message on 14 Oct 2025:*

I can't remember if we included the field UU_BEN_IND in the SQL we provided, but that would be my recommendation to use. A Benefit Indicator of "30 " means that job code is considered "Non-Employee". I'm happy to add that field to the SQL if you'd like, but below is a list of all the job codes in Ben Ind 30, so you could just try excluding those job codes as well. I've also provided the current headcount of employees in these job codes
 
Job Code	Job Title	UU Ben Ind	UU Ben Ind Descr	Count Distinct EE
0233	Field Instructor	30	Non-Employee	15
6000	Volunteer Staff	30	Non-Employee	21
6001	Volunteer Faculty	30	Non-Employee	34
6002	Adjunct Professor	30	Non-Employee	474
6003	Adjunct Associate Professor	30	Non-Employee	371
6004	Adjunct Assistant Professor	30	Non-Employee	748
6005	Adjunct Instructor	30	Non-Employee	588
6006	Shared Faculty (Unpaid)	30	Non-Employee	17
6100	Univ Asia Staff	30	Non-Employee	56
6102	Adjunct Professor (Ext)	30	Non-Employee	134
6103	Adjunct Assoc Professor (Ext)	30	Non-Employee	126
6104	Adjunct Asst Professor (Ext)	30	Non-Employee	784
6105	Adjunct Instructor (Ext)	30	Non-Employee	416
7993	Surviving Spouse	30	Non-Employee	0
9261	COBRA Beneficiary	30	Non-Employee	0
799999	Volunteer Staff	30	Non-Employee	0 


