## ---- echo = TRUE, message = FALSE, warning = FALSE,tidy=FALSE,eval=FALSE-----
#  install.packages("remotes")
#  remotes::install_github("OHDSI/FeatureExtraction")
#  remotes::install_github("OHDSI/PatientLevelPrediction")

## ---- echo = TRUE, message = FALSE, warning = FALSE,tidy=FALSE,eval=FALSE-----
#  library(PatientLevelPrediction)
#  reticulate::install_miniconda()
#  configurePython(envname='r-reticulate', envtype='conda')
#  

## ---- echo = TRUE, message = FALSE, warning = FALSE,tidy=FALSE,eval=FALSE-----
#  reticulate::conda_install(envname='r-reticulate', packages = c('scikit-survival'), forge = TRUE, pip = FALSE, pip_ignore_installed = TRUE, conda = "auto", channel = 'sebp')
#  

## ---- echo = TRUE, message = FALSE, warning = FALSE,tidy=FALSE,eval=FALSE-----
#  
#  # load the checkPlpInstallation function
#  library(devtools)
#  source_url('https://raw.github.com/OHDSI/PatientLevelPrediction/issue242/extras/checkPlpInstallation.R')
#  
#  # set up the database connection details
#  library(DatabaseConnector)
#  connectionDetails <- createConnectionDetails(
#    dbms = 'sql_server',
#    user = 'username',
#    password = 'hidden',
#    server = 'your server',
#    port = 'your port'
#    )
#  
#  # run the test
#  checkPlpInstallation(
#    connectionDetails = connectionDetails,
#    python = T
#    )

## ---- echo = TRUE, message = FALSE, warning = FALSE,tidy=FALSE,eval=FALSE-----
#  
#  checkPlpInstallation(
#    connectionDetails = connectionDetails,
#    python = F
#    )

## ----eval=FALSE---------------------------------------------------------------
#  usethis::edit_r_profile()

## ----eval=FALSE---------------------------------------------------------------
#  Sys.setenv(PATH = paste("your python bin location", Sys.getenv("PATH"), sep=":"))

## ----eval=FALSE---------------------------------------------------------------
#  reticulate::conda_list()

## ----tidy=TRUE,eval=TRUE------------------------------------------------------
citation("PatientLevelPrediction")

