---
title: Identities from outside, and every kind written down
version: 1
---

**The last kind of principal comes from somebody else's directory.** A company whose people sign in
with Microsoft Entra ID or Okta, and a CI system such as GitHub Actions whose jobs carry a signed token,
can be trusted by Google Cloud without any Google account existing for them. Google calls this
**federation**, and it writes the principals it produces with a longer prefix:

| written as | what it is |
|---|---|
| `principal://iam.googleapis.com/locations/global/workforcePools/staff/subject/ana@example.com` | one person from an outside identity provider, through a **workforce** pool |
| `principalSet://iam.googleapis.com/locations/global/workforcePools/staff/group/planner-devs` | a group from that provider |
| `principal://iam.googleapis.com/projects/415104041262/locations/global/workloadIdentityPools/ci-pool/subject/repo:example/planner:ref:refs/heads/main` | one workload from outside, through a **workload** pool |
| `principalSet://iam.googleapis.com/projects/415104041262/locations/global/workloadIdentityPools/ci-pool/attribute.repository/example/planner` | every workload whose token says it came from one repository |

Two words to keep apart: a **workforce** pool is for people, and lives on the organisation; a **workload**
pool is for programs, and lives in a project. Lesson 9 builds a workload pool for the planner's CI, and
lesson 10 says when a workforce pool is the right answer for people. Here, the point is only that **these
are principals like any other**: a role is granted to one exactly as to `user:` or `group:`, and the
long name is the price of saying precisely which outside identity is meant.

## Every kind, checked by the provider

None of these identities exists in the lab, but every one of them can be written into a policy and
checked. Make a directory with lesson 2's provider file:

```sh
mkdir -p ~/gcp/principals && cd ~/gcp/principals
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

A first attempt at granting Ana a role, saved as `grants.tf`, forgets the prefix:

```hcl
resource "google_project_iam_member" "ana" {
  project = "planner-dev"
  role    = "roles/viewer"
  member  = "ana@example.com"
}
```

```
ana@laptop:~/gcp/principals$ terraform validate -no-color

Error: invalid value "ana@example.com" for member (IAM members must have one of the values outlined here: https://cloud.google.com/billing/docs/reference/rest/v1/Policy#Binding)

  with google_project_iam_member.ana,
  on grants.tf line 4, in resource "google_project_iam_member" "ana":
   4:   member  = "ana@example.com"
```

**The provider refused an address without a kind.** `ana@example.com` could be a person or a group,
and IAM will not guess. The complete file grants one role to one
principal of each kind:

```hcl
locals {
  project = "planner-dev"
  pool    = "projects/415104041262/locations/global/workloadIdentityPools/ci-pool"
}

resource "google_project_iam_member" "grants" {
  for_each = {
    person   = "user:ana@example.com"
    group    = "group:planner-devs@example.com"
    domain   = "domain:example.com"
    workload = "serviceAccount:reports@planner-dev.iam.gserviceaccount.com"
    outside  = "principalSet://iam.googleapis.com/${local.pool}/attribute.repository/example/planner"
  }
  project = local.project
  role    = "roles/viewer"
  member  = each.value
}
```

`for_each` makes one resource per entry of the map, each with its own name, so a grant can be added or
removed without moving the others:

```
ana@laptop:~/gcp/principals$ terraform plan -input=false -no-color | grep -E '^  # |^Plan:'
  # google_project_iam_member.grants["domain"] will be created
  # google_project_iam_member.grants["group"] will be created
  # google_project_iam_member.grants["outside"] will be created
  # google_project_iam_member.grants["person"] will be created
  # google_project_iam_member.grants["workload"] will be created
Plan: 5 to add, 0 to change, 0 to destroy.
```

**Five grants, one per kind of principal, and every one would be refused if applied**: not for the
placeholder token alone, but because none of these identities exists. Google checks, at the moment of a
grant, that a `user:`, `group:` or `serviceAccount:` names something real, and the workload pool's
number was made up for this course. The provider checked the form; only Google can check the substance.
