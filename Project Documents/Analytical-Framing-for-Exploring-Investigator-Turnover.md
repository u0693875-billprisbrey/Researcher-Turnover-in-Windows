---
title: "Analytical Framing for Exploring Investigator Turnover"
author: "Bill Prisbrey"
date: "2025-04-17"
output: 
  html_document:
    keep_md: TRUE
---

**PURPOSE:**  This document creates the initial analytical framing of investigating turnover by principal investigators.  This is a living document and may be continuously updated with feedback and new information.   

**PROBLEM STATEMENT:** ***Can the University of Utah improve research spending by improving retention of high performing and high potential researchers?***

## **ANALYTICS PROBLEM RE-FRAMING:**

### **1. Decomposition:**   

  The business problem can be broken into several distinct aspects, each with their own modeling approach.   
  
  1.1.  ***Identify high performing researchers.***    
  &nbsp;&nbsp;(a) Pareto analysis.    
  &nbsp;&nbsp;Historically, high performers have simply been defined as the researchers contributing to the top x% of research funds per college per year.    
  &nbsp;&nbsp;(b) Cluster.    
  &nbsp;&nbsp;Un-supervised learning techniques uncover latent structure in the data sets.  This could provide more information than  a simple Pareto analysis.   
        
  1.2.  ***Identify high potential researchers.***    
  &nbsp;&nbsp;(a) Supervised learning (particularly extreme gradient boosting.)    
  &nbsp;&nbsp;Identify membership in "high-performing" clusters or according to the Pareto definition as early in a PI's career as possible.     
        
  1.3.  ***Calculate turn-over.***    
  &nbsp;&nbsp;(a)  By colleges, departments, clusters, and Pareto definition.    
      
  1.4.  ***Statistical comparison of turn-over.***    
  &nbsp;&nbsp;(a)  Chi-squared, ANOVA, and Kruskal-Wallis      
  
  1.5.  ***Advanced investigation of turn-over.***    
  &nbsp;&nbsp;(a)  Logistic regression, decisions trees, and survival models

### **2. Data:**

  2.1 ***Internally available data that will be used:***    
  &nbsp;&nbsp;(a) Win/loss per proposal as used in Grants Exploratory Phase I.    
  &nbsp;&nbsp;(b) Hire and separation data per PI
  
  2.2 ***Internal data that might be used:***   
  &nbsp;&nbsp;(a) HR data further describing the PI's.    
  &nbsp;&nbsp;(b) Faculty activity and performance data per PI in "Elements" database (such as class load, committee service, conference presentations, publications, and publication status)
  
  2.3 ***External data that might be used:***   
  &nbsp;&nbsp;(a) "Dimensions" database describing researcher activity.
  
  
  2.4 ***Data that will not be used:***   
  
  - No focus groups will be conducted.    
  - No surveys will be performed.
  - No external data (such as scraping LinkedIn or identifying author affiliation in research literature) will be acquired by scraping websites.      
  - No text-based data or analysis of research themes   

### **3. Actions and actors:**

Dr. Rothwell could use this information to develop and recommend a strategy to senior leadership that improves retention of high-performing and high-potential principal investigators.    


## **DRIVERS AND RELATIONSHIPS:**    

Following is a brain-stormed list where the author invites any additional contribution.  It is developed without a literature review, focus groups, or surveys, any of which would contribute to the quality, comprehensiveness, and relevance of this list.   

Factors that are related to turnover:   

- Offer elsewhere
  - Higher pay
  - Desired geography (closer to home)    
- Quality of life   
  - Air quality and smog    
  - Great Salt ~~Lake~~Desert dust and arsenic    
  - Lengthy commute / bad traffic         
  - Quality of public schools 
  - House size and quality    
  - Crime, safety, and peace-of-mind 
  - Winter storms and summer heat     
- Quality of job    
  - Access to research literature / library
  - Quality of research facilities, buildings, office
  - Access to parking   
  - Conflicts with co-workers   
  - Under-stimulating co-workers / institution prestige        
  - Incompetent staff / graduate students   
  - Non-research work loads and expectations are too high (teaching, committees)
- Quality of management   
  - Rapport with immediate managers   
  - Confidence in senior management 
  - Micro-managing, denying opportunities, no career advancement    
- Culture and politics    
  - University culture is too liberal or too conservative    
  - State legislation is too liberal or too restrictive (eg gynecology restrictions)   
  

Factors that could INCREASE turnover:   


Factors that could DECREASE turnover: 

## **ASSUMPTIONS:**    

Needs attention

## **KEY METRICS OF SUCCESS:**   

### *Model:*    

- Identification of high and low performers are validated by key stakeholders as reasonable, meaningful, and useful.
- Significance level of .05 (p-value) for chi-squared, ANOVA, and Kruskal-Wallis tests
- Classification and survival models have a minimum Kappa score of 0.5 or a Concordance index of 0.7 as applicable.


### *Business:*   

- Increases:   

  - Longevity of high-potential and high-performing researchers   
  - Tenure awarded to high-potential and high-performing researchers 
  - Turn-over among low-performing researchers
  - Award submissions and 'requested funds won' by high-potential and high-performing researchers    

- Decreases: 

  - Longevity of low-potential and low-performing researchers   
  - Tenure awarded to low-potential and low-performing researchers
  - Turn-over among high-performing researchers
  - Award submissions by low-potential and low-performing researchers   

