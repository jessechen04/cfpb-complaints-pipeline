import json
import os
import time
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

OLD_FILE = "complaints_raw.jsonl"
OUTPUT_FILE = "complaints_raw.jsonl.tmp"

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


# ---- Read Old File ----
seen_ids = set()
first_date = None

if os.path.exists(OLD_FILE):
    with open(OLD_FILE, "r", encoding="utf-8") as f:
        for line in f:
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if first_date is None:
                first_date = rec["date_received"]   # line 1 = newest
            seen_ids.add(rec["complaint_id"])

    if first_date:
        start = datetime.strptime(first_date[:10], "%Y-%m-%d") - timedelta(days=1)
        params["date_received_min"] = start.strftime("%Y-%m-%d")
        print(f"Collecting new records back to {start.date()}")
else:
    raise RuntimeError("No previous snapshot found. Run the initial pull locally first.")

new_written = 0
duplicates_skipped = 0
cutoff = six_months_ago.strftime("%Y-%m-%d")

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    while True:
        data = get_page(params)
        hits = data.get("hits", {}).get("hits", [])
        if not hits:
            break

        for hit in hits:
            src = hit["_source"]
            cid = src["complaint_id"]
            if cid in seen_ids:
                duplicates_skipped += 1
                continue
            seen_ids.add(cid)
            f.write(json.dumps(src) + "\n")
            new_written += 1

        last_sort = hits[-1]["sort"]
        params["search_after"] = f"{last_sort[0]}_{last_sort[1]}"

        print(f"New records: {new_written} (skipped {duplicates_skipped} dupes)")
        time.sleep(0.5)

    kept = 0
    bad_lines = 0
    with open(OLD_FILE, "r", encoding="utf-8") as old:
        for line_no, line in enumerate(old, 1):
            try:
                date = json.loads(line)["date_received"][:10]
            except (ValueError, KeyError):
                bad_lines += 1
                print(f"Bad line {line_no} in old file: {line[:80]!r}")
                continue
            if date < cutoff:
                break
            f.write(line)
            kept += 1

if bad_lines:
    raise RuntimeError(
        f"{bad_lines} unreadable line(s) in the old snapshot. "
        "Not replacing it. Inspect the file first."
    )

os.replace(OUTPUT_FILE, OLD_FILE)
print(f"\nDone. {new_written} new + {kept} kept = {new_written + kept} records in {OLD_FILE}")
print(f"Duplicates skipped: {duplicates_skipped}")