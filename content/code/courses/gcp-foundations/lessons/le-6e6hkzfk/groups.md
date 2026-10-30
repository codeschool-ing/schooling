---
title: Groups, written down
version: 1
---

**A group is the one directory object IAM grants are meant to name**, lesson 5's rule, and a group can be
created and filled from Terraform through the Cloud Identity API. That puts the question "who is in
`planner-oncall`?" in a file somebody reviews, rather than in an administrator's memory. Make a directory
with lesson 2's provider file:

```sh
mkdir -p ~/gcp/groups && cd ~/gcp/groups
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `groups.tf`:

```hcl
locals {
  customer = "customers/C01abcd23" # the directory's customer id, made up for this course
}

resource "google_cloud_identity_group" "oncall" {
  parent       = local.customer
  display_name = "planner on-call"
  description  = "Holds the on-call grants of lessons 7 and 8."

  group_key {
    id = "planner-oncall@example.com"
  }

  # The label that makes this an ordinary mailing-list group in the directory.
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_cloud_identity_group_membership" "ana" {
  group = google_cloud_identity_group.oncall.id

  preferred_member_key {
    id = "ana@example.com"
  }

  roles {
    name = "MEMBER"
  }
}
```

As in lesson 4, the plan is saved with `-out`, and `terraform show -json` and `jq` pick out of it the
fields that matter, one line per resource:

```
ana@laptop:~/gcp/groups$ terraform plan -input=false -no-color -out=plan.bin | grep "^Plan:"
Plan: 2 to add, 0 to change, 0 to destroy.
ana@laptop:~/gcp/groups$ terraform show -json plan.bin | jq -c '.resource_changes[] | {address, after: (.change.after | {parent, display_name, group_key, preferred_member_key, roles} | with_entries(select(.value != null)))}'
{"address":"google_cloud_identity_group.oncall","after":{"parent":"customers/C01abcd23","display_name":"planner on-call","group_key":[{"id":"planner-oncall@example.com","namespace":null}]}}
{"address":"google_cloud_identity_group_membership.ana","after":{"preferred_member_key":[{"id":"ana@example.com","namespace":null}],"roles":[{"expiry_detail":[],"name":"MEMBER"}]}}
```

## What the file says that a console would not

- **The parent is the directory, not a project.** `customers/C01abcd23` is the directory's own id, shown in
  the Admin console. Groups belong to the company, not to any project, which is why they outlive every
  project they are granted in.
- **The group's address is its id.** `planner-oncall@example.com` is what IAM policies name, so renaming
  the group's display name changes nothing in any policy, and changing the address would break every grant.
- **A membership is a resource of its own.** Adding Ana is one block; removing her is deleting it, in a
  diff somebody reads. A membership can also carry an **expiry**, which is the directory's version of the
  temporary grant of lesson 7.

**Applying this needs more than a project role.** The Cloud Identity API acts on the directory, so the
caller needs a directory administrator role, and calling it with a service account needs that account to be
given the role in the Admin console, outside Google Cloud's IAM. That split is deliberate: the people who
run projects should not, by holding Owner, be able to add themselves to `break-glass`.

The plan above is the provider's. Nothing reached Google, and the customer id is made up.
