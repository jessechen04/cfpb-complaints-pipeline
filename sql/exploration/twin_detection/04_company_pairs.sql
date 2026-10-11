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
  a.company AS company_a,
  b.company AS company_b,
  COUNT(*) AS matched_pairs,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_pairs
FROM base a
JOIN base b
  ON a.zip_code = b.zip_code
 AND a.company < b.company
 AND a.issue = b.issue
 AND a.sub_issue = b.sub_issue
 AND b.date_received BETWEEN TIMESTAMP_SUB(a.date_received, INTERVAL 3 SECOND)
                         AND TIMESTAMP_ADD(a.date_received, INTERVAL 3 SECOND)
GROUP BY company_a, company_b
ORDER BY matched_pairs DESC

/*
[{
  "company_a": "Experian Information Solutions Inc.",
  "company_b": "TRANSUNION INTERMEDIATE HOLDINGS, INC.",
  "matched_pairs": "262621",
  "pct_of_pairs": "48.0"
}, {
  "company_a": "EQUIFAX, INC.",
  "company_b": "TRANSUNION INTERMEDIATE HOLDINGS, INC.",
  "matched_pairs": "149570",
  "pct_of_pairs": "27.3"
}, {
  "company_a": "EQUIFAX, INC.",
  "company_b": "Experian Information Solutions Inc.",
  "matched_pairs": "135215",
  "pct_of_pairs": "24.7"
}]
*/