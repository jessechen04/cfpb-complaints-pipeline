SELECT sub_issue, COUNT(*) AS complaints
FROM `cfpb-complaints-pipeline.cfpb.complaints_raw`
GROUP BY sub_issue
ORDER BY complaints DESC

/*
[{
  "sub_issue": "Information belongs to someone else",
  "complaints": "1299560"
}, {
  "sub_issue": "Reporting company used your report improperly",
  "complaints": "541786"
}, {
  "sub_issue": "Account information incorrect",
  "complaints": "436957"
}, {
  "sub_issue": "Investigation took more than 30 days",
  "complaints": "348083"
}, {
  "sub_issue": "Their investigation did not fix an error on your report",
  "complaints": "296620"
}, {
  "sub_issue": "Account status incorrect",
  "complaints": "167250"
}, {
  "sub_issue": "Credit inquiries on your report that you don\u0027t recognize",
  "complaints": "108571"
}, {
  "sub_issue": "Personal information incorrect",
  "complaints": "73717"
}, {
  "sub_issue": "Information is missing that should be on the report",
  "complaints": "26552"
}, {
  "sub_issue": "Was not notified of investigation status or results",
  "complaints": "17618"
}, {
  "sub_issue": "Other problem getting your report or credit score",
  "complaints": "8215"
}, {
  "sub_issue": "Public record information inaccurate",
  "complaints": "8027"
}, {
  "sub_issue": "Difficulty submitting a dispute or getting information about a dispute over the phone",
  "complaints": "7020"
}, {
  "sub_issue": "Old information reappears or never goes away",
  "complaints": "6798"
}, {
  "sub_issue": "Problem with personal statement of dispute",
  "complaints": "6274"
}, {
  "sub_issue": null,
  "complaints": "5751"
}, {
  "sub_issue": "Problem canceling credit monitoring or identify theft protection service",
  "complaints": "1205"
}, {
  "sub_issue": "Received unsolicited financial product or insurance offers after opting out",
  "complaints": "1202"
}, {
  "sub_issue": "Didn\u0027t receive services that were advertised",
  "complaints": "1178"
}, {
  "sub_issue": "Problem getting your free annual credit report",
  "complaints": "835"
}, {
  "sub_issue": "Information is incorrect",
  "complaints": "735"
}, {
  "sub_issue": "Report provided to employer without your written authorization",
  "complaints": "702"
}, {
  "sub_issue": "Billing dispute for services",
  "complaints": "312"
}, {
  "sub_issue": "Problem with product or service terms changing",
  "complaints": "145"
}, {
  "sub_issue": "Information that should be on the report is missing",
  "complaints": "66"
}, {
  "sub_issue": "Received unwanted marketing or advertising",
  "complaints": "51"
}]
*/