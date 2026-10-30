---
title: Uptime checks and a dashboard, declared in Terraform
version: 1
---

**An uptime check asks the shop's API from outside, from several places in the world, every few minutes,
and records whether it answered.** It is the one measurement that does not depend on the shop's own code
reporting anything: a process that has crashed exports no metrics, and an uptime check still notices. Like
the rest of Cloud Monitoring, it does not run on your computer. What runs is Terraform's plan of it, which
proves the configuration is well formed and nothing more.

Create `~/gcp/tf/monitoring` with two files. The first is the configuration:

```hcl
# tf/monitoring/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_monitoring_uptime_check_config" "api" {
  display_name     = "shop-api /healthz"
  timeout          = "10s"
  period           = "300s"
  selected_regions = ["SOUTH_AMERICA", "USA", "EUROPE"]

  http_check {
    path         = "/healthz"
    port         = 443
    use_ssl      = true
    validate_ssl = true
    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "planner-dev"
      host       = "shop.example.com"
    }
  }
}

resource "google_monitoring_dashboard" "api" {
  dashboard_json = file("${path.module}/dashboard.json")
}
```

The second is the dashboard, in the JSON Cloud Monitoring's API takes, `dashboard.json`:

```json
{
  "displayName": "shop-api",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "Requests per second, by class",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"shop-api\"",
                "aggregation": {
                  "alignmentPeriod": "60s",
                  "perSeriesAligner": "ALIGN_RATE",
                  "crossSeriesReducer": "REDUCE_SUM",
                  "groupByFields": ["metric.label.response_code_class"]
                }
              }
            }
          }]
        }
      },
      {
        "title": "Latency p50 and p99",
        "xyChart": {
          "dataSets": [
            {"timeSeriesQuery": {"timeSeriesFilter": {
              "filter": "metric.type=\"run.googleapis.com/request_latencies\" resource.label.service_name=\"shop-api\"",
              "aggregation": {"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_PERCENTILE_50", "crossSeriesReducer": "REDUCE_MEAN"}}}},
            {"timeSeriesQuery": {"timeSeriesFilter": {
              "filter": "metric.type=\"run.googleapis.com/request_latencies\" resource.label.service_name=\"shop-api\"",
              "aggregation": {"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_PERCENTILE_99", "crossSeriesReducer": "REDUCE_MEAN"}}}}
          ]
        }
      }
    ]
  }
}
```

```
ana@laptop:~/gcp/tf/monitoring$ terraform validate -no-color
Success! The configuration is valid.
ana@laptop:~/gcp/tf/monitoring$ terraform plan -input=false -no-color | grep -E "^  # |period|timeout|path|selected_regions|Plan:"
  # google_monitoring_dashboard.api will be created
  # google_monitoring_uptime_check_config.api will be created
      + period           = "300s"
      + selected_regions = [
      + timeout          = "10s"
          + path           = "/healthz"
Plan: 2 to add, 0 to change, 0 to destroy.
```

The dashboard's first chart is the last section's arithmetic written down: align each revision's counter
to a rate over sixty seconds, then sum across revisions grouped by status class. The second reads p50 and
p99 from the latency distribution. `REDUCE_MEAN` across revisions is a compromise the section above warned
about, accepted here because the shop's revisions serve similar traffic. A service whose instances differ
widely would chart one line per revision instead.

## The uptime check, read

- **`period = "300s"`** asks every five minutes from each region. A shorter period notices an outage
  sooner and costs more; five minutes is the shop's choice because its alert waits for two failures in a
  row anyway (lesson 14).
- **Three regions**, because a failure seen from one place is often that place's network, and an alert
  that needs two of three regions to fail is one that rarely fires for somebody else's problem.
- **`/healthz` answers 200 without touching the database.** That checks that the process is up and
  reachable, which is what an uptime check is for. A health check that also queries the database turns a
  slow database into "the site is down" from every region at once.

## What it costs

From the pricing page, read on 30 October 2026: an uptime check is charged per execution, **0.30 USD per
1,000** after the first million executions per project per month, and each region counts as one execution.
The shop's check runs 3 regions × 12 times an hour × 730 hours = 26,280 times a month, well inside the
million. Google's own Cloud Run metrics cost nothing to receive; metrics a program writes are charged by the
mebibyte, at 0.2580 USD per MiB after the first 150 MiB per billing account.
