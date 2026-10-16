SELECT filing_id, complaint_id, company, zip_code, date_received, issue, sub_issue
FROM `cfpb-complaints-pipeline.cfpb.complaints_enriched`
WHERE filing_id IN (
  SELECT filing_id
  FROM `cfpb-complaints-pipeline.cfpb.complaints_enriched`
  GROUP BY filing_id
  HAVING COUNT(*) = 3
  LIMIT 5
)
ORDER BY filing_id, date_received;

/*
[{
  "filing_id": "4170151332145606707",
  "complaint_id": "26925612",
  "company": "TRANSUNION INTERMEDIATE HOLDINGS, INC.",
  "zip_code": "60565",
  "date_received": "2026-09-10 05:26:56.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "4170151332145606707",
  "complaint_id": "26925611",
  "company": "EQUIFAX, INC.",
  "zip_code": "60565",
  "date_received": "2026-09-10 05:26:56.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "4170151332145606707",
  "complaint_id": "26925610",
  "company": "Experian Information Solutions Inc.",
  "zip_code": "60565",
  "date_received": "2026-09-10 05:26:56.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "4520212144698313874",
  "complaint_id": "22009603",
  "company": "TRANSUNION INTERMEDIATE HOLDINGS, INC.",
  "zip_code": "91733",
  "date_received": "2026-05-08 10:09:03.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "4520212144698313874",
  "complaint_id": "22009604",
  "company": "EQUIFAX, INC.",
  "zip_code": "91733",
  "date_received": "2026-05-08 10:09:06.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "4520212144698313874",
  "complaint_id": "22009605",
  "company": "Experian Information Solutions Inc.",
  "zip_code": "91733",
  "date_received": "2026-05-08 10:09:09.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "6034844518380097899",
  "complaint_id": "26771269",
  "company": "EQUIFAX, INC.",
  "zip_code": "33139",
  "date_received": "2026-09-08 13:35:05.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "6034844518380097899",
  "complaint_id": "26771268",
  "company": "Experian Information Solutions Inc.",
  "zip_code": "33139",
  "date_received": "2026-09-08 13:35:05.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "6034844518380097899",
  "complaint_id": "26771270",
  "company": "TRANSUNION INTERMEDIATE HOLDINGS, INC.",
  "zip_code": "33139",
  "date_received": "2026-09-08 13:35:05.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "7117091757592440595",
  "complaint_id": "21377761",
  "company": "EQUIFAX, INC.",
  "zip_code": "79118",
  "date_received": "2026-04-18 21:23:11.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "7117091757592440595",
  "complaint_id": "21377756",
  "company": "Experian Information Solutions Inc.",
  "zip_code": "79118",
  "date_received": "2026-04-18 21:23:12.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "7117091757592440595",
  "complaint_id": "21377768",
  "company": "TRANSUNION INTERMEDIATE HOLDINGS, INC.",
  "zip_code": "79118",
  "date_received": "2026-04-18 21:23:12.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "8558792574141532473",
  "complaint_id": "21647745",
  "company": "EQUIFAX, INC.",
  "zip_code": "33626",
  "date_received": "2026-04-27 23:42:37.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "8558792574141532473",
  "complaint_id": "21647743",
  "company": "Experian Information Solutions Inc.",
  "zip_code": "33626",
  "date_received": "2026-04-27 23:42:37.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}, {
  "filing_id": "8558792574141532473",
  "complaint_id": "21647744",
  "company": "TRANSUNION INTERMEDIATE HOLDINGS, INC.",
  "zip_code": "33626",
  "date_received": "2026-04-27 23:42:37.000000 UTC",
  "issue": "Incorrect information on your report",
  "sub_issue": "Account information incorrect"
}]
*/