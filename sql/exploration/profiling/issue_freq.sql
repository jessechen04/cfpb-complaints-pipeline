SELECT
  issue,
  COUNT(*) AS complaints,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
GROUP BY issue
ORDER BY complaints DESC


/*
[{
  "issue": "Incorrect information on your report",
  "complaints": "2019662",
  "pct": "60.0"
}, {
  "issue": "Problem with a company\u0027s investigation into an existing problem",
  "complaints": "673224",
  "pct": "20.0"
}, {
  "issue": "Improper use of your report",
  "complaints": "652261",
  "pct": "19.4"
}, {
  "issue": "Unable to get your credit report or credit score",
  "complaints": "9050",
  "pct": "0.3"
}, {
  "issue": "Problem with fraud alerts or security freezes",
  "complaints": "5751",
  "pct": "0.2"
}, {
  "issue": "Credit monitoring or identity theft protection services",
  "complaints": "2764",
  "pct": "0.1"
}, {
  "issue": "Problem with a company\u0027s investigation into an existing issue",
  "complaints": "2391",
  "pct": "0.1"
}, {
  "issue": "Identity theft protection or other monitoring services",
  "complaints": "127",
  "pct": "0.0"
}]
*/