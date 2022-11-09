## ---- echo = FALSE, message = FALSE, warning = FALSE--------------------------
library(PatientLevelPrediction)

## ---- echo = TRUE, eval=FALSE-------------------------------------------------
#  createAgeSpine <- function(
#                       knots = 5
#                       ){
#  
#    # add input checks
#    checkIsClass(knots, c('numeric','integer'))
#    checkHigher(knots,0)
#  
#    # create list of inputs to implement function
#    featureEngineeringSettings <- list(
#      knots = knots
#      )
#  
#    # specify the function that will implement the sampling
#    attr(featureEngineeringSettings, "fun") <- "implementAgeSpine"
#  
#    # make sure the object returned is of class "sampleSettings"
#    class(featureEngineeringSettings) <- "featureEngineeringSettings"
#    return(featureEngineeringSettings)
#  
#  }

## ----tidy=FALSE,eval=FALSE----------------------------------------------------
#  implementAgeSpine <- function(trainData, featureEngineeringSettings){
#  
#    # currently not used
#    knots <- featureEngineeringSettings$knots
#  
#  
#    # age in in trainData$labels as ageYear
#    ageData <- trainData$labels
#  
#    # now implement the code to do your desired feature engineering
#  
#    data <- Matrix::sparseMatrix(
#      i = 1:length(ageData$rowId),
#      j = rep(1, length(ageData$rowId)),
#      x = ageData$ageYear,
#      dims=c(length(ageData$rowId),1)
#    )
#  
#    data <- as.matrix(data)
#    x <- data[,1]
#    y <- ageData$outcomeCount
#  
#  mRCS <- rms::ols(
#    y~rms::rcs(x,
#               stats::quantile(
#                 x,
#                 c(0, .05, .275, .5, .775, .95, 1),
#                 include.lowest = TRUE
#                 )
#               )
#    )
#  
#  newData <- data.frame(
#    rowId = ageData$rowId,
#    covariateId = 2002,
#    covariateValue = mRCS$fitted.values
#    )
#  
#  # add new data
#  Andromeda::appendToTable(tbl = trainData$covariateData$covariates,
#                           data = newData)
#  
#  featureEngeering <- list(
#      funct = 'implementAgeSpine',
#      settings = list(
#        featureEngineeringSettings = featureEngineeringSettings
#      )
#    )
#  
#    attr(trainData, 'metaData')$featureEngineering = listAppend(
#      attr(trainData, 'metaData')$featureEngineering,
#      featureEngeering
#   )
#    # return the updated trainData
#    return(trainData)
#  }
#  

## ----tidy=TRUE,eval=TRUE------------------------------------------------------
citation("PatientLevelPrediction")

