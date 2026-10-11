SELECT COUNT(*) AS records, COUNT(DISTINCT filing_id) AS filings
FROM `cfpb-complaints-pipeline.cfpb.complaints_enriched`;

/*
[{
  "records": "3365230",
  "filings": "2849379"
}]
*/