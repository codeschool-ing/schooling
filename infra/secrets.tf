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

/* The mail provider's key, in a container this file does not fill.

   SAME ARRANGEMENT AS THE DATABASE URL AND FOR THE SAME REASON: a
   `secret_version` here would put the value in the plan, in the state, and in
   every version of the state the bucket keeps.

   IT IS CREATED WHETHER OR NOT ANYTHING SENDS MAIL. An empty container costs
   nothing, and a service that names a secret which does not exist fails to
   start — so the container existing first is what makes turning mail on a
   matter of writing one value rather than a Terraform run. */
resource "google_secret_manager_secret" "mail_api_key" {
  secret_id = "schooling-mail-api-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}

/* And what stands in front of the delivery hook.

   BREVO DOES NOT SIGN ITS WEBHOOKS — no HMAC, no shared secret in a header,
   nothing to verify a body against. So the secret is a segment of the path the
   provider posts to, and this is its container.

   It is a secret rather than a plain variable for the reason the other two are:
   a `tfvars` file is a file on somebody's laptop and in a plan's output, and an
   endpoint that marks addresses as refused is a way to stop this platform
   writing to anybody. Empty mounts no endpoint at all, which is the right
   failure — nothing there, rather than something anybody may post to. */
resource "google_secret_manager_secret" "mail_hook_secret" {
  secret_id = "schooling-mail-hook-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}
