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
main_analysis <- tabPanel("Ananlyze Data", fluidPage(
  tags$div(style = "position: absolute; top: -100px;",
           textOutput("clock")
  ), # keep the app from "greying out" on shinyapps.io (connection stops when inactive)
  sidebarLayout(
    position = "left",
    sidebarPanel(
      fileInput("odData", "Choose Optical Density Data File",
                accept = c(
                  "text/csv",
                  "text/comma-separated-values,text/plain",
                  ".csv")
      ),
      fileInput("metaData", "Choose Meta Data File",
                accept = c(
                "text/csv",                  
                "text/comma-separated-values,text/plain",
                ".csv")
      ),
      tags$hr(),
      uiOutput("fitModelButton"),
      shinybusy::use_busy_spinner(spin = "fading-circle"),
      br(),
      uiOutput("downloadButton")
    ),
    mainPanel(
      plotOutput("odDataPlot"),
      tableOutput("metaDataFrame")
    )
  )
))

# model_parameters <- tabPanel("Model Parameters",fixedPage(
#   fixedRow(
#     column(12,
#     h4("Warning: Default values should work well for most users.
#            Modify at your own risk. Selected parameters are recylced across all
#            functional effect prior distributions, regardless of model version,
#            except where specified.")
#     )
#   ),
#   fixedRow(
#     column(6,
#            numericInput("alphaPriorShape",
#                         "Alpha prior (Gamma distribution shape)",
#                         value = 1)),
#     column(6,
#            numericInput("alphaPriorRate",
#                         "Alpha prior (Gamma distribution rate)",
#                         value = 1))
#   ),
#   fixedRow(
#     column(6,
#            numericInput("lengthscalePriorShape",
#                         "Lengthscale prior (Inverse-Gamma distribution shape)",
#                         value = 1)),
#     column(6,
#            numericInput("lengthscalePriorRate",
#                         "Lengthscale prior (Inverse-Gamma distribution rate)",
#                         value = 1))
#   ),
#   fixedRow(
#     column(6,
#            numericInput("minZeroCrossings",
#                         "Minimum Expected Zero Crossings for Functional Effects",
#                         value = 0.01)),
#     column(6,
#            numericInput("maxZeroCrossings",
#                         "Maximum Expected Zero Crossings for Functional Effects",
#                         value = 100.0))
#   ),
#   fixedRow(
#     column(6,
#            numericInput("sigmaPriorShape",
#                         "Sigma (MNULL/MBATCH error) prior (Gamma distribution shape)",
#                         value = 1)),
#     column(6,
#            numericInput("sigmaPriorRate",
#                         "Sigma (MNULL/MBATCH error) prior (Gamma distribution rate)",
#                         value = 1))
#   ),
#   fixedRow(
#     column(6,
#            numericInput("marginalAlphaPriorShape",
#                         "Alpha (MFULL error) prior (Gamma distribution shape)",
#                         value = 1)),
#     column(6,
#            numericInput("marginalAlphaPriorRate",
#                         "Alpha (MFULL error) prior (Gamma distribution rate)",
#                         value = 1))
#   ),
#   fixedRow(
#     column(6,
#            numericInput("marginalLengthscalePriorShape",
#                         "Lengthscale (MFULL error) prior (Inverse-Gamma distribution shape)",
#                         value = 1)),
#     column(6,
#            numericInput("marginalLengthscalePriorRate",
#                         "Lengthscale (MFULL error) prior (Inverse-Gamma distribution rate)",
#                         value = 1))
#   ),
# ))
# 
# sampling_parameters <- tabPanel("Sampling Parameters",fixedPage(
#   fixedRow(
#     column(12,
#     h4("Warning: Default values should work well for most users.
#            Modify at your own risk.")
#     )
#   ),
#   fixedRow(
#     column(12,
#            numericInput("chains",
#                         "Number of Markov chains: ",
#                         value = 2))
#   ),
#   fixedRow(
#     column(12,
#            numericInput("iter",
#                         "Sampling iterations for each chain (including warmup): ",
#                         value = 1000))
#   ),
#   fixedRow(
#     column(12,
#            numericInput("warmup",
#                         "Number of warm-up iterations to discard per chain: ",
#                         value = 500))
#   ),
#   fixedRow(
#     column(12,
#            numericInput("thin",
#                         "Thinning factor for samples: ",
#                         value = 1))
#   )
# ))

app_information <- tabPanel("App Information",
                       fluidRow(
                         column(12,
                                h2("Instructions"),
                                p("Welcome to the beta test of the Phenom web app. 
                                  This application will analyze microbial growth data 
                                  collected by an optical density scanner, fitting the 
                                  flexible *Phenom* model described in Tonner et al. (2020).
                                  Specifically, we fit the 'MFULL' model described in that
                                  article, which features random effects for experimental
                                  replicates and (if included in the user-provided 
                                  meta-data) experimental batches. Using flexible Gaussian Process
                                  models, we learn growth curves, with pointwise
                                  standard errors, for each experimental treatment condition.
                                  Since we allow for the possibility of multi-way covariate interactions,
                                  this app expects all combinations of covariate levels
                                  are observed for at least one replicate.
                                  To use this application you will need to make sure you 
                                  have correctly formatted your data files in advance, as 
                                  outlined below:")
                         )),
                       fluidRow(
                         column(12,
                                h3("Optical Density Data"),
                                p("Here we need a 'csv' file with N+1 rows and P+1 columns, 
                                  where N is the number of time points and P is the number of wells
                                  in which optical density measurements were taken. 
                                  The first row will consist of column labels, and the first column
                                  will contain the times at which observations were recorded. 
                                  The remaining PxN cells will contain optical density measurements.
                                  Please subsample Optical Density time-series to ensure N <= 15, 
                                  since time to fit this model scales with N^3, and even with 15 rows you 
                                  can expect the fitting process to last up to 48 hours.
                                  Note that, while the first row must be reserved for names, we need 
                                  not specify a name for every column. A screenshot of a 
                                  well-formatted file is provided below.")
                         )),
                        fluidRow(img(src='od_screenshot.png', width = "40%", align = "left")),
                       fluidRow(
                         column(12,
                                h3("Meta Data"),
                                p("Here we need a 'csv' file with P+1 rows and J columns, 
                                  where P matches our optical density data. 
                                  The first row will consist of column labels, and 
                                  each row thereafter will correspond to the P wells, 
                                  in the same order as the columns of the optical density dataset. 
                                  The jth column will contain the treatment level for each well along 
                                  the jth covariate. The column name 'BATCH', in all capital letters, 
                                  is reserved to indicate experimental batches. 
                                  If no 'BATCH' column is included, the app will 
                                  assume that all replicates were observed in 
                                  the same batch, and no batch-level random effect
                                  will be included. Any column included in the
                                  meta-data file (including 'BATCH', if it is used)
                                  must feature at least 2 treatment levels. The effects of
                                  treatment conditions which are not varied across 
                                  replicates are absorbed into the intercept and 
                                  are not separately identifiable.
                                  Since we allow for the possibility of multi-way covariate 
                                  interactions, all possible covariate combinations must be present 
                                  in your meta-data to fit the model.
                                  To satisfy this requirement, you can either add replicates 
                                  collected under those missing experimental conditions or 
                                  remove treatment covariates from your meta-data file.
                                  A screenshot of a well-formatted file is provided below.")
                         )),
                        fluidRow(img(src='meta_screenshot.png', width = "20%", align = "left")),
                        fluidRow(
                          column(12,
                                h3("Fitting the Model and Dowloading Results"),
                                p("Once you have uploaded both (1) a file containing 
                                  a sequence of optical density measurements for a 
                                  collection of wells, and (2) a meta data file 
                                  indicating the treatments applied to each well, 
                                  a button will appear to fit the model. At the 
                                  same time, a plot of the optical density data 
                                  and a printout of the metadata will appear below 
                                  this text so that the user can appraise whether 
                                  their data have been uploaded and parsed correctly. 
                                  When you are ready, click 'Fit Model' and
                                  the app will fit the Phenom model to the provided 
                                  data. Depending on the number of timepoints, the 
                                  number of replicates, the number of covariates, 
                                  and the number of treatment levels within each covariate, 
                                  this may take quite a while (10 min to a few hours). 
                                  In the meantime, a spinning wheel will appear in the top right corner 
                                  of the display to indicate the model is being fit. 
                                  Once the process is complete, another button will 
                                  appear which will allow you to download a summary 
                                  of the model fit, along with MCMC convergence 
                                  diagnostics.")
                          )),
                       fluidRow(
                         column(12,
                                h3("Acknowledgements"),
                                tags$ul(
                                  tags$li(a("Schmid Lab", href = "https://schmidlab.biology.duke.edu/")),
                                  tags$li(a("Schmidler Lab", href = "http://www2.stat.duke.edu/~scs/Research.shtml")),
                                  tags$li(a("Peter Tonner", href = "https://www.linkedin.com/in/petertonner")),
                                  tags$li(a("David Buch", href = "https://davidbuch.github.io")),
                                  tags$li("Data+ 2021 Team: Molly Borowiak, Josh Tennyson"),
                                  tags$li("MIDS 2021 Capstone Team: Chayut Wongkamthong, Andrew Patterson, and Joseph Krinke") 
                                )
                         ))
)



# Don't include "model_parameters" or "sampling_parameters" pages
# because Dr. Schmid things they will be confusing to users.
navbarPage("Phenom Microbial Growth Model",
           app_information,
           main_analysis
           )