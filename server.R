#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  output$MetaDataFrame <- renderTable({
    inFile <- input$MetaData
    if (is.null(inFile))
      return(NULL)
    else if (input$MetaIsExcel)
      return(readxl::read_excel(inFile$datapath))
    else
      return(read.csv(inFile$datapath))
  })
  output$OdDataFrame <- renderTable({
    inFile <- input$OdData
    if (is.null(inFile))
      return(NULL)
    else if (input$OdIsExcel)
      return(readxl::read_excel(inFile$datapath))
    else
      return(read.csv(inFile$datapath))
  })
  
  sfit <- eventReactive(input$run, {
    
    rstan::sampling(
      object = PhenomStanModel:::stanmodels$phenom_deriv,
      data = list(),
      chains = 2,
      iter = 1000
    )
  }, ignoreNULL = TRUE)
  
  output$FitSummary <- renderTable({
    if (is.null(sfit()))
      return(NULL)
    else
      return(sfit()$summary)
  })
  
})
