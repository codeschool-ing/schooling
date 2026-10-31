---
title: A metric alert policy, condition by condition
version: 1
---

**An alert policy is a condition that Cloud Monitoring evaluates every minute, and a list of channels it
notifies when the condition becomes true.** Lessons 10 and 13 wrote policies with no channel; this one adds
them, and adds the decisions a metric condition needs that a log condition did not: how long the value must
stay over the threshold, and what to do when there is no data at all. Nothing here ran against Google: it is
Terraform's plan, computed locally.

Write `~/gcp/tf/alerting/main.tf`:

```hcl
# tf/alerting/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_monitoring_notification_channel" "oncall" {
  display_name = "shop on-call"
  type         = "email"
  labels = {
    email_address = "oncall@shop.example.com"
  }
}

resource "google_monitoring_notification_channel" "tickets" {
  display_name = "shop tickets"
  type         = "pubsub"
  labels = {
    topic = "projects/planner-dev/topics/shop-tickets"
  }
}

resource "google_monitoring_alert_policy" "payment_retries" {
  display_name          = "payment retries high"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.tickets.id]
  severity              = "WARNING"

  conditions {
    display_name = "more than 5 retries a minute, for 10 minutes"
    condition_threshold {
      filter                  = "metric.type=\"logging.googleapis.com/user/shop/payment_retries\" resource.type=\"cloud_run_revision\""
      comparison              = "COMPARISON_GT"
      threshold_value         = 5
      duration                = "600s"
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  alert_strategy {
    auto_close = "3600s"
  }

  documentation {
    content   = "Checkout is retrying payments. Look at the payment service's latency first: lesson 10's labels say whether one provider or both."
    mime_type = "text/markdown"
  }
}
```

```
ana@laptop:~/gcp/tf/alerting$ terraform plan -input=false -no-color | grep -E "^  # |duration|evaluation_missing_data|severity|type  |Plan:"
  # google_monitoring_alert_policy.payment_retries will be created
      + severity              = "WARNING"
              + duration                = "600s"
              + evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
  # google_monitoring_notification_channel.oncall will be created
      + type                = "email"
  # google_monitoring_notification_channel.tickets will be created
      + type                = "pubsub"
Plan: 3 to add, 0 to change, 0 to destroy.
```

## The condition, line by line

- **The filter** names the log-based counter of lesson 10. Its metric type is
  `logging.googleapis.com/user/` followed by the metric's name: user-defined log metrics live there.
- **The aggregation** sums each minute's count (`ALIGN_SUM`) and adds up the series of every revision
  (`REDUCE_SUM`), so the threshold is compared with the service's total, not with one revision's share.
- **`threshold_value = 5` and `duration = "600s"`**: more than five retries a minute, **for ten minutes**. The
  duration is what separates an incident from a blip. The background of lesson 10 sometimes reaches three in
  a minute; the bad patch stayed between 11 and 18 for six minutes. A condition with no duration would have
  fired at the first busy minute of a normal day.
- **`evaluation_missing_data`** answers lesson 10's question about the minutes with no point. A counter of
  failures has no data exactly when everything is fine, so missing data must count as **inactive**. The other
  choices, active or "keep the last state", would either page on every quiet night or leave an incident open
  after it ended.

## Severity and auto-close

`severity` is a label on the incident, `CRITICAL`, `ERROR` or `WARNING`, which the notification carries and
a channel can route by. `auto_close` closes an incident that has stayed below the threshold for an hour,
which keeps the list of open incidents true without somebody tidying it.

## Two channels for two kinds of attention

| channel | what it is for | the shop's policies |
|---|---|---|
| `shop on-call`, e-mail and phone | somebody must act now, at any hour | uptime failing, fast budget burn |
| `shop tickets`, a Pub/Sub topic | somebody must act this week, in working hours | payment retries, slow budget burn |

The payment-retry policy goes to tickets, not to the person on call: retries cost the shop little and the
payment service usually recovers on its own. The rule the table encodes is the next section's: **a page is a
promise that somebody has to do something now.** Everything that is not that belongs in a queue that is read
in the morning.

Other channel types exist (SMS, Slack, PagerDuty, webhooks, the Cloud mobile app). The type matters less than
the split above, and an e-mail channel is the one that can be declared here without inventing an address on a
service the course cannot show.
