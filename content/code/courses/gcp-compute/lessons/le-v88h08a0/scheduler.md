---
title: Cloud Scheduler, cron in the platform
version: 1
---

Every system ends up with work that must happen on a clock: the nightly sales report, the hourly
clean-up of abandoned carts. On a single server that is a line of cron. **Cloud Scheduler is the
same line of cron, run by Google, calling an HTTP endpoint, a Pub/Sub topic or an App Engine
handler when it fires.** No machine waits all day to run one thing at three in the morning.

## The job, written down

The shop's nightly report runs at ten past three, São Paulo time. **Create `~/gcp/scheduler` and
save this as `main.tf`:**

```hcl
# scheduler/main.tf
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

resource "google_cloud_scheduler_job" "nightly" {
  name      = "nightly-report"
  region    = "southamerica-east1"
  schedule  = "10 3 * * *"
  time_zone = "America/Sao_Paulo"

  http_target {
    uri         = "https://orders.example.com/reports/nightly"
    http_method = "POST"
    oidc_token {
      service_account_email = "scheduler@planner-dev.iam.gserviceaccount.com"
    }
  }

  retry_config {
    retry_count = 2
  }
}
```

Then `terraform init` and the plan:

```
ana@laptop:~/gcp/scheduler$ terraform plan -no-color | grep -E '^  #|schedule |time_zone|uri|http_method|retry_count|^Plan'
  # google_cloud_scheduler_job.nightly will be created
      + schedule        = "10 3 * * *"
      + time_zone       = "America/Sao_Paulo"
          + http_method = "POST"
          + uri         = "https://orders.example.com/reports/nightly"
          + retry_count          = 2
Plan: 1 to add, 0 to change, 0 to destroy.
```

**`schedule` is ordinary cron**, five fields: minute, hour, day of the month, month, day of the
week, so `10 3 * * *` is 03:10 every day. **`time_zone` is the line people leave out**, and Cloud
Scheduler then reads the schedule in UTC, which is 00:10 in São Paulo. With the zone named, Scheduler
follows that zone's rules, including any daylight saving the zone has; Brazil has observed none
since 2019, so here the report runs at 03:10 all year. The URL is a placeholder for the orders
service's address, and the OIDC token proves to the service that the call came from Scheduler.

## What it costs, and the free jobs

```
ana@laptop:~/gcp$ python3 prices.py other | grep Scheduler
  Cloud Scheduler, after 3 free jobs                     0.1  per job per 31 days
```

The unit is the job, not the run: **ten cents per job per 31 days, however often it fires**, with
three jobs free per billing account. A job that runs every minute costs the same as one that runs
once a month. That makes Scheduler nearly free for the shop and makes the cost of the work it
triggers the number to watch.

## Scheduler and Tasks together

The two products meet at the nightly report. Scheduler fires once, at 03:10, and calls a handler
that creates one task per store for the report's heavy part; the queue then works through them at
its own rate, retrying each on its own. **Scheduler decides when; the queue decides how fast and
how persistently.** Neither does the other's job well: a schedule has no rate limit, and a queue has
no clock.

None of this was run here, beyond the plan. The handler for the report would be written exactly as
the mailer of section 03, with the same two obligations.
