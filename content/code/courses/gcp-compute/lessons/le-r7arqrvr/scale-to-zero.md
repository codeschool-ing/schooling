---
title: Scale to zero, and what deploying it would take
version: 1
---

When nobody is asking, a Cloud Run service has **no instances at all**, and costs nothing for
compute. When a request arrives, Cloud Run starts an instance from the image, waits for it to
listen, and hands it the request. **That first request pays for the start, and every later one
until the instance goes idle does not.** This section is that cycle, and the description of the
service Terraform would send to make it real.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline of one service. At first there are no instances. A request arrives and waits while an instance starts: the image is pulled, the container starts and begins listening; that wait is the cold start. The instance then serves this request and the ones after it. When requests stop it stays idle for a while, up to about fifteen minutes, and is then shut down with SIGTERM, returning to no instances.\"><defs><marker id=\"l8z-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">no instances</text><rect x=\"150\" y=\"90\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"235.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">starting</text><rect x=\"330\" y=\"90\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">serving</text><rect x=\"510\" y=\"90\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">idle</text><path d=\"M140 115 L150 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8z-ah)\"></path><path d=\"M320 115 L330 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8z-ah)\"></path><path d=\"M500 115 L510 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8z-ah)\"></path><path d=\"M165 40 L165 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8z-ah)\"></path><text x=\"165\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the first request arrives</text><text x=\"235\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pull, start, listen</text><text x=\"235\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the cold start</text><text x=\"415\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">this request and the next</text><text x=\"605\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">up to about 15 minutes</text><path d=\"M605 196 L70 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l8z-ah)\"></path><text x=\"340\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SIGTERM, then back to no instances</text></svg>", "caption": "Only the first request after a quiet spell pays for the start. How long the idle state lasts is Google's decision, and with no minimum set it costs nothing."}
```

## The cycle, in four states

**No instances.** The service exists, has an address, and answers nothing yet. A request that
arrives now is held by Cloud Run's front end while an instance starts.

**Starting.** Cloud Run pulls the image, starts the container and waits for the startup probe,
by default a TCP connection to `PORT`. The time from request to first byte here is the **cold
start**, and it is the sum of the pull, the start of the runtime, and whatever your program does
before it listens. Lesson 11 takes it apart.

**Serving.** The instance answers this request and any others that arrive, several at a time if
its concurrency allows. More instances start when the ones running are full.

**Idle.** When requests stop, the instance is not stopped at once. Google's documentation says an
idle instance may be kept for up to fifteen minutes, so that the next request finds it warm, and
then shut down with the `SIGTERM` of the last section. With request-based billing, an idle
instance with no minimum set costs nothing while it waits; the sheet's prices are in lesson 11.

**A minimum number of instances** changes the first state: with `min_instance_count = 1`, one
instance is always there and the first request of the morning finds it warm. That one instance is
billed while idle, at the idle rate the price sheet lists, and lesson 11 works out when it is
worth it.

## The service, written down

Save this as `cloudrun/main.tf` in `~/gcp`:

```hcl
# cloudrun/main.tf
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
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }
}
```

Then, in `~/gcp/cloudrun`, run `terraform init` as in lesson 1, and plan:

```
ana@laptop:~/gcp/cloudrun$ terraform plan -no-color | grep -E '^  #|^      \+ (name|location|ingress) |image|min_instance|max_instance|cpu|memory|container_port|^Plan'
  # google_cloud_run_v2_service.orders will be created
      + ingress                 = "INGRESS_TRAFFIC_ALL"
      + location                = "southamerica-east1"
      + name                    = "orders"
          + max_instance_request_concurrency = (known after apply)
              + image      = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1"
                  + container_port = 8080
                      + "cpu"    = "1"
                      + "memory" = "512Mi"
              + max_instance_count = 10
              + min_instance_count = 0
Plan: 1 to add, 0 to change, 0 to destroy.
```

Each line is a decision this lesson made. **The image is named by its Artifact Registry path**,
which lesson 21 explains, because Cloud Run cannot pull from your laptop. `container_port` is the
`PORT` the container will be given. One vCPU and 512 MiB is the size of every instance, and the
unit of every price. `min_instance_count = 0` is scale to zero, and `max_instance_count = 10` is a
ceiling on how many instances a burst of traffic, or an attack, can make you pay for. The ingress
setting lets anybody on the internet reach the address; lesson 12 narrows it. And one line the file never mentions,
`max_instance_request_concurrency`, is left for Cloud Run to fill in: how many requests one
instance takes at once, which lesson 11 is about.

## What deploying needs, and why it does not happen here

The same service can be deployed with gcloud in one command, which in this lab stops where every
remote command stops:

```
ana@laptop:~/gcp/cloudrun$ gcloud run deploy orders --image=southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1 --region=southamerica-east1
ERROR: (gcloud.run.deploy) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

With an account, that command would ask for the image to be in Artifact Registry, create the
service and its first revision, and print an address ending in `run.app`. **Nothing of that can be
shown here, and nothing about it is invented**: no address, no revision name, no timing. What the
lab does show is the part that decides whether a deployment works, which is the container keeping
its contract, and the description of the service, which is what Terraform would send. Lesson 9
picks up the revisions every deployment creates.
