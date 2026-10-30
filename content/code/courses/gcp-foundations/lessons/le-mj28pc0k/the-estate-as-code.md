---
title: The tree, written down and planned
version: 1
---

The hierarchy cannot be run in the lab, but it can be **written down exactly** and checked against
everything Google's Terraform provider knows about it. That is worth more than it sounds: a company's
tree is usually created by clicking, and a year later nobody can say why a folder exists. A file says
so, and a plan says whether the file is coherent before anybody asks Google for anything.

## One file every Terraform lesson starts from

Terraform needs to know which provider to use and how to reach it. Make a directory for this lesson
and write the file every later lesson copies:

```sh
mkdir -p ~/gcp/hierarchy && cd ~/gcp/hierarchy
```

Save this as `provider.tf`:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.7.0"
    }
  }
}

# The lab's provider: the project and region every lesson uses, and the same
# placeholder token gcloud sends. A plan asks Google nothing; an apply would
# send this token and be refused.
provider "google" {
  project      = "planner-dev"
  region       = "southamerica-east1"
  access_token = "placeholder"
}
```

`version = "8.7.0"` pins Google's provider exactly, the version every plan in this course was made
with. `access_token` is the placeholder again, written into the file rather than read from
`~/gcp/placeholder-token`, so that the file says on its face that it holds no secret.

## The tree

Save this as `hierarchy.tf`. It is the estate of the figure in the first section, written as three
folders and five projects:

```hcl
locals {
  org = "organizations/123456789012" # example.com, made up for this course
}

resource "google_folder" "production" {
  display_name = "production"
  parent       = local.org
}

resource "google_folder" "non_production" {
  display_name = "non-production"
  parent       = local.org
}

resource "google_folder" "shared" {
  display_name = "shared"
  parent       = local.org
}

resource "google_project" "prod" {
  name       = "Planner production"
  project_id = "planner-prod"
  folder_id  = google_folder.production.folder_id
}

resource "google_project" "staging" {
  name       = "Planner staging"
  project_id = "planner-staging"
  folder_id  = google_folder.non_production.folder_id
}

resource "google_project" "dev" {
  name       = "Planner development"
  project_id = "planner-dev"
  folder_id  = google_folder.non_production.folder_id
}

resource "google_project" "network" {
  name       = "Shared network"
  project_id = "planner-network"
  folder_id  = google_folder.shared.folder_id
}

resource "google_project" "logs" {
  name       = "Logs"
  project_id = "planner-logs"
  folder_id  = google_folder.shared.folder_id
}
```

**A project names its folder by reference, never by number.** `google_folder.production.folder_id` is
a value Google invents when the folder is created; written as a reference, Terraform knows to create
the folder first and to fill in the number it gets back.

## Init, validate, plan

`terraform init` downloads the provider into the cache `env.sh` named, once; every later directory
finds it there. `terraform validate` checks the files against the provider's schema. `terraform plan`
says what Terraform would ask Google to do:

```
ana@laptop:~/gcp/hierarchy$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/google versions matching "8.7.0"...
- Installing hashicorp/google v8.7.0...
- Installed hashicorp/google v8.7.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/gcp/hierarchy$ terraform validate
Success! The configuration is valid.

ana@laptop:~/gcp/hierarchy$ terraform plan -input=false -no-color | grep -E '^  # |^Plan:'
  # google_folder.non_production will be created
  # google_folder.production will be created
  # google_folder.shared will be created
  # google_project.dev will be created
  # google_project.logs will be created
  # google_project.network will be created
  # google_project.prod will be created
  # google_project.staging will be created
Plan: 8 to add, 0 to change, 0 to destroy.
ana@laptop:~/gcp/hierarchy$ terraform plan -input=false -no-color -target=google_project.dev | sed -n "/# google_project.dev/,/^    }/p"
  # google_project.dev will be created
  + resource "google_project" "dev" {
      + auto_create_network = true
      + deletion_policy     = "PREVENT"
      + effective_labels    = {
          + "goog-terraform-provisioned" = "true"
        }
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "Planner development"
      + number              = (known after apply)
      + project_id          = "planner-dev"
      + terraform_labels    = {
          + "goog-terraform-provisioned" = "true"
        }
    }
```

**Eight resources to add, and every number Google would choose is `(known after apply)`**: the folder
numbers, the project numbers, the folder each project ends up in. The plan knows the shape and none
of the identities, which is exactly what can be known without asking. The second plan, narrowed to
one project with `-target`, shows three values nobody wrote: `deletion_policy = "PREVENT"`, which
lesson 3 explains; a label `goog-terraform-provisioned`, which the provider puts on everything it
creates so that a resource says who made it; and `auto_create_network = true`, a network Google would
create in the new project unless told not to, which lesson 15 takes apart.

## What the plan cannot know

**This plan would be refused if it were applied**, and not only because the token is a placeholder.
Creating a folder needs the role `resourcemanager.folderCreator` on the organisation, creating a
project needs `resourcemanager.projectCreator` on the folder, and `organizations/123456789012` is not an
organisation anybody in this course owns. A plan checks the description; whether the caller may make
the request is decided by Google, at the moment of the request, and that is lessons 5 to 9.
