import json
import os
import time
from collections import Counter
from datetime import datetime, timedelta, timezone

import requests
from dateutil.relativedelta import relativedelta

base_url = "https://www.consumerfinance.gov/data-research/consumer-complaints/search/api/v1/"

headers = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json",
}

OUTPUT_FILE = "complaints_raw.jsonl"

today = datetime.now(timezone.utc)
six_months_ago = today - relativedelta(months=6)

params = {
    "size": 1000,
    "no_aggs": "true",
    "sort": "created_date_desc",
    "company": [
        "TRANSUNION INTERMEDIATE HOLDINGS, INC.",
        "EQUIFAX, INC.",
        "Experian Information Solutions Inc.",
    ],
    "product": "Credit reporting or other personal consumer reports",
    "date_received_min": six_months_ago.strftime("%Y-%m-%d"),
    "date_received_max": today.strftime("%Y-%m-%d"),
}

session = requests.Session()
session.headers.update(headers)


def get_page(params, retries=6):
    """GET with exponential backoff: waits 5, 10, 20, 40, 60s between tries."""
    for attempt in range(1, retries + 1):
        try:
            r = session.get(base_url, params=params, timeout=120)
            r.raise_for_status()
            return r.json()
        except (requests.RequestException, ValueError) as e:
            print(f"Request failed (attempt {attempt}/{retries}): {e}")
            if attempt == retries:
                raise
            wait = min(5 * 2 ** (attempt - 1), 60)
            print(f"  waiting {wait}s before retrying...")
            time.sleep(wait)


# ---- Resume from an existing file ----
seen_ids = set()
by_company = Counter()
last_date = None

if os.path.exists(OUTPUT_FILE):
    with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
        for line in f:
            try:
                rec = json.loads(line)
            except ValueError:
                continue  # skip a partial last line
            seen_ids.add(rec["complaint_id"])
            by_company[rec.get("company")] += 1
            last_date = rec.get("date_received")

    if last_date:
        # max is inclusive, so restart from the last saved record's day
        params["date_received_max"] = last_date[:10]
        print(f"Resuming: {len(seen_ids)} records already saved, "
              f"restarting from {last_date[:10]}")

total_written = len(seen_ids)
duplicates_skipped = 0
first_page = True

with open(OUTPUT_FILE, "a", encoding="utf-8") as f:
    while True:
        data = get_page(params)
        hits = data.get("hits", {}).get("hits", [])
        if not hits:
            break

        if first_page:
            print("total_record_count:", data.get("_meta", {}).get("total_record_count"))
            print("hits.total:", data.get("hits", {}).get("total"))
            print("Newest record on first page:", hits[0]["_source"].get("date_received"))
            first_page = False

        for hit in hits:
            src = hit["_source"]
            cid = src["complaint_id"]
            if cid in seen_ids:
                duplicates_skipped += 1
                continue
            seen_ids.add(cid)
            by_company[src.get("company")] += 1
            f.write(json.dumps(src) + "\n")
            total_written += 1

        f.flush()  # make sure each page is on disk

        last_sort = hits[-1]["sort"]
        params["search_after"] = f"{last_sort[0]}_{last_sort[1]}"

        print(f"Total records: {total_written} (skipped {duplicates_skipped} dupes)")
        time.sleep(0.5)

print(f"\nDone. {total_written} records in {OUTPUT_FILE}")
print(f"Duplicates skipped: {duplicates_skipped}")
for company, n in by_company.most_common():
    print(f"  {company}: {n}")