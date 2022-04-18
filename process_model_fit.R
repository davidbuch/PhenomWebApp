# In this file, write functions to process the Stan model fit
get_function_summary <- function(model_fit, meta){
  samples <- rstan::extract(model_fit)
  covariates <- meta[names(meta) != 'BATCH']
  treatments <- do.call(expand.grid,lapply(covariates,levels))
  
  treatments <- sapply(treatments, as.integer)
  colnames(treatments) <- NULL
  
  level_counts <- apply(treatments, 2, max)
  treatment_design <- t(apply(treatments, 1, function(r) get_design(r,level_counts)))
  Km <- ncol(treatment_design)
  
  # No need to add batch indicators to the design since we are only interested in 
  # main effects. Just fill out the design matrix with '0' columns.
  main_effects <- apply(samples$f[,1:Km,], 3, function(samps_ft) samps_ft %*% t(treatment_design))
  
  S <- dim(samples$f)[1]
  N <- dim(samples$f)[3]
  
  expected_fval <- matrix(NA, nrow = Km, ncol = N)
  std_dev_fval <- matrix(NA, nrow = Km, ncol = N)
  for(k in 1:Km){ # iterate over functions
    samps_fk <- main_effects[((k - 1)*S + 1):(k*S),]
    expected_fval[k,] <- colMeans(samps_fk)
    std_dev_fval[k,] <- apply(samps_fk,2,sd) # column std dev.
  }
  
  colnames(expected_fval) <- paste0("E[f(t",1:N,")]")
  colnames(std_dev_fval) <- paste0("std[f(t",1:N,")]")
  function_summary <- cbind(do.call(expand.grid,lapply(covariates,levels)), 
                            expected_fval, 
                            std_dev_fval)
  return(function_summary)
}
