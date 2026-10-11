SELECT submitted_via, COUNT(*) AS complaints
FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
GROUP BY submitted_via
ORDER BY complaints DESC

/*
[{
  "submitted_via": "Web",
  "complaints": "3362125"
}, {
  "submitted_via": "Phone",
  "complaints": "1724"
}, {
  "submitted_via": "Postal mail",
  "complaints": "702"
}, {
  "submitted_via": "Referral",
  "complaints": "679"
}]
*/