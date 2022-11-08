install.packages("rjson")

drugConceptsPath <- "./inst/settings/DrugConceptsToCreate.csv"
drugConcepts <- read.csv(drugConceptsPath)

#SQL

S <- readLines("./inst/sql/sql_server/MOAnormal_RFT_acetaminophen.sql")

for(i in seq(nrow(drugConcepts))){
  drugConceptId <- drugConcepts$concept_id[i]
  drugConceptName <- drugConcepts$concept_name[i]

  SS <- gsub(1125315, drugConceptId, S)
  filename <- paste0("./inst/sql/sql_server/MOAnormal_RFT_", drugConceptName, ".sql")
  writeLines(SS, filename)
}

#Json

J <- readLines("./inst/cohorts/MOAnormal_RFT_acetaminophen.json")

for(i in seq(nrow(drugConcepts))){
  drugConceptId <- drugConcepts$concept_id[i]
  drugConceptName <- drugConcepts$concept_name[i]
  
  JJ <- gsub(1125315, drugConceptId, J)
  JJ <- gsub("acetaminophen", drugConceptName, JJ)
  filename <- paste0("./inst/cohorts/MOAnormal_RFT_", drugConceptName, ".json")
  writeLines(JJ, filename) 
}

