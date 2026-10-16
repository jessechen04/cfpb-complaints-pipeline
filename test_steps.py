import main
from google.cloud import bigquery

bq = bigquery.Client(project=main.PROJECT)

# # 1. Upload: use a snapshot file you already have locally
# blob = main.upload_snapshot("complaints_raw.jsonl.gz")
# # return example: "raw/2026-10-08T001100/complaints_raw.jsonl.gz"

# main.load_bq(bq, "raw/2026-10-08T001100/complaints_raw.jsonl.gz")
# # 2. Load + rebuild: use that blob (or any existing one in your bucket)
# main.load_bq(bq, blob)
main.rebuild_tables(bq)

# # 3. Sheets (set SHEET_ID first)
# main.push_sheets(bq)