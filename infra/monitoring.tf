/* Whether it is up, and who finds out.

   IT IS OFF UNTIL THERE IS SOMEWHERE TO WATCH AND SOMEBODY TO TELL. Either
   variable empty creates none of this, which is the honest default while the
   DNS does not exist: a check against a name nobody has published fails on its
   first run and every run after, and the only thing it teaches anybody is to
   ignore the alert. An alarm that is always ringing is worse than no alarm — it
   is an alarm plus the habit of not looking.

   THE HOST IS A SCHOOL'S AND NOT THE PLATFORM'S, and that distinction was
   bought by deploying: an unmapped host never reaches the container, because
   Google's front end routes by name and answers its own 404 first. A check
   against one measures an error page nobody here wrote. See `uptime_host`.

   Set both, apply again, and it starts watching. */

locals {
  monitoring = (var.alert_email == "" || var.uptime_host == "") ? 0 : 1
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
      host       = var.uptime_host
    }
  }
}

/* TWO FAILURES BEFORE IT SAYS ANYTHING. One failed check is a network blip
   somewhere between a probe and a region; alerting on it produces a page a
   month that resolves itself before anybody reads it, which is how a real one
   ends up unread.

   # READ THE COMPARISON AGAINST THE REDUCER, NOT AGAINST THE NAME

   `check_passed` is a boolean per probe, and `REDUCE_COUNT_FALSE` turns a
   period's worth of them into ONE NUMBER: how many probes FAILED. Every reading
   of the threshold has to start there, because the metric is called
   `check_passed` and the number is a count of failures — so the intuition the
   name gives you is exactly backwards.

   Failures GREATER THAN one is the alert. `COMPARISON_LT` was written here
   instead, and it says failures fewer than one — which is what a perfectly
   healthy service produces, every five minutes, forever.

   THAT IS NOT A THEORY. It fired fourteen minutes after it was created, on a
   deployment answering 200, with the start time reading "less than 1 sec ago".
   An alert that rings because nothing is wrong is worse than no alert: it is
   the same silence, arrived at through a rule that everybody learns to delete.

   The nearest thing to a test is arithmetic done out loud:

     all probes pass  → count_false = 0 → 0 > 1 is false → quiet
     one probe fails  → count_false = 1 → 1 > 1 is false → quiet, on purpose
     two probes fail  → count_false = 2 → 2 > 1 is TRUE  → and it has to hold
                                                           for `duration` */
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

      // More than one FAILED probe. See the arithmetic above.
      comparison      = "COMPARISON_GT"
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

  /* `enabled` BELONGS TO THE CLOCK BELOW, NOT TO THIS FILE. The two jobs at
     the foot of it set it false at 22:00 and true at 08:00 on the nights the
     database sleeps. Without this, a plan read at night would propose
     `enabled = false -> true`, and an apply at that hour would re-arm the
     alert inside the window it is switched off for, which is the false alarm
     all of this exists to prevent.

     The cost is that Terraform no longer puts it back if somebody switches
     it off by hand. The morning job does, at the next 08:00 that follows a
     sleeping night. */
  lifecycle {
    ignore_changes = [enabled]
  }
}

/* THE ALERT SLEEPS WHEN THE DATABASE DOES.

   The shared instance the database is moving to stops at 22:00 and starts at
   07:30, Monday to Thursday. While it is stopped, `/readyz` fails every probe,
   because it answers 200 only when the process can reach its database. The
   policy above would fire every one of those nights, and this file's own
   argument, at its top, is that an alarm that always rings is worse than none.

   So two jobs switch the policy off and on. Each is a single PATCH that sets
   the policy's `enabled` field and nothing else. It is the mechanism
   aleogr/lab uses to stop and start the instance itself
   (`gcp/terraform/sleep.tf`): Cloud Scheduler calls the API directly, with no
   function, no queue and no source to maintain.

   # OFF AT 22:00, ON AT 08:00, AND NOT AT 07:30

   Off in the same minute the instance is stopped. The policy needs ten
   minutes of failed probes before it fires, so switching it off at 22:00 is
   in time.

   On half an hour after the instance is started, not at the start itself.
   When it was timed, the instance took 686 seconds after being started at
   07:30 to answer. Probes are expected to fail until about 07:42, so an alert
   re-armed at 07:30 would fire on exactly those. At 08:00 the probes have
   passed for about fifteen minutes, and the ten-minute condition has nothing
   to count.

   `1-4` TO SLEEP AND `2-5` TO WAKE: the night of Monday into Tuesday, through
   the night of Thursday into Friday. Friday night and the weekend are awake,
   and so is the alert. The zone is São Paulo's, because the instance's window
   is written in it.

   # UNTIL THE DATABASE MOVES, THIS SILENCES A CHECK THAT STILL MEANS SOMETHING

   The instance this project has today never sleeps. For the weeks until the
   move, an outage that starts between 22:00 and 08:00 on those four nights is
   not reported until 08:00. If it is still going on then, the policy fires
   ten minutes later. If it healed overnight, nobody hears about it.

   THAT IS ACCEPTED RATHER THAN GATED BEHIND A VARIABLE, and the reason is the
   move itself. Gated, these jobs would run for the first time on the night
   the database moves, which is the night everything else is new too. Running
   now, they get weeks of real nights to show they work, on a lab with no
   students, where the cost is a night's outage reported late. A variable
   would also be one more thing the move had to remember to flip.

   # WHAT A FAILURE HERE LOOKS LIKE

   The two jobs do not fail the same way.

   A sleep job that fails leaves the alert armed, and the night's failed probes
   fire it. That is loud, and it retries once.

   A wake job that fails leaves the alert off for the day, and nothing says
   so. That is the silent one, so it retries three times, like aleogr/lab's
   start job. What bounds it: a lasting cause, such as a missing permission,
   fails the sleep job the same way the night before, so the policy is never
   switched off in the first place. Only a transient error that outlasts
   three retries leaves the alert off, and only until the next wake. From
   Tuesday to Thursday that is the next morning. After a failed FRIDAY wake
   it is the following Tuesday, because the weekend has no wake: four days
   with the alert off. A log-based alert on this job's failures would make
   even that say so. It is not here yet.

   # THE IDENTITY, AND WHY NOBODY IS GRANTED `serviceAccountUser` ON IT

   Both jobs authenticate as an account of their own, and it holds one custom
   role: `monitoring.alertPolicies.update`, which is what the PATCH checks, and
   `monitoring.alertPolicies.get`, because the response is the policy it
   wrote. It reads no metric, no log and no notification channel.

   THE ROLE READS SMALLER THAN IT IS. An alert policy has no IAM policy of its
   own, so the grant is on the project, and the account could switch off ANY
   alert policy in this project, not only this one. Today there is only
   this one. The jobs send a constant body to one policy's URL, so what the
   account can be made to do is what they already do.

   Creating a job that carries an `oauth_token` for an account means acting
   as that account, which is `iam.serviceAccounts.actAs`. aleogr/lab lost an
   afternoon to exactly that: its apply runs as a CI service account that
   administers accounts without being allowed to act as them, and it needed
   an explicit `serviceAccountUser` binding. Here the apply runs as the
   person who created the project, from a terminal. That role, Owner,
   includes `actAs` on every account in it. `scheduler.tf`'s two jobs are
   the proof: they act as `schooling-scheduler` and were created without any
   such binding. So none is declared. Declaring one would put a person's
   address in a public repository, and `terraform.tfvars.example` explains
   why this project keeps addresses out of it. IF THE APPLY EVER MOVES TO A
   SERVICE ACCOUNT, that account needs `roles/iam.serviceAccountUser` on
   `schooling-alert-toggle`, the way `deploy_acts_as_the_service` in
   `iam.tf` grants it for the runtime account.

   Cloud Scheduler's own service agent mints the token. It already does that
   for `scheduler.tf`'s jobs, so nothing new is needed for it.

   EVERYTHING HERE FOLLOWS `local.monitoring`. With no policy there is nothing
   to switch, and an account with nothing to do is only a permission waiting
   for a use. */
resource "google_project_iam_custom_role" "alert_toggle" {
  count = local.monitoring

  role_id     = "schoolingAlertToggle"
  title       = "Switch an alert policy on and off"
  description = "Updates an alert policy, which is how its enabled field is set. Held by the account the two alert-sleep jobs use. Project-wide, because alert policies have no IAM of their own."

  permissions = [
    "monitoring.alertPolicies.get",
    "monitoring.alertPolicies.update",
  ]
}

resource "google_service_account" "alert_toggle" {
  count = local.monitoring

  account_id   = "schooling-alert-toggle"
  display_name = "The clock that silences the uptime alert"
  description  = "Held by two Cloud Scheduler jobs and nothing else. Switches the uptime alert off at night and on in the morning; reads nothing."
}

resource "google_project_iam_member" "alert_toggle" {
  count = local.monitoring

  project = var.project
  role    = google_project_iam_custom_role.alert_toggle[0].name
  member  = "serviceAccount:${google_service_account.alert_toggle[0].email}"
}

resource "google_cloud_scheduler_job" "alert_sleep" {
  count = local.monitoring

  name        = "schooling-alert-sleep"
  region      = var.region
  description = "Switches the uptime alert off while the shared database sleeps."

  schedule  = "0 22 * * 1-4"
  time_zone = "America/Sao_Paulo"

  // Failing is loud: the alert stays armed and fires on the night's probes.
  retry_config {
    retry_count = 1
  }

  attempt_deadline = "30s"

  http_target {
    http_method = "PATCH"
    uri         = "https://monitoring.googleapis.com/v3/${google_monitoring_alert_policy.down[0].name}?updateMask=enabled"
    headers     = { "Content-Type" = "application/json" }
    body        = base64encode(jsonencode({ enabled = false }))

    oauth_token {
      service_account_email = google_service_account.alert_toggle[0].email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  // The permission before the job that needs it. Nothing in this resource
  // refers to the binding, so the graph would not order them on its own.
  depends_on = [
    google_project_service.enabled,
    google_project_iam_member.alert_toggle,
  ]
}

resource "google_cloud_scheduler_job" "alert_wake" {
  count = local.monitoring

  name        = "schooling-alert-wake"
  region      = var.region
  description = "Switches the uptime alert back on once the shared database answers again."

  schedule  = "0 8 * * 2-5"
  time_zone = "America/Sao_Paulo"

  // Failing is SILENT: the alert stays off for the day. See above.
  retry_config {
    retry_count = 3
  }

  attempt_deadline = "30s"

  http_target {
    http_method = "PATCH"
    uri         = "https://monitoring.googleapis.com/v3/${google_monitoring_alert_policy.down[0].name}?updateMask=enabled"
    headers     = { "Content-Type" = "application/json" }
    body        = base64encode(jsonencode({ enabled = true }))

    oauth_token {
      service_account_email = google_service_account.alert_toggle[0].email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [
    google_project_service.enabled,
    google_project_iam_member.alert_toggle,
  ]
}
