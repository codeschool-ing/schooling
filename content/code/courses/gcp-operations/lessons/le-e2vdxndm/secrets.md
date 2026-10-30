---
title: A secret, its versions, and who may read them
version: 1
---

**Secret Manager stores a secret as a container with numbered versions, and every read names a version.** The
secret `shop-db-password` holds no value by itself; version 1 holds the first password, version 2 the one that
replaced it, and `latest` is an alias for the newest enabled one. A version can be **enabled**, **disabled**
(kept, unreadable, and re-enabled in seconds) or **destroyed** (gone for good). Reading is an IAM permission on
the secret, `roles/secretmanager.secretAccessor`, granted to the service account that needs it and to nobody
else. **Nothing in this lesson reaches Secret Manager**, which has no emulator. What runs is a Terraform plan,
a container reading a mounted file, and a demonstration, with Terraform alone, of why the value must not pass
through Terraform at all.

The shop's secret, in `~/gcp/tf/secrets/main.tf`:

```hcl
# tf/secrets/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_pubsub_topic" "rotation" {
  name = "shop-secret-rotation"
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "shop-db-password"

  replication {
    user_managed {
      replicas {
        location = "southamerica-east1"
      }
    }
  }

  rotation {
    rotation_period    = "2592000s"
    next_rotation_time = "2026-12-01T09:00:00Z"
  }

  topics {
    name = google_pubsub_topic.rotation.id
  }
}

resource "google_secret_manager_secret_iam_member" "api_reads" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:shop-api@planner-dev.iam.gserviceaccount.com"
}
```

```
ana@laptop:~/gcp/tf/secrets$ terraform plan -input=false -no-color | grep -E "^  # |location|rotation_period|role|Plan:"
  # google_pubsub_topic.rotation will be created
  # google_secret_manager_secret.db_password will be created
                  + location = "southamerica-east1"
          + rotation_period    = "2592000s"
  # google_secret_manager_secret_iam_member.api_reads will be created
      + role      = "roles/secretmanager.secretAccessor"
Plan: 3 to add, 0 to change, 0 to destroy.
```

Three decisions are written in it:

- **Replication `user_managed` in São Paulo only.** The default, `auto`, lets Google keep copies wherever it
  chooses; a secret whose location is part of a compliance answer names its regions.
- **Rotation every 30 days** (`2592000s`), starting on 1 December. Secret Manager does not change the password: it
  publishes a message to the topic when rotation is due, and something the shop runs does the changing. The
  last section is about that something.
- **One accessor**, the API's own service account, on this one secret. Granting the role on the project instead
  would let the API read every secret in it, including the ones that are not its business.

**There is no `google_secret_manager_secret_version` here, and that is on purpose.** The version, the value
itself, is added outside Terraform, for the reason this lesson's third section shows:

```sh
printf '%s' "$NEW_PASSWORD" | gcloud secrets versions add shop-db-password --data-file=-
```

That command was not run: there is no Secret Manager here. The value comes from standard input, so it never
appears in the command line, the shell history or a file.

## What it costs

From the pricing page, read on 30 October 2026, per billing account each month: the first **6 active versions** are
free, then 0.000082192 USD per version per hour, about 0.06 USD a month each; the first **10,000 access
operations** are free, then 0.03 USD per 10,000; the first 3 rotation notifications are free, then 0.05 USD each.
A destroyed version costs nothing, a disabled one costs the same as an enabled one, which is a reason to destroy
old versions once nothing reads them.
