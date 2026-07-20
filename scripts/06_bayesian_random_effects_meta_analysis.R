# Project: Bayesian Random-Effects Meta-Analysis of Published BCG Vaccine Studies 
# Author: Akash Bhardwaj 
# Purpose: Fit a Bayesian random-effects meta-analysis in Stan using CmdStanR 

library(tidyverse) 
library(cmdstanr) 
library(here) 

# Load study-level effect sizes created by the frequentist meta-analysis script 

bcg_effect_sizes <- read_csv( 
  here("data_processed", "bcg_study_level_effect_sizes.csv"), 
  show_col_types = FALSE 
) 

# Prepare the data list required by the Stan model. 
# yi is the study-level log odds ratio. 
# vi is its sampling variance, so sqrt(vi) is the standard error. 

stan_data <- list( 
  K = nrow(bcg_effect_sizes), 
  y = bcg_effect_sizes$yi, 
  sigma = sqrt(bcg_effect_sizes$vi) 
) 

# Define the location of the Stan model file 

stan_model_file <- here( 
  "models", 
  "bayesian_random_effects_meta_analysis.stan" 
) 

# Compile the Stan model 

bayesian_meta_model <- cmdstan_model( 
  stan_file = stan_model_file 
) 

# Fit the Bayesian random-effects model. 
# Four chains are run; two run in parallel to reduce computer load. 

bayesian_meta_fit <- bayesian_meta_model$sample( 
  data = stan_data, 
  seed = 20260720, 
  chains = 4, 
  parallel_chains = 2, 
  iter_warmup = 1000, 
  iter_sampling = 2000, 
  adapt_delta = 0.95, 
  refresh = 500 
) 

# Print the main model summary 

print( 
  bayesian_meta_fit$summary( 
    variables = c("mu", "tau", "pooled_odds_ratio") 
  ) 
) 

# Save MCMC diagnostics for pooled effect and heterogeneity. 
# R-hat values close to 1.00 support chain convergence. 

mcmc_diagnostics <- bayesian_meta_fit$summary( 
  variables = c("mu", "tau", "pooled_odds_ratio") 
) %>% 
  as_tibble() 

write_csv( 
  mcmc_diagnostics, 
  here("outputs", "tables", "bcg_bayesian_mcmc_diagnostics.csv") 
) 

# Extract posterior draws for the pooled log odds ratio and heterogeneity. 

posterior_draws <- bayesian_meta_fit$draws( 
  variables = c("mu", "tau", "pooled_odds_ratio"), 
  format = "draws_df" 
) %>% 
  as.data.frame() 

# Create a posterior summary table. 
# The 2.5th and 97.5th percentiles form a 95% credible interval. 

bayesian_results <- tibble( 
  parameter = c( 
    "Pooled log odds ratio", 
    "Pooled odds ratio", 
    "Between-study heterogeneity (tau)" 
  ), 
  posterior_mean = c( 
    mean(posterior_draws$mu), 
    mean(posterior_draws$pooled_odds_ratio), 
    mean(posterior_draws$tau) 
  ), 
  posterior_median = c( 
    median(posterior_draws$mu), 
    median(posterior_draws$pooled_odds_ratio), 
    median(posterior_draws$tau) 
  ), 
  credible_interval_lower = c( 
    quantile(posterior_draws$mu, probs = 0.025), 
    quantile(posterior_draws$pooled_odds_ratio, probs = 0.025), 
    quantile(posterior_draws$tau, probs = 0.025) 
  ), 
  credible_interval_upper = c( 
    quantile(posterior_draws$mu, probs = 0.975), 
    quantile(posterior_draws$pooled_odds_ratio, probs = 0.975), 
    quantile(posterior_draws$tau, probs = 0.975) 
  ) 
) 

print(bayesian_results) 

write_csv( 
  bayesian_results, 
  here("outputs", "tables", "bcg_bayesian_random_effects_results.csv") 
) 

# Save the fitted CmdStanR object locally. 
# This is excluded from GitHub because it can be large. 

saveRDS( 
  bayesian_meta_fit, 
  here("data_processed", "bcg_bayesian_meta_fit.rds") 
) 

cat("Bayesian random-effects meta-analysis completed.\n") 
cat( 
  "Posterior mean pooled odds ratio:", 
  round(mean(posterior_draws$pooled_odds_ratio), 3), 
  "\n" 
) 
