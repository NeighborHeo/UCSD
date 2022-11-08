Prediction of Drug Induced Kidney Injury
========================================================

- Analytics use case(s): **Patient-Level-Prediction**
- Study type: **Clinical Application**
- Tags: **-**
- Study lead: **Seng Chan You**
- Study lead forums tag: **-**
- Study start date: **Feburary 2022**
- Study end date: **-**
- Protocol: **-**
- Publications: **-**
- Results explorer: **-**

Requirements
============

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, IBM Netezza, Apache Impala, Amazon RedShift, Google BigQuery, or Microsoft APS.
- R version 4.1.3 (recommended)
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- 100 GB of free disk space

Instructions
========================================================

- [Instructions to build the study library if generated using ATLAS](STUDY-PACKAGE-BUILD.md)
- [Instructions to share an ATLAS generated study library on github](STUDY-PACKAGE-SHARE.md)
- [Instructions to execute the study ](STUDY-PACKAGE-EXECUTE.md)

1. Follow [these instructions](https://ohdsi.github.io/Hades/rSetup.html) for seting up your R environment, including RTools and Java.

2. (option) Open your study package in RStudio. Use the following code to install all the dependencies:

	```r
	install.packages("renv")
	renv::activate()
	renv::restore()
	```

3. In RStudio, select 'Build' then 'Install and Restart' to install the `PredDrugInducedKidenyInjury` package.

4. Once installed, you can execute the feasibility assessment partion of the study by modifying and using the code below. For your convenience, this code is also provided under `extras/CodeToRun.R`:

	```r
	library(PredDrugInducedKidneyInjury)
    #=======================
    # USER INPUTS
    #=======================
    # The folder where the study intermediate and result files will be written:
    outputFolder <- "~/result"

    # set-up your details for connecting to the server:
    dbms <- 
    user <- 
    pw <- 
    server <- 
    port <- 
    pathToDriver <- 

    connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                    server = server,
                                                                    user = user,
                                                                    password = pw,
                                                                    port = port,
                                                                    pathToDriver = pathToDriver)
    
    
    # Add the database containing the OMOP CDM data
    cdmDatabaseSchema <- "cdm.dbo"
    # Add a sharebale name for the database containing the OMOP CDM data
    cdmDatabaseName <- "cdm"
    # Add a database with read/write access as this is where the cohorts will be generated
    cohortDatabaseSchema <- "cdm.dbo"
    # table name where the cohorts will be generated
    cohortTable <- "PredDrugInducedKidenyInjuryCohort"

	```

5. Pick things to execute to want to generate a study
  	```r
    # protocol? Set below to TRUE
    createProtocol <- FALSE
    # want to generate the cohorts for the study? Set below to TRUE
    createCohorts <- TRUE
    # want to run a diagnoston on the prediction and explore results? Set below to TRUE
    runDiagnostic <- FALSE
    viewDiagnostic <- FALSE
    # want to run the prediction study? Set below to TRUE
    runAnalyses <- TRUE
    sampleSize <- 100000  # edit this to the number to sample if needed
    # want to populate the protocol with the results? Set below to TRUE
    createResultsDoc <- FALSE
    # want to create a validation package with the developed models? Set below to TRUE
    createValidationPackage <- FALSE
    analysesToValidate <- NULL
    # want to package the results ready to share? Set below to TRUE
    packageResults <- TRUE
    # want to create a shiny app with the results to share online? Set below to TRUE
    createShiny <- TRUE
    # want to create a journal document with the settings and results populated? Set below to TRUE
    createJournalDocument <- FALSE
    analysisIdDocument <- 1
    ```

9. Execute the Prediction Study via:
	```r
	execute(databaseDetails = databaseDetails,
            outputFolder = outputFolder, 
            createProtocol = createProtocol, 
            createCohorts = createCohorts, 
            runDiagnostic = runDiagnostic,
            viewDiagnostic = viewDiagnostic, 
            runAnalyses = runAnalyses, 
            createValidationPackage = createValidationPackage, 
            analysesToValidate = analysesToValidate, 
            packageResults = packageResults,
            minCellCount = minCellCount, 
            logSettings = logSettings)
	```
	and upload the file ```outputfolder``` in the output folder to the study coordinator:

	```r
	# Uncomment and run the next line to see the shiny results:
    PatientLevelPrediction::viewMultiplePlp(outputFolder)
	```

License
=======
The `PredDrugInducedKidenyInjury` package is licensed under Apache License 2.0

Development
===========
`PredDrugInducedKidenyInjury` was developed in ATLAS and R Studio.

Extras
========================================================

For information on how to generate shiny apps using the R skeleton package see: [Creating shiny app for patient-level prediction studies](https://raw.githubusercontent.com/OHDSI/PatientLevelPrediction/testcode/inst/doc/CreatingShinyApp.pdf).  To combine multiple skeleton package results into a single shiny app [see populate multiple shiny app R code code](https://github.com/OHDSI/PredDrugInducedKidenyInjury/blob/master/extras/populateMultipleShiny.R)

For information on adding custom covariates based on ATLAS cohorts see:  [Adding custom covariates using ATLAS cohorts](https://raw.githubusercontent.com/OHDSI/PredDrugInducedKidenyInjury/master/inst/doc/AddingCohortCovariates.pdf).
