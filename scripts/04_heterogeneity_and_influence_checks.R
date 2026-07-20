# Project: Bayesian Random-Effects Meta-Analysis of Published BCG Vaccine Studies 
# Author: Akash Bhardwaj 
# Purpose: Assess heterogeneity and study influence in the frequentist meta-analysis 

library(tidyverse) 
library(metafor) 
library(here) 

# Load study-level effect sizes created in the previous script 

bcg_effect_sizes <- read_csv( 
  here("data_processed", "bcg_study_level_effect_sizes.csv"), 
  show_col_types = FALSE 
) 

# Refit the frequentist random-effects model 

random_effects_model <- rma( 
  yi = yi, 
  vi = vi, 
  data = bcg_effect_sizes, 
  method = "REML" 
) 

# Cochran's Q test and heterogeneity summary 

heterogeneity_summary <- tibble( 
  number_of_studies = random_effects_model$k, 
  cochran_q = random_effects_model$QE, 
  q_test_degrees_freedom = random_effects_model$k - 1, 
  q_test_p_value = random_effects_model$QEp, 
  tau_squared = random_effects_model$tau2, 
  tau = sqrt(random_effects_model$tau2), 
  i_squared_percent = random_effects_model$I2 
) 

print(heterogeneity_summary) 

write_csv( 
  heterogeneity_summary, 
  here("outputs", "tables", "bcg_heterogeneity_summary.csv") 
) 

# Leave-one-out analysis. 
# Refit the model after omitting each study in turn. 

leave_one_out_results <- lapply( 
  seq_len(nrow(bcg_effect_sizes)), 
  function(i) { 
    
    model_without_one_study <- rma( 
      yi = yi, 
      vi = vi, 
      data = bcg_effect_sizes[-i, ], 
      method = "REML" 
    ) 
    
    tibble( 
      omitted_study = bcg_effect_sizes$study_id[i], 
      omitted_author = bcg_effect_sizes$author[i], 
      omitted_year = bcg_effect_sizes$year[i], 
      pooled_log_odds_ratio = as.numeric(model_without_one_study$b), 
      pooled_odds_ratio = exp(as.numeric(model_without_one_study$b)), 
      tau_squared = model_without_one_study$tau2, 
      i_squared_percent = model_without_one_study$I2 
    ) 
  } 
) %>% 
  bind_rows() 

print(leave_one_out_results) 

write_csv( 
  leave_one_out_results, 
  here("outputs", "tables", "bcg_leave_one_out_influence_results.csv") 
) 


# Create a Baujat plot. 
# This visualises each study's contribution to heterogeneity 
# and influence on the pooled estimate. 

png( 
  filename = here("outputs", "figures", "bcg_baujat_plot.png"), 
  width = 1800, 
  height = 1500, 
  res = 200 
) 

baujat( 
  random_effects_model, 
  xlab = "Contribution to overall heterogeneity", 
  ylab = "Influence on pooled estimate", 
  main = "Baujat Plot: Heterogeneity and Influence Diagnostics" 
) 

dev.off() 

cat("Heterogeneity and influence checks completed.\n") 
