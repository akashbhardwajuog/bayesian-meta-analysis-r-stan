data { 
 int<lower=1> K; 
 vector[K] y; 
 vector<lower=0>[K] sigma; 
} 
 
parameters { 
 real mu; 
 real<lower=0> tau; 
 vector[K] theta; 
} 
 
model { 
 mu ~ normal(0, 2); 
 tau ~ normal(0, 1); 
 
 theta ~ normal(mu, tau); 
 y ~ normal(theta, sigma); 
} 
 
generated quantities { 
 real pooled_odds_ratio; 
 
 pooled_odds_ratio = exp(mu); 
} 
 