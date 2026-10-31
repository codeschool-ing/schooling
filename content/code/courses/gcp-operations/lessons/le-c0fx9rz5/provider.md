---
title: The provider, the project and the region
version: 1
---

`iac` taught Terraform from its first lesson: providers, resources, state, a plan before every apply.
This lesson and the next two are about the part that only appears once the provider points at Google
Cloud: which project a resource lands in, whose identity Terraform acts with, and where the state lives.
Terraform goes into `~/.local/bin`, at the version `iac` used:

```sh
cd ~/gcp
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -o -q terraform.zip terraform -d ~/.local/bin && rm terraform.zip
```

On an Arm computer the file is `terraform_1.16.4_linux_arm64.zip`.

```
ana@laptop:~/gcp/tf/shop$ terraform version
Terraform v1.16.4
on linux_amd64
```

## The shop's provider

Create `~/gcp/tf/shop` and write this file in it:

```hcl
# tf/shop/main.tf
terraform {
  required_version = "1.16.4"
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"

  default_labels = {
    team       = "shop"
    managed-by = "terraform"
  }

  storage_custom_endpoint = "http://localhost:4443/storage/v1/"
}

resource "google_storage_bucket" "assets" {
  name                        = "planner-dev-shop-assets"
  location                    = "SOUTHAMERICA-EAST1"
  uniform_bucket_level_access = true
}
```

Four things in the provider block, and the last is only for this course:

- **`project`** is where a resource goes when it does not say. Every resource of the google provider
  accepts a `project` argument of its own, and a resource that sets one lands there instead. A
  configuration that manages two projects names the project on every resource, or uses two provider
  blocks with an `alias` each; leaving it to the default is how a production bucket ends up in the
  development project.
- **`region`** is the same for regional resources. A bucket has a `location` of its own instead, which is
  why the resource repeats it.
- **`default_labels`** puts the same labels on every resource the provider creates that accepts labels,
  with nothing written per resource. Lesson 23 is about why every resource needs an owner it can be
  traced to; this block is the cheapest way to have one.
- **`storage_custom_endpoint`** sends the provider's Cloud Storage calls to `fake-gcs-server` on your
  computer. Against Google it is left out, and every other service still points at Google, which is why
  only buckets can be created in this course.

`version = "8.9.0"` is exact on purpose. A provider is a program that changes what `plan` means, and the
lock file `terraform init` writes, `.terraform.lock.hcl`, records the checksums of what it downloaded, so
that everybody who runs this configuration runs the same provider. The lock file is committed with the
code.

```
ana@laptop:~/gcp/tf/shop$ terraform init -input=false -no-color | grep -E "Installing|Installed|successfully"
- Installing hashicorp/google v8.9.0...
- Installed hashicorp/google v8.9.0 (signed by HashiCorp)
Terraform has been successfully initialized!
```

`init` fetched the provider from the Terraform Registry into `.terraform/` beside the file.
