---
title: Whose credentials the provider uses
version: 1
---

**The provider block names no key, and it should not.** The google provider looks for credentials in a
fixed order and takes the first it finds. On a laptop that is a person's login, in a pipeline it is the
machine's own service account, and in neither place is a key file written into the configuration.

Ask for a plan before giving it anything:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color 2>&1 | tail -8


Error: Attempted to load application default credentials since neither `credentials` nor `access_token` was set in the provider block.  No credentials loaded. To use your gcloud credentials, run 'gcloud auth application-default login'.  Original error: google: could not find default credentials. See https://cloud.google.com/docs/authentication/external/set-up-adc for more information

  with provider["registry.terraform.io/hashicorp/google"],
  on main.tf line 9, in provider "google":
   9: provider "google" {
```

The provider looked in every place it knows, found nothing, and stopped before computing anything. The
message names the third place, Application Default Credentials, because that is where it expected a
person on a laptop to have logged in.

## The order, first match wins

1. **An access token** in `GOOGLE_OAUTH_ACCESS_TOKEN`, or `access_token` in the block. It is used as it
   is, with no refresh, and expires in an hour when it comes from Google. This course uses it to give the
   provider something that is not a credential at all.
2. **A credentials file** named by `GOOGLE_APPLICATION_CREDENTIALS` or `credentials` in the block: a
   service account key, or a Workload Identity Federation configuration.
3. **Application Default Credentials**, the file `gcloud auth application-default login` writes to
   `~/.config/gcloud/application_default_credentials.json`. This is the laptop's answer: a person's own
   login, short-lived, refreshed by `gcloud`.
4. **The metadata server**, when Terraform runs on Google Cloud: a Cloud Build step, a Compute Engine
   machine, a Cloud Run job. The machine's service account answers, with nothing stored anywhere. This is
   the pipeline's answer.

**A service account key file is the last resort and never the default.** It is a long-lived secret that
works from anywhere until somebody deletes it, and `gcp-foundations` lesson 8 is the lesson on why. The
second item exists mostly for Workload Identity Federation, where the file holds no secret, only where
to exchange a token from another platform, which is that course's lesson 9.

## The token this course uses

There is no Google account here, so this course gives the provider a token that is not one:

```sh
export GOOGLE_OAUTH_ACCESS_TOKEN=fake
```

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | grep -A3 -E "^  #|terraform_labels" | grep -v "^--"
  # google_storage_bucket.assets will be created
  + resource "google_storage_bucket" "assets" {
      + deletion_policy             = "DELETE"
      + effective_labels            = {
      + terraform_labels            = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "team"                       = "shop"
```

The plan is computed on your computer: Terraform compares the configuration with the state, finds
nothing in the state, and proposes to create the bucket. `terraform_labels` is the merge of the
resource's own labels and the provider's `default_labels`, which is what will be written on the bucket:
the two from the provider block, and a third the provider adds on its own, `goog-terraform-provisioned`,
which says a resource came from Terraform without anybody having to remember to say so.
`effective_labels` adds any that Google itself attaches. With the token, the provider asks Google once
whose token it is, is told it is invalid, and carries on without saying so; nothing else leaves your
computer, and the bucket goes to `fake-gcs-server`.

## Acting as another account

A person on a laptop should not hold the permissions to change production directly. The provider can
**impersonate** a service account instead: the person's own credentials are used only to ask for a
short-lived token of the service account, and everything else is done as that account:

```hcl
provider "google" {
  project                     = "planner-prod"
  region                      = "southamerica-east1"
  impersonate_service_account = "terraform@planner-prod.iam.gserviceaccount.com"
}
```

To do that, the person needs `roles/iam.serviceAccountTokenCreator` on that one account, and nothing on
the project. Taking it away takes away their access to production, and the audit log of lesson 9 records
both names: the account that acted and the person behind it. That block was not run here: there is no
`planner-prod` to impersonate into.
