import gzip, shutil
from datetime import datetime, timezone
from google.cloud import storage

BUCKET = "yourname-cfpb-complaints"

with open("complaints_raw.jsonl", "rb") as src, gzip.open("complaints_raw.jsonl.gz", "wb") as dst:
    shutil.copyfileobj(src, dst)

stamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%S")
blob = storage.Client().bucket(BUCKET).blob(f"raw/{stamp}/complaints_raw.jsonl.gz")
blob.upload_from_filename("complaints_raw.jsonl.gz", timeout=600)
print("Uploaded", blob.name)


import gzip
import shutil
import tempfile
from google.cloud import storage

BUCKET = os.environ.get("CFPB_BUCKET", "yourname-cfpb-complaints")
WORK_DIR = tempfile.gettempdir()   # /tmp on Cloud Run, your temp folder on Windows
OLD_FILE = os.path.join(WORK_DIR, "complaints_raw.jsonl")
OUTPUT_FILE = OLD_FILE + ".tmp"

client = storage.Client()


def download_latest_snapshot():
    blobs = [
        b for b in client.list_blobs(BUCKET, prefix="raw/")
        if b.name.endswith("complaints_raw.jsonl.gz")
    ]
    if not blobs:
        raise RuntimeError("No snapshot in bucket. Seed it first.")
    latest = max(blobs, key=lambda b: b.name)   # ISO timestamps sort correctly
    print("Using snapshot:", latest.name)

    gz_path = OLD_FILE + ".gz"
    latest.download_to_filename(gz_path)
    with gzip.open(gz_path, "rb") as src, open(OLD_FILE, "wb") as dst:
        shutil.copyfileobj(src, dst)
    os.remove(gz_path)


def validate(path, previous_count):
    ids, prev_date, violations, count = set(), None, 0, 0
    with open(path, encoding="utf-8") as f:
        for line in f:
            rec = json.loads(line)
            ids.add(rec["complaint_id"])
            d = rec["date_received"]
            if prev_date is not None and d > prev_date:
                violations += 1
            prev_date = d
            count += 1
    problems = []
    if len(ids) != count:
        problems.append(f"{count - len(ids)} duplicate IDs")
    if violations:
        problems.append(f"{violations} order violations")
    if count < previous_count * 0.95:
        problems.append(f"count {count} is >5% below previous {previous_count}")
    if problems:
        raise RuntimeError("Validation failed, not uploading: " + "; ".join(problems))
    print(f"Validation passed: {count} records")
    return count


def upload_snapshot(path):
    gz_path = path + ".gz"
    with open(path, "rb") as src, gzip.open(gz_path, "wb") as dst:
        shutil.copyfileobj(src, dst)
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%S")
    blob = client.bucket(BUCKET).blob(f"raw/{stamp}/complaints_raw.jsonl.gz")
    blob.upload_from_filename(gz_path, timeout=600)
    print("Uploaded", blob.name)

    os.replace(OUTPUT_FILE, OLD_FILE)
validate(OLD_FILE, previous_count)
upload_snapshot(OLD_FILE)