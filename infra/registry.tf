/* Where the image lives.

   ONE REPOSITORY, IN THE SAME REGION AS THE SERVICE. A registry in another
   region works and costs a cross-region pull on every cold start, which for a
   service that scales to zero is every deploy and then some.

   THE CLEANUP POLICY IS NOT HOUSEKEEPING. Every push of every branch leaves an
   image; without a policy they accumulate for the life of the project and the
   bill grows in a line nobody reads. Untagged images are the ones no deploy can
   reach — a tag was moved off them — so deleting them after a month removes
   only what is already unreferenced. */
resource "google_artifact_registry_repository" "images" {
  location      = var.region
  repository_id = "schooling"
  format        = "DOCKER"
  description   = "The API and its embedded interface, one image."

  cleanup_policies {
    id     = "untagged-after-a-month"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "2592000s"
    }
  }

  depends_on = [google_project_service.enabled]
}
