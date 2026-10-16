#!/usr/bin/env bash
set -euo pipefail

PROJECT="cfpb-complaints-pipeline"
REGION="us-east1"
FUNCTION="cfpb-weekly-refresh"
SA="cfpb-pipeline@${PROJECT}.iam.gserviceaccount.com"

# One-time setup (uncomment on first run)
# gcloud services enable cloudfunctions.googleapis.com run.googleapis.com cloudbuild.googleapis.com \
#   cloudscheduler.googleapis.com sheets.googleapis.com drive.googleapis.com --project "$PROJECT"
# gcloud iam service-accounts create cfpb-pipeline --project "$PROJECT"
# gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$SA" --role roles/bigquery.jobUser
# bq add-iam-policy-binding / dataset-level BigQuery Data Editor for $SA on the cfpb dataset
# gcloud storage buckets add-iam-policy-binding gs://chenj-cfpb-complaints-raw \
#   --member "serviceAccount:$SA" --role roles/storage.objectAdmin
# Also share each of the 4 Google Sheets with $SA as Editor.

gcloud functions deploy "$FUNCTION" \
  --gen2 --runtime python312 --region "$REGION" --project "$PROJECT" \
  --source . --entry-point run --trigger-http --no-allow-unauthenticated \
  --service-account "$SA" \
  --memory 2GiB --timeout 3600 \
  --env-vars-file env.yaml

URL=$(gcloud functions describe "$FUNCTION" --gen2 --region "$REGION" --project "$PROJECT" \
  --format='value(serviceConfig.uri)')

# Let the scheduler's service account invoke the function
gcloud run services add-iam-policy-binding "$FUNCTION" --region "$REGION" --project "$PROJECT" \
  --member "serviceAccount:$SA" --role roles/run.invoker

# Mondays 6am Eastern. Scheduler's max attempt deadline for HTTP targets is 30m.
gcloud scheduler jobs create http "${FUNCTION}-weekly" \
  --location "$REGION" --project "$PROJECT" \
  --schedule "0 6 * * 1" --time-zone "America/New_York" \
  --uri "$URL" --http-method POST \
  --oidc-service-account-email "$SA" --oidc-token-audience "$URL" \
  --attempt-deadline 30m
