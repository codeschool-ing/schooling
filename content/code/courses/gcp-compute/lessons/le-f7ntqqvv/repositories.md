---
title: Repositories, and the address an image lives at
version: 1
---

Every compute product in this course runs an image from somewhere: Cloud Run, its jobs, GKE, a
function's build. **On Google Cloud that somewhere is Artifact Registry, and the image's address
says where it is stored, which project owns it and which repository holds it.** Container Registry,
the older `gcr.io` service, has been replaced by it, and `gcr.io` addresses in new projects are
served by Artifact Registry behind the scenes.

## Reading an address

A full image address in Artifact Registry has five parts:

| part | in the shop's address | what it is |
|---|---|---|
| host | `southamerica-east1-docker.pkg.dev` | the region, then the format |
| project | `planner-dev` | who owns and pays for it |
| repository | `shop` | a container with its own permissions and policies |
| image | `web` | one name inside the repository |
| tag or digest | `:1.4.0` or `@sha256:…` | which version of the image |

So `southamerica-east1-docker.pkg.dev/planner-dev/shop/web:1.4.0` is read left to right like a
path. **The region is part of the host**, and that is a decision with a cost: a Cloud Run service
in São Paulo pulling from a repository in São Paulo pulls within the region, while the same service
pulling from a repository in another region pays for the data crossing between them and waits for
it at every cold start.

## What a repository decides

A repository is created with a **format**, `DOCKER` here, but also Maven, npm, Python, apt, yum
and Go, so one product holds a company's container images and its libraries. And it has a
**mode**:

- **standard**, the default: you push to it and it stores what you push;
- **remote**: a cache in front of an upstream such as Docker Hub or PyPI, which fetches on the
  first pull and serves its copy afterwards, so a build keeps working when the upstream limits or
  goes down;
- **virtual**: one address in front of several repositories, searched in an order you set.

Permissions are granted on the repository, which is why the shop's images and its libraries
usually live in different ones even when the same people use both.

## The repository, written down

**Create `~/gcp/registry` and save this as `main.tf`:**

```hcl
# registry/main.tf
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

resource "google_artifact_registry_repository" "shop" {
  repository_id = "shop"
  location      = "southamerica-east1"
  format        = "DOCKER"
  description   = "Container images of the shop"
}
```

Then `terraform init` and the plan:

```
ana@laptop:~/gcp/registry$ terraform plan -no-color | grep -E '^  #|repository_id|format|mode +=|location|^Plan'
  # google_artifact_registry_repository.shop will be created
      + format           = "DOCKER"
      + location         = "southamerica-east1"
      + mode             = "STANDARD_REPOSITORY"
      + repository_id    = "shop"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**`mode` came out as `STANDARD_REPOSITORY`** without being written, which is the default the
provider fills in. The plan says nothing about who may push or pull; that is an IAM binding on the
repository, `roles/artifactregistry.writer` for whoever builds and `roles/artifactregistry.reader`
for whatever runs, and `gcp-foundations` covers how such bindings are written.

## What it costs

```
ana@laptop:~/gcp$ python3 prices.py other | grep 'Artifact Registry'
  Artifact Registry, after the free 0.5 GiB              0.1  per GiB-month
```

Ten cents per GiB per month, after the first half GiB, and the shop's `web` image is mostly the
Python base it was built on. Storage is rarely the expensive part of a registry; **data leaving the
region is**, which is one more reason to keep the repository beside the services that pull from it.
