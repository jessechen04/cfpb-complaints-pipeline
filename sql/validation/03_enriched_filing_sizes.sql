SELECT records_in_filing, COUNT(*) AS filings
FROM (
  SELECT filing_id, COUNT(*) AS records_in_filing
  FROM `cfpb-complaints-pipeline.cfpb.complaints_enriched`
  GROUP BY filing_id
)
GROUP BY records_in_filing
ORDER BY records_in_filing;

/*
[{
  "records_in_filing": "1",
  "filings": "2362941"
}, {
  "records_in_filing": "2",
  "filings": "457025"
}, {
  "records_in_filing": "3",
  "filings": "29413"
}]
*/