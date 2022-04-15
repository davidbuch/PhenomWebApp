add_batch_to_priors <- function(priors, nbatch){
  # the first batch effect prior succeeds the last fixed effect prior
  batch_effect_priors <- priors + max(priors)
  return(c(priors, rep(batch_effect_priors, nbatch)))
}

add_batch_to_design <- function(design, batch_level, nbatch){
  # operates on a single "design" row, as returned by "get_design"
  K_main <- length(design) # number of latent functions/coefficients
  batch_design <- c(rep(0,K_main*(batch_level - 1)), 
                    design, 
                    rep(0,K_main*(nbatch - batch_level)))
  return(c(design,batch_design))
}

get_design <- function(covariate_levels, level_counts){
  # Accepts a length J vector of integers (each in 1,...,k_j) 
  # corresponding to the level of the jth covariate
  if(any((covariate_levels > level_counts) | (covariate_levels < 1))){
    stop("All covariate levels must be in set {1, ..., k_j}!")
  }
  J <- length(level_counts) # number of covariates
  
  design <- c(1) # the first prior is baseline
  
  for(j in 1:J){
    # main effects, 2-way interactions, 3-way interactions, etc.
    size_j_covariate_sets <- combn(1:J, j)
    for(s in 1:ncol(size_j_covariate_sets)){
      # for each size j set:
      # get the set of variable indices
      vars <- size_j_covariate_sets[,s]

      # expand.grid enumerates covariate level combinations in colex order
      # we drop rows containing 1s since those correspond to baseline covariate levels
      # and then match our covariate row to a row from the remaining table
      # if no match occurs, then we do not include a function from this set
      # since one of the covariates is at baseline
      level_grid <- as.matrix(do.call(expand.grid, lapply(level_counts[vars], function(x) 1:x)))
      colnames(level_grid) <- NULL
      level_grid <- level_grid[apply(level_grid,1,function(r) all(r != 1)),]
      level_grid <- matrix(level_grid, ncol = j)
      level_match <- apply(level_grid, 1, function(r) all.equal(r, covariate_levels[vars]) == TRUE)

      design <- c(design, as.numeric(level_match))
    }
  }
  return(design)
}

get_priors <- function(level_counts){
  # Accepts a length J vector of integers (k_j) corresponding to the number
  # of unique values of the jth covariate
  J <- length(level_counts) # number of covariates
  
  prior_id <- 1 # track which prior we are on
  priors <- c(prior_id) # the first prior is baseline
  
  # subtract one from each count for baseline levels, which don't get functions
  level_counts <- level_counts - 1 
  for(j in 1:J){
    # main effects, 2-way interactions, 3-way interactions, etc.
    size_j_covariate_sets <- combn(1:J, j)
    for(s in 1:ncol(size_j_covariate_sets)){
      # for each size j set:
      # increment the prior id
      prior_id <- prior_id + 1
      # count how many instances of that prior there will be
      n_instances <- prod(level_counts[size_j_covariate_sets[,s]])
      # append to our running list of priors
      priors <- c(priors, rep(prior_id, n_instances))
    }
  }
  return(priors)
}


createStanData <- function(od, meta, model_params, model_type){
  # Identify the names of all treatment columns
  # Currently, we are assuming this includes all columns that aren't called
  # 'BATCH' or 'REPLICATE', which we reserve as keywords
  covariates <- meta[!(names(meta) %in% c('BATCH', 'REPLICATE'))]
  covariates <- sapply(covariates, as.integer)
  colnames(covariates) <- NULL
  
  level_counts <- apply(covariates, 2, max)
  priors <- get_priors(level_counts)
  design <- t(apply(covariates, 1, function(r) get_design(r,level_counts)))
  if(model_type %in% c("MBATCH", "MFULL")){
    batch <- as.integer(meta$BATCH)
    nbatch <- max(batch)
    priors <- add_batch_to_priors(priors, nbatch)
    design <- t(sapply(1:nrow(design), function(idx) add_batch_to_design(design[idx,],batch[idx],nbatch)))
  }
  
  x <- as.numeric(row.names(od))
  y <- as.matrix(od)
  L <- max(priors) # number of priors
  K <- length(priors) # number of functions
  
  stan_data <- list(
    N = length(x), # number of timepoints
    P = ncol(y), # number of observations
    design = design, # design matrix
    x = x, # observation times
    y = t(y), # each row is one well's time series of OD measurements
    K = K,
    L = L,
    prior = priors, # prior assignment for each functional coefficient
    # THE BELOW COME FROM ```model_params``` user input
    alpha_prior = matrix(model_params$alpha_prior, nrow = L, ncol = 2, byrow = TRUE),
    lengthscale_prior = matrix(model_params$lengthscale_prior, nrow = L, ncol = 2, byrow = TRUE),
    sigma_prior = model_params$sigma_prior,
    ls_min = 1/(pi*model_params$maxExpectedCross), # equiv. to "maxExpectedCross = 100"
    ls_max = 1/(pi*model_params$minExpectedCross), # equiv. to "minExpectedCross = 0.01"
    marginal_alpha_prior = model_params$marginal_alpha_prior,
    marginal_lengthscale_prior = model_params$marginal_lengthscale_prior
  )
  return(stan_data)
}