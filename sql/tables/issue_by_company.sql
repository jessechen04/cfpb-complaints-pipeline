CREATE OR REPLACE TABLE `cfpb-complaints-pipeline.cfpb.issue_by_company` AS
SELECT
  company,
  issue,
  COUNT(*) AS records,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY company), 2) AS pct_of_company
FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
GROUP BY company, issue