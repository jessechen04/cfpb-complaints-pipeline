WITH base AS (
  SELECT
    complaint_id,
    company,
    zip_code,
    date_received,
    IFNULL(issue, '')     AS issue,
    IFNULL(sub_issue, '') AS sub_issue
  FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
  WHERE zip_code IS NOT NULL
    AND NOT REGEXP_CONTAINS(zip_code, r'X')
)
SELECT
  n_other_companies,
  COUNT(*) AS complaints,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_zip_valid
FROM (
  SELECT a.complaint_id, COUNT(DISTINCT b.company) AS n_other_companies
  FROM base a
  LEFT JOIN base b
    ON a.zip_code = b.zip_code
   AND a.company != b.company
   AND a.issue = b.issue
   AND a.sub_issue = b.sub_issue
   AND b.date_received BETWEEN TIMESTAMP_SUB(a.date_received, INTERVAL 3 SECOND)
                           AND TIMESTAMP_ADD(a.date_received, INTERVAL 3 SECOND)
  GROUP BY a.complaint_id
)
GROUP BY n_other_companies
ORDER BY n_other_companies

/*
[{
  "n_other_companies": "0",
  "complaints": "2250680",
  "pct_of_zip_valid": "69.1"
}, {
  "n_other_companies": "1",
  "complaints": "931087",
  "pct_of_zip_valid": "28.6"
}, {
  "n_other_companies": "2",
  "complaints": "76980",
  "pct_of_zip_valid": "2.4"
}]
*/