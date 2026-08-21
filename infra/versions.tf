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
}
