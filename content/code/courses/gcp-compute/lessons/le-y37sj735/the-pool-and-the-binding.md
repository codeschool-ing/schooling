---
title: The workload pool and the binding
version: 1
---

Workload Identity rests on one idea: **a Kubernetes service account in your cluster is given a
name that Google's IAM understands, and IAM is then told what that name may do.** No secret is
copied anywhere. The cluster vouches for the pod, and Google trusts the cluster.

## The pool

The name comes from the cluster's **workload pool**, and lesson 13's cluster already has one:

```hcl
  workload_identity_config {
    workload_pool = "planner-dev.svc.id.goog"
  }
```

A pool is always `PROJECT_ID.svc.id.goog`, one per project, shared by every cluster in it that has
Workload Identity on. Inside the pool, a Kubernetes service account is named by its namespace and
its own name: the `photos` service account in the namespace `shop` is
`planner-dev.svc.id.goog[shop/photos]`. Autopilot clusters, as lesson 14 said, come with the pool
already enabled.

On Standard the node pool also has to run GKE's metadata server, which is the
`workload_metadata_config` with `GKE_METADATA` that lesson 13's `pool.tf` set. Without it, a pod
asking for credentials reaches the node's own service account instead, which is the leak Workload
Identity is meant to close.

## The binding

There are two ways to give that name access. This section shows the older and still common one:
**the pod's identity is allowed to act as a Google service account**, and the service account is
given the access. Create a folder `wi` in `~/gcp` with this `main.tf`:

```hcl
# wi/main.tf
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

resource "google_service_account" "photos" {
  account_id   = "photos-reader"
  display_name = "Reads the shop's photos"
}

resource "google_service_account_iam_member" "photos_pod" {
  service_account_id = google_service_account.photos.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:planner-dev.svc.id.goog[shop/photos]"
}

resource "google_storage_bucket_iam_member" "photos_read" {
  bucket = "shop-photos"
  role   = "roles/storage.objectViewer"
  member = google_service_account.photos.member
}
```

Three resources, and each has one job: a Google service account; a binding **on that service
account** letting the Kubernetes identity use it, through `roles/iam.workloadIdentityUser`; and a
binding **on the bucket** letting the service account read. After `terraform init`:

```
ana@laptop:~/gcp/wi$ terraform plan -no-color | grep -E '^  #|account_id|email|member|role|^Plan'
  # google_service_account.photos will be created
      + account_id      = "photos-reader"
      + email           = "photos-reader@planner-dev.iam.gserviceaccount.com"
      + member          = "serviceAccount:photos-reader@planner-dev.iam.gserviceaccount.com"
  # google_service_account_iam_member.photos_pod will be created
  + resource "google_service_account_iam_member" "photos_pod" {
      + member             = "serviceAccount:planner-dev.svc.id.goog[shop/photos]"
      + role               = "roles/iam.workloadIdentityUser"
      + service_account_id = (known after apply)
  # google_storage_bucket_iam_member.photos_read will be created
  + resource "google_storage_bucket_iam_member" "photos_read" {
      + member = "serviceAccount:photos-reader@planner-dev.iam.gserviceaccount.com"
      + role   = "roles/storage.objectViewer"
Plan: 3 to add, 0 to change, 0 to destroy.
```

The provider worked out the service account's email from its `account_id` and the project, so the
plan shows it before anything exists. Two refusals are worth seeing once, because both are mistakes
people make. The member of a binding needs its kind in front:

```
ana@laptop:~/gcp/wi$ sed -i 's#"serviceAccount:planner-dev.svc.id.goog#"planner-dev.svc.id.goog#' main.tf
ana@laptop:~/gcp/wi$ terraform validate -no-color

Error: invalid value "planner-dev.svc.id.goog[shop/photos]" for member (IAM members must have one of the values outlined here: https://cloud.google.com/billing/docs/reference/rest/v1/Policy#Binding)

  with google_service_account_iam_member.photos_pod,
  on main.tf line 24, in resource "google_service_account_iam_member" "photos_pod":
  24:   member             = "planner-dev.svc.id.goog[shop/photos]"
```

And an `account_id` has to be between 6 and 30 characters:

```
ana@laptop:~/gcp/wi$ sed -i 's/"photos-reader"/"pr"/' main.tf
ana@laptop:~/gcp/wi$ terraform validate -no-color

Error: "account_id" ("pr") must be between 6 and 30 characters long

  with google_service_account.photos,
  on main.tf line 17, in resource "google_service_account" "photos":
  17:   account_id   = "pr"
```

## The other half, in the cluster

IAM now allows `[shop/photos]` to act as `photos-reader`, but the pod still has to say which Google
service account it means. That is an annotation on the Kubernetes service account, applied with
`kubectl` to a cluster this lab does not have. It is shown here from Google's documentation and was
not run:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: photos
  namespace: shop
  annotations:
    iam.gke.io/gcp-service-account: photos-reader@planner-dev.iam.gserviceaccount.com
```

A Deployment whose pods use `serviceAccountName: photos` in the namespace `shop` is then done. The
code inside does nothing special: Google's client libraries find credentials on their own, the
same way they would on a virtual machine.
