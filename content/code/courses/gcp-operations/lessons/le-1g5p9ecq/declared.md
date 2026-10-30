---
title: The SLO, declared in Cloud Monitoring
version: 1
---

**Cloud Monitoring has SLOs as objects: a service, an SLI defined by two filters, a goal and a window.** It
computes the last section's numbers continuously from the real metrics, draws the budget as a line going
down, and offers the burn rate as a time series an alert can watch. None of that can run here; what runs is
Terraform's plan of the objects, which is the whole definition, written down.

Write `~/gcp/tf/slo/main.tf`:

```hcl
# tf/slo/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_monitoring_custom_service" "api" {
  service_id   = "shop-api"
  display_name = "shop-api"
}

resource "google_monitoring_slo" "availability" {
  service             = google_monitoring_custom_service.api.service_id
  slo_id              = "availability-28d"
  display_name        = "99.5% of requests succeed, 28 days"
  goal                = 0.995
  rolling_period_days = 28

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"run.googleapis.com/request_count\"",
        "resource.type=\"cloud_run_revision\"",
        "resource.label.\"service_name\"=\"shop-api\"",
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"run.googleapis.com/request_count\"",
        "resource.type=\"cloud_run_revision\"",
        "resource.label.\"service_name\"=\"shop-api\"",
        "metric.label.\"response_code_class\"!=\"5xx\"",
      ])
    }
  }
}

resource "google_monitoring_alert_policy" "fast_burn" {
  display_name = "shop-api is burning its error budget fast"
  combiner     = "AND"

  conditions {
    display_name = "burn rate above 14.4 over 1 hour"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.availability.id}\", \"3600s\")"
      comparison      = "COMPARISON_GT"
      threshold_value = 14.4
      duration        = "0s"
    }
  }

  conditions {
    display_name = "burn rate above 14.4 over 5 minutes"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.availability.id}\", \"300s\")"
      comparison      = "COMPARISON_GT"
      threshold_value = 14.4
      duration        = "0s"
    }
  }
}
```

```
ana@laptop:~/gcp/tf/slo$ terraform plan -input=false -no-color | grep -E "^  # |goal|rolling_period_days|threshold_value|duration|Plan:"
  # google_monitoring_alert_policy.fast_burn will be created
              + duration        = "0s"
              + threshold_value = 14.4
              + duration        = "0s"
              + threshold_value = 14.4
  # google_monitoring_custom_service.api will be created
  # google_monitoring_slo.availability will be created
      + goal                = 0.995
      + rolling_period_days = 28
Plan: 3 to add, 0 to change, 0 to destroy.
```

Three objects:

- **A custom service**, `shop-api`, which the SLO belongs to. Cloud Monitoring also detects Cloud Run services
  on its own and offers them as services; declaring one keeps the SLO in Terraform rather than in somebody's
  clicks.
- **The SLO**: good requests over all requests, both counted from `run.googleapis.com/request_count`, with
  good meaning "not `5xx`", as the first section decided. `goal = 0.995` and 28 rolling days.
- **The alert**, on the burn rate, which is the next part.

## Alerting on the burn rate, in two windows

**An alert on the SLI itself fires too late or too often.** "Availability below 99.5% over five minutes" pages
somebody for a two-minute blip that cost a sliver of the budget. "Below 99.5% over 28 days" fires after the
objective is already missed. The burn rate asks the useful question: at the current pace, how soon is the budget
gone?

A burn rate of **14.4** sustained for one hour spends 14.4 hours' worth of budget in that hour. Over a 28-day
window of 672 hours, that is 14.4 / 672 = 2.1% of the whole budget gone in sixty minutes; kept up, the budget
lasts under two days. That is worth waking somebody for, and the threshold comes from Google's SRE practice,
where it is the "fast burn" page.

The policy has **two conditions joined by `AND`**: the burn rate over the last hour, and over the last five
minutes, both above 14.4. The hour makes sure enough budget is really being spent; the five minutes make sure
it is still happening, so that an incident that ended twenty minutes ago does not page anybody for the next
forty while the hour's average comes down. A second policy, not written here, watches a slower burn (6 over
six hours) and opens a ticket rather than a page.

`duration = "0s"` means each condition is true as soon as one evaluation crosses the threshold; the windows
inside `select_slo_burn_rate` already do the smoothing. As written, the policy names no channel, which lesson 14
adds.
