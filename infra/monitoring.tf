/* Whether it is up, and who finds out.

   IT IS OFF UNTIL THERE IS AN ADDRESS. `alert_email` empty creates none of
   this, and that is the honest default while the DNS record does not exist: a
   check against a name nobody has published fails on its first run and every
   run after, and the only thing it teaches anybody is to ignore the alert. An
   alarm that is always ringing is worse than no alarm — it is an alarm plus the
   habit of not looking.

   Set the address, apply again, and it starts watching. */

locals {
  monitoring = var.alert_email == "" ? 0 : 1
}

resource "google_monitoring_notification_channel" "email" {
  count = local.monitoring

  display_name = "The person who is on call, which is one person"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }

  depends_on = [google_project_service.enabled]
}

/* `/readyz` AND NOT `/`. The root is the interface: it is served from the
   binary's own filesystem and answers 200 while the database is unreachable,
   which is precisely the outage worth being woken for. `/readyz` is the
   handler that says whether this process can actually do its job. */
resource "google_monitoring_uptime_check_config" "readyz" {
  count = local.monitoring

  display_name = "schooling is ready"
  timeout      = "10s"
  period       = "300s"

  http_check {
    path         = "/readyz"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project
      host       = var.platform_domain
    }
  }
}

/* TWO FAILURES BEFORE IT SAYS ANYTHING. One failed check is a network blip
   somewhere between a probe and a region; alerting on it produces a page a
   month that resolves itself before anybody reads it, which is how a real one
   ends up unread. */
resource "google_monitoring_alert_policy" "down" {
  count = local.monitoring

  display_name = "schooling is not answering"
  combiner     = "OR"

  conditions {
    display_name = "the readiness check has failed twice"

    condition_threshold {
      filter = join(" AND ", [
        "metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\"",
        "resource.type = \"uptime_url\"",
        "metric.label.check_id = \"${google_monitoring_uptime_check_config.readyz[0].uptime_check_id}\"",
      ])

      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "600s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.host"]
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email[0].id]

  documentation {
    content   = "`/readyz` has failed for ten minutes. It answers 200 only when the process can reach its database, so this is either the service or the database, and the logs of the Cloud Run revision say which."
    mime_type = "text/markdown"
  }
}
