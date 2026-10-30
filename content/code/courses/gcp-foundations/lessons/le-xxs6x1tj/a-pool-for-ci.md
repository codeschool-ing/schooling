---
title: A pool for the planner's CI, written and planned
version: 1
---

The planner's repository is `example/planner` on GitHub, and its deploy workflow should run Terraform as
the deployer of lesson 8, from the `main` branch only, with no key anywhere. Three resources do it: a pool,
a provider for GitHub, and a grant letting the right identities from the pool act as the deployer. Make a
directory with lesson 2's provider file:

```sh
mkdir -p ~/gcp/federation && cd ~/gcp/federation
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

A first draft of `pool.tf` names the pool `ci`:

```hcl
resource "google_iam_workload_identity_pool" "ci" {
  workload_identity_pool_id = "ci"
  display_name              = "CI"
}
```

```
ana@laptop:~/gcp/federation$ terraform validate -no-color

Error: "workload_identity_pool_id" cannot be smaller than 4 characters

  with google_iam_workload_identity_pool.ci,
  on pool.tf line 2, in resource "google_iam_workload_identity_pool" "ci":
   2:   workload_identity_pool_id = "ci"
```

**A pool id takes four to thirty-two characters**, lowercase letters, digits and hyphens. The complete
file names it `ci-pool` and adds the rest:

```hcl
resource "google_iam_workload_identity_pool" "ci" {
  workload_identity_pool_id = "ci-pool"
  display_name              = "CI"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.ci.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # The lock: only tokens from repositories of the example organisation.
  attribute_condition = "assertion.repository_owner == 'example'"
}

# The second lock: only the planner repository may act as the deployer.
resource "google_service_account_iam_member" "ci_acts_as_deployer" {
  service_account_id = "projects/planner-dev/serviceAccounts/deployer@planner-dev.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.ci.name}/attribute.repository/example/planner"
}
```

```
ana@laptop:~/gcp/federation$ terraform plan -input=false -no-color | grep -E '^  # |attribute_condition|issuer_uri|      \+ role|^Plan:'
  # google_iam_workload_identity_pool.ci will be created
  # google_iam_workload_identity_pool_provider.github will be created
      + attribute_condition                = "assertion.repository_owner == 'example'"
          + issuer_uri = "https://token.actions.githubusercontent.com"
  # google_service_account_iam_member.ci_acts_as_deployer will be created
      + role               = "roles/iam.workloadIdentityUser"
Plan: 3 to add, 0 to change, 0 to destroy.
```

## Reading what was planned

- **The mapping names the claims** this provider will turn into attributes. `assertion.sub` from GitHub
  reads like `repo:example/planner:ref:refs/heads/main`, so `google.subject` is unique per repository and
  branch.
- **The condition** refuses every token whose repository belongs to another organisation, before any role
  is read.
- **The grant is `roles/iam.workloadIdentityUser`**, not Token Creator. It is the role that lets a
  federated identity impersonate a service account, and it is granted on the deployer, to the set of
  identities whose `repository` attribute is `example/planner`.

**One lock is still missing**, and the plan cannot point at it: any branch of `example/planner`, including
a branch an outside contributor opened in a pull request, matches that `principalSet`. Restricting it to
`main` is a stricter condition, `assertion.repository == 'example/planner' && assertion.ref ==
'refs/heads/main'`, or a grant to the single `principal://` whose subject names `main`. Which one a team
picks is a design choice; leaving the gap open is not.

The plan is the provider's. Whether GitHub's issuer answers, whether the pool's id is free in the project
and whether the deployer exists are Google's questions, asked only at apply.
