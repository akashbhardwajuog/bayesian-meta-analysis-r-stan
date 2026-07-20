# Project: Bayesian Random-Effects Meta-Analysis of Published BCG Vaccine Studies 
# Author: Akash Bhardwaj 
# Purpose: Calculate study-level odds ratios and fit a frequentist random-effects meta-analysis 

library(tidyverse) 
library(metafor) 
library(here) 

# Load the study-level BCG vaccine data 

bcg_data <- read_csv( 
  here("data_raw", "bcg_vaccine_tuberculosis_studies.csv"), 
  show_col_types = FALSE 
) 

# Calculate log odds ratios and corresponding sampling variances. 
# OR < 1 indicates fewer tuberculosis cases in the vaccinated group 
# relative to the non-vaccinated control group. 

bcg_effect_sizes <- escalc( 
  measure = "OR", 
  ai = treatment_events, 
  bi = treatment_non_events, 
  ci = control_events, 
  di = control_non_events, 
  data = bcg_data, 
  append = TRUE 
) %>% 
  as_tibble() %>% 
  mutate( 
    odds_ratio = exp(yi), 
    ci_lower = exp(yi - 1.96 * sqrt(vi)), 
    ci_upper = exp(yi + 1.96 * sqrt(vi)) 
  ) 

# Inspect study-level effect sizes 

print( 
  bcg_effect_sizes %>% 
    select( 
      study_id, 
      author, 
      year, 
      odds_ratio, 
      ci_lower, 
      ci_upper 
    ) 
) 

# Save study-level effect sizes 

write_csv( 
  bcg_effect_sizes, 
  here("data_processed", "bcg_study_level_effect_sizes.csv") 
) 

# Fit a random-effects meta-analysis using REML. 
# yi is the log odds ratio and vi is its sampling variance. 

random_effects_model <- rma( 
  yi = yi, 
  vi = vi, 
  data = bcg_effect_sizes, 
  method = "REML" 
) 

# Display model results 

print(random_effects_model) 

# Extract pooled results 

pooled_results <- tibble( 
  model = "Frequentist random-effects meta-analysis (REML)", 
  number_of_studies = random_effects_model$k, 
  pooled_log_odds_ratio = as.numeric(random_effects_model$b), 
  pooled_odds_ratio = exp(as.numeric(random_effects_model$b)), 
  confidence_interval_lower = exp(random_effects_model$ci.lb), 
  confidence_interval_upper = exp(random_effects_model$ci.ub), 
  p_value = random_effects_model$pval, 
  tau_squared = random_effects_model$tau2, 
  i_squared_percent = random_effects_model$I2 
) 

print(pooled_results) 

# Save pooled meta-analysis results 

write_csv( 
  pooled_results, 
  here("outputs", "tables", "bcg_frequentist_random_effects_results.csv") 
) 

# Create a forest plot 

png( 
  filename = here("outputs", "figures", "bcg_frequentist_forest_plot.png"), 
  width = 1800, 
  height = 1600, 
  res = 200 
) 

forest( 
  random_effects_model, 
  slab = paste(bcg_effect_sizes$author, bcg_effect_sizes$year, sep = ", "), 
  atransf = exp, 
  xlab = "Odds Ratio for Tuberculosis Cases (BCG Vaccinated vs Control)", 
  mlab = "Random-effects model (REML)" 
) 

dev.off() 

cat("Frequentist random-effects meta-analysis completed.\n") 
cat("Number of studies:", random_effects_model$k, "\n") 
cat( 
  "Pooled odds ratio:", 
  round(exp(as.numeric(random_effects_model$b)), 3), 
  "\n" 
) 
cat( 
  "I-squared:", 
  round(random_effects_model$I2, 1), 
  "%\n" 
) 
