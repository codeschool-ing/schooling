/* What this deployment is, in the few values that differ between one and
   another. Every one has a default, so `terraform apply` needs no arguments and
   two people applying it get the same thing.

   NONE OF THESE IS A SECRET. A project id and a region are not credentials, and
   nothing here grants access to anything — which is what makes it safe for them
   to be read in a pull request. The values that ARE secret are in Secret
   Manager, and this configuration creates the containers without ever seeing
   what goes in them (see secrets.tf). */

variable "project" {
  description = "The GCP project id. Permanent, and never reused once created."
  type        = string
  default     = "aleogr-schooling"
}

variable "region" {
  description = "Where the service and the database run."
  type        = string
  default     = "us-central1"
}

/* The platform's own address, and the base every school's is built from:
   `code.schooling.lab.aleogr.dev` is a school of `schooling.lab.aleogr.dev`.

   THE APPLICATION READS IT AS ONE VARIABLE, which is what keeps the eventual
   move to a bought domain a DNS change and a redeploy rather than an edit to
   the code. */
variable "platform_domain" {
  description = "The host the platform answers on; schools are subdomains of it."
  type        = string
  default     = "schooling.lab.aleogr.dev"
}

/* THE ONLY REPOSITORY ALLOWED TO DEPLOY. It is the whole security boundary of
   the federation — see federation.tf, where it becomes a condition rather than
   a comment. */
variable "github_repository" {
  description = "owner/repo of the repository whose Actions may deploy."
  type        = string
  default     = "codeschool-ing/schooling"
}

/* The smallest instance there is. Cloud SQL does not scale to zero, so this is
   the standing cost of the project and the number to revisit first — before a
   student exists it is the entire bill.

   IT ONLY EXISTS IN THE ENTERPRISE EDITION, which `database.tf` therefore
   states rather than inherits. `db-g1-small` is the next size up if this one
   is ever refused, and a `db-custom-<cpu>-<mb>` after that. */
variable "database_tier" {
  description = "The Cloud SQL machine type. Shared-core tiers need edition ENTERPRISE."
  type        = string
  default     = "db-f1-micro"
}

/* Where an alert goes. Empty means no alerting is created at all, which is the
   honest default for a project whose DNS does not exist yet: an uptime check
   against a name nobody has published would alert on its first run and teach
   everybody to ignore it. */
variable "alert_email" {
  description = "Address an uptime failure reaches. Empty disables monitoring."
  type        = string
  default     = ""
}
