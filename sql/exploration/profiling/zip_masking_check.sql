SELECT
  COUNTIF(zip_code IS NULL) AS null_zip,
  COUNTIF(REGEXP_CONTAINS(zip_code, r'X')) AS masked_zip,
  COUNT(*) AS total
FROM `your-project-id.cfpb.complaints_raw`

/*
[{
  "null_zip": "1065",
  "masked_zip": "105418",
  "total": "3365230"
}]
*/
