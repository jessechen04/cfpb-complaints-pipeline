SELECT tags, COUNT(*) AS complaints
FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
GROUP BY tags
ORDER BY complaints DESC

/*
[{
  "tags": null,
  "complaints": "3327772"
}, {
  "tags": "Servicemember",
  "complaints": "27548"
}, {
  "tags": "Older American",
  "complaints": "9087"
}, {
  "tags": "Older American, Servicemember",
  "complaints": "823"
}]
*/