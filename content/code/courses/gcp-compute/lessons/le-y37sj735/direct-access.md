---
title: Direct access, without a Google service account
version: 1
---

Section 03 used two identities: the Kubernetes service account, and a Google service account it was
allowed to act as. **Google now also lets the Kubernetes identity itself be granted roles directly,
with no Google service account in between.** One identity, one binding, and nothing to impersonate.

## The principal

In a direct grant, the member is not `serviceAccount:` anything. It is a **principal identifier**
that names the Kubernetes service account inside the workload pool, and it carries the project's
**number**, the twelve digits Google assigns, rather than its id:

```
principal://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/planner-dev.svc.id.goog/subject/ns/shop/sa/photos
```

Read it from the right: the Kubernetes service account `photos`, in the namespace `shop`, in the
pool `planner-dev.svc.id.goog`. A variant ending in a namespace instead of a service account, or
naming a principal set, grants something to every pod that matches, which is how a whole namespace
is given one role at once.

## Writing it down

Add a file `direct.tf` to the `wi` folder of section 03. **`planner-dev` has no project number in
this lab, because it does not exist at Google**, so the number is a variable with twelve zeros as a
stand-in for the real one:

```hcl
# wi/direct.tf
variable "project_number" {
  type    = string
  default = "000000000000"
}

resource "google_storage_bucket_iam_member" "photos_direct" {
  bucket = "shop-photos"
  role   = "roles/storage.objectViewer"
  member = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/planner-dev.svc.id.goog/subject/ns/shop/sa/photos"
}
```

Plan, filtered to the new binding:

```
ana@laptop:~/gcp/wi$ terraform plan -no-color | grep -E '^  # .*direct|principal|^Plan'
  # google_storage_bucket_iam_member.photos_direct will be created
      + member = "principal://iam.googleapis.com/projects/000000000000/locations/global/workloadIdentityPools/planner-dev.svc.id.goog/subject/ns/shop/sa/photos"
Plan: 4 to add, 0 to change, 0 to destroy.
```

That one resource does what section 03 needed three for. On a real project you would set the
variable from the project's number, which `gcloud projects describe planner-dev` prints and which
needs an account; it was not run here.

## Which to use

Direct access is the simpler arrangement and Google's documentation now presents it first. The
service-account way remains, and is still the right one in two cases:

- **a Google API that does not accept principal identifiers yet.** Google keeps a list of products
  that support the direct form and of the limitations, and a binding on a resource outside it has
  to go through a service account;
- **the same identity is needed outside the cluster too**, by a Cloud Run service or a job on a
  virtual machine, where acting as one named Google service account keeps a single place to grant
  and revoke.

For the shop's `photos`, which only reads one bucket, the direct grant is enough. Either way the
change from section 01 is the same, and it is the one that matters: **no key exists**, so there is
nothing to leak, nothing to rotate and nothing that outlives the pod's need for it.
