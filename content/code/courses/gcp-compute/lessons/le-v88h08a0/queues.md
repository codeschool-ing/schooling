---
title: A queue that calls you
version: 1
---

Lesson 18 used Pub/Sub, where a publisher announces something and any number of subscribers
react. **Cloud Tasks is the other shape: one piece of work, addressed to one handler, delivered at
a rate you choose and retried until it succeeds.** Pub/Sub says "this happened"; a task says "do
this". The shop's order confirmation emails are a task: each one must be sent once, by the
mailer, and not all at once when a sale brings a thousand orders in a minute.

## What a task is

A task is an HTTP request waiting to be made. It carries a URL, a method, headers and a body, an
optional time before which it must not run, and a name that is unique in its queue. The **queue**
holds the tasks and decides when each is dispatched; the **handler** is any HTTPS endpoint, such
as a Cloud Run service, that answers it. A 2xx answer completes the task. Anything else, or no
answer before the dispatch deadline, is a failure, and the task waits and is tried again.

So the queue owns three decisions that would otherwise be scattered through the code:

- **how fast**: the most tasks dispatched per second, and the most in flight at once;
- **how persistently**: how many attempts, and how long to wait between them;
- **as whom**: an identity token or an OAuth token attached to each request, so the handler can
  refuse anything that did not come from the queue.

## The queue, written down

**Create `~/gcp/tasks` and save this as `main.tf`:**

```hcl
# tasks/main.tf
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

resource "google_cloud_tasks_queue" "emails" {
  name     = "emails"
  location = "southamerica-east1"

  rate_limits {
    max_dispatches_per_second = 5
    max_concurrent_dispatches = 10
  }

  retry_config {
    max_attempts  = 5
    min_backoff   = "10s"
    max_backoff   = "300s"
    max_doublings = 3
  }
}
```

Then `terraform init` and the plan, filtered to the decisions:

```
ana@laptop:~/gcp/tasks$ terraform plan -no-color | grep -E '^  #|max_dispatches|max_concurrent|max_attempts|min_backoff|max_backoff|max_doublings|^Plan'
  # google_cloud_tasks_queue.emails will be created
          + max_concurrent_dispatches = 10
          + max_dispatches_per_second = 5
          + max_attempts       = 5
          + max_backoff        = "300s"
          + max_doublings      = 3
          + min_backoff        = "10s"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Five a second, ten at once, five attempts.** The mail provider's own limit is what sets the rate:
if it accepts five messages a second, a queue that sends twenty buys nothing but refusals.
Section 04 works out what the retry block means in seconds.

## Creating a task, as Google documents it

With an account, a task is created by the application, through the client library or the API,
whenever there is work to queue. From the command line the same thing looks like this. **This
command was not run:**

```sh
gcloud tasks create-http-task --queue=emails --location=southamerica-east1 \
  --url=https://mailer-example.a.run.app/send --method=POST \
  --header=Content-Type:application/json \
  --body-content='{"order": 1042, "email": "ana@example.com"}' \
  --oidc-service-account-email=tasks@planner-dev.iam.gserviceaccount.com
```

The URL is a placeholder for the mailer's address, which Cloud Run would assign. Nothing on your
laptop dispatches tasks, so the next section plays the queue's part with curl, and says so.
