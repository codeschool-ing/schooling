/* The APIs this project uses.

   THEY ARE HERE AND NOT IN THE BOOTSTRAP because "which services a project has
   turned on" is part of what the project IS, and a service somebody enabled by
   hand at 2am is invisible to everybody afterwards. The bootstrap enables only
   the five Terraform itself needs in order to act; everything past that is this
   list.

   DISABLED ON DESTROY IS OFF, deliberately. Turning an API off is not the
   inverse of turning it on: it can break resources outside this configuration
   that happen to share the project, and it fails noisily when anything still
   depends on it. Destroying this configuration should remove what it made, not
   reach further. */
locals {
  services = [
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "sts.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",

    // What runs the nightly item analysis. Without it the job exists and
    // nothing ever starts one — which was the state this platform was in
    // before `scheduler.tf`, and the state that is invisible from every screen.
    "cloudscheduler.googleapis.com",
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(local.services)

  service            = each.value
  disable_on_destroy = false
}
