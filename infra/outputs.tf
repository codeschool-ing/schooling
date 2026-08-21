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

output "database_connection_name" {
  description = "What the Auth Proxy and the Cloud Run socket both address."
  value       = google_sql_database_instance.main.connection_name
}
