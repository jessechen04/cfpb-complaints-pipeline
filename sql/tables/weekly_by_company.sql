CREATE OR REPLACE TABLE `cfpb-complaints-pipeline.cfpb.weekly_by_company` AS
SELECT
  DATE_TRUNC(DATE(date_received), WEEK) AS week,
  company,
  COUNT(*) AS records
FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
GROUP BY week, company
QUALIFY week > MIN(week) OVER() 
  AND week < MAX(week) OVER();