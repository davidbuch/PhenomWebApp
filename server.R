#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
source("create_design.R")
source("process_model_fit.R")

loadMetaFile <- function(inFile){
  if (is.null(inFile))
    return(NULL)
  
  meta <- read.csv(inFile$datapath)
  meta[] <- lapply(meta, factor) # convert all variables to factors before returning
  
  # Validation:
  # for each possible treatment condition, was there at least one replicate that 
  # received it?
  covariates <- meta[names(meta) != 'BATCH']
  treatments <- do.call(expand.grid,lapply(covariates,levels))
  tried_all_treatments <- all(apply(treatments,1, 
                                    function(treatment) 
                                      any(apply(covariates,1, 
                                                function(covs) 
                                                  all(covs == treatment)))))
  validate(
    need(tried_all_treatments, "All possible covariate combinations must be present 
        in your meta-data to fit the model. Add replicates collected under those
        missing experimental conditions or remove covariates from your model."),
    need(min(sapply(meta, nlevels)) >= 2, "Any column included in the meta-data 
         file (including 'BATCH', if it is used) must feature at least 2 treatment 
         levels.")
  )
  meta
}

loadOdFile <- function(inFile){
  if (is.null(inFile))
    return(NULL)
  
  od <- read.csv(inFile$datapath, row.names = 1)
  validate(
    need(nrow(od) <= 15, "Please subsample Optical Density time-series to include
         at most 15 timepoints. Ten or fewer would be ideal."),
    need(nrow(od) >= 2, "Optical Density time-series must include
         at least 2 timepoints. Ten or fewer would be ideal.")
  )
  od
}

shinyServer(function(input, output) {
  output$clock <- renderText({
    invalidateLater(5000)
    Sys.time()
  }) # keep the app from "greying out" on shinyapps.io (connection stops when inactive)
  
  od <- eventReactive(input$odData,{
    loadOdFile(input$odData)
  })
  meta <- eventReactive(input$metaData,{
    loadMetaFile(input$metaData)
  })

  output$odDataPlot <- renderPlot({
    req(od())
    od <- od()
    matplot(as.numeric(row.names(od)), od, 
            type = "l", 
            xlab = "Time", 
            ylab = "Optical Density",
            main = "Observed Data")
  })
  output$metaDataFrame <- renderTable({
    meta()
  })
  
  output$fitModelButton <- renderUI({
    req(od())
    req(meta())
    actionButton("run", "Fit Model")
  })
  
  model_fit <- eventReactive(input$run, {
    od <- od()
    meta <- meta()

    validate(
      need(ncol(od()) == nrow(meta()), "Columns of optical density data must match rows of meta data.")
    )

    if(!('BATCH' %in% names(meta))){
      warning("No 'BATCH' column detected in meta data.")
    }
    
    model_params <- list(alpha_prior = c(1,1),
                         lengthscale_prior = c(1,1),
                         sigma_prior = c(1,1),
                         minExpectedCross = 0.01,
                         maxExpectedCross = 100,
                         marginal_alpha_prior = c(1,1),
                         marginal_lengthscale_prior = c(1,1))
    
    sampling_params <- list(chains = round(2),
                            iter = round(1000),
                            warmup = round(500),
                            thin = round(1))
    
    # Don't add columns for batch-specific random effects if there's no BATCH column
    stan_data <- createStanData(od, meta, model_params, 'BATCH' %in% names(meta))
   
    shinybusy::show_spinner() # Indicate that we are busy sampling
    stan_fit <- rstan::sampling(
      object = PhenomStanModel:::stanmodels$phenom_marginal,
      data = stan_data,
      chains = sampling_params$chains,
      iter = sampling_params$iter,
      warmup = sampling_params$warmup,
      thin = sampling_params$thin
    )
    shinybusy::hide_spinner() # Indicate that we are done sampling
    
    growth_curve_summary <- get_function_summary(stan_fit, meta)
    growth_curve_summary
  }, ignoreNULL = TRUE)

  output$downloadButton <- renderUI({
    req(model_fit()) # requires result to be non-null before showing button
    downloadButton('download',"Download Model Fit Summary")
  })
  
  output$download <- downloadHandler(
    filename = function(){paste0("phenom_", format(Sys.time(),"%d_%m_%Y__%H_%M_%S"), ".csv")},
    content = function(fname){
      if(is.null(model_fit())){
        write.csv(NULL,fname)
      }else{
        write.csv(model_fit(),fname)
      }
    },
    contentType = "text/csv"
  )
  
})
