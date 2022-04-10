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
library(PhenomStanModel)
library(shinybusy)
# We do not load rstan, PhenomStanModel, or shinybusy but they must be installed

# Define UI for application
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Phenom Microbial Growth Model"),
  
  sidebarLayout(
    position = "right",
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
                ".csv")
      ),
      tags$hr(),
      uiOutput("FitModelButton"),
      shinybusy::use_busy_spinner(spin = "fading-circle"),
      br(),
      uiOutput("DownloadButton")
    ),
    mainPanel(
      h2("Instructions"),
      p("Welcome to the beta test of the Phenom web app. This application will analyze microbial growth data collected by an optical density scanner, fitting the flexible *Phenom* model described in Tonner et al. (2020). This preliminary version of the app will only fit the so-called 'MNULL' version of the model outlined in that article. Furthermore, to use this application you will need to make sure you have correctly formatted your data files in advance, as outlined below:"),
      h3("Optical Density Data"),
      p("Here we need a 'csv' file with P+1 rows and N+1 columns, where P is the number of time points and N is the number of wells in which optical density measurements were taken. The first row will consist of column labels, and the first column will contain the times at which observations were recorded. The remaining PxN cells will contain optical density measurements. Note that, while the first row must be reserved for names, we need not specify a name for every column. A screenshot of a well-formatted file is provided below."),
      br(),
      fluidRow(img(src='od_screenshot.png', width = "40%", align = "left")),
      br(),
      h3("Meta Data"),
      p("Here we need a 'csv' file with N+1 rows and 1 column, where N is the same as above. The first row will consist of column labels, and each row thereafter will correspond to the N wells, in the same order as the columns of the optical density dataset. The column will contain the treatment value of each well. A screenshot of a well-formatted file is provided below."),
      br(),
      fluidRow(img(src='meta_screenshot.png', width = "20%", align = "left")),
      br(),
      h3("Fitting the Model and Dowloading Results"),
    p("Once you have uploaded both (1) a file containing a sequence of optical density measurements for a collection of wells , and (2) a meta data file indicating the treatments applied to each well, a button will appear to fit the model. At the same time, a plot of the optical density data and a printout of the metadata will appear below this text so that the user can appraise whether their data have been uploaded and parsed correctly. When the botton is clicked, the app will fit the Phenom model to the provided data. Depending on the size of the dataset, this may take quite a while (10 min to several hours). In the meantime, a spinning wheel will appear in the top right corner of the display to indicate the model is being fit. Once the process is complete, another button will appear which will allow you to download a summary of the model fit, along with MCMC convergence diagnostics."),
      tableOutput("FitSummary"),
      plotOutput("OdDataPlot"),
      tableOutput("MetaDataFrame")
    )
  )
))
