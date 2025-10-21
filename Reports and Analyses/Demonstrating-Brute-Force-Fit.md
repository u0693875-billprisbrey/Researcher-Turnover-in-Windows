---
title: "Demonstrating Brute Force Fit"
author: "Bill Prisbrey"
date: "2025-10-21"
output:
  html_document:
    keep_md: true
---




  










**PURPOSE:**


**OBJECTIVES:**

### Population breakdown by journey characteristics 

![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-6-1.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-6-2.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-6-3.png)<!-- -->

### Individual journeys 

#### **EXCLUSIVE JOURNEY**

***No work break, no leave***


![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-7-1.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-7-2.png)<!-- -->



***Work break, no leave***


![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-8-1.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-8-2.png)<!-- -->


***No work break, leave***


![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-9-1.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-9-2.png)<!-- -->




***Work break and leave***  


![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-10-1.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-10-2.png)<!-- -->




#### **CONCURRENT JOURNEY**

***No work break, no leave***

![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-11-1.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-11-2.png)<!-- -->



***Work break, no leave***


![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-12-1.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-12-2.png)<!-- -->




***No work break, leave***


![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-13-1.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-13-2.png)<!-- -->


***Work break and leave***  

![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-14-1.png)<!-- -->![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-14-2.png)<!-- -->



### Headcount Metrics 

#### **EXCLUSIVE JOURNEY**




#### **CONCURRENT JOURNEY**

![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-16-1.png)<!-- -->

### Explain HeadCount

![](Demonstrating-Brute-Force-Fit_files/figure-html/unnamed-chunk-17-1.png)<!-- -->

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

