#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

loadMetaFile <- function(inFile){
  if (is.null(inFile))
    return(NULL)
  
  read.csv(inFile$datapath)
}

loadOdFile <- function(inFile){
  if (is.null(inFile))
    return(NULL)
  
  read.csv(inFile$datapath, row.names = 1)
}

createStanData <- function(od, meta, model_params){
  L <- 1 # number of priors
  K <- nlevels(factor(meta[,1])) # number of functions
  priors <- rep(1,K) # prior assignment for each functional coefficient
  maxExpectedCross <- 100
  minExpectedCross <- 0.01
  
  ls_min <- 1/(pi*maxExpectedCross)
  ls_max <- 1/(pi*minExpectedCross)
  
  x <- as.numeric(row.names(od))
  y <- as.matrix(od)
  dm <- model.matrix(~factor(meta[,1]) - 1)
  
  stan_data <- list(
    N = length(x), # number of timepoints
    P = ncol(y), # number of observations
    design = dm, # design matrix
    x = x, # observation times
    y = t(y), # each row is one well's time series of OD measurements
    K = K,
    L = L,
    prior = rep(1,K), # prior assignment for each functional coefficient
    alpha_prior = matrix(1, nrow = L, ncol = 2),
    lengthscale_prior = matrix(1, nrow = L, ncol = 2),
    sigma_prior = c(1,1),
    ls_min = 1/(pi*100), # equiv. to "maxExpectedCross = 100"
    ls_max = 1/(pi*0.01) # equiv. to "minExpectedCross = 0.01"
  )
  return(stan_data)
}

shinyServer(function(input, output) {
  od <- eventReactive(input$OdData,{
    loadOdFile(input$OdData)
  })
  meta <- eventReactive(input$MetaData,{
    loadMetaFile(input$MetaData)
  })

  output$OdDataPlot <- renderPlot({
    req(od())
    od <- od()
    matplot(as.numeric(row.names(od)), od, 
            type = "l", 
            xlab = "Time", 
            ylab = "Optical Density",
            main = "Observed Data")
  })
  output$MetaDataFrame <- renderTable({
    meta()
  })
  
  output$FitModelButton <- renderUI({
    req(od())
    req(meta())
    actionButton("run", "Fit Model")
  })
  
  res <- eventReactive(input$run, {
    od <- od()
    meta <- meta()
    validate(
      need(ncol(od()) == nrow(meta()), "Columns of Optical Density data must match rows of meta data.")
    )
    
    model_params <- NULL
    sampling_params <- NULL
    if(is.null(sampling_params)){
      sampling_params <- list(chains = 2, iter = 1000)
    }
    
    stan_data <- createStanData(od, meta, model_params)
    
    # attach sampling_params for stan call
    shinybusy::show_spinner() # Indicate that we are busy sampling
    attach(sampling_params)
    stan_fit <- rstan::sampling(
      object = PhenomStanModel:::stanmodels$phenom_deriv,
      data = stan_data,
      chains = chains,
      iter = iter
    )
    detach(sampling_params)
    shinybusy::hide_spinner() # Indicate that we are done sampling
    
    summary(stan_fit)$summary[,c(4,6,8:10)]
  }, ignoreNULL = TRUE)
  
  output$FitSummary <- renderTable({
    if (is.null(res()))
      return(NULL)
    else
      return(res())
  })

  output$DownloadButton <- renderUI({
    req(res()) # requires result to be non-null before showing button
    downloadButton('Download',"Download Model Fit Summary")
  })
  
  output$Download <- downloadHandler(
    filename = function(){paste0("phenom_", format(Sys.time(),"%d_%m_%Y__%H_%M_%S"), ".csv")},
    content = function(fname){
      if(is.null(res())){
        write.csv(NULL,fname)
      }else{
        write.csv(res(),fname)
      }
    },
    contentType = "text/csv"
  )
  
})
