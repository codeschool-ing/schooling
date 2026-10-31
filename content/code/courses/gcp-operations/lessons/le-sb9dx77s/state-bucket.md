---
title: The state, in a bucket of its own
version: 1
---

**Terraform's state is the only record of which real object each resource in the files is**, and on
a laptop it is a file called `terraform.tfstate` that nobody else can see. `iac` lesson 7 moved it to a
remote backend; on Google Cloud the backend is a Cloud Storage bucket, through the `gcs` backend, and the
bucket is the first thing to create, because everything else's state will live in it.

It is created by a configuration of its own, `bootstrap`, which keeps its own state locally and is
applied once:

```hcl
# tf/bootstrap/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project                 = "planner-dev"
  storage_custom_endpoint = "http://localhost:4443/storage/v1/"
}

resource "google_storage_bucket" "tfstate" {
  name                        = "planner-dev-tfstate"
  location                    = "SOUTHAMERICA-EAST1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 50
    }
    action {
      type = "Delete"
    }
  }
}
```

Three settings make it a bucket fit for state:

- **`versioning`**: every write of the state keeps the previous one as a noncurrent version. This is
  what makes the accident later in this lesson survivable, and it is the setting a state bucket must not
  be without.
- **`public_access_prevention = "enforced"`**: state holds every attribute of every resource, often
  including connection strings and generated passwords, so nothing may ever make this bucket public,
  whoever tries later.
- **the lifecycle rule** keeps the newest 50 versions and deletes older ones, so the history does not
  grow for ever. Fifty is about a month of applies for the shop.

```
ana@laptop:~/gcp/tf/bootstrap$ terraform apply -auto-approve -input=false -no-color | grep -E "^google_|Apply"
google_storage_bucket.tfstate: Creating...
google_storage_bucket.tfstate: Creation complete after 0s [id=planner-dev-tfstate]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## The shop's configuration, local first

The shop's configuration manages a price list in the assets bucket and the Pub/Sub topic its orders go
to. `pubsub_custom_endpoint` sends the provider's Pub/Sub calls to Google's emulator, as
`storage_custom_endpoint` does for Cloud Storage. Write it into `~/gcp/tf/shop/main.tf`, replacing the
one from lesson 5:

```hcl
# tf/shop/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project                 = "planner-dev"
  storage_custom_endpoint = "http://localhost:4443/storage/v1/"
  pubsub_custom_endpoint  = "http://localhost:8085/v1/"
}

resource "google_storage_bucket_object" "prices" {
  bucket  = "planner-dev-shop-assets"
  name    = "prices.json"
  content = jsonencode({ notebook = 2490, pencil_case = 1890 })
}

resource "google_pubsub_topic" "orders" {
  name = "shop-orders"
}
```

The assets bucket is created first with `gcloud storage buckets create gs://planner-dev-shop-assets
--location=southamerica-east1`. Applied with no backend, the state is a file beside the configuration:

```
ana@laptop:~/gcp/tf/shop$ terraform apply -auto-approve -input=false -no-color | grep -E "^google_|Apply"
google_storage_bucket_object.prices: Creating...
google_pubsub_topic.orders: Creating...
google_storage_bucket_object.prices: Creation complete after 0s [id=planner-dev-shop-assets-prices.json]
google_pubsub_topic.orders: Creation complete after 0s [id=projects/planner-dev/topics/shop-orders]
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

## Moving the state into the bucket

Add the backend in a file of its own:

```hcl
# tf/shop/backend.tf
terraform {
  backend "gcs" {
    bucket                  = "planner-dev-tfstate"
    prefix                  = "shop"
    storage_custom_endpoint = "http://localhost:4443/storage/v1/"
  }
}
```

`prefix` is the folder inside the bucket. One bucket holds the state of many configurations, each under
its own prefix, so the prefix is effectively the configuration's address, and two configurations sharing
one would overwrite each other's state. `terraform init -migrate-state` copies the local state into the
bucket:

```
ana@laptop:~/gcp/tf/shop$ terraform init -migrate-state -force-copy -input=false -no-color | grep -E "backend|Successfully|copy"
Initializing the backend...
Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.
If you ever set or change modules or backend configuration for Terraform,
```

The state is now `shop/default.tfstate` in the bucket (`default` is the workspace), and the local copy can
go. **Leaving it is how two copies of the truth start to disagree.**

## Who may read it

The state bucket gets its own IAM: `roles/storage.objectAdmin` for the service accounts that run
Terraform, and for the people who may need to repair it, and nothing for anybody else. A person who can
read the state can read every secret Terraform ever wrote into it, which is why `iac` lesson 12 keeps
secrets out of it and why this bucket is not in the project's general-purpose IAM.
