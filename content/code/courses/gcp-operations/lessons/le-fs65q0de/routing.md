---
title: The Log Router, buckets, retention and sinks
version: 1
---

**Every entry a project writes goes through the Log Router, and the router decides where it is kept.** It
holds a list of **sinks**, each a filter and a destination, and sends every entry to every sink whose filter
matches. A new project has two: `_Required`, which keeps audit logs of administrative activity for 400 days
at no charge and cannot be changed, and `_Default`, which keeps everything else for 30 days. The rest of
this section adds the shop's own. Nothing in it ran against Google: it is a Terraform plan, computed on your
computer.

Create `~/gcp/tf/logging/main.tf`:

```hcl
# tf/logging/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_logging_project_bucket_config" "shop" {
  project        = "planner-dev"
  location       = "southamerica-east1"
  bucket_id      = "shop"
  retention_days = 90
}

resource "google_logging_project_sink" "shop" {
  name                   = "shop-to-bucket"
  destination            = "logging.googleapis.com/projects/planner-dev/locations/southamerica-east1/buckets/shop"
  filter                 = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"shop-api\""
  unique_writer_identity = true
}

resource "google_logging_project_exclusion" "healthz" {
  name   = "drop-healthz"
  filter = "resource.type=\"cloud_run_revision\" AND httpRequest.requestUrl=\"/healthz\" AND httpRequest.status=200"
}

resource "google_pubsub_topic" "log_errors" {
  name = "shop-log-errors"
}

resource "google_logging_project_sink" "errors" {
  name                   = "shop-errors-to-pubsub"
  destination            = "pubsub.googleapis.com/projects/planner-dev/topics/shop-log-errors"
  filter                 = "resource.labels.service_name=\"shop-api\" AND severity>=ERROR"
  unique_writer_identity = true
}

resource "google_pubsub_topic_iam_member" "errors_writer" {
  topic  = google_pubsub_topic.log_errors.name
  role   = "roles/pubsub.publisher"
  member = google_logging_project_sink.errors.writer_identity
}
```

```
ana@laptop:~/gcp/tf/logging$ terraform plan -input=false -no-color | grep -E "^  # |retention_days|writer_identity|Plan:"
  # google_logging_project_bucket_config.shop will be created
      + retention_days  = 90
  # google_logging_project_exclusion.healthz will be created
  # google_logging_project_sink.errors will be created
      + unique_writer_identity = true
      + writer_identity        = (known after apply)
  # google_logging_project_sink.shop will be created
      + unique_writer_identity = true
      + writer_identity        = (known after apply)
  # google_pubsub_topic.log_errors will be created
  # google_pubsub_topic_iam_member.errors_writer will be created
Plan: 6 to add, 0 to change, 0 to destroy.
```

Six resources, and each is a decision:

- **A log bucket**, `shop`, in São Paulo, keeping entries for **90 days** instead of `_Default`'s 30. A log
  bucket is where entries are stored and searched; its location is where they live, which matters when a
  regulator asks.
- **A sink to that bucket** for everything the shop's API writes. The entries still reach `_Default` too,
  unless `_Default` is told to exclude them; a project that adds buckets without that pays for each entry
  twice.
- **An exclusion** that drops the successful `/healthz` requests before they are stored. The uptime check of
  lesson 8 makes 26,280 of them a month, and a log entry for each says nothing anybody will read. An excluded
  entry is never stored and never billed.
- **A sink to Pub/Sub** for errors only, so that something can react to them as they happen. Its
  `writer_identity` is a service account Google creates for the sink, known only after apply, and the last
  resource lets it publish to the topic. **A sink without that permission routes nothing and says so only in
  its own error counter.**

## What it costs

From the pricing page, read on 30 October 2026: entries are charged once, when they are stored, at **0.50 USD
per GiB** after the first 50 GiB per project per month, and that includes 30 days of storage. Keeping them
longer adds **0.01 USD per GiB per month** beyond the 30 days. Routing, querying and excluding cost nothing.

So the shop's choices are priced like this. Ninety days instead of thirty, for 20 GiB a month, adds 60 days
of 20 GiB, which is about 0.40 USD a month once the bucket is full. The exclusion of health checks removes a
small volume and a lot of noise. The expensive mistake is the other one: debug logging left on in production
can write a gigabyte an hour, and 720 GiB a month, less the 50 free, is 335 USD, for entries nobody reads.
