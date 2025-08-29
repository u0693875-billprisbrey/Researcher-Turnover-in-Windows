# EMPLIDs per regime
# 8.25.2025

# PURPOSE:  This creates several RDS files that contain a vector of EMPLIDs
# based on various "journey regime" criteria.
# This was written to simplify the individual journey app.    
# It should simplify querying and manipulating data.

##########
## LOAD ##
##########

journeyPopulation <- readRDS(here::here("Data", "journeyPopulation.rds"))

############
## DEFINE ##
############

exclusiveEMPLIDs <- journeyPopulation$EMPLID[journeyPopulation$EXCLUSIVEJOB == "exclusive"]
concurrentEMPLIDs <- journeyPopulation$EMPLID[journeyPopulation$EXCLUSIVEJOB == "concurrent"]

###########
## WRITE ##
###########

saveRDS(exclusiveEMPLIDs, here::here("Data","exclusiveEMPLIDs.rds"))
saveRDS(concurrentEMPLIDs, here::here("Data","concurrentEMPLIDs.rds"))


