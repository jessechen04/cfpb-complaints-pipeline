"""CFPB complaints pipeline: pull -> GCS -> BigQuery -> rebuild tables -> Google Sheets.

Triggered weekly by Cloud Scheduler. Every run re-pulls the full 6-month window,
so stale "In progress" statuses are always replaced with current ones.
"""
import gzip
import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import functions_framework
import google.auth
import gspread
import requests
from dateutil.relativedelta import relativedelta
from google.api_core.exceptions import NotFound
from google.cloud import bigquery, storage

# ---------------------------------------------------------------- config
PROJECT = os.environ.get("GCP_PROJECT_ID", "cfpb-complaints-pipeline")
DATASET = os.environ.get("BQ_DATASET", "cfpb")
BUCKET = os.environ.get("BUCKET", "chenj-cfpb-complaints-raw")
SHEET_ID = os.environ.get("SHEET_ID", "1h_cfHDtJtsBV05-Uh08fxYbf9LCbF921FoGNN3XTS5Q")

RAW_TABLE = f"{PROJECT}.{DATASET}.complaints_raw"
DERIVED_TABLES = [
    "bureau_scorecard",
    "issue_by_company",
    "state_by_company",
    "weekly_by_company",
]
SQL_DIR = Path(__file__).parent / "sql" / "tables"
LOCAL_FILE = "/tmp/complaints_raw.jsonl.gz"

# Abort if the new pull has fewer than this fraction of the rows already loaded
# for the same date range. Tight on purpose: this only catches truncated pulls.
MIN_ROW_RATIO = 0.95

# True = keep only the 15 schema columns (smaller file). False = keep the full API payload.
KEEP_ONLY_SCHEMA_FIELDS = True

BASE_URL = "https://www.consumerfinance.gov/data-research/consumer-complaints/search/api/v1/"
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json",
}

SCHEMA = [
    bigquery.SchemaField("complaint_id", "STRING"),
    bigquery.SchemaField("company", "STRING"),
    bigquery.SchemaField("product", "STRING"),
    bigquery.SchemaField("sub_product", "STRING"),
    bigquery.SchemaField("issue", "STRING"),
    bigquery.SchemaField("sub_issue", "STRING"),
    bigquery.SchemaField("state", "STRING"),
    bigquery.SchemaField("zip_code", "STRING"),
    bigquery.SchemaField("submitted_via", "STRING"),
    bigquery.SchemaField("timely", "STRING"),
    bigquery.SchemaField("company_response", "STRING"),
    bigquery.SchemaField("company_public_response", "STRING"),
    bigquery.SchemaField("tags", "STRING"),
    bigquery.SchemaField("date_received", "TIMESTAMP"),
    bigquery.SchemaField("date_sent_to_company", "TIMESTAMP"),
]
FIELDS = [f.name for f in SCHEMA]


# ---------------------------------------------------------------- step 1: pull
def get_page(session, params, retries=6):
    """GET with exponential backoff: waits 5, 10, 20, 40, 60s between tries."""
    for attempt in range(1, retries + 1):
        try:
            r = session.get(BASE_URL, params=params, timeout=120)
            r.raise_for_status()
            return r.json()
        except (requests.RequestException, ValueError) as e:
            print(f"Request failed (attempt {attempt}/{retries}): {e}")
            if attempt == retries:
                raise
            wait = min(5 * 2 ** (attempt - 1), 60)
            print(f"  waiting {wait}s before retrying...")
            time.sleep(wait)


def pull_complaints(out_path=LOCAL_FILE):
    """Pull the last 6 months into a gzipped JSONL file. Returns the row count."""
    today = datetime.now(timezone.utc)
    # Built per call so nothing (e.g. search_after) leaks across warm invocations.
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
        "date_received_min": (today - relativedelta(months=6)).strftime("%Y-%m-%d"),
        "date_received_max": today.strftime("%Y-%m-%d"),
    }

    session = requests.Session()
    session.headers.update(HEADERS)

    seen = set()
    with gzip.open(out_path, "wt", encoding="utf-8") as f:
        while True:
            hits = get_page(session, params).get("hits", {}).get("hits", [])
            if not hits:
                break

            for hit in hits:
                src = hit["_source"]
                cid = src["complaint_id"]
                if cid in seen:
                    continue
                seen.add(cid)
                if KEEP_ONLY_SCHEMA_FIELDS:
                    src = {k: src.get(k) for k in FIELDS}
                f.write(json.dumps(src) + "\n")

            last_sort = hits[-1]["sort"]
            params["search_after"] = f"{last_sort[0]}_{last_sort[1]}"
            print(f"{len(seen)} records")
            time.sleep(0.5)

    return len(seen)


# ---------------------------------------------------------------- step 2: guard
def check_row_count(bq, new_count):
    """Refuse to replace the table with a suspiciously small pull."""
    if new_count == 0:
        raise RuntimeError("Pull returned 0 rows; aborting")

    cutoff = (datetime.now(timezone.utc) - relativedelta(months=6)).strftime("%Y-%m-%d")
    try:
        prev = next(iter(bq.query(
            f"SELECT COUNT(*) AS n FROM `{RAW_TABLE}` "
            f"WHERE DATE(date_received) >= '{cutoff}'"
        ).result())).n
    except NotFound:
        print("complaints_raw does not exist yet; skipping row-count guard")
        return

    print(f"New pull: {new_count} rows; same date range currently loaded: {prev}")
    if prev and new_count < MIN_ROW_RATIO * prev:
        raise RuntimeError(
            f"Pull returned {new_count} rows vs {prev} already loaded for "
            f"{cutoff} onward; aborting"
        )


# ---------------------------------------------------------------- step 3: upload
def upload_snapshot(local_path=LOCAL_FILE):
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%S")
    blob = storage.Client().bucket(BUCKET).blob(f"raw/{stamp}/complaints_raw.jsonl.gz")
    blob.upload_from_filename(local_path, timeout=600)
    print("Uploaded", blob.name)
    return blob.name


# ---------------------------------------------------------------- step 4: BigQuery
def load_bq(bq, blob_name):
    cfg = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        schema=SCHEMA,
        write_disposition="WRITE_TRUNCATE",
        ignore_unknown_values=True,  # API payload has extra fields
    )
    job = bq.load_table_from_uri(f"gs://{BUCKET}/{blob_name}", RAW_TABLE, job_config=cfg)
    job.result()
    print(f"Loaded {job.output_rows} rows into {RAW_TABLE}")


def rebuild_tables(bq):
    # .result() blocks, so tables rebuild one at a time after the load completes.
    for name in DERIVED_TABLES:
        bq.query((SQL_DIR / f"{name}.sql").read_text()).result()
        print(f"Rebuilt {name}")


# ---------------------------------------------------------------- step 5: Sheets
def refresh_sheet():
    """Tell Google Sheets to re-pull every BigQuery-connected data source in the spreadsheet."""
    if not SHEET_ID:
        print("SHEET_ID not set; skipping Sheets refresh")
        return
 
    creds, _ = google.auth.default(scopes=[
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/bigquery.readonly",  # needed for Connected Sheets data
    ])
    gc = gspread.authorize(creds)
    # The refresh runs in the background; this call returns before the data finishes loading.
    gc.open_by_key(SHEET_ID).batch_update(
        {"requests": [{"refreshDataSource": {"isAll": True}}]}
    )
    print("Requested refresh of all data sources in the spreadsheet")


# ---------------------------------------------------------------- entrypoint
@functions_framework.http
def run(request):
    start = time.time()
    bq = bigquery.Client(project=PROJECT)
    try:
        n = pull_complaints()
        check_row_count(bq, n)
        blob_name = upload_snapshot()
        load_bq(bq, blob_name)
        rebuild_tables(bq)
        refresh_sheet(bq)
    finally:
        # Warm instances reuse /tmp, so always clean up.
        if os.path.exists(LOCAL_FILE):
            os.remove(LOCAL_FILE)

    msg = f"OK: {n} rows in {time.time() - start:.0f}s"
    print(msg)
    return msg, 200