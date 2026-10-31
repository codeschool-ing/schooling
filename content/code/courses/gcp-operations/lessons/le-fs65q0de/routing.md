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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Every entry the project writes enters the Log Router. An exclusion drops the successful health checks before storage. Sinks then send entries to their destinations: _Required keeps audit logs for 400 days, the shop sink sends shop-api entries to the bucket shop kept 90 days, a sink sends errors to a Pub/Sub topic, and _Default takes the rest.\"><defs><marker id=\"ah4\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">entries</text><rect x=\"200\" y=\"95\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Log Router</text><line x1=\"152\" y1=\"130\" x2=\"198\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"460\" y=\"20\" width=\"240\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">_Required</text><text x=\"580\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">audit, 400 days</text><line x1=\"352\" y1=\"130\" x2=\"458\" y2=\"43\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"460\" y=\"75\" width=\"240\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bucket shop</text><text x=\"580\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop-api, 90 days</text><line x1=\"352\" y1=\"130\" x2=\"458\" y2=\"98\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"460\" y=\"130\" width=\"240\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-log-errors</text><text x=\"580\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Pub/Sub, errors</text><line x1=\"352\" y1=\"130\" x2=\"458\" y2=\"153\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"460\" y=\"185\" width=\"240\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">_Default</text><text x=\"580\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the rest, 30 days</text><line x1=\"352\" y1=\"130\" x2=\"458\" y2=\"208\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"200\" y=\"210\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"275\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">exclusion: /healthz</text><line x1=\"275\" y1=\"167\" x2=\"275\" y2=\"208\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line></svg>", "caption": "Every entry is routed; where it lands decides what it costs and how long it lives."}
```

## What it costs

From the pricing page, read on 30 October 2026: entries are charged once, when they are stored, at **0.50 USD
per GiB** after the first 50 GiB per project per month, and that includes 30 days of storage. Keeping them
longer adds **0.01 USD per GiB per month** beyond the 30 days. Routing, querying and excluding cost nothing.

So the shop's choices are priced like this. Ninety days instead of thirty, for 20 GiB a month, adds 60 days
of 20 GiB, which is about 0.40 USD a month once the bucket is full. The exclusion of health checks removes a
small volume and a lot of noise. The expensive mistake is the other one: debug logging left on in production
can write a gigabyte an hour, and 720 GiB a month, less the 50 free, is 335 USD, for entries nobody reads.
