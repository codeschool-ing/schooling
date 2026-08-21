/* How GitHub Actions deploys without a key.

   # THE POINT: THERE IS NO CREDENTIAL TO STEAL

   The ordinary way to let CI touch a cloud is to create a service account key —
   a JSON file with a private key in it — and paste it into a repository secret.
   That file does not expire, works from anywhere on earth, and is now in the
   hands of every action the workflow runs and everybody who can read the
   repository's settings. Rotating it is a task nobody has.

   Federation replaces it with a trade: GitHub signs a short-lived token saying
   which repository, which workflow and which ref is running; Google is
   configured to believe that issuer, and to exchange such a token for an access
   token that lasts an hour. Nothing durable exists to leak.

   # THE CONDITION IS THE WHOLE SECURITY BOUNDARY

   Without `attribute_condition`, this trusts GITHUB — not this repository.
   Anybody with a public repository could run an action, present a perfectly
   valid token, and receive credentials to this project. It is the single most
   consequential line in this directory, and it is why the repository is a
   variable rather than a string typed twice.

   The binding below narrows it a second time, on the other side: even a token
   this provider accepted may only impersonate the deploy account if it carries
   the same repository. */

data "google_project" "this" {}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
  description               = "Short-lived tokens from this project's repository."

  depends_on = [google_project_service.enabled]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  // Read the block comment above before touching this line.
  attribute_condition = "assertion.repository == \"${var.github_repository}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

/* THE REPOSITORY, NOT A WORKFLOW OR A BRANCH. Deploys run from `main` and
   releases run from a tag, so narrowing to a ref here would refuse half of
   them. `attribute.ref` is mapped above so that narrowing later is a condition
   and not a migration. */
resource "google_service_account_iam_member" "github_may_deploy" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member = join("", [
    "principalSet://iam.googleapis.com/projects/",
    data.google_project.this.number,
    "/locations/global/workloadIdentityPools/",
    google_iam_workload_identity_pool.github.workload_identity_pool_id,
    "/attribute.repository/",
    var.github_repository,
  ])
}
