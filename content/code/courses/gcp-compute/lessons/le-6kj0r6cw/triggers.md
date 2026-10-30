---
title: Eventarc, the router between a source and a service
version: 1
---

Lesson 17 wired a topic to a function by hand. **Eventarc is the product that does that wiring for
you, for every source Google offers, and delivers every event in the same shape**: a CloudEvent
over HTTP, to a Cloud Run service, a function or a workflow. When a function is deployed with
`--trigger-topic`, it is an Eventarc trigger that gets created behind it.

## What a trigger says

A trigger is three answers and an identity:

- **which events**: a list of matching criteria, always including `type`, and for most types one
  or two more attributes that narrow it, such as the bucket an object landed in;
- **where they go**: the destination, a Cloud Run service by name and region, or a function;
- **through what**: the transport, which for most sources is a Pub/Sub topic and subscription that
  Eventarc creates and manages, the same push you ran by hand;
- **as whom**: a service account whose identity token accompanies each delivery, so the
  destination can refuse anything that is not Eventarc.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"An Eventarc trigger in three parts. On the left, the source: a bucket, shop-photos, where an object is finalized. In the middle, the trigger: matching criteria type equals google.cloud.storage.object.v1.finalized and bucket equals shop-photos, and a transport, a Pub/Sub topic and subscription that Eventarc creates and manages. On the right, the destination: the Cloud Run service thumbnails, which receives a CloudEvent over HTTP with an identity token from the trigger&#x27;s service account.\"><defs><marker id=\"f18trig-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"12\" y=\"70\" width=\"150\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"87\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">source</text><text x=\"87\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">shop-photos</text><text x=\"87\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">an object is</text><text x=\"87\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">finalized</text><rect x=\"196\" y=\"20\" width=\"328\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">the trigger photo-uploaded</text><rect x=\"210\" y=\"54\" width=\"300\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">matching criteria</text><text x=\"360\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">type = ...storage.object.v1.finalized</text><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bucket = shop-photos</text><rect x=\"210\" y=\"140\" width=\"300\" height=\"76\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">transport, made by Eventarc</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a Pub/Sub topic and a</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">push subscription</text><rect x=\"558\" y=\"70\" width=\"150\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"633\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">destination</text><text x=\"633\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">thumbnails</text><text x=\"633\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a CloudEvent, with</text><text x=\"633\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">an identity token</text><path d=\"M162 125 L208 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f18trig-phosphor)\"></path><path d=\"M512 178 L556 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f18trig-phosphor)\"></path></svg>", "caption": "A trigger answers which events, where they go and as whom. The transport between them is a Pub/Sub topic and subscription that Eventarc makes for you."}
```

Event types are named the way a reversed domain names a package. A few the shop will meet:

| event type | when it fires |
|---|---|
| `google.cloud.storage.object.v1.finalized` | an object was written to a bucket |
| `google.cloud.storage.object.v1.deleted` | an object was deleted |
| `google.cloud.pubsub.topic.v1.messagePublished` | a message reached a topic |
| `google.cloud.audit.log.v1.written` | an audit log entry was written; section 04 |

## A trigger for the photos

The shop keeps product photos in a bucket called `shop-photos`, and wants a service that makes
thumbnails whenever one arrives. **Create `~/gcp/eventarc` and save this as `main.tf`:**

```hcl
# eventarc/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_eventarc_trigger" "photos" {
  name     = "photo-uploaded"
  location = "southamerica-east1"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = "shop-photos"
  }

  destination {
    cloud_run_service {
      service = "thumbnails"
      region  = "southamerica-east1"
    }
  }

  service_account = "eventarc@planner-dev.iam.gserviceaccount.com"
}
```

Run `terraform init` and the plan, filtered to what the trigger promises:

```
ana@laptop:~/gcp/eventarc$ terraform plan -no-color | grep -E '^  #|attribute|value|service +=|region +=|service_account|transport|^Plan'
  # google_eventarc_trigger.photos will be created
      + service_account         = "eventarc@planner-dev.iam.gserviceaccount.com"
              + region  = "southamerica-east1"
              + service = "thumbnails"
          + attribute = "bucket"
          + value     = "shop-photos"
            # (1 unchanged attribute hidden)
          + attribute = "type"
          + value     = "google.cloud.storage.object.v1.finalized"
            # (1 unchanged attribute hidden)
      + transport (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

**The transport is `(known after apply)`**: Eventarc creates the topic and the subscription when the
trigger is created, and names them itself. Two details matter before you would apply this for
real. A trigger on a bucket must live in the bucket's own region, so a bucket in São Paulo needs a
trigger in `southamerica-east1`. And the bucket's service agent needs permission to publish to
Pub/Sub, which Google's documentation lists as a one-time grant per project; the plan cannot tell
you it is missing, because no API was asked.
