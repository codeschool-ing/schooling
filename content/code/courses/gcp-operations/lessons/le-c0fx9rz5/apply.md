---
title: Applying, what an imitation does not keep, and the APIs a project must turn on
version: 1
---

With the token in place, apply creates the bucket in `fake-gcs-server`, and `gcloud` reads it back:

```
ana@laptop:~/gcp/tf/shop$ terraform apply -auto-approve -input=false -no-color | grep -E "^google_|Apply"
google_storage_bucket.assets: Creating...
google_storage_bucket.assets: Creation complete after 1s [id=planner-dev-shop-assets]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/gcp/tf/shop$ gcloud storage buckets describe gs://planner-dev-shop-assets --format='yaml(name,labels,location)'
location: US-CENTRAL1
name: planner-dev-shop-assets
```

**The bucket exists, and it is not the bucket that was asked for.** It has no labels, and its location
is `US-CENTRAL1`, not São Paulo. `fake-gcs-server` keeps a bucket's name and its objects, and answers
every other question with a default: it never stored the three labels the plan showed, nor the location.
Google keeps both. This is the clearest example in the course of what lesson 1 warned about: the request
was well formed and accepted, and that proves nothing about what the real service would have done with
it.

Ask Terraform for a plan now, with nothing changed in the file:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | grep -E "^  #|forces replacement|Plan:"
  # google_storage_bucket.assets must be replaced
      ~ location                    = "US-CENTRAL1" -> "SOUTHAMERICA-EAST1" # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

Terraform refreshed the bucket, read back `US-CENTRAL1`, and compared it with the file. **A bucket's
location cannot be changed**, so the only way to make reality match the file is to destroy the bucket
and create it again, with everything in it. That is what `# forces replacement` means, and it is the
line in a plan that deserves the slowest reading: against Google, this plan would delete every object in
the bucket. Here it is an artefact of the imitation; in a real project the same line appears when
somebody changes a location or a name in the file, and lesson 6 is about the day that line is applied by
mistake.

## Every service is an API, and an API is off until it is on

A new Google Cloud project has almost every API turned off. Creating a Cloud Run service in a project
where `run.googleapis.com` is off fails with `SERVICE_DISABLED`, whatever the caller's permissions. So a
configuration that creates resources usually starts by turning on the APIs they need, as resources of
their own:

```hcl
# tf/apis/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}
```

```
ana@laptop:~/gcp/tf/apis$ terraform plan -input=false -no-color | grep -E "^  # |Plan:"
  # google_project_service.artifactregistry will be created
  # google_project_service.run will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

The plan was computed and nothing more: `fake-gcs-server` knows no APIs, so applying it would send the
request to Google, with a token Google refuses. **`disable_on_destroy = false` is the line to keep.**
Without it, `terraform destroy` on this configuration turns the API off for the whole project, and every
service that uses it stops, including the ones this configuration never created.

Turning an API on also takes a minute or two to reach every part of Google, so a resource created in the
same apply sometimes fails the first time and succeeds the second. A `depends_on` from the resource to its
`google_project_service` makes the order explicit, and a retry is still sometimes needed.
