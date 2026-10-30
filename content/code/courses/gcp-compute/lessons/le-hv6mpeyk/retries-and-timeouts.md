---
title: Retries, timeouts and doing it twice safely
version: 1
---

A task that exits with anything but 0 has failed, and **Cloud Run starts it again, as a new
attempt of the same task with the same index, up to the job's maximum number of retries.** That is
almost always what you want, and it has one consequence the program must be written for: some of
the work may be done twice.

## A failure and its retry, at home

`FAIL_TASK=1` makes task 1 fail on its first attempt, the way a call to a slow invoice service
would. Playing Cloud Run's part again, run attempt 0 and then attempt 1 of the same task:

```
ana@laptop:~/gcp$ docker run --rm -e CLOUD_RUN_TASK_INDEX=1 -e CLOUD_RUN_TASK_COUNT=3 -e FAIL_TASK=1 invoices:1; echo "exit status $?"
{"severity": "INFO", "message": "task 1 of 3, attempt 0: orders [1002, 1005, 1008]"}
{"severity": "ERROR", "message": "task 1: the invoice service timed out"}
exit status 1
ana@laptop:~/gcp$ docker run --rm -e CLOUD_RUN_TASK_INDEX=1 -e CLOUD_RUN_TASK_COUNT=3 -e CLOUD_RUN_TASK_ATTEMPT=1 -e FAIL_TASK=1 invoices:1; echo "exit status $?"
{"severity": "INFO", "message": "task 1 of 3, attempt 1: orders [1002, 1005, 1008]"}
{"severity": "INFO", "message": "invoice for order 1002 written"}
{"severity": "INFO", "message": "invoice for order 1005 written"}
{"severity": "INFO", "message": "invoice for order 1008 written"}
exit status 0
```

**The first attempt failed with status 1, so Cloud Run would retry it; the second succeeded.** The
index did not change: the retry is the same piece of work, and only `CLOUD_RUN_TASK_ATTEMPT` tells
the program it has been here before. Tasks 0 and 2 are not affected: retries are per task, as
gcloud's help said in section 03, so one bad piece does not restart the others.

## Doing it twice safely

Look at what attempt 0 did before failing: it logged its orders and stopped before writing any
invoice. Suppose instead it had failed after writing two of them. Attempt 1 would write all three,
and orders 1002 and 1005 would have **two invoices each**. That is the general shape of the
problem: a retry repeats whatever the failed attempt did before it failed.

The fix is to make each step **idempotent**, so that doing it twice leaves the same result as doing
it once. For the invoice job that means giving each invoice an identity that comes from the order,
`invoice-1002`, and writing it with an operation that replaces rather than adds: a file named
after the order in a bucket, a row with the order id as its primary key, an API call carrying an
idempotency key. Then attempt 1 rewrites `invoice-1002` instead of creating a second one. **A job
that is not idempotent should have `max_retries = 0`**, and an alert when it fails, because a
retry would do harm.

## The job, written down

Save this as `jobtf/main.tf` in `~/gcp`:

```hcl
# jobtf/main.tf
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

resource "google_cloud_run_v2_job" "invoices" {
  name     = "invoices"
  location = "southamerica-east1"

  template {
    task_count  = 3
    parallelism = 3

    template {
      max_retries = 3
      timeout     = "600s"

      containers {
        image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/invoices:1"
      }
    }
  }
}
```

The two nested `template` blocks are the vocabulary of section 02 in Terraform's spelling: the
outer one describes an **execution** (how many tasks, how many at once), the inner one a **task**
(its retries, its timeout, its container). In `~/gcp/jobtf`, `terraform init` and the plan:

```
ana@laptop:~/gcp/jobtf$ terraform plan -no-color | grep -E '^  #|task_count|parallelism|max_retries|timeout|image|^Plan'
  # google_cloud_run_v2_job.invoices will be created
          + parallelism = 3
          + task_count  = 3
              + max_retries           = 3
              + timeout               = "600s"
                  + image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/invoices:1"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**`timeout` applies to each attempt, not to the execution.** With a timeout of ten minutes and
three retries, one task can run for up to forty minutes in total before the execution is marked
failed, which is worth knowing before somebody sets the timeout to an hour "to be safe".

Running it is `gcloud run jobs execute invoices --region=southamerica-east1`, which in this lab
stops at the missing account like every remote command. With an account, it starts one execution
and, with `--wait`, waits for it to finish and reports whether every task succeeded.
