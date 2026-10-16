CREATE OR REPLACE TABLE `cfpb-complaints-pipeline.cfpb.state_by_company` AS
SELECT
  state,
  company,
  COUNT(*) AS records,
  ROUND(100 * COUNTIF(timely = 'Yes') / COUNT(*), 2) AS pct_timely,
  ROUND(100 * COUNTIF(LOWER(company_response) LIKE '%relief%')
        / NULLIF(COUNTIF(company_response != 'In progress'), 0), 2) AS pct_relief_of_resolved,
  ROUND(100 * COUNTIF(LOWER(company_response) LIKE '%explanation%')
        / NULLIF(COUNTIF(company_response != 'In progress'), 0), 2) AS pct_explanation_of_resolved
FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
WHERE state IS NOT NULL
GROUP BY state, company
