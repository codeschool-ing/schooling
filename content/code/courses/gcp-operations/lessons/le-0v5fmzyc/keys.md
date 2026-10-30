---
title: Key rings, keys and customer-managed encryption
version: 1
---

**Cloud KMS organises keys as key rings, keys and key versions, and the ring and the key can never be deleted.** A
**key ring** is a named group in one location; a **key** is a named purpose inside it (`ENCRYPT_DECRYPT`, signing,
MAC); **key versions** are the actual key material, as `envelope.py`'s files were. Rings and keys are permanent
names: once created, they exist until the project does, so a typo in a key's name is a typo for ever. This is the
plan of the shop's key, and nothing here ran against Cloud KMS.

Everything Google stores is already encrypted at rest with keys Google manages. **CMEK, customer-managed
encryption keys**, means a service such as Cloud Storage encrypts your data with a key in *your* Cloud KMS
instead, so that you control who may use it and you can disable it. Write `~/gcp/tf/kms/main.tf`:

```hcl
# tf/kms/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_kms_key_ring" "shop" {
  name     = "shop"
  location = "southamerica-east1"
}

resource "google_kms_crypto_key" "orders" {
  name            = "orders"
  key_ring        = google_kms_key_ring.shop.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "google_storage_project_service_account" "gcs" {}

resource "google_kms_crypto_key_iam_member" "gcs_uses_key" {
  crypto_key_id = google_kms_crypto_key.orders.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

resource "google_storage_bucket" "order_exports" {
  name                        = "planner-dev-order-exports"
  location                    = "SOUTHAMERICA-EAST1"
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = google_kms_crypto_key.orders.id
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_uses_key]
}
```

```
ana@laptop:~/gcp/tf/kms$ terraform validate -no-color
Success! The configuration is valid.
ana@laptop:~/gcp/tf/kms$ terraform plan -input=false -no-color 2>&1 | grep -E "Error|^  # |Plan:" | head -6
  # google_kms_crypto_key.orders will be created
  # google_kms_key_ring.shop will be created
Plan: 2 to add, 0 to change, 0 to destroy.
Error: Error when reading or editing GCS service account not found: googleapi: Error 401: Invalid Credentials, authError
```

**The plan stopped with an error, and this is the first time in the course a plan has.** The configuration is
valid; what failed is `data "google_storage_project_service_account"`, which asks Google, at plan time, the e-mail
address of the project's Cloud Storage service agent. A **data source is read during the plan**, so a plan that
contains one needs a real answer, and the fake token gets `401 Invalid Credentials`. Resources are only proposed,
which is why every plan before this one worked; the first data source is where planning without an account ends.

## Reading the configuration

- **`location = "southamerica-east1"`**: a key used for CMEK must be in the same location as the data it
  protects. A São Paulo bucket needs a São Paulo key; a key in `global` will not do.
- **`rotation_period = "7776000s"`**, 90 days: a new primary version every quarter, with old versions kept, as the
  last section showed.
- **`protection_level = "SOFTWARE"`**: the key is protected by Google's software. `HSM` keeps it in a hardware
  security module, at a higher price, for when a compliance rule demands hardware.
- **`prevent_destroy = true`**: Terraform refuses to plan the key's destruction at all. A key cannot be deleted in
  Cloud KMS anyway; what Terraform's destroy would do is schedule every version for destruction, which is the
  last section's `rm`, for all the data at once.
- **The IAM member** lets the Cloud Storage service agent, Google's own account acting for Cloud Storage in your
  project, use the key. Without it, every write to the bucket fails, because Cloud Storage can no longer wrap the
  keys of the objects it stores. `depends_on` makes sure the permission exists before the bucket that needs it.

## What CMEK buys, and what it costs

Disabling the key makes every object in the bucket unreadable at once, by anybody, including Google; re-enabling
it brings them back. That is the control CMEK exists for, and it comes with the matching risk: **whoever can
disable or destroy the key can make the data disappear**, so `roles/cloudkms.admin` on the key ring is held by as
few people as `roles/owner` on the project.
