---
title: Alerts on a single line
version: 1
---

**Some lines matter the first time they appear, and counting them per minute is the wrong tool.** Lesson 4
ended with break-glass: a deployment admitted without a signature, recorded in the audit log, and reviewed
"in the morning". The review only happens if somebody is told. A **log-based alert** is a policy whose
condition is a log filter: one matching entry opens an incident and sends a notification, with no metric in
between. None of it can run here; it is part of the same Terraform plan.

Add this to `~/gcp/tf/logmetrics/alerts.tf`:

```hcl
# tf/logmetrics/alerts.tf
resource "google_monitoring_alert_policy" "break_glass" {
  display_name = "Binary Authorization break-glass used"
  combiner     = "OR"

  conditions {
    display_name = "a break-glass deployment was admitted"
    condition_matched_log {
      filter = "resource.type=\"k8s_cluster\" AND protoPayload.request.metadata.annotations.\"alpha.image-policy.k8s.io/break-glass\"=\"true\""
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
    auto_close = "1800s"
  }

  documentation {
    content   = "Somebody deployed an unsigned image with break-glass. Find who in the audit log, and why, before the end of the day."
    mime_type = "text/markdown"
  }
}
```

```
ana@laptop:~/gcp/tf/logmetrics$ terraform plan -input=false -no-color | grep -E "^  # |metric_kind|value_type|period|Plan:"
  # google_logging_metric.order_value will be created
          + metric_kind = "DELTA"
          + value_type  = "DISTRIBUTION"
  # google_logging_metric.payment_retries will be created
          + metric_kind = "DELTA"
          + value_type  = "INT64"
              + value_type  = "STRING"
  # google_monitoring_alert_policy.break_glass will be created
              + period = "300s"
Plan: 3 to add, 0 to change, 0 to destroy.
```

Three resources: the two metrics of the last section and this policy. Reading the policy:

- **`condition_matched_log`** is the whole condition: a filter on the GKE audit log for a request carrying the
  break-glass annotation, as Google's documentation writes it. There is no threshold and no window; one entry
  is enough.
- **`notification_rate_limit`** sends at most one notification every five minutes for this policy. A
  log-based alert fires once per matching entry, and an operator retrying a break-glass deployment ten times
  would otherwise send ten messages. A log-based alert must carry this block; Cloud Monitoring refuses one
  without it.
- **`auto_close`** closes the incident after half an hour with no new match, since a single line cannot
  "recover" the way a metric does.
- **`documentation`** is the text that arrives with the notification. It says what happened and what to do
  next, in a sentence, because whoever reads it may be reading it on a phone at night.

The policy names no notification channel, so as written it would open incidents that nobody hears about.
Lesson 14 adds the channels, and is about which alerts deserve to wake somebody.

## Counter or log alert

| the question | the tool |
|---|---|
| is this happening more than usual? | a counter, and an alert on its rate (lesson 14) |
| has this happened at all? | a log-based alert |
| how are these values spread? | a distribution |

A log-based alert on "payment retried" would notify somebody for each of the background retries of the
first section: twenty-one of them in the twenty-four quiet minutes of that log, and none of them a problem. That question is the first row's, and the counter answers it.
