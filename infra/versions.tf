/* The state lives in a bucket, and the bucket is not managed here.

   A BACKEND CANNOT BE BUILT BY THE THING IT HOLDS THE STATE OF. The bucket is
   created by hand once — see README.md — because Terraform would have to write
   its state somewhere in order to create the place it writes its state. It is
   the one piece of this project's infrastructure that is not code, and it is
   versioned so that a truncated write is recoverable.

   The bucket name is written here rather than passed in: a backend is read
   before variables exist, so it cannot be one. */
terraform {
  /* A FLOOR AND A CEILING. `>= 1.9` alone accepts a future 2.0, which is the
     one release allowed to break things — and it would break them during an
     apply somebody ran for an unrelated reason, on infrastructure that is
     already running. */
  required_version = ">= 1.9, < 2.0"

  backend "gcs" {
    bucket = "aleogr-schooling-tfstate"
    prefix = "infra"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region

  /* WHOSE QUOTA PAYS FOR THE CALL, SAID HERE RATHER THAN TAKEN FROM THE SHELL.

     Every request carries two projects: the one being acted on, and the one
     billed for the API call. The first is `project` above. The second, left
     out, comes from whatever `gcloud config set project` last wrote — so a
     Cloud Shell session that restarted and restored an older default sends
     every call for THIS project against ANOTHER project's quota, and the
     failure reads:

         Error when reading or editing Project "aleogr-schooling":
         Cloud Resource Manager API has not been used in project
         codeschool-ing before or it is disabled

     Two project names in one sentence, the right one first, and the advice
     pointing at the wrong one — enabling an API on a project that has no
     business with this configuration would have "fixed" it.

     Said here, the ambient value cannot reach it. It is the same rule as the
     three in README.md: a default is a decision made somewhere else by
     somebody who does not know what this project is — and this one was made by
     a shell. */
  user_project_override = true
  billing_project       = var.project
}
