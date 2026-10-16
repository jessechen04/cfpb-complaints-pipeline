import requests, json 
from google.cloud import storage
from datetime import datetime, timedelta, timezone
from dateutil.relativedelta import relativedelta

base_url = ( "https://www.consumerfinance.gov/data-research/consumer-complaints/search/api/v1/" )

# 1. Add headers to mimic a browser/legitimate tool
headers = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML,"
        " like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json",
}

today = datetime.now(timezone.utc)
# three_years_ago = today - timedelta(days=3*365)
six_months_ago = today - relativedelta(months=6)

params = {
    "size": 1,
    "frm": 0, 
    "no_aggs": True,
    "sort": "created_date_desc",
    "company": ["TRANSUNION INTERMEDIATE HOLDINGS, INC.", "EQUIFAX, INC.", "Experian Information Solutions Inc."],
    "date_received_max": today.strftime("%Y-%m-%d"),
    "date_received_min": six_months_ago.strftime("%Y-%m-%d"),
    "product": "Credit reporting or other personal consumer reports"
}

all_hits = []
max_records = 1

with open("complaints_raw.json", "w") as f:
    while True:

        # calls api
        response = requests.get(base_url, params=params, headers=headers)

        # DEBUGGING
        # print(f"Status Code: {response.status_code}")
        # print(f"Raw Response Text: {repr(response.text)}")

        # converts to python dict
        data = response.json()

        # api structure has complaints inside hits
        hits = data.get("hits", {}).get("hits", [])
        if not hits:
            break


        # for hit in hits:
        #     f.write(json.dumps(hit["_source"]) + "\n")

        # # like append() but more elements
        all_hits.extend(hits)

        # adjust to start next batch
        params["frm"] += params["size"]

        # for visuals and debug
        # total_count = data.get("_meta", {}).get("total_record_count", 0)
        # print(
        #     f"Fetched up to index {params['frm']} (Total available in DB:"
        #     f" {total_count})..."
        # )

        print(f"Fetched up to index {params['frm']}")

        # end early if hit limit
        if params["frm"] >= max_records:
            print(f"Reached test limit of {max_records} records. Stopping early!")
            break

    json.dump(all_hits, f, indent=2)

    print("Saved test file successfully")


# # --- Component 1b: Upload local file to Google Cloud Storage ---

# # 1. Initialize the GCS client
# storage_client = storage.Client()

# # 2. Define your bucket name (replace with your actual GCS bucket name)
# bucket_name = "your-gcs-bucket-name"
# bucket = storage_client.bucket(bucket_name)

# # 3. Define the destination blob (file) name inside the bucket
# blob = bucket.blob("raw/complaints_raw.json")

# # 4. Upload the local file
# blob.upload_from_filename("complaints_raw.json")

# print(
#     f"Successfully uploaded complaints_raw.json to gs://{bucket_name}/raw/"
#     "complaints_raw.json"
# )