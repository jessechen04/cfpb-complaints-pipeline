import requests
import json

base_url = "https://www.consumerfinance.gov/data-research/consumer-complaints/search/api/v1/"

headers = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "*/*",
}

# No page, no frm
params = {
    "size": 1,
    "no_aggs": "true",
    "company": "EQUIFAX, INC.",
    "product": "Credit reporting or other personal consumer reports",
    "date_received_min": "2026-04-08",
    "date_received_max": "2026-04-09",
    "sort": "created_date_desc",
}


def fetch(p):
    r = requests.get(base_url, params=p, headers=headers, timeout=60)
    print("URL:", r.url)
    print("Status:", r.status_code)
    if r.status_code != 200:
        print("Body:", r.text[:300])
        return None
    data = r.json()
    hits = data["hits"]["hits"]
    ids = [h["_source"]["complaint_id"] for h in hits]
    print("Records:", len(ids), "| first:", ids[0], "| last:", ids[-1])
    print("Last sort:", hits[-1]["sort"])
    print("_meta:")
    print(json.dumps(data.get("_meta"), indent=2), "\n")
    return ids


print("=== Without page/frm ===")
without = fetch(params)

print("=== With page=1, frm=0 (baseline) ===")
baseline = fetch({**params, "page": 1, "frm": 0})

if without is not None and baseline is not None:
    print("Identical results:", without == baseline)