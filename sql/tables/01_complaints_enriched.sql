-- QUESTION: Which complaint records probably came from one submission to several bureaus?
-- RULE: same ZIP, same issue, same sub_issue, different bureau, within window_sec seconds
--       of the previous record. Each bureau appears at most once per filing.
-- NOTE: filing_id is an estimate. Records with null or masked ZIPs get their own solo_ ID.
-- All rows from complaints_raw are kept; nothing is deleted.

DECLARE window_sec INT64 DEFAULT 3;   -- change this one number to test other windows

CREATE OR REPLACE TABLE `cfpb-complaints-pipeline.cfpb.complaints_enriched` AS
WITH cleaned AS (
  SELECT
    *,
    IFNULL(issue, '')     AS issue_key,
    IFNULL(sub_issue, '') AS sub_issue_key,
    (zip_code IS NOT NULL AND NOT REGEXP_CONTAINS(zip_code, r'X')) AS zip_valid
  FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
),
gapped AS (
  SELECT
    *,
    TIMESTAMP_DIFF(
      date_received,
      LAG(date_received) OVER (
        PARTITION BY zip_code, issue_key, sub_issue_key
        ORDER BY date_received, complaint_id),
      SECOND) AS gap_sec
  FROM cleaned
  WHERE zip_valid
),
chained AS (
  SELECT
    *,
    SUM(IF(gap_sec IS NULL OR gap_sec > window_sec, 1, 0)) OVER (
      PARTITION BY zip_code, issue_key, sub_issue_key
      ORDER BY date_received, complaint_id) AS chain_no
  FROM gapped
),
numbered AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY zip_code, issue_key, sub_issue_key, chain_no, company
      ORDER BY date_received, complaint_id) AS rn
  FROM chained
)
SELECT
  * EXCEPT (gap_sec, chain_no, rn),
  CAST(FARM_FINGERPRINT(CONCAT(zip_code, '|', issue_key, '|', sub_issue_key, '|',
                               CAST(chain_no AS STRING), '|', CAST(rn AS STRING))) AS STRING) AS filing_id
FROM numbered

UNION ALL

SELECT
  *,
  CONCAT('solo_', complaint_id) AS filing_id
FROM cleaned
WHERE NOT zip_valid;
