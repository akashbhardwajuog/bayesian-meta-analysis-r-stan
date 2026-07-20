# Project: Bayesian Random-Effects Meta-Analysis of Published BCG Vaccine Studies 
# Author: Akash Bhardwaj 
# Purpose: Install CmdStanR and CmdStan for Bayesian modelling in Stan 

# Install cmdstanr from the official Stan R package repository 

install.packages( 
  "cmdstanr", 
  repos = c( 
    "https://stan-dev.r-universe.dev", 
    getOption("repos") 
  ) 
) 

# Load cmdstanr 

library(cmdstanr) 

# Install CmdStan itself. 
# This downloads and compiles the Stan toolchain. 

install_cmdstan( 
  cores = 2, 
  quiet = FALSE 
) 

# Confirm the CmdStan installation location 

print(cmdstan_path())