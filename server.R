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

loadMetaFile <- function(inFile){
  if (is.null(inFile))
    return(NULL)
  
  meta <- read.csv(inFile$datapath)
  meta[] <- lapply(meta, factor) # convert all variables to factors before returning
  meta
}

loadOdFile <- function(inFile){
  if (is.null(inFile))
    return(NULL)
  
  read.csv(inFile$datapath, row.names = 1)
}

shinyServer(function(input, output) {
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

    if(input$modelSelect %in% c("MBATCH", "MFULL")){
      validate(
        need('BATCH' %in% names(meta), "MBATCH/MFULL selected but no 'BATCH' column detected in meta data.")
      )
    }

    
    # Identify the names of all treatment columns
    # Currently, we are assuming this includes all columns that aren't called
    # 'BATCH' or 'REPLICATE', which we reserve as keywords
    covariate_set <- names(meta)[!(names(meta) %in% c('BATCH', 'REPLICATE'))]

    model_params <- list(alpha_prior = c(input$alphaPriorShape,input$alphaPriorRate),
                         lengthscale_prior = c(input$lengthscalePriorShape,input$lengthscalePriorRate),
                         sigma_prior = c(input$sigmaPriorShape,input$sigmaPriorRate),
                         minExpectedCross = input$minZeroCrossings,
                         maxExpectedCross = input$maxZeroCrossings,
                         marginal_alpha_prior = c(input$marginalAlphaPriorShape,input$marginalAlphaPriorRate),
                         marginal_lengthscale_prior = c(input$marginalLengthscalePriorShape,input$marginalLengthscalePriorRate))
    
    stan_data <- createStanData(od, meta, model_params, input$modelSelect)
    
    # MFULL uses the "phenom_marginal" stanmodel object
    # MNULL/MBATCH use "phenom_deriv"
    if(input$modelSelect == "MFULL"){
      stan_model <- PhenomStanModel:::stanmodels$phenom_marginal
    }else{
      stan_model <- PhenomStanModel:::stanmodels$phenom_deriv
    }

    shinybusy::show_spinner() # Indicate that we are busy sampling
    stan_fit <- rstan::sampling(
      object = stan_model,
      data = stan_data,
      chains = round(input$chains),
      iter = round(input$iter),
      warmup = round(input$warmup),
      thin = round(input$thin)
    )
    shinybusy::hide_spinner() # Indicate that we are done sampling
    
    summary(stan_fit)$summary[,c(4,6,8:10)]
  }, ignoreNULL = TRUE)
  
  output$fitSummary <- renderTable({
    if (is.null(model_fit()))
      return(NULL)
    else
      return(model_fit())
  })

  output$downloadButton <- renderUI({
    req(model_fit()) # requires result to be non-null before showing button
    downloadButton('Download',"Download Model Fit Summary")
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
