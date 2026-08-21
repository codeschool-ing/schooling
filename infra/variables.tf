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

/* Where an alert goes, and what it watches. BOTH are needed before anything is
   created, and that is not fussiness — it is the two halves of a working alarm.

   An address with nobody to tell is a check that fails into a log. Somebody to
   tell with no address to watch is worse: it alerts on its first run and every
   run after, and the only thing it teaches is to ignore the alert. */
variable "alert_email" {
  description = "Address an uptime failure reaches. Empty disables monitoring."
  type        = string
  default     = ""
}

/* WHAT A STUDENT TYPES, NOT THE PLATFORM'S OWN NAME.

   This was `platform_domain`, and that was wrong for a reason only deploying
   showed: a host that no Cloud Run domain mapping carries never reaches the
   container at all. Google's front end routes by hostname and answers its own
   404 first — so a check against an unmapped name measures Google's error page
   and reports the service down while it is perfectly healthy.

   `schooling.lab.aleogr.dev` is exactly that host today: it names the platform
   and nothing serves it, because there is no platform page and the tenant
   resolver refuses a host it does not know. So the address worth watching is a
   SCHOOL's — `code.schooling.lab.aleogr.dev` — where `/readyz` is reachable and
   answers only when the process can open its database. */
variable "uptime_host" {
  description = "A mapped host where /readyz answers. Empty disables monitoring."
  type        = string
  default     = ""
}
