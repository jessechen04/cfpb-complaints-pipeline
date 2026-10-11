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
, gaps AS (
  SELECT
    a.complaint_id,
    MIN(ABS(TIMESTAMP_DIFF(a.date_received, b.date_received, SECOND))) AS min_gap_sec
  FROM base a
  JOIN base b
    ON a.zip_code = b.zip_code
   AND a.company != b.company
   AND a.issue = b.issue
   AND a.sub_issue = b.sub_issue
   AND b.date_received BETWEEN TIMESTAMP_SUB(a.date_received, INTERVAL 60 SECOND)
                           AND TIMESTAMP_ADD(a.date_received, INTERVAL 60 SECOND)
  GROUP BY a.complaint_id
)
SELECT
  min_gap_sec,
  COUNT(*) AS complaints,
  ROUND(100 * SUM(COUNT(*)) OVER (ORDER BY min_gap_sec)
            / SUM(COUNT(*)) OVER (), 1) AS cum_pct_of_matched
FROM gaps
GROUP BY min_gap_sec
ORDER BY min_gap_sec

/*
[{
  "min_gap_sec": "0",
  "complaints": "810325",
  "cum_pct_of_matched": "67.6"
}, {
  "min_gap_sec": "1",
  "complaints": "100408",
  "cum_pct_of_matched": "75.9"
}, {
  "min_gap_sec": "2",
  "complaints": "65797",
  "cum_pct_of_matched": "81.4"
}, {
  "min_gap_sec": "3",
  "complaints": "31537",
  "cum_pct_of_matched": "84.1"
}, {
  "min_gap_sec": "4",
  "complaints": "19060",
  "cum_pct_of_matched": "85.7"
}, {
  "min_gap_sec": "5",
  "complaints": "13558",
  "cum_pct_of_matched": "86.8"
}, {
  "min_gap_sec": "6",
  "complaints": "10117",
  "cum_pct_of_matched": "87.6"
}, {
  "min_gap_sec": "7",
  "complaints": "7608",
  "cum_pct_of_matched": "88.3"
}, {
  "min_gap_sec": "8",
  "complaints": "6327",
  "cum_pct_of_matched": "88.8"
}, {
  "min_gap_sec": "9",
  "complaints": "5481",
  "cum_pct_of_matched": "89.2"
}, {
  "min_gap_sec": "10",
  "complaints": "4830",
  "cum_pct_of_matched": "89.7"
}, {
  "min_gap_sec": "11",
  "complaints": "4440",
  "cum_pct_of_matched": "90.0"
}, {
  "min_gap_sec": "12",
  "complaints": "4156",
  "cum_pct_of_matched": "90.4"
}, {
  "min_gap_sec": "13",
  "complaints": "4104",
  "cum_pct_of_matched": "90.7"
}, {
  "min_gap_sec": "14",
  "complaints": "4249",
  "cum_pct_of_matched": "91.1"
}, {
  "min_gap_sec": "15",
  "complaints": "4241",
  "cum_pct_of_matched": "91.4"
}, {
  "min_gap_sec": "16",
  "complaints": "4360",
  "cum_pct_of_matched": "91.8"
}, {
  "min_gap_sec": "17",
  "complaints": "4674",
  "cum_pct_of_matched": "92.2"
}, {
  "min_gap_sec": "18",
  "complaints": "4682",
  "cum_pct_of_matched": "92.6"
}, {
  "min_gap_sec": "19",
  "complaints": "4735",
  "cum_pct_of_matched": "93.0"
}, {
  "min_gap_sec": "20",
  "complaints": "4509",
  "cum_pct_of_matched": "93.3"
}, {
  "min_gap_sec": "21",
  "complaints": "4168",
  "cum_pct_of_matched": "93.7"
}, {
  "min_gap_sec": "22",
  "complaints": "3939",
  "cum_pct_of_matched": "94.0"
}, {
  "min_gap_sec": "23",
  "complaints": "3811",
  "cum_pct_of_matched": "94.3"
}, {
  "min_gap_sec": "24",
  "complaints": "3455",
  "cum_pct_of_matched": "94.6"
}, {
  "min_gap_sec": "25",
  "complaints": "3208",
  "cum_pct_of_matched": "94.9"
}, {
  "min_gap_sec": "26",
  "complaints": "3052",
  "cum_pct_of_matched": "95.1"
}, {
  "min_gap_sec": "27",
  "complaints": "2954",
  "cum_pct_of_matched": "95.4"
}, {
  "min_gap_sec": "28",
  "complaints": "2811",
  "cum_pct_of_matched": "95.6"
}, {
  "min_gap_sec": "29",
  "complaints": "2709",
  "cum_pct_of_matched": "95.8"
}, {
  "min_gap_sec": "30",
  "complaints": "2642",
  "cum_pct_of_matched": "96.1"
}, {
  "min_gap_sec": "31",
  "complaints": "2495",
  "cum_pct_of_matched": "96.3"
}, {
  "min_gap_sec": "32",
  "complaints": "2515",
  "cum_pct_of_matched": "96.5"
}, {
  "min_gap_sec": "33",
  "complaints": "2491",
  "cum_pct_of_matched": "96.7"
}, {
  "min_gap_sec": "34",
  "complaints": "2460",
  "cum_pct_of_matched": "96.9"
}, {
  "min_gap_sec": "35",
  "complaints": "2289",
  "cum_pct_of_matched": "97.1"
}, {
  "min_gap_sec": "36",
  "complaints": "2293",
  "cum_pct_of_matched": "97.3"
}, {
  "min_gap_sec": "37",
  "complaints": "2286",
  "cum_pct_of_matched": "97.5"
}, {
  "min_gap_sec": "38",
  "complaints": "2123",
  "cum_pct_of_matched": "97.6"
}, {
  "min_gap_sec": "39",
  "complaints": "2042",
  "cum_pct_of_matched": "97.8"
}, {
  "min_gap_sec": "40",
  "complaints": "1895",
  "cum_pct_of_matched": "98.0"
}, {
  "min_gap_sec": "41",
  "complaints": "1778",
  "cum_pct_of_matched": "98.1"
}, {
  "min_gap_sec": "42",
  "complaints": "1692",
  "cum_pct_of_matched": "98.3"
}, {
  "min_gap_sec": "43",
  "complaints": "1584",
  "cum_pct_of_matched": "98.4"
}, {
  "min_gap_sec": "44",
  "complaints": "1493",
  "cum_pct_of_matched": "98.5"
}, {
  "min_gap_sec": "45",
  "complaints": "1549",
  "cum_pct_of_matched": "98.6"
}, {
  "min_gap_sec": "46",
  "complaints": "1312",
  "cum_pct_of_matched": "98.8"
}, {
  "min_gap_sec": "47",
  "complaints": "1351",
  "cum_pct_of_matched": "98.9"
}, {
  "min_gap_sec": "48",
  "complaints": "1297",
  "cum_pct_of_matched": "99.0"
}, {
  "min_gap_sec": "49",
  "complaints": "1250",
  "cum_pct_of_matched": "99.1"
}, {
  "min_gap_sec": "50",
  "complaints": "1126",
  "cum_pct_of_matched": "99.2"
}, {
  "min_gap_sec": "51",
  "complaints": "1137",
  "cum_pct_of_matched": "99.3"
}, {
  "min_gap_sec": "52",
  "complaints": "1104",
  "cum_pct_of_matched": "99.4"
}, {
  "min_gap_sec": "53",
  "complaints": "979",
  "cum_pct_of_matched": "99.4"
}, {
  "min_gap_sec": "54",
  "complaints": "1008",
  "cum_pct_of_matched": "99.5"
}, {
  "min_gap_sec": "55",
  "complaints": "959",
  "cum_pct_of_matched": "99.6"
}, {
  "min_gap_sec": "56",
  "complaints": "981",
  "cum_pct_of_matched": "99.7"
}, {
  "min_gap_sec": "57",
  "complaints": "921",
  "cum_pct_of_matched": "99.8"
}, {
  "min_gap_sec": "58",
  "complaints": "974",
  "cum_pct_of_matched": "99.9"
}, {
  "min_gap_sec": "59",
  "complaints": "922",
  "cum_pct_of_matched": "99.9"
}, {
  "min_gap_sec": "60",
  "complaints": "872",
  "cum_pct_of_matched": "100.0"
}]
*/