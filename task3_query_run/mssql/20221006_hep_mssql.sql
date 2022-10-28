--select * from kyuh_cdm_5_3.drug_era
--select * from kyuh_cdm_5_3.person

if OBJECT_ID('tempdb..#drug_era_arb') IS NOT NULL
    drop table #drug_era_arb

SELECT * 
INTO #drug_era_arb
FROM kyuh_cdm_5_3.drug_era
WHERE drug_concept_id IN (
    SELECT concept_id 
    FROM kyuh_cdm_5_3.concept 
    WHERE lower(concept_name) like '%azilsartan%'
    OR  lower(concept_name) like '%candesartan%'
    OR  lower(concept_name) like '%eprosartan%'
    OR  lower(concept_name) like '%fimasartan%'
    OR  lower(concept_name) like '%irbesartan%'
    OR  lower(concept_name) like '%olmesartan%'
    OR  lower(concept_name) like '%telmisartan%'
    OR  lower(concept_name) like '%valsartan%'
)
    
if OBJECT_ID('tempdb..#min_drug_era_arb') IS NOT NULL
    drop table #min_drug_era_arb

SELECT a.*
INTO #min_drug_era_arb
FROM #drug_era_arb a
INNER JOIN (
    SELECT person_id, min(drug_era_start_date) drug_era_start_date
    FROM #drug_era_arb
    GROUP BY person_id
) b ON a.person_id = b.person_id AND a.drug_era_start_date = b.drug_era_start_date

if OBJECT_ID('tempdb..#new_drug_era_arb') IS NOT NULL
    drop table #new_drug_era_arb

SELECT DISTINCT '0' AS test_no
, A.person_id
, (YEAR(drug_era_start_date)-year_of_birth) AS age_onset
, (SELECT lower(concept_name) FROM kyuh_cdm_5_3.concept WHERE concept_id = A.drug_concept_id) AS ingredient_name
, drug_concept_id
, drug_era_start_date
, drug_era_end_date
, DATEDIFF(DAY, drug_era_end_date, drug_era_start_date) AS exposure_period_days
INTO #new_drug_era_arb
FROM #min_drug_era_arb A
INNER JOIN kyuh_cdm_5_3.person P 
ON A.person_id = P.person_id
WHERE (YEAR(drug_era_start_date)-year_of_birth) <= 65 

--select * from #new_drug_era_arb

-- 2. ARB_total_drugs
if OBJECT_ID('tempdb..#drug_era_total') IS NOT NULL
    drop table #drug_era_total

SELECT DISTINCT '0' AS test_no
        , A.person_id 
        , (YEAR(drug_era_start_date)-year_of_birth) AS age_onset
        , drug_concept_id
        , (SELECT lower(concept_name) FROM kyuh_cdm_5_3.concept WHERE concept_id = A.drug_concept_id) AS ingredient_name
        , drug_era_start_date
        , drug_era_end_date 
        , DATEDIFF(DAY, drug_era_end_date, drug_era_start_date) AS exposure_period_days
        INTO #drug_era_total
        FROM kyuh_cdm_5_3.drug_era A
        INNER JOIN kyuh_cdm_5_3.person P ON A.person_id = P.person_id    
        AND (YEAR(drug_era_start_date)-year_of_birth) <= 65

if OBJECT_ID('tempdb..#new_drug_era_total') IS NOT NULL
    drop table #new_drug_era_total

SELECT a.*
INTO #new_drug_era_total
FROM #drug_era_total a
INNER JOIN (
    SELECT person_id, min(drug_era_start_date) drug_era_start_date
    FROM #drug_era_total
    GROUP BY person_id
) b ON a.person_id = b.person_id AND a.drug_era_start_date = b.drug_era_start_date

-- 3. Hepatotoxicity_case

if OBJECT_ID('tempdb..#condition_code_K') IS NOT NULL
    drop table #condition_code_K

/*SELECT *
INTO #condition_code_K
FROM kyuh_cdm_5_3.condition_occurrence
WHERE upper(condition_source_value) like 'K25%'
or upper(condition_source_value) like 'K26%'
or upper(condition_source_value) like 'K27%'
or upper(condition_source_value) like 'B15%'
or upper(condition_source_value) like 'B16%'
or upper(condition_source_value) like 'B17%'
or upper(condition_source_value) like 'B18%'
or upper(condition_source_value) like 'B19%'
or upper(condition_source_value) like 'E84%'
or upper(condition_source_value) like 'E20%'
or upper(condition_source_value) like 'E21%'*/

SELECT *
INTO #condition_code_K
FROM cdm.condition_occurrence
where condition_concept_id in (
4211974,193693,4239780,4173408,4265600,4169592,4027663,196029,4289830,4146517,4211001,4138962,4027729,4012113,4336230,198964,439674,4163865,4294973,4195231,441267,194856,4174044,4247008,197493,4057953,4150681,4222896,4296611,4204555,4198381,194574,133729,140362,192240,138388,4265479,192242,4248429,138713,4194543,4291028,4232181,197795,4209746,136934,4034970,196625,4231580,439675,4046500
)


if OBJECT_ID('tempdb..#condition_code_N') IS NOT NULL
    drop table #condition_code_N

/*SELECT *
INTO #condition_code_N
FROM cdm.condition_occurrence
WHERE upper(condition_source_value ) like 'K70%'
or upper(condition_source_value ) like 'K71%'
or upper(condition_source_value ) like 'K72%'
or upper(condition_source_value ) like 'K73%'
or upper(condition_source_value ) like 'K74%'
or upper(condition_source_value ) like 'K75%'
or upper(condition_source_value ) like 'K76%'
or upper(condition_source_value ) like 'K77%'*/

SELECT *
INTO #condition_code_N
FROM cdm.condition_occurrence
where condition_source_concept_id in (
4225905,4310665,193256,4340385,201901,192680,46271813,46269836,4340386,199867,4046123,194417,196463,377604,4058694,4340941,4245975,4059297,4240725,46269816,194984,4340948,192675,4055224,196455,4341650,4340394,200762,4340383,194990,201612,200763,200451,4135822,4064161,46271812,4059299,4059290,4267417,4340390,4026125,45771255,46269818,46271811,46269835
)


if OBJECT_ID('tempdb..#measuremet_creatinine') IS NOT NULL
    drop table #measuremet_creatinine

SELECT person_id, measurement_date, value_as_number, range_low, range_high 
INTO #measurement_all
FROM kyuh_cdm_5_3.measurement 
WHERE measurement_concept_id in ('3006923')
or measurement_concept_id in ('3013721')
or measurement_concept_id in ('3035995')
or measurement_concept_id in ('3011258')

if OBJECT_ID('tempdb..#temp_hep_case') IS NOT NULL
    drop table #temp_hep_case

SELECT AA.person_id, AA.ingredient_name, AA.drug_era_start_date, AA.drug_era_end_date, C.condition_source_value, C.condition_start_date 
INTO #temp_hep_case
FROM 
(SELECT A.person_id
      , A.age_onset
      , A.ingredient_name
      , A.drug_era_start_date
      , A.drug_era_end_date 
      , A.exposure_period_days
        FROM #new_drug_era_arb A) AA
        LEFT JOIN  --탐색기간 전 아래 진단명 가진 경우 제외(Exclusion Criteria)
        #condition_code_K B 
        ON AA.person_id = B.person_id AND B.condition_start_date < DATEADD(DAY, -60, AA.drug_era_start_date)

        LEFT JOIN --탐색기간 전 검사 수치 정상
        #measurement_all E           -- 
        ON AA.person_id = E.person_id 
        AND measurement_date BETWEEN DATEADD(DAY, -60, AA.drug_era_start_date) AND AA.drug_era_start_date
        AND value_as_number <= range_high
        
        LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        #condition_code_N C
        ON AA.person_id = C.person_id AND C.condition_start_date BETWEEN AA.drug_era_start_date AND DATEADD(DAY, +60, AA.drug_era_start_date)
WHERE exposure_period_days >= 7
AND B.person_id is NULL
AND C.condition_source_concept_id is not null

if OBJECT_ID('tempdb..#hep_case') IS NOT NULL
    drop table #hep_case

SELECT Z.condition_source_concept_id, Z.ingredient_name, count(distinct Z.person_id) 
INTO #hep_case
FROM #temp_hep_case Z
GROUP BY condition_source_value, ingredient_name, person_id
ORDER BY condition_source_concept_id;

if OBJECT_ID('tempdb..#temp_hep_total_case') IS NOT NULL
    drop table #temp_hep_total_case

SELECT AA.person_id, AA.drug_era_start_date, AA.drug_era_end_date, C.condition_source_concept_id, C.condition_start_date 
INTO #temp_hep_total_case
FROM (SELECT A.person_id
      , A.drug_era_start_date
      , A.drug_era_end_date 
      , DATEDIFF(DAY, drug_era_end_date, drug_era_start_date) AS exposure_period_days
        FROM #new_drug_era_total A ) AA
    
        LEFT JOIN  --탐색기간 전 아래 진단명 가진 경우 제외(Exclusion Criteria)
        #condition_code_K B 
        ON AA.person_id = B.person_id AND B.condition_start_date < DATEADD(DAY, -60, AA.drug_era_start_date)

        LEFT JOIN --탐색기간 전 검사 수치 정상
        #measurement_all E           -- 
        ON AA.person_id = E.person_id 
        AND measurement_date BETWEEN DATEADD(DAY, -60, AA.drug_era_start_date) AND AA.drug_era_start_date
        AND value_as_number <= range_high
        
        LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        #condition_code_N C
        ON AA.person_id = C.person_id AND C.condition_start_date BETWEEN AA.drug_era_start_date AND DATEADD(DAY, +60, AA.drug_era_start_date)
                    
    WHERE exposure_period_days >= 7
    AND B.person_id is NULL
    AND C.condition_source_concept_id is not null

if OBJECT_ID('tempdb..#hep_total_case') IS NOT NULL
    drop table #hep_total_case

-- 4. Hepatotoxicity_total_case
SELECT Z.condition_source_value, count(distinct Z.person_id)
INTO #hep_total_case
FROM #temp_hep_total_case Z
GROUP BY condition_source_concept_id
ORDER BY condition_source_concept_id;


-- 5. Output
select * from #hep_case;
select * from #hep_total_case;


select * from #hep_case a
inner join #hep_total_case b
on a.condition_source_concept_id = b.condition_source_concept_id;


-- 6. Drop table
--drop table #new_drug_era_arb, #new_drug_era_total, #hep_case, #hep_total_case;

