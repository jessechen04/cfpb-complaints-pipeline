# from google.cloud import storage

# BUCKET = "chenj-cfpb-complaints-raw"

# client = storage.Client()
# blob = client.bucket(BUCKET).blob("raw/test/hello.txt")
# blob.upload_from_string("hello")
# print("Uploaded:", blob.name)

# print([b.name for b in client.list_blobs(BUCKET, prefix="raw/")])

import gzip, shutil
from datetime import datetime, timezone
from google.cloud import storage

BUCKET = "chenj-cfpb-complaints-raw"

with open("complaints_raw.jsonl", "rb") as src, gzip.open("complaints_raw.jsonl.gz", "wb") as dst:
    shutil.copyfileobj(src, dst)

stamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%S")
blob = storage.Client().bucket(BUCKET).blob(f"raw/{stamp}/complaints_raw.jsonl.gz")
blob.upload_from_filename("complaints_raw.jsonl.gz", timeout=600)
print("Uploaded", blob.name)