DROP TABLE IF EXISTS new_drug_era_nsaids;

-- 1. Nephrotoxicity_12_drugs
create temp table new_drug_era_nsaids as
	SELECT DISTINCT '0' AS test_no
			, A.person_id
			, CAST(A.drug_era_start_date- CAST(year_of_birth || '-'|| month_of_birth|| '-'|| day_of_birth AS DATE) AS INT )/365  AS age_onset
	  		, drug_concept_id
			, lower(concept_name) AS ingredient_name
      		, min(drug_era_start_date ) as drug_era_start_date
      		, drug_era_end_date 
      		, drug_era_end_date - drug_era_start_date + 1 AS exposure_period_days
			FROM kyuh_cdm_5_3.drug_era A
			INNER JOIN kyuh_cdm_5_3.person P ON A.person_id = P.person_id	
			INNER JOIN kyuh_cdm_5_3.concept C ON A.drug_concept_id = C.concept_id
			WHERE A.drug_concept_id IN (SELECT concept_id FROM kyuh_cdm_5_3.concept WHERE lower(concept_name) 
										like ANY(ARRAY['%acetaminophen%', '%amphotericin b%', '%vancomycin%', '%cisplatin%', '%acyclovir%', '%foscarnet%', '%lithium%'
													  , '%ibuprofen%', '%diclofenac%', '%naproxen%', '%ketoprofen%', '%piroxicam%']))
			AND CAST(A.drug_era_start_date- CAST(year_of_birth || '-'|| month_of_birth|| '-'|| day_of_birth AS DATE) AS INT )/365 >= 18
			GROUP BY A.person_id, age_onset, drug_concept_id, ingredient_name, drug_era_start_date, drug_era_end_date , exposure_period_days;
			
		
DROP TABLE IF EXISTS new_drug_era_total;

-- 2. Nephrotoxicity_total_drugs
create temp table new_drug_era_total as
	SELECT DISTINCT '0' AS test_no
			, A.person_id 
			, CAST(A.drug_era_start_date- CAST(year_of_birth || '-'|| month_of_birth|| '-'|| day_of_birth AS DATE) AS INT )/365  AS age_onset
	  		, drug_concept_id
			, lower(concept_name) AS ingredient_name
      		, min(drug_era_start_date ) as drug_era_start_date
      		, drug_era_end_date 
      		, drug_era_end_date - drug_era_start_date + 1 AS exposure_period_days
			FROM kyuh_cdm_5_3.drug_era A
			INNER JOIN kyuh_cdm_5_3.person P ON A.person_id = P.person_id
			INNER JOIN kyuh_cdm_5_3.concept C ON A.drug_concept_id = C.concept_id
			AND CAST(A.drug_era_start_date- CAST(year_of_birth || '-'|| month_of_birth|| '-'|| day_of_birth AS DATE) AS INT )/365 >= 18
			GROUP BY A.person_id, age_onset, drug_concept_id, ingredient_name, drug_era_start_date, drug_era_end_date , exposure_period_days;
			

-- 3. Nephrotoxicity_case
create temp table nep_case as
SELECT Z.condition_source_value, Z.ingredient_name, count(distinct Z.person_id) FROM (
(SELECT AA.person_id, AA.ingredient_name, AA.drug_era_start_date, AA.drug_era_end_date, C.condition_source_value, C.condition_start_date FROM 
(SELECT A.person_id
      , A.age_onset
	  , A.ingredient_name
      , A.drug_era_start_date
      , A.drug_era_end_date 
      , A.exposure_period_days
		FROM new_drug_era_nsaids A) AA
	
         LEFT JOIN  --탐색기간 전 아래 진단명 가진 경우 제외(Exclusion Criteria)
        (SELECT *
         FROM kyuh_cdm_5_3.condition_occurrence
         WHERE upper(condition_source_value )
         LIKE any(array['K25%', 'K26%', 'K27%', 'K260%', 'K262%', 'K264%', 'K270%', 'K272%', 'K274%','K276%','K280%'
						, 'K282%', 'K284%', 'K286%', 'K290%', 'K625%', 'K922%', 'I20%', 'I60%', 'I61%', 'I62%', 'I63%'])) B 
        ON AA.person_id = B.person_id AND B.condition_start_date < AA.drug_era_start_date::date - 60

		LEFT JOIN --탐색기간 전 검사 수치 정상
		(SELECT person_id, measurement_date,value_as_number, range_low, range_high 
		FROM kyuh_cdm_5_3.measurement WHERE  measurement_concept_id in ('3016723'))   E           -- serum creatinine
		ON AA.person_id = E.person_id 
		AND measurement_date BETWEEN AA.drug_era_start_date -60  AND AA.drug_era_start_date
		AND value_as_number <= 1.2
		
    	LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        (SELECT *
         FROM kyuh_cdm_5_3.condition_occurrence
         WHERE upper(condition_source_value )
         LIKE any(array['N0%','N1%'])) C
        ON AA.person_id = C.person_id AND C.condition_start_date BETWEEN AA.drug_era_start_date AND AA.drug_era_end_date::date + 60
					
	WHERE exposure_period_days >= 7
	AND B.person_id is NULL
	AND C.condition_source_value is not null)) Z
						
GROUP BY condition_source_value, ingredient_name
ORDER BY condition_source_value;


-- 4. Nephrotoxicity_total_case
create temp table neph_total_case as
SELECT Z.condition_source_value, count(distinct Z.person_id) FROM (
(SELECT AA.person_id, AA.drug_era_start_date, AA.drug_era_end_date, C.condition_source_value, C.condition_start_date FROM 
(SELECT A.person_id
      , A.drug_era_start_date
      , A.drug_era_end_date 
      , (A.drug_era_end_date - A.drug_era_start_date + 1) AS exposure_period_days
		FROM new_drug_era_total A ) AA
	
         LEFT JOIN  --탐색기간 전 아래 진단명 가진 경우 제외(Exclusion Criteria)
        (SELECT *
         FROM kyuh_cdm_5_3.condition_occurrence
         WHERE upper(condition_source_value )
         LIKE any(array['K25%', 'K26%', 'K27%', 'K260%', 'K262%', 'K264%', 'K270%', 'K272%', 'K274%','K276%','K280%'
						, 'K282%', 'K284%', 'K286%', 'K290%', 'K625%', 'K922%', 'I20%', 'I60%', 'I61%', 'I62%', 'I63%'])) B 
        ON AA.person_id = B.person_id AND B.condition_start_date < AA.drug_era_start_date::date - 60

		LEFT JOIN --탐색기간 전 검사 수치 정상
		(SELECT person_id, measurement_date,value_as_number, range_low, range_high 
		FROM kyuh_cdm_5_3.measurement WHERE  measurement_concept_id in ('3016723'))   E           -- serum creatinine
		ON AA.person_id = E.person_id 
		AND measurement_date BETWEEN AA.drug_era_start_date -60  AND AA.drug_era_start_date
		AND value_as_number <= 1.2
		
    	LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        (SELECT *
         FROM kyuh_cdm_5_3.condition_occurrence
         WHERE upper(condition_source_value )
         LIKE any(array['N0%','N1%'])) C
        ON AA.person_id = C.person_id AND C.condition_start_date BETWEEN AA.drug_era_start_date AND AA.drug_era_end_date::date + 60
					
	WHERE exposure_period_days >= 7
	AND B.person_id is NULL
	AND C.condition_source_value is not null)) Z
						
GROUP BY condition_source_value
ORDER BY condition_source_value;


-- 5. Output
select * from nep_case;
select * from neph_total_case;


select * from nep_case a
inner join neph_total_case b
on a.condition_source_value = b.condition_source_value;


-- 6. Drop table
drop table new_drug_era_nsaids, new_drug_era_total, nep_case, neph_total_case;


