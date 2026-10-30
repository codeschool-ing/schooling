---
title: Custom roles, and the cost of owning one
version: 1
---

**A custom role is a set of permissions you choose, defined on the organisation or on a project.** It
exists for the case a predefined role does not fit: a job that needs three permissions from one role and
one from another, or a predefined role that holds one permission too many for a sensitive project.

The planner's reports job needs to read the messages published to `orders` and to see which topics
exist, and nothing else. No predefined role is exactly that, so the team writes one. Make a directory
with lesson 2's provider file:

```sh
mkdir -p ~/gcp/roles && cd ~/gcp/roles
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

The first draft, saved as `roles.tf`, gives the role an id with hyphens, the way projects are named:

```hcl
resource "google_project_iam_custom_role" "reports_reader" {
  project     = "planner-dev"
  role_id     = "reports-reader"
  title       = "Reports reader"
  description = "Reads the orders subscription and lists topics, for the monthly reports."
  stage       = "GA"
  permissions = [
    "pubsub.subscriptions.consume",
    "pubsub.topics.list",
  ]
}
```

```
ana@laptop:~/gcp/roles$ terraform validate -no-color

Error: "role_id" ("reports-reader") doesn't match regexp "^[a-zA-Z0-9_\\.]{3,64}$"

  with google_project_iam_custom_role.reports_reader,
  on roles.tf line 3, in resource "google_project_iam_custom_role" "reports_reader":
   3:   role_id     = "reports-reader"
```

**A role id is not a project id.** It takes letters, digits, underscores and full stops, between three
and sixty-four of them, and no hyphen. The refusal came from the provider, before any request existed.
With `role_id = "reportsReader"` the plan shows the role Google would hold:

```hcl
resource "google_project_iam_custom_role" "reports_reader" {
  project     = "planner-dev"
  role_id     = "reportsReader"
  title       = "Reports reader"
  description = "Reads the orders subscription and lists topics, for the monthly reports."
  stage       = "GA"
  permissions = [
    "pubsub.subscriptions.consume",
    "pubsub.topics.list",
  ]
}

resource "google_project_iam_member" "reports_job" {
  project = "planner-dev"
  role    = google_project_iam_custom_role.reports_reader.name
  member  = "serviceAccount:reports@planner-dev.iam.gserviceaccount.com"
}
```

```
ana@laptop:~/gcp/roles$ terraform plan -input=false -no-color | grep -E '^  # |      \+ (name|role|role_id|permissions)|^Plan:'
  # google_project_iam_custom_role.reports_reader will be created
      + name            = (known after apply)
      + permissions     = [
      + role_id         = "reportsReader"
  # google_project_iam_member.reports_job will be created
      + role    = (known after apply)
Plan: 2 to add, 0 to change, 0 to destroy.
```

The role's `name` is `(known after apply)` because Google writes it: `projects/planner-dev/roles/reportsReader`
for a role on a project, `organizations/123456789012/roles/reportsReader` for one on the organisation.
That full name is what a grant uses, so the grant refers to it rather than spelling it out.

## The cost of owning one

**A custom role does not grow.** When Google adds a feature to Pub/Sub, it adds the new permission to
`roles/pubsub.subscriber`, and every holder of that role can use the feature the same day. The custom
role above never gets it; somebody has to notice and add it. For a role meant to be narrow that is the
point. For a role written to save a few permissions it becomes a maintenance job nobody signed up for,
and the usual symptom is a workload refused months later for a permission that did not exist when the
role was written.

Three more facts that catch people:

- **Not every permission may go in a custom role.** Each permission has a support level, and some are
  `NOT_SUPPORTED` in custom roles, or `TESTING`, which works and may change. The provider does not know
  which, so a plan that passes can still be refused by Google at apply.
- **A custom role lives on the organisation or on a project, never on a folder.** A role meant for every
  project is defined once on the organisation and granted wherever it is needed.
- **A deleted role's id is not free at once.** A deleted custom role can be restored for seven days, and
  its id cannot be reused until Google has purged it, some weeks later. Name the next one differently.

None of the last two sections ran against Google: the IAM API has no emulator. The validation and the
plan are real, and they are the provider's.
