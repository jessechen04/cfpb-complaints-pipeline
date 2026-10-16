CREATE OR REPLACE TABLE `cfpb-complaints-pipeline.cfpb.bureau_scorecard` AS
SELECT
  company,
  COUNT(*) AS records,
  COUNTIF(company_response != 'In progress') AS resolved_records,
  ROUND(100 * COUNTIF(timely = 'Yes') / COUNT(*), 2) AS pct_timely,
  ROUND(100 * COUNTIF(LOWER(company_response) LIKE '%relief%')
        / NULLIF(COUNTIF(company_response != 'In progress'), 0), 2) AS pct_relief_of_resolved,
  ROUND(100 * COUNTIF(LOWER(company_response) LIKE '%explanation%')
        / NULLIF(COUNTIF(company_response != 'In progress'), 0), 2) AS pct_explanation_of_resolved,
  ROUND(AVG(TIMESTAMP_DIFF(date_sent_to_company, date_received, HOUR)), 1) AS avg_hours_to_company
FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
GROUP BY company