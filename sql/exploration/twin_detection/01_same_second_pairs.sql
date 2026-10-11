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
, grp AS (
  SELECT zip_code, date_received, issue, sub_issue,
         COUNT(*) AS n,
         COUNT(DISTINCT company) AS n_companies
  FROM base
  GROUP BY zip_code, date_received, issue, sub_issue
  HAVING COUNT(*) >= 2
)
SELECT
  n AS group_size,
  n_companies,
  COUNT(*) AS n_groups,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY n), 1) AS pct_within_size
FROM grp
GROUP BY group_size, n_companies
ORDER BY group_size, n_companies


/*
[{
  "group_size": "2",
  "n_companies": "1",
  "n_groups": "8095",
  "pct_within_size": "2.0"
}, {
  "group_size": "2",
  "n_companies": "2",
  "n_groups": "398843",
  "pct_within_size": "98.0"
}, {
  "group_size": "3",
  "n_companies": "1",
  "n_groups": "7",
  "pct_within_size": "0.2"
}, {
  "group_size": "3",
  "n_companies": "2",
  "n_groups": "263",
  "pct_within_size": "6.3"
}, {
  "group_size": "3",
  "n_companies": "3",
  "n_groups": "3914",
  "pct_within_size": "93.5"
}, {
  "group_size": "4",
  "n_companies": "2",
  "n_groups": "19",
  "pct_within_size": "70.4"
}, {
  "group_size": "4",
  "n_companies": "3",
  "n_groups": "8",
  "pct_within_size": "29.6"
}]
*/