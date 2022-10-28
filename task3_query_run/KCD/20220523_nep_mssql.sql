--select * from kyuh_cdm_5_3.drug_era
--select * from kyuh_cdm_5_3.person

if OBJECT_ID('tempdb..#drug_era_nsaids') IS NOT NULL
    drop table #drug_era_nsaids

SELECT * 
INTO #drug_era_nsaids
FROM kyuh_cdm_5_3.drug_era
WHERE drug_concept_id IN (
    SELECT concept_id 
    FROM kyuh_cdm_5_3.concept 
    WHERE lower(concept_name) like '%acetaminophen%'
    OR  lower(concept_name) like '%amphotericin b%'
    OR  lower(concept_name) like '%vancomycin%'
    OR  lower(concept_name) like '%cisplatin%'
    OR  lower(concept_name) like '%acyclovir%'
    OR  lower(concept_name) like '%foscarnet%'
    OR  lower(concept_name) like '%lithium%'
    OR  lower(concept_name) like '%ibuprofen%'
    OR  lower(concept_name) like '%diclofenac%'
    OR  lower(concept_name) like '%naproxen%'
    OR  lower(concept_name) like '%ketoprofen%'
    OR  lower(concept_name) like '%piroxicam%'
)
    
if OBJECT_ID('tempdb..#min_drug_era_nsaids') IS NOT NULL
    drop table #min_drug_era_nsaids

SELECT a.*
INTO #min_drug_era_nsaids
FROM #drug_era_nsaids a
INNER JOIN (
    SELECT person_id, min(drug_era_start_date) drug_era_start_date
    FROM #drug_era_nsaids
    GROUP BY person_id
) b ON a.person_id = b.person_id AND a.drug_era_start_date = b.drug_era_start_date

if OBJECT_ID('tempdb..#new_drug_era_nsaids') IS NOT NULL
    drop table #new_drug_era_nsaids

SELECT DISTINCT '0' AS test_no
, A.person_id
, (YEAR(drug_era_start_date)-year_of_birth) AS age_onset
, (SELECT lower(concept_name) FROM kyuh_cdm_5_3.concept WHERE concept_id = A.drug_concept_id) AS ingredient_name
, drug_concept_id
, drug_era_start_date
, drug_era_end_date
, DATEDIFF(DAY, drug_era_end_date, drug_era_start_date) AS exposure_period_days
INTO #new_drug_era_nsaids
FROM #min_drug_era_nsaids A
INNER JOIN kyuh_cdm_5_3.person P 
ON A.person_id = P.person_id
WHERE (YEAR(drug_era_start_date)-year_of_birth) >= 18

--select * from #new_drug_era_nsaids

-- 2. Nephrotoxicity_total_drugs
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
        AND (YEAR(drug_era_start_date)-year_of_birth) >= 18

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

-- 3. Nephrotoxicity_case

if OBJECT_ID('tempdb..#condition_code_K') IS NOT NULL
    drop table #condition_code_K

SELECT *
INTO #condition_code_K
FROM kyuh_cdm_5_3.condition_occurrence
WHERE upper(condition_source_value) like 'K25%'
or upper(condition_source_value) like 'K26%'
or upper(condition_source_value) like 'K27%'
or upper(condition_source_value) like 'K260%'
or upper(condition_source_value) like 'K262%'
or upper(condition_source_value) like 'K264%'
or upper(condition_source_value) like 'K270%'
or upper(condition_source_value) like 'K272%'
or upper(condition_source_value) like 'K274%'
or upper(condition_source_value) like 'K276%'
or upper(condition_source_value) like 'K280%'
or upper(condition_source_value) like 'K282%'
or upper(condition_source_value) like 'K284%'
or upper(condition_source_value) like 'K286%'
or upper(condition_source_value) like 'K290%'
or upper(condition_source_value) like 'K625%'
or upper(condition_source_value) like 'K922%'
or upper(condition_source_value) like 'I20%'
or upper(condition_source_value) like 'I60%'
or upper(condition_source_value) like 'I61%'
or upper(condition_source_value) like 'I62%'
or upper(condition_source_value) like 'I63%'

if OBJECT_ID('tempdb..#condition_code_N') IS NOT NULL
    drop table #condition_code_N

SELECT *
INTO #condition_code_N
FROM kyuh_cdm_5_3.condition_occurrence
WHERE upper(condition_source_value ) like 'N0%'
or upper(condition_source_value ) like 'N1%'

if OBJECT_ID('tempdb..#measuremet_creatinine') IS NOT NULL
    drop table #measuremet_creatinine

SELECT person_id, measurement_date, value_as_number, range_low, range_high 
INTO #measurement_creatinine
FROM kyuh_cdm_5_3.measurement 
WHERE measurement_concept_id in ('3016723')

if OBJECT_ID('tempdb..#temp_nep_case') IS NOT NULL
    drop table #temp_nep_case

SELECT AA.person_id, AA.ingredient_name, AA.drug_era_start_date, AA.drug_era_end_date, C.condition_source_value, C.condition_start_date 
INTO #temp_nep_case
FROM 
(SELECT A.person_id
      , A.age_onset
      , A.ingredient_name
      , A.drug_era_start_date
      , A.drug_era_end_date 
      , A.exposure_period_days
        FROM #new_drug_era_nsaids A) AA
        LEFT JOIN  --탐색기간 전 아래 진단명 가진 경우 제외(Exclusion Criteria)
        #condition_code_K B 
        ON AA.person_id = B.person_id AND B.condition_start_date < DATEADD(DAY, -60, AA.drug_era_start_date)

        LEFT JOIN --탐색기간 전 검사 수치 정상
        #measurement_creatinine E           -- serum creatinine
        ON AA.person_id = E.person_id 
        AND measurement_date BETWEEN DATEADD(DAY, -60, AA.drug_era_start_date) AND AA.drug_era_start_date
        AND value_as_number <= 1.2
        
        LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        #condition_code_N C
        ON AA.person_id = C.person_id AND C.condition_start_date BETWEEN AA.drug_era_start_date AND DATEADD(DAY, +60, AA.drug_era_start_date)
WHERE exposure_period_days >= 7
AND B.person_id is NULL
AND C.condition_source_value is not null

if OBJECT_ID('tempdb..#nep_case') IS NOT NULL
    drop table #nep_case

SELECT Z.condition_source_value, Z.ingredient_name, count(distinct Z.person_id) 
INTO #nep_case
FROM #temp_nep_case Z
GROUP BY condition_source_value, ingredient_name, person_id
ORDER BY condition_source_value;

if OBJECT_ID('tempdb..#temp_neph_total_case') IS NOT NULL
    drop table #temp_neph_total_case

SELECT AA.person_id, AA.drug_era_start_date, AA.drug_era_end_date, C.condition_source_value, C.condition_start_date 
INTO #temp_neph_total_case
FROM (SELECT A.person_id
      , A.drug_era_start_date
      , A.drug_era_end_date 
      , DATEDIFF(DAY, drug_era_end_date, drug_era_start_date) AS exposure_period_days
        FROM #new_drug_era_total A ) AA
    
        LEFT JOIN  --탐색기간 전 아래 진단명 가진 경우 제외(Exclusion Criteria)
        #condition_code_K B 
        ON AA.person_id = B.person_id AND B.condition_start_date < DATEADD(DAY, -60, AA.drug_era_start_date)

        LEFT JOIN --탐색기간 전 검사 수치 정상
        #measurement_creatinine E           -- serum creatinine
        ON AA.person_id = E.person_id 
        AND measurement_date BETWEEN DATEADD(DAY, -60, AA.drug_era_start_date) AND AA.drug_era_start_date
        AND value_as_number <= 1.2
        
        LEFT JOIN  -- --탐색기간동안 다음 진단명이 추가된 경우(outcome)
        #condition_code_N C
        ON AA.person_id = C.person_id AND C.condition_start_date BETWEEN AA.drug_era_start_date AND DATEADD(DAY, +60, AA.drug_era_start_date)
                    
    WHERE exposure_period_days >= 7
    AND B.person_id is NULL
    AND C.condition_source_value is not null

if OBJECT_ID('tempdb..#neph_total_case') IS NOT NULL
    drop table #neph_total_case

-- 4. Nephrotoxicity_total_case
SELECT Z.condition_source_value, count(distinct Z.person_id)
INTO #neph_total_case
FROM #temp_neph_total_case Z
GROUP BY condition_source_value
ORDER BY condition_source_value;


-- 5. Output
select * from #nep_case;
select * from #neph_total_case;


select * from #nep_case a
inner join #neph_total_case b
on a.condition_source_value = b.condition_source_value;


-- 6. Drop table
--drop table #new_drug_era_nsaids, #new_drug_era_total, #nep_case, #neph_total_case;

