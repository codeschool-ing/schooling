---
title: The link between a project and what pays for it
version: 1
---

**Every project that uses paid services is linked to exactly one billing account.** The link can be made
when the project is created or later, and it can be moved to another account at any time: a project in
development paid for by the team's account moves to the production account when it goes live, and its
resources do not notice.

`gcloud` has the commands for both ends, and the lab can send the first of them to Google:

```
ana@laptop:~/gcp$ gcloud billing accounts list
ERROR: (gcloud.billing.accounts.list) UNAUTHENTICATED: Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property.
- '@type': type.googleapis.com/google.rpc.ErrorInfo
  metadata:
    method: google.cloud.billing.v1.CloudBilling.ListBillingAccounts
    service: cloudbilling.googleapis.com
  reason: CREDENTIALS_MISSING
```

The refusal comes from `cloudbilling.googleapis.com`, the Cloud Billing API, in its own words. Against a
real account the command lists every billing account the caller may see, with its id, its name and whether
it is open. `gcloud billing projects link planner-dev --billing-account=012345-6789AB-CDEF01` would then
make the link, and `gcloud billing projects describe planner-dev` would show it. **Neither was run here**:
both would be refused in the same way.

## The link as code

Terraform writes the link as an argument of the project. Make a directory with lesson 2's provider file:

```sh
mkdir -p ~/gcp/billing && cd ~/gcp/billing
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `billing.tf`. It links the reports project of lesson 3 to the company's account, and lets the
team's lead link projects to it:

```hcl
locals {
  billing_account = "012345-6789AB-CDEF01" # made up for this course
}

resource "google_project" "reports" {
  name            = "Planner reports"
  project_id      = "planner-reports"
  folder_id       = "345678901234"
  billing_account = local.billing_account
}

resource "google_billing_account_iam_member" "lead_links_projects" {
  billing_account_id = local.billing_account
  role               = "roles/billing.user"
  member             = "user:ana@example.com"
}
```

```
ana@laptop:~/gcp/billing$ terraform plan -input=false -no-color | grep -E '^  # |      \+ (billing_account|billing_account_id|role|member) |^Plan:'
  # google_billing_account_iam_member.lead_links_projects will be created
      + billing_account_id = "012345-6789AB-CDEF01"
      + member             = "user:ana@example.com"
      + role               = "roles/billing.user"
  # google_project.reports will be created
      + billing_account     = "012345-6789AB-CDEF01"
Plan: 2 to add, 0 to change, 0 to destroy.
```

## What unlinking does

**Unlinking is the switch that stops a project's paid services**, and Google treats it as the serious act it
is. When a project loses its billing account, or the account is closed, the paid services in it stop: virtual
machines are shut down, APIs that cost money refuse requests, and resources that cost money to keep, such as
disks and stored data, **may be deleted** if billing is not restored, on a schedule Google's documentation
gives per service. A project that was meant to pause should be stopped deliberately, not unlinked to see
what happens.

It is also, in an emergency, the only way to stop spending at once. Lesson 12 comes back to that: a budget
does not stop spending, and an automated unlink is the documented way to make it.
