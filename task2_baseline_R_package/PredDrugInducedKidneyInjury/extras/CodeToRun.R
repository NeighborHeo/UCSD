.libPaths("~/PredDrugInducedKidneyInjury/library")
# install.packages("remotes")
# remotes::install_github("OHDSI/FeatureExtraction")
# remotes::install_github("OHDSI/PatientLevelPrediction")
# remotes::install_github("OHDSI/CohortGenerator")

library(PredDrugInducedKidneyInjury)
#=======================
# USER INPUTS
#=======================
# The folder where the study intermediate and result files will be written:
outputFolder <- "~/PredDrugInducedKidneyInjury/output"

# Details for connecting to the server:
dbms <- "sql server"                    # "you dbms"
user <- "user"                          # "your username"
pw <- "password"                        # "your password"
server <- "111.111.111.111"             # "your server"
port <- "4333"                          # "your port"
pathToDriver <- "~/jdbcDrivers"         # "your db driver"

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port,
                                                                pathToDriver = pathToDriver)

# Add the database containing the OMOP CDM data
cdmDatabaseSchema <- "cdm.dbo"          # "cdm database schema"
# Add a sharebale name for the database containing the OMOP CDM data
cdmDatabaseName <- "cdm"                # "a friendly shareable name for your database"
# Add a database with read/write access as this is where the cohorts will be generated
cohortDatabaseSchema <- "temp_plp.dbo"  # "work database schema"

# table name where the cohorts will be generated
cohortTable <- "PredDrugInducedKidneyInjuryCohort"

# pick the minimum count that will be displayed if creating the shiny app, the validation package,
# the diagnosis or packaging the results to share
minCellCount <- 5

tempEmulationSchema <- NULL

databaseDetails <- PatientLevelPrediction::createDatabaseDetails(
        connectionDetails = connectionDetails, 
        cdmDatabaseSchema = cdmDatabaseSchema, 
        cdmDatabaseName = cdmDatabaseName, 
        tempEmulationSchema = tempEmulationSchema, 
        cohortDatabaseSchema = cohortDatabaseSchema, 
        cohortTable = cohortTable, 
        outcomeDatabaseSchema = cohortDatabaseSchema,  
        outcomeTable = cohortTable, 
        cdmVersion = 5
)

logSettings <- PatientLevelPrediction::createLogSettings(
        verbosity = 'INFO', 
        logName = 'PredDrugInducedKidneyInjury'
)




# ====================== PICK THINGS TO EXECUTE ======================= want to generate a study
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


# =======================

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

# Uncomment and run the next line to see the shiny results:
PatientLevelPrediction::viewMultiplePlp(outputFolder)
