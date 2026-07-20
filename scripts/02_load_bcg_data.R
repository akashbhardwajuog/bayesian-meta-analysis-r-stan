# Project: Bayesian Random-Effects Meta-Analysis of Published BCG Vaccine Studies 
# Author: Akash Bhardwaj 
# Purpose: Load and inspect published BCG vaccine study-level event data 

library(tidyverse) 
library(metadat) 
library(here) 

# Load the published BCG vaccine dataset from the metadat package 

data("dat.colditz1994", package = "metadat") 

bcg_data <- dat.colditz1994 %>% 
  as_tibble() 

# Inspect the dataset 

print(bcg_data) 
glimpse(bcg_data) 

# Keep the variables needed for the meta-analysis 

bcg_analysis_data <- bcg_data %>% 
  select( 
    trial, 
    author, 
    year, 
    tpos, 
    tneg, 
    cpos, 
    cneg, 
    ablat, 
    alloc 
  ) %>% 
  rename( 
    study_id = trial, 
    treatment_events = tpos, 
    treatment_non_events = tneg, 
    control_events = cpos, 
    control_non_events = cneg, 
    absolute_latitude = ablat, 
    allocation_method = alloc 
  ) %>% 
  mutate( 
    treatment_total = treatment_events + treatment_non_events, 
    control_total = control_events + control_non_events 
  ) 

# Basic checks 

stopifnot(nrow(bcg_analysis_data) == 13) 
stopifnot(all(bcg_analysis_data$treatment_events >= 0)) 
stopifnot(all(bcg_analysis_data$control_events >= 0)) 
stopifnot(all(bcg_analysis_data$treatment_total > 0)) 
stopifnot(all(bcg_analysis_data$control_total > 0)) 

# Save a reproducible CSV copy for this project 

write_csv( 
  bcg_analysis_data, 
  here("data_raw", "bcg_vaccine_tuberculosis_studies.csv") 
) 

# Create a short data dictionary 

data_dictionary <- tribble( 
  ~variable, ~description, 
  "study_id", "Study identifier", 
  "author", "Study author or study label", 
  "year", "Publication year", 
  "treatment_events", "Tuberculosis cases in the BCG-vaccinated group", 
  "treatment_non_events", "Participants without tuberculosis in the BCG-vaccinated group", 
  "control_events", "Tuberculosis cases in the non-vaccinated control group", 
  "control_non_events", "Participants without tuberculosis in the non-vaccinated control group", 
  "treatment_total", "Total participants in the BCG-vaccinated group", 
  "control_total", "Total participants in the non-vaccinated control group", 
  "absolute_latitude", "Absolute latitude of the study location in degrees", 
  "allocation_method", "Reported treatment-allocation method" 
) 

write_csv( 
  data_dictionary, 
  here("references", "bcg_data_dictionary.csv") 
) 

cat("Published BCG dataset saved successfully.\n") 
cat("Number of studies:", nrow(bcg_analysis_data), "\n") 
