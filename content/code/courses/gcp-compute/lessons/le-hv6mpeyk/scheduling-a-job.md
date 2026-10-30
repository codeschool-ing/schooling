---
title: Running a job on a schedule
version: 1
---

A job has no schedule of its own. **Something else starts each execution, and for "every night at
two" that something is Cloud Scheduler**, Google's managed cron, calling the Cloud Run API on the
job's behalf. Lesson 20 covers Cloud Scheduler in full; this section is the one connection a job
needs.

## What the schedule calls

Starting an execution is an ordinary API call: a `POST` to the job's `:run` method in the Cloud Run
Admin API. Cloud Scheduler can make an HTTP call on a cron expression, and attach an OAuth token for
a service account it is allowed to act as, so the call is authorised like any other. Save this as
`scheduletf/main.tf` in `~/gcp`:

```hcl
# scheduletf/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_service_account" "scheduler" {
  account_id   = "invoices-scheduler"
  display_name = "Starts the nightly invoice job"
}

resource "google_cloud_scheduler_job" "nightly_invoices" {
  name      = "nightly-invoices"
  region    = "southamerica-east1"
  schedule  = "0 2 * * *"
  time_zone = "America/Sao_Paulo"

  http_target {
    http_method = "POST"
    uri         = "https://run.googleapis.com/v2/projects/planner-dev/locations/southamerica-east1/jobs/invoices:run"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }
  }
}
```

In `~/gcp/scheduletf`, `terraform init` and the plan:

```
ana@laptop:~/gcp/scheduletf$ terraform plan -no-color | grep -E '^  #|schedule|time_zone|uri|http_method|service_account_email|^Plan'
  # google_cloud_scheduler_job.nightly_invoices will be created
  + resource "google_cloud_scheduler_job" "nightly_invoices" {
      + schedule        = "0 2 * * *"
      + time_zone       = "America/Sao_Paulo"
          + http_method = "POST"
          + uri         = "https://run.googleapis.com/v2/projects/planner-dev/locations/southamerica-east1/jobs/invoices:run"
              + service_account_email = "invoices-scheduler@planner-dev.iam.gserviceaccount.com"
  # google_service_account.scheduler will be created
  + resource "google_service_account" "scheduler" {
      + account_id      = "invoices-scheduler"
      + email           = "invoices-scheduler@planner-dev.iam.gserviceaccount.com"
      + member          = "serviceAccount:invoices-scheduler@planner-dev.iam.gserviceaccount.com"
Plan: 2 to add, 0 to change, 0 to destroy.
```

Three lines carry the decisions. **`schedule` is standard cron, five fields**, here minute 0 of
hour 2 every day. **`time_zone` says whose two o'clock**: without it Cloud Scheduler uses UTC, and
the job would run at eleven at night in São Paulo, before the day it is invoicing has ended. And
**the token is the scheduler account's**, which needs one role for this to work: permission to run
the job, `roles/run.invoker` on it, granted in the same file in a real setup and left out here to
keep the plan short.

## What can go wrong at night

A schedule hides failures by running while nobody watches. Three habits keep the invoice job
honest, each from Google's documentation and none run here:

- **an alert on a failed execution**, from Cloud Monitoring's metrics for jobs, so a failure is a
  message in the morning rather than a customer's question at noon; `gcp-operations` sets one up;
- **a schedule that cannot overlap itself**: if an execution may take longer than the gap between
  runs, two executions can work on the same orders at once, and only idempotent writes of the last
  section make that harmless;
- **a way to run it by hand**, `gcloud run jobs execute invoices`, for the morning the schedule
  failed and the invoices are still owed. A job that can only be started by its schedule is a job
  that cannot be recovered without waiting a day.
