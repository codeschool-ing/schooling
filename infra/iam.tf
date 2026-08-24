/* Two identities, and neither of them is a person.

   THE SERVICE AND THE PIPELINE ARE NOT THE SAME ACCOUNT, and the separation is
   the interesting part: what runs the application may read one secret and open
   one database, and can deploy nothing. What deploys may push an image and
   replace a revision, and cannot read the secret at all. Neither can do the
   other's job, so a mistake in one is not a way into the other.

   THE DEFAULT COMPUTE SERVICE ACCOUNT IS USED FOR NEITHER. It is an editor on
   the whole project by default — the single widest grant in a fresh GCP
   project, and the one that makes "it works" and "it is safe" the same
   sentence for exactly as long as nobody looks. */

resource "google_service_account" "run" {
  account_id   = "schooling-run"
  display_name = "The API, as it runs"
  description  = "Reads one secret, opens one database, deploys nothing."
}

resource "google_service_account" "deploy" {
  account_id   = "schooling-deploy"
  display_name = "GitHub Actions, deploying"
  description  = "Pushes an image and replaces a revision. Cannot read secrets."
}

/* WHAT THE SERVICE MAY DO */

// The socket to the instance, and nothing about administering it.
resource "google_project_iam_member" "run_opens_the_database" {
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.run.email}"
}

/* THE SECRET IS GRANTED ON THE SECRET, not on the project.
   `roles/secretmanager.secretAccessor` at project level is every secret this
   project will ever hold, granted in advance to whatever needs one of them. */
resource "google_secret_manager_secret_iam_member" "run_reads_the_database_url" {
  secret_id = google_secret_manager_secret.database_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run.email}"
}

// A custom service account starts with nothing, logging included.
resource "google_project_iam_member" "run_writes_logs" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.run.email}"
}

/* AND IT MAY START ONE JOB — the analysis, and only that one.

   THIS IS THE GRANT THAT PUT A BUTTON ON THE CONSOLE. The jobs screen said for
   as long as it existed that there was nothing to press, and the reason it gave
   was this: starting a job means the service holding the right to run one,
   which is an identity and a network path it did not have. It has the identity
   now and the path is Google's own metadata server — no key, no configuration,
   a token minted for this instance and expiring in an hour.

   ON THE JOB AND NOT ON THE PROJECT, which is the rule the secret and the
   scheduler both follow. `roles/run.invoker` at project level is every job and
   every service this project will ever hold, granted in advance to a web
   application that anybody on the internet can reach the front door of. Here it
   is one resource, and the two jobs that must never be startable from a browser
   — the migration and the catalogue load — are not it.

   THE APPLICATION REFUSES BEFORE THIS DOES. `internal/console/writes.go`
   declares the route and `console.Jobs.Startable` is the closed list it checks
   against, so a name outside it never reaches Google. This grant is the second
   fence rather than the first: if that list were ever wrong, the worst it can
   reach is one more run of a job that is idempotent and runs nightly anyway. */
resource "google_cloud_run_v2_job_iam_member" "run_starts_the_analysis" {
  project  = google_cloud_run_v2_job.analyse.project
  location = google_cloud_run_v2_job.analyse.location
  name     = google_cloud_run_v2_job.analyse.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.run.email}"
}

/* WHAT THE PIPELINE MAY DO */

resource "google_artifact_registry_repository_iam_member" "deploy_pushes_images" {
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_project_iam_member" "deploy_replaces_revisions" {
  project = var.project
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

/* DEPLOYING A SERVICE MEANS SAYING WHICH IDENTITY IT RUNS AS, and Google
   requires the deployer to be allowed to act as that identity — otherwise
   anybody who can deploy could run their code as any service account in the
   project. It is granted on the ONE account rather than project-wide. */
resource "google_service_account_iam_member" "deploy_acts_as_the_service" {
  service_account_id = google_service_account.run.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deploy.email}"
}
