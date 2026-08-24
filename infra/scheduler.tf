/* What makes the nightly job nightly.

   # THE CLAIM WAS IN THE CODE AND THE MACHINERY WAS NOWHERE

   `cmd/analyse` opens by saying it runs on a schedule. Until this file existed
   that sentence was false in the only place it mattered: there was no job, no
   scheduler, and no execution. The command had never run in production, the
   rollup had never been written, and the console's item analysis had exactly
   one state — the one it draws when nothing has been computed.

   That screen was built to say so rather than to show an empty table, which is
   the reason this was findable at all. A screen that had drawn zeroes would
   have looked like a platform whose questions are all fine.

   # A THIRD IDENTITY, AND IT MAY DO ONE THING

   `iam.tf` has two service accounts and argues for the separation: what runs
   the application cannot deploy, and what deploys cannot read the secret. This
   is the third and it is the narrowest of them — it may start one job, and it
   may not read the database, the secret, or anything else. A scheduler that
   held the runtime account would be a cron entry with the application's whole
   reach behind it.

   # WHY THE URL LOOKS LIKE THAT

   Cloud Scheduler starts a Cloud Run job by calling the Admin API, and the
   shape below — `apis/run.googleapis.com/v1/namespaces/.../jobs/NAME:run` on
   the REGIONAL host — is the one Google documents for it. It reads like a
   legacy path beside the v2 resources this configuration otherwise uses, and it
   is: the v2 surface exists, and the v1 namespaces form is what the scheduler
   integration is tested against. A URL assembled from the resource's own
   attributes rather than typed out, so a rename cannot leave a schedule
   pointing at a job that is no longer there.
*/

resource "google_service_account" "scheduler" {
  account_id   = "schooling-scheduler"
  display_name = "The clock, starting jobs"
  description  = "Starts one Cloud Run job on a schedule. Reads nothing."
}

// ON THE JOB AND NOT ON THE PROJECT, which is the same rule the secret follows
// in `iam.tf`: `roles/run.invoker` at project level is every service and every
// job this project will ever have, granted in advance to a cron entry.
resource "google_cloud_run_v2_job_iam_member" "scheduler_starts_the_analysis" {
  project  = google_cloud_run_v2_job.analyse.project
  location = google_cloud_run_v2_job.analyse.location
  name     = google_cloud_run_v2_job.analyse.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}

/* 03:10, IN SÃO PAULO, EVERY NIGHT.

   THE HOUR IS THE QUIET ONE AND THE MINUTE IS NOT ROUND. Ten past rather than
   on the hour because every other scheduled thing in the world runs at :00, and
   a job that shares its minute with a hosting provider's maintenance window is
   a job that fails on the nights the platform is busiest with somebody else's
   work.

   THE ZONE IS THE STUDENTS' AND NOT UTC. It is when the platform is empty that
   matters, and the platform's population is Brazilian — an analysis at 03:10
   UTC would run at midnight in São Paulo, which is neither quiet nor the end of
   a day. It also means the rollup an operator opens in the morning is about the
   day that just ended, rather than about a day that ended three hours into it.

   IT IS NOT A VARIABLE. A second knob for "which hour" is one nobody turns
   twice, and this configuration already carries the argument for why a value
   with a right answer lives in code (K-13). What would make it a variable is a
   second deployment in another country, and that day it becomes one. */
resource "google_cloud_scheduler_job" "analyse" {
  name        = "schooling-analyse-nightly"
  region      = var.region
  description = "Item analysis: recompute the rollup and withdraw what is broken."

  schedule  = "10 3 * * *"
  time_zone = "America/Sao_Paulo"

  /* ONE ATTEMPT, AND THEN TOMORROW. The command is idempotent, so a retry
     would be safe — and a retry an hour later writes a second set of numbers
     for the same night, which is a report that quietly disagrees with itself
     about when it was made. A night that failed is a night that failed, and the
     console shows when the rollup was last written precisely so that a missing
     one is visible rather than inferred. */
  retry_config {
    retry_count = 0
  }

  /* THE DEADLINE IS THE HANDSHAKE'S AND NOT THE JOB'S. This call only STARTS
     an execution and returns; how long the analysis then takes is the job's own
     timeout. Thirty seconds is generous for an API call and short enough that a
     scheduler hanging on an unreachable endpoint is reported tonight rather
     than tomorrow. */
  attempt_deadline = "30s"

  http_target {
    http_method = "POST"
    uri = join("", [
      "https://", var.region, "-run.googleapis.com",
      "/apis/run.googleapis.com/v1/namespaces/", var.project,
      "/jobs/", google_cloud_run_v2_job.analyse.name, ":run",
    ])

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  depends_on = [
    google_project_service.enabled,
    google_cloud_run_v2_job_iam_member.scheduler_starts_the_analysis,
  ]
}
