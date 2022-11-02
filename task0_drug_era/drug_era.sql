"""
  Drug_era
  https://github.com/OHDSI/ETL-Synthea/blob/master/ETL/SQL/insert_drug_era.sql
  2018.11.28

  2020.04.08
  MSSQL 쿼리로 수정

  2020.11.04
  cdm DB에 맞게 수정
"""

-- Code taken from:
-- https://github.com/OHDSI/ETL-CMS/blob/master/SQL/create_CDMv5_drug_era_non_stockpile.sql

drop TABLE cdm.dbo.drug_era;
CREATE TABLE cdm.dbo.drug_era
(
  drug_era_id					INTEGER			NOT NULL ,
  person_id						INTEGER			NOT NULL ,
  drug_concept_id				INTEGER			NOT NULL ,
  drug_era_start_date			DATE			NOT NULL ,
  drug_era_end_date				DATE			NOT NULL ,
  drug_exposure_count			INTEGER			NULL ,
  gap_days						INTEGER			NULL
)
;


DROP TABLE IF EXISTS ctePreDrugTarget;
DROP TABLE IF EXISTS cteSubExposureEndDates;
DROP TABLE IF EXISTS cteDrugExposureEnds;
DROP TABLE IF EXISTS cteSubExposures;
DROP TABLE IF EXISTS cteFinalTarget;
DROP TABLE IF EXISTS cteEndDates;
DROP TABLE IF EXISTS cteDrugEraEnds;



	SELECT
		d.drug_exposure_id                      --drug_exposure에 있는 매핑된 concept_id
		, d.person_id
		, c.concept_id AS ingredient_concept_id
		, d.drug_exposure_start_date AS drug_exposure_start_date
		, d.days_supply AS days_supply
		, COALESCE(DRUG_EXPOSURE_END_DATE,
             DATEADD(day, DAYS_SUPPLY, DRUG_EXPOSURE_START_DATE),
             DATEADD(day, 1, DRUG_EXPOSURE_START_DATE)) AS DRUG_EXPOSURE_END_DATE  --아래 코드 생각해서 만들긴 했지만, Drug_exposure 에서 end_date NULL은 없음
  INTO ctePreDrugTarget
	FROM cdm.dbo.drug_exposure d
		JOIN cdm.dbo.concept_ancestor ca ON ca.descendant_concept_id = d.drug_concept_id    -- 2개의 조인으로 descendant 중 ingredient를 추출함
		JOIN cdm.dbo.concept c ON ca.ancestor_concept_id = c.concept_id
		WHERE c.vocabulary_id = 'RxNorm'                                            ---8 selects RxNorm from the vocabulary_id
		AND c.concept_class_id = 'Ingredient'
		AND d.drug_concept_id != 0                                                  ---매핑 안 된 concept_id를 0으로 치환 했으므로, 0인 concept_id 제거 ---Our unmapped drug_concept_id's are set to 0, so we don't want different drugs wrapped up in the same era
		AND coalesce(d.days_supply,0) >= 0                                          ---days_supply가 음수인 것을 제외 ---We have cases where days_supply is negative, and this can set the end_date before the start_date, which we don't want. So we're just looking over those rows. This is a data-quality issue.
    ;

-- , cteSubExposureEndDates (person_id, ingredient_concept_id, end_date) AS --- A preliminary sorting that groups all of the overlapping exposures into one exposure so that we don't double-count non-gap-days
-- (                                                                               -- 같은 시작날짜에 같은 약을 여러번 처방 받은 경우를 하나로 만들어줌

  SELECT person_id, ingredient_concept_id, event_date AS end_date
INTO cteSubExposureEndDates
	FROM
	(
		SELECT person_id, ingredient_concept_id, event_date, event_type,
		MAX(start_ordinal) OVER (PARTITION BY person_id, ingredient_concept_id
			ORDER BY event_date, event_type ROWS unbounded preceding) AS start_ordinal, --ROWS BETWEEN UNBOUNDED PRECEDING  AND CURRENT ROW : window가 이전부터 현재까지 거기서의 최대값 구하기
		-- this pulls the current START down from the prior rows so that the NULLs
		-- from the END DATES will contain a value we can compare with
			ROW_NUMBER() OVER (PARTITION BY person_id, ingredient_concept_id
				ORDER BY event_date, event_type) AS overall_ord
			-- this re-numbers the inner UNION so all rows are numbered ordered by the event date
      -- person_id, ingredient_concept_id로 group 지어진 상태에서 evend_date로 정렬
    FROM (
			-- select the start dates, assigning a row number to each
			SELECT person_id, ingredient_concept_id, drug_exposure_start_date AS event_date,
			-1 AS event_type,
			ROW_NUMBER() OVER (PARTITION BY person_id, ingredient_concept_id ORDER BY drug_exposure_start_date) AS start_ordinal
			FROM ctePreDrugTarget --134개

			UNION ALL

			SELECT person_id, ingredient_concept_id, drug_exposure_end_date,
      1 AS event_type,
      NULL
			FROM ctePreDrugTarget --134개
		) RAWDATA                                                                   --각각의 start_date에 row_number을 매김
	) e                                                                           --start_ordinal 최대값만 넣고, date 순서대로 row_number을 매김
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
  ;                         --113개



SELECT
	dt.person_id
	, dt.ingredient_concept_id
	, dt.drug_exposure_start_date
	, MIN(e.end_date) AS drug_sub_exposure_end_date
INTO cteDrugExposureEnds
FROM ctePreDrugTarget dt
JOIN cteSubExposureEndDates e ON dt.person_id = e.person_id
                              AND dt.ingredient_concept_id = e.ingredient_concept_id
                              AND e.end_date >= dt.drug_exposure_start_date
GROUP BY
      	dt.drug_exposure_id
      	, dt.person_id
	, dt.ingredient_concept_id
	, dt.drug_exposure_start_date
  ;

--------------------------------------------------------------------------------------------------------------



	SELECT ROW_NUMBER() OVER (PARTITION BY person_id, ingredient_concept_id, drug_sub_exposure_end_date ORDER BY person_id, ingredient_concept_id) as row_number
		, person_id, ingredient_concept_id, MIN(drug_exposure_start_date) AS drug_sub_exposure_start_date, drug_sub_exposure_end_date, COUNT(*) AS drug_exposure_count
INTO cteSubExposures
	FROM cteDrugExposureEnds
	GROUP BY person_id, ingredient_concept_id, drug_sub_exposure_end_date
  ;

--------------------------------------------------------------------------------------------------------------
/*Everything above grouped exposures into sub_exposures if there was overlap between exposures.
 *So there was no persistence window. Now we can add the persistence window to calculate eras.
 */
--------------------------------------------------------------------------------------------------------------



	SELECT row_number, person_id, ingredient_concept_id, drug_sub_exposure_start_date, drug_sub_exposure_end_date, drug_exposure_count
		, DATEDIFF(day, drug_sub_exposure_start_date, drug_sub_exposure_end_date) AS days_exposed
INTO cteFinalTarget
	FROM cteSubExposures
  ;

--------------------------------------------------------------------------------------------------------------


	SELECT person_id, ingredient_concept_id, DATEADD(day, -30, event_date) AS end_date -- unpad the end date
INTO cteEndDates
  FROM
	(
		SELECT person_id, ingredient_concept_id, event_date, event_type,
		MAX(start_ordinal) OVER (PARTITION BY person_id, ingredient_concept_id
			ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal,
		-- this pulls the current START down from the prior rows so that the NULLs
		-- from the END DATES will contain a value we can compare with
			ROW_NUMBER() OVER (PARTITION BY person_id, ingredient_concept_id
				ORDER BY event_date, event_type) AS overall_ord
			-- this re-numbers the inner UNION so all rows are numbered ordered by the event date
		FROM (
			-- select the start dates, assigning a row number to each
			SELECT person_id, ingredient_concept_id, drug_sub_exposure_start_date AS event_date,
			-1 AS event_type,
			ROW_NUMBER() OVER (PARTITION BY person_id, ingredient_concept_id ORDER BY drug_sub_exposure_start_date) AS start_ordinal
			FROM cteFinalTarget

			UNION ALL

			-- pad the end dates by 30 to allow a grace period for overlapping ranges.
			SELECT person_id, ingredient_concept_id, DATEADD(day, 30, drug_sub_exposure_end_date),
      1 AS event_type,
      NULL
			FROM cteFinalTarget
		) RAWDATA
	) e
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
;



SELECT
	ft.person_id
	, ft.ingredient_concept_id as drug_concept_id
	, ft.drug_sub_exposure_start_date
	, MIN(e.end_date) AS drug_era_end_date
	, drug_exposure_count
	, days_exposed
INTO cteDrugEraEnds
FROM cteFinalTarget ft
JOIN cteEndDates e ON ft.person_id = e.person_id
                  AND ft.ingredient_concept_id = e.ingredient_concept_id
                  AND e.end_date >= ft.drug_sub_exposure_start_date
GROUP BY
    ft.person_id
	, ft.ingredient_concept_id
	, ft.drug_sub_exposure_start_date
	, drug_exposure_count
	, days_exposed
;

INSERT INTO cdm.dbo.drug_era(drug_era_id,person_id, drug_concept_id, drug_era_start_date, drug_era_end_date, drug_exposure_count, gap_days)
SELECT
    ROW_NUMBER() OVER (ORDER BY person_id, drug_concept_id) as drug_era_id
	, person_id
	, drug_concept_id
	, MIN(drug_sub_exposure_start_date) AS drug_era_start_date
	, drug_era_end_date
	, SUM(drug_exposure_count) AS drug_exposure_count
	, DATEDIFF(day, MIN(drug_sub_exposure_start_date), drug_era_end_date) - SUM(days_exposed) AS gap_days
FROM cteDrugEraEnds dee
GROUP BY person_id, drug_concept_id, drug_era_end_date
;

--4월 8일 drug_era : 1,290,127

DROP TABLE IF EXISTS ctePreDrugTarget;
DROP TABLE IF EXISTS cteSubExposureEndDates;
DROP TABLE IF EXISTS cteDrugExposureEnds;
DROP TABLE IF EXISTS cteSubExposures;
DROP TABLE IF EXISTS cteFinalTarget;
DROP TABLE IF EXISTS cteEndDates;
DROP TABLE IF EXISTS cteDrugEraEnds;
