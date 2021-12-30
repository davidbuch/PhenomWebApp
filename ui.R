#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(rstan)
# We do not load PhenomStanModel but it must be installed

# Define UI for application
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Phenom Microbial Growth Model"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("OdData", "Choose Optical Density Data File",
                accept = c(
                  "text/csv",
                  "text/comma-separated-values,text/plain",
                  ".csv")
      ),
      fileInput("MetaData", "Choose Meta Data File",
                accept = c(
                "text/csv",                  
                "text/comma-separated-values,text/plain",
                ".csv",
                "application/vnd.ms-excel",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                ".xlsx",
                ".xls")
      ),
      tags$hr(),
      checkboxInput("OdIsExcel", "OD Data is Excel File", FALSE),
      checkboxInput("MetaIsExcel", "Meta Data is Excel File", TRUE),
      tags$hr(),
      actionButton("run", "Fit Model")
    ),
    mainPanel(
      tableOutput("FitSummary"),
      tableOutput("OdDataFrame"),
      tableOutput("MetaDataFrame")
    )
  )
))
