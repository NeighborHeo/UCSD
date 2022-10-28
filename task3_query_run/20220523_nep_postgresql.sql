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
			FROM ucsd_research_clone.drug_era A
			INNER JOIN ucsd_research_clone.person P ON A.person_id = P.person_id	
			INNER JOIN ucsd_research_clone.concept C ON A.drug_concept_id = C.concept_id
			WHERE A.drug_concept_id IN (SELECT concept_id FROM ucsd_research_clone.concept WHERE lower(concept_name) 
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
			FROM ucsd_research_clone.drug_era A
			INNER JOIN ucsd_research_clone.person P ON A.person_id = P.person_id
			INNER JOIN ucsd_research_clone.concept C ON A.drug_concept_id = C.concept_id
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
         FROM ucsd_research_clone.condition_occurrence
		 WHERE condition_concept_id IN (
		 4027729,4336230,4265479,4138962,4231580,4169592,4057953,4195231,4274491,4217947,4280942,4147683,193249,42535426,4046500,4006994,4194543,4163865,321318,4155963,4087310,26441,4048606,4071589,4110189,443454,762951,43530683,4111714,4108356,45772786,4110190,763015,46273649,35610084,46270031,762934,35610085,4110192,45767658,44782773,4232181,4289830,4173408,4222896,4211001,4294973,4150681,4296611,433515,4164920,4101870,4177387,4174044,4247008,4146517,4204555,4095094,4127089,4209746,36716543,36716544,36716572,4248429,192671,4101104,26727,4199890,442190,197925,46269901,4043731,46273183,46269907,4345688,4110185,4110186,4071732,4048277,4048278,4048279,4046360,316457,4046090,379778,37109016,4071070,4048286,436430,4027663,4291028,260841,315296,4045737,4045738,4096781,197024,43530674,43530727,42539269,42535425,42535424,4148906,4096773,432923,4071066,4134162,441709,435959,4108952,4111708,4049659,25844,4291649,4046089
		 )
        --  WHERE upper(condition_source_value )
        --  LIKE any(array['K25%', 'K26%', 'K27%', 'K260%', 'K262%', 'K264%', 'K270%', 'K272%', 'K274%','K276%','K280%'
		-- 				, 'K282%', 'K284%', 'K286%', 'K290%', 'K625%', 'K922%', 'I20%', 'I60%', 'I61%', 'I62%', 'I63%'])
		) B 
        ON AA.person_id = B.person_id AND B.condition_start_date < AA.drug_era_start_date::date - 60

		LEFT JOIN --탐색기간 전 검사 수치 정상
		(SELECT person_id, measurement_date,value_as_number, range_low, range_high 
		FROM ucsd_research_clone.measurement WHERE  measurement_concept_id in ('3016723'))   E           -- serum creatinine
		ON AA.person_id = E.person_id 
		AND measurement_date BETWEEN AA.drug_era_start_date -60  AND AA.drug_era_start_date
		AND value_as_number <= 1.2
		
    	LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        (SELECT *
         FROM ucsd_research_clone.condition_occurrence
		 WHERE condition_source_concept_id IN (42494533,42494534,42494535,42494536,42494540,42494541,42494542,42494545,42494550,42494552,42494553,42494554,42494556,42494557,42494558,42494559,42494561,42494562,42494563,42494564,42494565,42494567,42494568,42494569,42494570,42494572,42494574,42494575,42494576,42494578,42494579,42494580,42494581,42494583,42494584,42494585,42494586,42494587,42494589,42494590,42494591,42494592,42494593,42494594,42494595,42494596,42494597,42494598,42494600,42494601,42494603,42494604,42494607,42494609,42494610,42494623,42494624,42494625,42494626,42494627,42494628,42494629,42494630,42494631,42494632,42494633,42494634,42494635,42494636,42494637,42494638,42494639,42494640,42494641,42494642,42494643,42494644,42494645,42494646,42494647,42494648,42494649,42494650,42494651,42494652,42494653,42494654,42494655,42494656,42494657,42494658,42494659,42494660,42494661,42494662,42494663,42494664,42494665,42494666,42494667,42494668,42494669,42494670,42494671,42494672,42494673,42494674,42494675,42494676,42494677,42494678,42494679,42494680,42494681,42494682,42494683,42494684,42494685,42494686,42494687,42494688,42494689,42494690,42494691,42494692,42506066)
        --  WHERE upper(condition_source_value )
        --  LIKE any(array['N0%','N1%'])
		 ) C
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
         FROM ucsd_research_clone.condition_occurrence
		 WHERE condition_concept_id IN (
		 4027729,4336230,4265479,4138962,4231580,4169592,4057953,4195231,4274491,4217947,4280942,4147683,193249,42535426,4046500,4006994,4194543,4163865,321318,4155963,4087310,26441,4048606,4071589,4110189,443454,762951,43530683,4111714,4108356,45772786,4110190,763015,46273649,35610084,46270031,762934,35610085,4110192,45767658,44782773,4232181,4289830,4173408,4222896,4211001,4294973,4150681,4296611,433515,4164920,4101870,4177387,4174044,4247008,4146517,4204555,4095094,4127089,4209746,36716543,36716544,36716572,4248429,192671,4101104,26727,4199890,442190,197925,46269901,4043731,46273183,46269907,4345688,4110185,4110186,4071732,4048277,4048278,4048279,4046360,316457,4046090,379778,37109016,4071070,4048286,436430,4027663,4291028,260841,315296,4045737,4045738,4096781,197024,43530674,43530727,42539269,42535425,42535424,4148906,4096773,432923,4071066,4134162,441709,435959,4108952,4111708,4049659,25844,4291649,4046089
		 )
        --  WHERE upper(condition_source_value )
        --  LIKE any(array['K25%', 'K26%', 'K27%', 'K260%', 'K262%', 'K264%', 'K270%', 'K272%', 'K274%','K276%','K280%'
		-- 				, 'K282%', 'K284%', 'K286%', 'K290%', 'K625%', 'K922%', 'I20%', 'I60%', 'I61%', 'I62%', 'I63%'])
		) B 
        ON AA.person_id = B.person_id AND B.condition_start_date < AA.drug_era_start_date::date - 60

		LEFT JOIN --탐색기간 전 검사 수치 정상
		(SELECT person_id, measurement_date,value_as_number, range_low, range_high 
		FROM ucsd_research_clone.measurement WHERE  measurement_concept_id in ('3016723'))   E           -- serum creatinine
		ON AA.person_id = E.person_id 
		AND measurement_date BETWEEN AA.drug_era_start_date -60  AND AA.drug_era_start_date
		AND value_as_number <= 1.2
		
    	LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        (SELECT *
         FROM ucsd_research_clone.condition_occurrence
		 WHERE condition_source_concept_id IN (42494533,42494534,42494535,42494536,42494540,42494541,42494542,42494545,42494550,42494552,42494553,42494554,42494556,42494557,42494558,42494559,42494561,42494562,42494563,42494564,42494565,42494567,42494568,42494569,42494570,42494572,42494574,42494575,42494576,42494578,42494579,42494580,42494581,42494583,42494584,42494585,42494586,42494587,42494589,42494590,42494591,42494592,42494593,42494594,42494595,42494596,42494597,42494598,42494600,42494601,42494603,42494604,42494607,42494609,42494610,42494623,42494624,42494625,42494626,42494627,42494628,42494629,42494630,42494631,42494632,42494633,42494634,42494635,42494636,42494637,42494638,42494639,42494640,42494641,42494642,42494643,42494644,42494645,42494646,42494647,42494648,42494649,42494650,42494651,42494652,42494653,42494654,42494655,42494656,42494657,42494658,42494659,42494660,42494661,42494662,42494663,42494664,42494665,42494666,42494667,42494668,42494669,42494670,42494671,42494672,42494673,42494674,42494675,42494676,42494677,42494678,42494679,42494680,42494681,42494682,42494683,42494684,42494685,42494686,42494687,42494688,42494689,42494690,42494691,42494692,42506066)
        --  WHERE upper(condition_source_value )
        --  LIKE any(array['N0%','N1%'])
		) C
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


