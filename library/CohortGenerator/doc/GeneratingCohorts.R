## ----setup, include=FALSE-----------------------------------------------------
options(width = 80)
knitr::opts_chunk$set(
  cache = FALSE,
  comment = "#>",
  error = FALSE)
someFolder <- tempdir()
packageRoot <- tempdir()
baseUrl <- "https://api.ohdsi.org/WebAPI"
library(CohortGenerator)

## ----results='hide', error=FALSE, warning=FALSE, message=FALSE----------------
# A list of cohort IDs for use in this vignette
cohortIds <- c(1778211,1778212,1778213)
# Get the SQL/JSON for the cohorts
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(baseUrl = baseUrl,
                                                               cohortIds = cohortIds)

## -----------------------------------------------------------------------------
names(cohortDefinitionSet)

## ---- results='hide', error=FALSE, warning=FALSE, message=FALSE---------------
saveCohortDefinitionSet(cohortDefinitionSet = cohortDefinitionSet,
                        settingsFileName = file.path(packageRoot, "inst/settings/CohortsToCreate.csv"),
                        jsonFolder = file.path(packageRoot, "inst/cohorts"),
                        sqlFolder = file.path(packageRoot, "inst/sql/sql_server"))

## ---- results='hide', error=FALSE, warning=FALSE, message=FALSE---------------
cohortDefinitionSet <- getCohortDefinitionSet(settingsFileName = file.path(packageRoot, "inst/settings/CohortsToCreate.csv"),
                                              jsonFolder = file.path(packageRoot, "inst/cohorts"),
                                              sqlFolder = file.path(packageRoot, "inst/sql/sql_server"))

## ---- results='hide', error=FALSE, warning=FALSE, message=FALSE---------------
# Get the Eunomia connection details
connectionDetails <- Eunomia::getEunomiaConnectionDetails()

# First get the cohort table names to use for this generation task
cohortTableNames <- getCohortTableNames(cohortTable = "cg_example")

# Next create the tables on the database
createCohortTables(connectionDetails = connectionDetails,
                   cohortTableNames = cohortTableNames,
                   cohortDatabaseSchema = "main")

# Generate the cohort set
cohortsGenerated <- generateCohortSet(connectionDetails= connectionDetails,
                                      cdmDatabaseSchema = "main",
                                      cohortDatabaseSchema = "main",
                                      cohortTableNames = cohortTableNames,
                                      cohortDefinitionSet = cohortDefinitionSet)


## ---- error=FALSE, warning=FALSE----------------------------------------------
getCohortCounts(connectionDetails = connectionDetails,
                cohortDatabaseSchema = "main",
                cohortTable = cohortTableNames$cohortTable)

## ---- results='hide', error=FALSE, warning=FALSE, message=FALSE---------------
# Get the cohorts and include the code to generate inclusion rule stats
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(baseUrl = baseUrl,
                                                               cohortIds = cohortIds,
                                                               generateStats = TRUE)

## ---- results='hide', error=FALSE, warning=FALSE, message=FALSE---------------
# First get the cohort table names to use for this generation task
cohortTableNames <- getCohortTableNames(cohortTable = "stats_example")

# Next create the tables on the database
createCohortTables(connectionDetails = connectionDetails,
                   cohortTableNames = cohortTableNames,
                   cohortDatabaseSchema = "main")

# We can then generate the cohorts the same way as before and it will use the 
# cohort statstics tables to store the results
# Generate the cohort set
generateCohortSet(connectionDetails= connectionDetails,
                  cdmDatabaseSchema = "main",
                  cohortDatabaseSchema = "main",
                  cohortTableNames = cohortTableNames,
                  cohortDefinitionSet = cohortDefinitionSet)


## ---- results='hide', error=FALSE, warning=FALSE, message=FALSE---------------
insertInclusionRuleNames(connectionDetails = connectionDetails,
                         cohortDefinitionSet = cohortDefinitionSet,
                         cohortDatabaseSchema = "main",
                         cohortInclusionTable = cohortTableNames$cohortInclusionTable)

exportCohortStatsTables(connectionDetails = connectionDetails,
                        cohortDatabaseSchema = "main",
                        cohortTableNames = cohortTableNames,
                        cohortStatisticsFolder = file.path(someFolder, "InclusionStats"))

## ---- results='hide', error=FALSE, warning=FALSE, message=FALSE---------------
dropCohortStatsTables(connectionDetails = connectionDetails,
                      cohortDatabaseSchema = "main",
                      cohortTableNames = cohortTableNames)


## ---- results='hide', error=FALSE, warning=FALSE, message=FALSE---------------
# Create a set of tables for this example
cohortTableNames <- getCohortTableNames(cohortTable = "cohort")
createCohortTables(connectionDetails = connectionDetails,
                   cohortTableNames = cohortTableNames,
                   cohortDatabaseSchema = "main",
                   incremental = TRUE)


## -----------------------------------------------------------------------------
createCohortTables(connectionDetails = connectionDetails,
                   cohortTableNames = cohortTableNames,
                   cohortDatabaseSchema = "main",
                   incremental = TRUE)

## ---- results='hide', error=FALSE, warning=FALSE, message=FALSE---------------
generateCohortSet(connectionDetails= connectionDetails,
                  cdmDatabaseSchema = "main",
                  cohortDatabaseSchema = "main",
                  cohortTableNames = cohortTableNames,
                  cohortDefinitionSet = cohortDefinitionSet,
                  incremental = TRUE,
                  incrementalFolder = file.path(someFolder, "RecordKeeping"))

## -----------------------------------------------------------------------------
generateCohortSet(connectionDetails= connectionDetails,
                  cdmDatabaseSchema = "main",
                  cohortDatabaseSchema = "main",
                  cohortTableNames = cohortTableNames,
                  cohortDefinitionSet = cohortDefinitionSet,
                  incremental = TRUE,
                  incrementalFolder = file.path(someFolder, "RecordKeeping"))

