DROP TABLE IF EXISTS new_drug_era_arb;

-- 1. Hepatotoxicity_12_drugs
create temp table new_drug_era_arb as
	SELECT DISTINCT '0' AS test_no
			, A.person_id
			, CAST(A.drug_era_start_date- CAST(year_of_birth || '-'|| month_of_birth|| '-'|| day_of_birth AS DATE) AS INT )/365  AS age_onset
	  		, drug_concept_id
			, lower(concept_name) AS ingredient_name
      		, min(drug_era_start_date ) as drug_era_start_date
      		, drug_era_end_date 
      		, drug_era_end_date - drug_era_start_date + 1 AS exposure_period_days
			FROM kyuh_cdm_5_3_2020.drug_era A
			INNER JOIN kyuh_cdm_5_3_2020.person P ON A.person_id = P.person_id	
			INNER JOIN kyuh_cdm_5_3_2020.concept C ON A.drug_concept_id = C.concept_id
			WHERE A.drug_concept_id IN (SELECT concept_id FROM kyuh_cdm_5_3.concept WHERE lower(concept_name) 
										like ANY(ARRAY['%azilsartan%', '%candesartan%', '%eprosartan%', '%fimasartan%', '%irbesartan%', '%olmesartan%'
													  , '%telmisartan%', '%valsartan%']))
			AND CAST(A.drug_era_start_date- CAST(year_of_birth || '-'|| month_of_birth|| '-'|| day_of_birth AS DATE) AS INT )/365 <= 65
			GROUP BY A.person_id, age_onset, drug_concept_id, ingredient_name, drug_era_start_date, drug_era_end_date , exposure_period_days;
			
			
-- 2. Hepatotoxicity_total_drugs
create temp table new_drug_era_total as
	SELECT DISTINCT '0' AS test_no
			, A.person_id 
			, CAST(A.drug_era_start_date- CAST(year_of_birth || '-'|| month_of_birth|| '-'|| day_of_birth AS DATE) AS INT )/365  AS age_onset
	  		, drug_concept_id
			, lower(concept_name) AS ingredient_name
      		, min(drug_era_start_date ) as drug_era_start_date
      		, drug_era_end_date 
      		, drug_era_end_date - drug_era_start_date + 1 AS exposure_period_days
			FROM kyuh_cdm_5_3_2020.drug_era A
			INNER JOIN kyuh_cdm_5_3_2020.person P ON A.person_id = P.person_id	
			INNER JOIN kyuh_cdm_5_3_2020.concept C ON A.drug_concept_id = C.concept_id
			AND CAST(A.drug_era_start_date- CAST(year_of_birth || '-'|| month_of_birth|| '-'|| day_of_birth AS DATE) AS INT )/365 <=65
			GROUP BY A.person_id, age_onset, drug_concept_id, ingredient_name, drug_era_start_date, drug_era_end_date , exposure_period_days;
			
			
-- 3. Hepatotoxicity_case
-- ALT : 3006923
-- AST : 3013721
-- ALP : 3035995
-- Bilirubin : 3011258

create temp table hep_case as
SELECT Z.condition_source_value, Z.ingredient_name, count(distinct Z.person_id) FROM (
(SELECT AA.person_id, AA.ingredient_name, AA.drug_era_start_date, AA.drug_era_end_date, C.condition_source_value, C.condition_start_date FROM 
(SELECT A.person_id
      , A.age_onset
	  , A.ingredient_name
      , A.drug_era_start_date
      , A.drug_era_end_date 
      , A.exposure_period_days
		FROM new_drug_era_arb A) AA
	
         LEFT JOIN  --탐색기간 전 아래 진단명 가진 경우 제외(Exclusion Criteria)
        (SELECT *
         FROM kyuh_cdm_5_3_2020.condition_occurrence
         WHERE upper(condition_source_value )
         LIKE any(array['K25%', 'K26%', 'K27%', 'B15%', 'B16%', 'B17%', 'B18%', 'B19%', 'E84%', 'E20%', 'E21%'])) B 
        ON AA.person_id = B.person_id AND B.condition_start_date < AA.drug_era_start_date::date - 60

		LEFT JOIN --탐색기간 전 검사 수치 정상
		(SELECT person_id, measurement_date,value_as_number, range_low, range_high 
		FROM kyuh_cdm_5_3_2020.measurement WHERE  measurement_concept_id in (3006923, 3013721, 3035995, 3011258))   E           -- ALT
		ON AA.person_id = E.person_id 
		AND measurement_date BETWEEN AA.drug_era_start_date -60  AND AA.drug_era_start_date
		AND value_as_number <= range_high
		
    	LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        (SELECT *
         FROM kyuh_cdm_5_3_2020.condition_occurrence
         WHERE upper(condition_source_value )
         LIKE any(array['K70%','K71%','K72%','K73%','K74%','K75%','K76%','K77%'])) C
        ON AA.person_id = C.person_id AND C.condition_start_date BETWEEN AA.drug_era_start_date AND AA.drug_era_end_date::date + 60
					
	WHERE exposure_period_days >= 7
	AND B.person_id is NULL
	AND C.condition_source_value is not null)) Z
						
GROUP BY condition_source_value, ingredient_name
ORDER BY condition_source_value;


-- 4. Hepatotoxicity_total_case
-- ALT : 3006923
-- AST : 3013721
-- ALP : 3035995

create temp table hep_total_case as
SELECT Z.condition_source_value, count(distinct Z.person_id) FROM (
(SELECT AA.person_id, AA.drug_era_start_date, AA.drug_era_end_date, C.condition_source_value, C.condition_start_date FROM 
(SELECT A.person_id
      , A.drug_era_start_date
      , A.drug_era_end_date 
      , (A.drug_era_end_date - A.drug_era_start_date + 1) AS exposure_period_days
		FROM new_drug_era_total A ) AA
	
         LEFT JOIN  --탐색기간 전 아래 진단명 가진 경우 제외(Exclusion Criteria)
        (SELECT *
         FROM kyuh_cdm_5_3_2020.condition_occurrence
         WHERE upper(condition_source_value )
         LIKE any(array['K25%', 'K26%', 'K27%', 'B15%', 'B16%', 'B17%', 'B18%', 'B19%', 'E84%', 'E20%', 'E21%'])) B 
        ON AA.person_id = B.person_id AND B.condition_start_date < AA.drug_era_start_date::date - 60

		LEFT JOIN --탐색기간 전 검사 수치 정상
		(SELECT person_id, measurement_date,value_as_number, range_low, range_high 
		FROM kyuh_cdm_5_3_2020.measurement WHERE  measurement_concept_id in (3006923, 3013721, 3035995, 3011258))   E           -- ALT
		ON AA.person_id = E.person_id 
		AND measurement_date BETWEEN AA.drug_era_start_date -60  AND AA.drug_era_start_date
		AND value_as_number <= range_high
		
    	LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        (SELECT *
         FROM kyuh_cdm_5_3_2020.condition_occurrence
         WHERE upper(condition_source_value )
         LIKE any(array['K70%','K71%','K72%','K73%','K74%','K75%','K76%','K77%'])) C
        ON AA.person_id = C.person_id AND C.condition_start_date BETWEEN AA.drug_era_start_date AND AA.drug_era_end_date::date + 60
					
	WHERE exposure_period_days >= 7
	AND B.person_id is NULL
	AND C.condition_source_value is not null)) Z
						
GROUP BY condition_source_value
ORDER BY condition_source_value;


-- 5. Output
select a.ingredient_name, a.condition_source_value, a.count as case, b.count as total from hep_case a
inner join hep_total_case b
on a.condition_source_value = b.condition_source_value
order by a.ingredient_name asc;

-- 6. Drop table
drop table new_drug_era_arb, new_drug_era_total, hep_case, hep_total_case;