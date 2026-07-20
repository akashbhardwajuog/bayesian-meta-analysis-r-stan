# Project: Bayesian Random-Effects Meta-Analysis of Published BCG Vaccine Studies 
# Author: Akash Bhardwaj 
# Purpose: Visualise Bayesian posterior distributions and compare Bayesian 
# and frequentist random-effects meta-analysis results 

library(tidyverse) 
library(cmdstanr) 
library(metafor) 
library(here) 

# Load study-level effect sizes 

bcg_effect_sizes <- read_csv( 
  here("data_processed", "bcg_study_level_effect_sizes.csv"), 
  show_col_types = FALSE 
) 

# Refit the frequentist random-effects model 

frequentist_model <- rma( 
  yi = yi, 
  vi = vi, 
  data = bcg_effect_sizes, 
  method = "REML" 
) 

# Load the fitted Bayesian CmdStanR object 

bayesian_meta_fit <- readRDS( 
  here("data_processed", "bcg_bayesian_meta_fit.rds") 
) 

# Extract posterior draws 

posterior_draws <- bayesian_meta_fit$draws( 
  variables = c("pooled_odds_ratio", "tau"), 
  format = "draws_df" 
) %>% 
  as.data.frame() %>% 
  as_tibble() 

# Posterior distribution of pooled odds ratio 

pooled_or_plot <- ggplot( 
  posterior_draws, 
  aes(x = pooled_odds_ratio) 
) + 
  geom_histogram( 
    bins = 40, 
    fill = "#0072B2", 
    colour = "white", 
    alpha = 0.85 
  ) + 
  geom_vline( 
    xintercept = 1, 
    linetype = "dashed", 
    linewidth = 0.8 
  ) + 
  labs( 
    title = "Posterior Distribution of the Pooled Odds Ratio", 
    subtitle = "Bayesian random-effects meta-analysis", 
    x = "Pooled odds ratio: BCG vaccinated versus control", 
    y = "Posterior draws" 
  ) + 
  theme_minimal(base_size = 12) 

print(pooled_or_plot) 

ggsave( 
  here( 
    "outputs", 
    "figures", 
    "bcg_bayesian_pooled_odds_ratio_posterior.png" 
  ), 
  plot = pooled_or_plot, 
  width = 8, 
  height = 5, 
  dpi = 300 
) 

# Posterior distribution of between-study heterogeneity 

tau_plot <- ggplot( 
  posterior_draws, 
  aes(x = tau) 
) + 
  geom_histogram( 
    bins = 40, 
    fill = "#D55E00", 
    colour = "white", 
    alpha = 0.85 
  ) + 
  labs( 
    title = "Posterior Distribution of Between-Study Heterogeneity", 
    subtitle = "Bayesian random-effects meta-analysis", 
    x = "Tau: between-study standard deviation on the log odds-ratio scale", 
    y = "Posterior draws" 
  ) + 
  theme_minimal(base_size = 12) 

print(tau_plot) 

ggsave( 
  here( 
    "outputs", 
    "figures", 
    "bcg_bayesian_tau_posterior.png" 
  ), 
  plot = tau_plot, 
  width = 8, 
  height = 5, 
  dpi = 300 
) 

# Read saved Bayesian results 

bayesian_results <- read_csv( 
  here( 
    "outputs", 
    "tables", 
    "bcg_bayesian_random_effects_results.csv" 
  ), 
  show_col_types = FALSE 
) 

# Create a frequentist-versus-Bayesian comparison table 

model_comparison <- tibble( 
  approach = c( 
    "Frequentist random-effects meta-analysis (REML)", 
    "Bayesian random-effects meta-analysis (Stan)" 
  ), 
  pooled_odds_ratio = c( 
    exp(as.numeric(frequentist_model$b)), 
    bayesian_results %>% 
      filter(parameter == "Pooled odds ratio") %>% 
      pull(posterior_mean) 
  ), 
  interval_lower = c( 
    exp(frequentist_model$ci.lb), 
    bayesian_results %>% 
      filter(parameter == "Pooled odds ratio") %>% 
      pull(credible_interval_lower) 
  ), 
  interval_upper = c( 
    exp(frequentist_model$ci.ub), 
    bayesian_results %>% 
      filter(parameter == "Pooled odds ratio") %>% 
      pull(credible_interval_upper) 
  ), 
  interval_type = c( 
    "95% confidence interval", 
    "95% credible interval" 
  ), 
  heterogeneity_measure = c( 
    paste0( 
      "Tau-squared = ", 
      round(frequentist_model$tau2, 3), 
      "; I-squared = ", 
      round(frequentist_model$I2, 1), 
      "%" 
    ), 
    paste0( 
      "Posterior mean tau = ", 
      round( 
        bayesian_results %>% 
          filter(parameter == "Between-study heterogeneity (tau)") %>% 
          pull(posterior_mean), 
        3 
      ) 
    ) 
  ) 
) 

print(model_comparison) 

write_csv( 
  model_comparison, 
  here( 
    "outputs", 
    "tables", 
    "bcg_frequentist_bayesian_model_comparison.csv" 
  ) 
) 

cat("Bayesian visualisations and model comparison completed.\n") 
