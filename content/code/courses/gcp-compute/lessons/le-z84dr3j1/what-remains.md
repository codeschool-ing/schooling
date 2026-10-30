---
title: What remains, and when it still fits
version: 1
---

App Engine is still supported, still deployed to, and still the cheapest place for some
applications to live. It also carries decisions from 2008 that newer products made differently,
and **a team that chooses it today should choose it knowing which of those decisions it is
accepting.**

## Four things that are permanent or nearly so

**One application per project, in one region, forever.** The application is created once, its
region is chosen then, and Google's documentation is explicit that it cannot be changed. Written as
Terraform, the application is one resource whose only required attribute is that location.
**Create `~/gcp/appengine` and save this as `main.tf`:**

```hcl
# appengine/main.tf
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

resource "google_app_engine_application" "app" {
  location_id = "southamerica-east1"
}
```

Then `terraform init` and the plan:

```
ana@laptop:~/gcp/appengine$ terraform plan -no-color | grep -E '^  #|location_id|default_hostname|url_dispatch|^Plan'
  # google_app_engine_application.app will be created
      + default_hostname  = (known after apply)
      + location_id       = "southamerica-east1"
      + url_dispatch_rule = (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

A team that wants the storefront in São Paulo and in Iowa needs two projects. A team that chose the
wrong region needs a new project and a migration.

**The default service cannot be deleted**, and every application has one. Other services can come
and go.

**The legacy bundled services belong to the past.** First-generation runtimes came with App
Engine's own Datastore access, Memcache, Task Queues, Mail and Users APIs, built into the runtime.
Second-generation runtimes, Python 3 among them, leave them out by default; Google offers them
through a compatibility layer for migrations, and recommends the standalone products instead:
Firestore, Memorystore, Cloud Tasks (lesson 20), and so on.

**Some quotas and limits are App Engine's own**, such as the time a request may take under
automatic scaling, ten minutes in the standard environment, and they differ from Cloud Run's. Read
them before porting a long request.

## When it still fits

| the situation | App Engine standard? |
|---|---|
| a small web app or internal tool that idles most of the day | yes: the free instance-hours cover it |
| a team that wants no container, no image, no registry | yes: source and `app.yaml` only |
| an existing App Engine app that works | keep it, and plan its runtime upgrades |
| any language or library the runtimes lack | no: that is a container, so Cloud Run |
| an app that must exist in two regions | no: one region per project |
| new work with no prior commitment | Cloud Run is where Google is investing |

The fair summary is the one Google's own pages imply. **App Engine standard remains a good home
for small, conventional web applications that fit its runtimes**, and is unbeatable on price at the
bottom of the range. Everything else that once needed it now has a better place, and lesson 22
puts the shop's services through that choice with the numbers.
