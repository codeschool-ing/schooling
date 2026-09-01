/* What the deploy pipeline needs to know, so that it is read rather than
   copied. Every one of these is a fact this configuration decides; a workflow
   with them typed in by hand is a second place they are decided, and the two
   drift on the day one of them changes. */

output "region" {
  value = var.region
}

output "api_image" {
  description = "Where the API image is pushed and read from."
  value       = local.api
}

output "migrate_image" {
  description = "Where the migration image is pushed and read from."
  value       = local.migrate
}

output "service" {
  description = "The Cloud Run service the pipeline replaces a revision of."
  value       = google_cloud_run_v2_service.api.name
}

output "migrate_job" {
  description = "The job the pipeline runs to completion before sending traffic."
  value       = google_cloud_run_v2_job.migrate.name
}

output "load_image" {
  description = "Where the catalogue loader is pushed and read from."
  value       = local.load
}

output "load_job" {
  description = "The job that writes the mirror from `content/`, after the schema."
  value       = google_cloud_run_v2_job.load.name
}

output "deploy_service_account" {
  description = "The identity GitHub Actions impersonates. It cannot read secrets."
  value       = google_service_account.deploy.email
}

/* WHAT GOES IN THE WORKFLOW, verbatim. It carries the project NUMBER rather
   than the id, which is why it is an output instead of something a person
   assembles. */
output "workload_identity_provider" {
  description = "The provider GitHub Actions authenticates against."
  value = join("", [
    "projects/", data.google_project.this.number,
    "/locations/global/workloadIdentityPools/",
    google_iam_workload_identity_pool.github.workload_identity_pool_id,
    "/providers/",
    google_iam_workload_identity_pool_provider.github.workload_identity_pool_provider_id,
  ])
}

/* THE TWO ON THE CLOCK, AND BOTH HALVES OF EACH.

   Named here for the reason at the top of this file: the pipeline updates their
   images and a person occasionally runs one by hand, and neither should be
   typing a name this configuration owns.

   THE IMAGES WERE THE HALF THAT WENT MISSING, twice, and in the same shape both
   times: the analysis arrived with a `_job` and no `_image`, and the settling
   arrived with neither. `release.yml` carried `ANALYSE_IMAGE`, `SETTLE_JOB` and
   `SETTLE_IMAGE` typed in with nothing here to read them from — which is
   exactly the "second place they are decided" this file opens by refusing.

   It is worth saying that this did not break anything and would not have: the
   values agreed. That is the point. A fact with one source and a copy that
   happens to match is indistinguishable from a fact with one source, right up
   until the day somebody changes the source. */
output "analyse_job" {
  description = "The Cloud Run job the scheduler starts every night."
  value       = google_cloud_run_v2_job.analyse.name
}

output "analyse_image" {
  description = "Where the item analysis is pushed and read from."
  value       = local.analyse
}

output "settle_job" {
  description = "The Cloud Run job that brings lapsed subscriptions up to date."
  value       = google_cloud_run_v2_job.settle.name
}

output "settle_image" {
  description = "Where the lapse sweeper is pushed and read from."
  value       = local.settle
}

output "database_connection_name" {
  description = "What the Auth Proxy and the Cloud Run socket both address."
  value       = google_sql_database_instance.main.connection_name
}
