---
title: Creating a project, and what comes with it
version: 1
---

**Creating a project takes four decisions, and only one of them can be changed afterwards.** The id
is permanent, the parent can be moved but rarely is, the billing link can change, and the name is a
label. So the minute spent on the id is the minute that matters:

| | rule | example |
|---|---|---|
| **id** | 6 to 30 characters: lowercase letters, digits and hyphens, starting with a letter, not ending with a hyphen; unique across Google Cloud, forever | `planner-reports` |
| **name** | 4 to 30 characters: letters, digits, spaces, hyphens, quotes and `!` | `Planner reports` |
| **parent** | a folder or the organisation | `folders/345678901234` |
| **billing account** | the account that pays, lesson 11 | `012345-6789AB-CDEF01` |

A good id says what the project is for and where it sits, `planner-reports`, and nothing that will
stop being true: not a person's name, not a year, not the word `test` on something that may end up in
production. Google suggests an id with a random tail when the console creates a project, such as
`planner-reports-471209`; the tail makes collisions unlikely and the id unreadable, and Terraform
users usually choose their own.

## Letting the provider check the rules

The team wants a project for monthly reports. Make a directory for this lesson with the provider file
from lesson 2:

```sh
mkdir -p ~/gcp/projects && cd ~/gcp/projects
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

A first draft, saved as `reports.tf`, breaks both naming rules:

```hcl
resource "google_project" "reports" {
  name       = "Planner (reports)"
  project_id = "Planner_Reports"
  folder_id  = "345678901234"
}
```

```
ana@laptop:~/gcp/projects$ terraform validate -no-color

Error: "Planner (reports)" name must be 4 to 30 characters with lowercase and uppercase letters, numbers, hyphen, single-quote, double-quote, space, and exclamation point.

  with google_project.reports,
  on reports.tf line 2, in resource "google_project" "reports":
   2:   name       = "Planner (reports)"


Error: "Planner_Reports" project_id must be 6 to 30 with lowercase letters, digits, hyphens and start with a letter. Trailing hyphens are prohibited.

  with google_project.reports,
  on reports.tf line 3, in resource "google_project" "reports":
   3:   project_id = "Planner_Reports"
```

**Both refusals came from the provider, on the laptop, before any request existed.** The parentheses
are not allowed in a name, and an id may not hold capitals or an underscore. That is the cheapest
place to meet the rules: the same mistake made in the console is a red line under a field, and made
through the API it is a `400` from Google. Fixed, the file reads:

```hcl
resource "google_project" "reports" {
  name       = "Planner reports"
  project_id = "planner-reports"
  folder_id  = "345678901234"
}

resource "google_project_service" "pubsub" {
  project = google_project.reports.project_id
  service = "pubsub.googleapis.com"
}
```

```
ana@laptop:~/gcp/projects$ terraform plan -input=false -no-color | grep -E '^  # |^Plan:|service '
  # google_project.reports will be created
  # google_project_service.pubsub will be created
      + service         = "pubsub.googleapis.com"
Plan: 2 to add, 0 to change, 0 to destroy.
```

## An API is switched on per project

The second resource is the part people forget. **A new project has almost every API switched off**,
and a request to one that is off is refused with `SERVICE_DISABLED`, whatever the caller's roles. An
API is switched on, *enabled* in Google's word, per project, with `gcloud services enable
pubsub.googleapis.com` or with a `google_project_service` like the one above. Switching one on can
take a minute, and some switch others on with them: enabling Compute Engine enables the APIs it
depends on.

That is also a guardrail. A project that never enabled an API cannot be made to run it by a leaked
credential, and an audit of which APIs each project has on says a great deal about what it does. The
emulator, which is one API and nothing else, has no notion of any of this; the plan above is as far as
the lab goes, and `gcloud services list` against Google would be refused like every other request.
