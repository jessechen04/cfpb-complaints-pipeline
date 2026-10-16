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

params = {
    "size": 2,
    "no_aggs": "false",   # false so _meta.break_points is included, as in your earlier runs
    "sort": "created_date_desc",
    "date_received_min": "2026-04-08",
    "date_received_max": "2026-04-09",
    # no company, no product, no search_after on the first request
}

seen_ids = []
all_stamps = []

for page_num in range(1, 4):
    r = requests.get(base_url, params=params, headers=headers, timeout=60)
    print(f"\n===== Request {page_num} =====")
    print("URL:", r.url)
    print("Status:", r.status_code)
    if r.status_code != 200:
        print("Body:", r.text[:300])
        break

    data = r.json()
    hits = data["hits"]["hits"]
    if not hits:
        print("No records returned.")
        break

    for h in hits:
        cid = h["_source"]["complaint_id"]
        print(f"  id={cid}  sort={h['sort']}  date_received={h['_source'].get('date_received')}")
        seen_ids.append(cid)
        all_stamps.append(h["sort"][0])

    last_sort = hits[-1]["sort"]
    cursor = f"{last_sort[0]}_{last_sort[1]}"
    print("Cursor built from last hit:", cursor)
    # print("break_points:", json.dumps(data.get("_meta", {}).get("break_points"), indent=2))

    # next request uses the cursor
    params["search_after"] = cursor

print("\n===== Summary =====")
print("IDs in order:", seen_ids)
print("Any duplicates:", len(seen_ids) != len(set(seen_ids)))
print("Timestamps non-increasing:", all_stamps == sorted(all_stamps, reverse=True))