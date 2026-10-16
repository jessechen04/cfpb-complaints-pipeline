#!/usr/bin/env bash
# Deploys the weekly CFPB refresh as a Cloud Run JOB and schedules it.
# A job has no 60-minute limit, and Scheduler only starts it (it doesn't wait for it).
#
# Run in Cloud Shell, Git Bash, or WSL (not plain PowerShell).
set -euo pipefail

PROJECT="cfpb-complaints-pipeline"
REGION="us-east1"
JOB="cfpb-weekly-refresh"
SA="cfpb-pipeline@${PROJECT}.iam.gserviceaccount.com"

# ------------------------------------------------------------------
# ONE-TIME SETUP. Run each line by hand once, then leave it commented.
# ------------------------------------------------------------------
# DONE: create the service account
#   gcloud iam service-accounts create cfpb-pipeline --project "$PROJECT"
# DONE: BigQuery roles (project level)
#   gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$SA" --role roles/bigquery.jobUser
#   gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$SA" --role roles/bigquery.dataEditor
# DONE: enable Sheets API; share the spreadsheet with $SA as Editor
#   gcloud services enable sheets.googleapis.com --project "$PROJECT"
#
# TODO: let the service account read/write the bucket
#   gcloud storage buckets add-iam-policy-binding gs://chenj-cfpb-complaints-raw \
#     --member "serviceAccount:$SA" --role roles/storage.objectAdmin
# TODO: enable the APIs the deploy needs
#   gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
#     artifactregistry.googleapis.com cloudscheduler.googleapis.com --project "$PROJECT"

# ------------------------------------------------------------------
# DEPLOY THE JOB. Rerun this every time the code changes.
# Builds the Dockerfile in this folder, then creates or updates the job.
# --max-retries 0: a failed run is not silently retried.
# ------------------------------------------------------------------
gcloud run jobs deploy "$JOB" \
  --source . --region "$REGION" --project "$PROJECT" \
  --service-account "$SA" \
  --memory 2Gi --task-timeout 3h --max-retries 0 --tasks 1 \
  --env-vars-file env.yaml

# Let the service account start this job (the scheduler uses it)
gcloud run jobs add-iam-policy-binding "$JOB" --region "$REGION" --project "$PROJECT" \
  --member "serviceAccount:$SA" --role roles/run.invoker

# ------------------------------------------------------------------
# SCHEDULE: Mondays 6am Eastern. Creates the schedule, or updates it if it exists.
# The URI is the Cloud Run API call that starts the job. It's a Google API, so it
# uses an OAuth token (not the OIDC token the function version used).
# ------------------------------------------------------------------
URI="https://run.googleapis.com/v2/projects/${PROJECT}/locations/${REGION}/jobs/${JOB}:run"

SCHEDULE_ARGS=(
  --location "$REGION" --project "$PROJECT"
  --schedule "0 6 * * 1" --time-zone "America/New_York"
  --uri "$URI" --http-method POST
  --oauth-service-account-email "$SA"
  --max-retry-attempts 0
)

if gcloud scheduler jobs describe "${JOB}-weekly" --location "$REGION" --project "$PROJECT" >/dev/null 2>&1; then
  gcloud scheduler jobs update http "${JOB}-weekly" "${SCHEDULE_ARGS[@]}"
else
  gcloud scheduler jobs create http "${JOB}-weekly" "${SCHEDULE_ARGS[@]}"
fi

# Test run (waits until the job finishes, then shows the result):
#   gcloud run jobs execute "$JOB" --region "$REGION" --project "$PROJECT" --wait