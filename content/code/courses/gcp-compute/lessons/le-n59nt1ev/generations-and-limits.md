---
title: Two generations, one platform, and the limits
version: 1
---

Search for Cloud Functions and you meet two products that share a name. **The first generation is
the original service; the second is built on Cloud Run and Eventarc, and Google now calls it Cloud
Run functions.** New work goes on the second. The first still runs functions deployed years ago,
which is why its limits still turn up in answers online.

## What the second generation changed

| | first generation | second generation (Cloud Run functions) |
|---|---|---|
| requests per instance | one at a time | up to 1,000 at a time |
| longest HTTP call | 9 minutes | 60 minutes |
| longest event call | 9 minutes | 9 minutes |
| largest instance | 8 GiB of memory | 32 GiB and 8 vCPUs |
| event sources | a fixed list | anything Eventarc delivers; lesson 18 |
| what runs it | a platform of its own | a Cloud Run service you can inspect |

The concurrency line is the one that changes bills. On the first generation, a hundred
simultaneous requests meant a hundred instances; on the second, one instance may serve many of
them, and lesson 11 is about choosing how many. The pricing follows the platform: Google's
Cloud Functions price page, read on 30 October 2026, opened on Cloud Run's prices, which are the
ones `prices.py` carries.

## Deploying, as Google documents it

Deploying needs an account, so this lab does not do it. With one, the quote function of section 02
is deployed from its folder like this. **This command was not run:**

```sh
gcloud functions deploy quote --gen2 --region=southamerica-east1 \
  --runtime=python312 --source=. --entry-point=quote --trigger-http
```

Google's build packs the folder, installs the framework and `requirements.txt` if there is one,
and creates a Cloud Run service named `quote`. An event function swaps `--trigger-http` for
`--trigger-topic=orders`, and that is the moment the push subscription of section 04 is created
for you.

## The same function, written down

Terraform describes the deployed function too, and that the lab can plan. **Create
`~/gcp/functions` and save this as `main.tf`:**

```hcl
# functions/main.tf
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

resource "google_cloudfunctions2_function" "quote" {
  name     = "quote"
  location = "southamerica-east1"

  build_config {
    runtime     = "python312"
    entry_point = "quote"
    source {
      storage_source {
        bucket = "planner-dev-sources"
        object = "quote.zip"
      }
    }
  }

  service_config {
    available_memory   = "256Mi"
    timeout_seconds    = 60
    max_instance_count = 10
  }
}
```

The source is a zip of the folder in a bucket, which is what `gcloud` uploads behind the scenes.
Run `terraform init`, then the plan, filtered:

```
ana@laptop:~/gcp/functions$ terraform plan -no-color | grep -E '^  #|runtime|entry_point|available_memory|timeout_seconds|max_instance_count|  \+ (uri|url) |^Plan'
  # google_cloudfunctions2_function.quote will be created
      + url              = (known after apply)
          + entry_point           = "quote"
          + runtime               = "python312"
          + available_memory                 = "256Mi"
          + max_instance_count               = 10
          + timeout_seconds                  = 60
          + uri                              = (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

Two numbers in that file are decisions rather than defaults. **`timeout_seconds` is how long one
call may run** before Google cuts it, and a quote that takes a minute is a bug, not a slow day.
**`max_instance_count` is the ceiling on copies**, and it is the one protection against a loop
that calls the function from itself, or a burst that would otherwise scale into a bill. The `uri`
and `url` are decided by Google at deployment, which is why both are `(known after apply)`.

## Where a function stops being the answer

A function fits a small piece of work with a clear trigger: a webhook, a reaction to an upload, a
message to process. It fits less well when the work is a whole application with many routes,
because every route becomes its own deployment to keep in step. That is a Cloud Run service, the
subject of lesson 8, and the boundary between the two has blurred on purpose: since the second
generation, a function is a Cloud Run service with a framework inside.
