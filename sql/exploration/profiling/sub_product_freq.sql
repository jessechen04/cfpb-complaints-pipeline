SELECT sub_product, COUNT(*) AS complaints
FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
GROUP BY sub_product
ORDER BY complaints DESC

/*
[{
  "sub_product": "Credit reporting",
  "complaints": "3357994"
}, {
  "sub_product": "Other personal consumer report",
  "complaints": "7236"
}]
*/