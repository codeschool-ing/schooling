/* The containers, and never what goes in them.

   A `google_secret_manager_secret_version` here would mean the value passing
   through Terraform — into the plan output, into the state file, into every
   version of that state the bucket keeps. The point of a secret manager is that
   the secret has exactly one home; a copy in a state bucket is a second one,
   and it is the copy nobody remembers to rotate.

   So this declares that the secret EXISTS and who may read it. What it says is
   written once by a person, and read by the service at start-up. */
resource "google_secret_manager_secret" "database_url" {
  secret_id = "schooling-database-url"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}
