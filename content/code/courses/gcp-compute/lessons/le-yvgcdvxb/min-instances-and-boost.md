---
title: Minimum instances and startup CPU boost
version: 1
---

When a cold start cannot be made short enough, two settings stop users from meeting it. **A minimum
number of instances keeps some warm at all times, and startup CPU boost gives a starting instance
more CPU than it will have later.** The first costs money every hour; the second costs a little at
each start.

## A warm minimum

`min_instance_count = 1` keeps one instance alive when there is no traffic. With request-based
billing it is billed at the idle rate the sheet lists while it waits: 0.0000025 dollars a
vCPU-second, about a tenth of the active rate, and the same 0.0000025 per GiB-second of memory. The middle column of section
03's program is that cost: **an instance of 1 vCPU and 512 MiB kept warm while idle 95% of the
month costs 9.36 dollars**, on top of whatever it costs while serving.

Whether that is worth it depends on how often a request would otherwise wait. A service called a
few times an hour, each call after the idle instances have been shut down, starts cold almost every
time; ten dollars a month to remove that is cheap. A service with steady traffic always has an
instance running, and a minimum adds nothing but cost. And **a minimum is per service and per
revision with traffic**, so a split of lesson 9 between two revisions can keep two warm.

## Startup CPU boost

Many runtimes do their heaviest work at start: Python importing, Java compiling, a framework
scanning its routes. **With `startup_cpu_boost = true`, Cloud Run gives the instance extra CPU while
it starts** and for a short while after, then takes it away. Google's documentation describes the
boost and how it is billed; this lab cannot measure it, and the course quotes no gain.

## The settings, written down

Save this as `tuning/main.tf` in `~/gcp`:

```hcl
# tuning/main.tf
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

resource "google_cloud_run_v2_service" "orders" {
  name     = "orders"
  location = "southamerica-east1"

  template {
    max_instance_request_concurrency = 80

    scaling {
      min_instance_count = 1
      max_instance_count = 10
    }

    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }
    }
  }
}
```

In `~/gcp/tuning`, `terraform init` and the plan:

```
ana@laptop:~/gcp/tuning$ terraform plan -no-color | grep -E 'concurrency|cpu_idle|startup_cpu_boost|min_instance_count|^Plan'
          + max_instance_request_concurrency = 80
                  + cpu_idle          = true
                  + startup_cpu_boost = true
              + min_instance_count = 1
Plan: 1 to add, 0 to change, 0 to destroy.
```

Each line is one decision of this lesson: **80 requests per instance**, because the orders service
waits rather than computes; **`cpu_idle = true`**, request-based billing, because the service is
busy a small part of the day; **one warm instance**, because its first request of the morning should
not wait; and **a boost at start**, because Python's imports are its heaviest moment.

## The order to decide them in

1. **Concurrency first**, from a measurement like section 02's, because it sets how many instances
   everything else is multiplied by.
2. **CPU allocation second**, from the busy share and section 03's arithmetic.
3. **Shorten the cold start** in the program, section 04.
4. **Only then a minimum and a boost**, for whatever cold start is left and still matters.
