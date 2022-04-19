# PhenomWebApp
A web app for fitting Tonner et al's Phenom model to Microbial Growth Data, created with RShiny

This app is currently hosted at https://davidabuch.shinyapps.io/phenom_web_app

If you would like to run this Shiny app locally, you can do so using RStudio.

To get started, open RStudio and enter
```install.packages("devtools")```
in the command console.

You will then use the "devtools" package to install the app's helper package ```PhenomStanModel```.
To install that package, enter
```devtools::install_github("davidbuch/PhenomStanModel")```
in the command console. In the process, you may be prompted by RStudio or your operating system to install other packages 
which support the download and compilation of the ```PhenomStanModel``` package. You may see a lot of warning messages depending 
on your current version of ```rstan```, but these will not impact your results.

Next, download this repository (using the green "code" button above, if you are using GitHub) and open either ```ui.R``` or ```server.R``` with RStudio. You may receive a warning about remaining package dependencies in the editor window, but all of these will be available on CRAN so you should be able to click "install" when prompted to download those. 

Finally, click "Run App" in the top right corner of the script editor pane, and the Web App interface will open.
