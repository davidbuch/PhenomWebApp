# PhenomWebApp
A web app for fitting Tonner et al's Phenom model to Microbial Growth Data, created with RShiny

This app is currently hosted at https://davidabuch.shinyapps.io/phenom_web_app

If you would like to run this Shiny app locally, you can do so using RStudio.

Before getting started, you first need to install the app's helper package ```PhenomStanModel```.
To install that package, try running 
```devtools::install_github("davidbuch/PhenomStanModel")```
in the command console of RStudio. 

If that doens't work, you may need to first install the devtools package from CRAN.
To install ```devtools``` you simply need to enter
```install.packages("devtools")```
in the command console.

All other dependencies for this app are available on CRAN, and RStudio should prompt you to install these packages if you have not installed them already.

One you have successfully installed that package, simply download this repository, open either ```ui.R``` or ```server.R``` with RStudio, 
and click "Run App" in the top right corner of the script editor pane.
