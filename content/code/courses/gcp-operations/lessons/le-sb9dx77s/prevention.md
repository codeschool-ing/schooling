---
title: When there is no version to go back to
version: 1
---

**If the state is gone and no version of it survives, the resources still exist and Terraform no longer
knows them.** A plan then proposes to create everything, and an apply would create duplicates or fail on
names already taken. The way back is to tell Terraform, resource by resource, which real object each one
is: an **import**.

The quickest way to see that situation without destroying anything is a backend with a prefix nobody has
used. Change `backend.tf` so that the state lives somewhere new, as a typo in the prefix would do:

```hcl
# tf/shop/backend.tf
terraform {
  backend "gcs" {
    bucket                  = "planner-dev-tfstate"
    prefix                  = "shop-v2"
    storage_custom_endpoint = "http://localhost:4443/storage/v1/"
  }
}
```

```
ana@laptop:~/gcp/tf/shop$ terraform init -reconfigure -input=false -no-color | grep -E "Successfully"
Successfully configured the backend "gcs"! Terraform will automatically
```

The state under `shop-v2` is empty; the topic and the price list are where they were. An `import` block
names a resource address and the real object's id, and the plan reads the object and adopts it:

```hcl
# tf/shop/imports.tf
import {
  to = google_pubsub_topic.orders
  id = "projects/planner-dev/topics/shop-orders"
}
```

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | grep -E "^  # |^Plan:|import"
google_pubsub_topic.orders: Preparing import... [id=projects/planner-dev/topics/shop-orders]
  # google_pubsub_topic.orders will be updated in-place
  # (imported from "projects/planner-dev/topics/shop-orders")
  # google_storage_bucket_object.prices will be created
Plan: 1 to import, 1 to add, 1 to change, 0 to destroy.
```

Three lines to read. The topic is **imported**: the plan found it by its id and will record it in the
state. It is also **updated in place**, and the next command shows why:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | sed -n "/pubsub_topic.orders will be/,/^    }/p" | grep -E "^ +[~+-] "
  ~ resource "google_pubsub_topic" "orders" {
      ~ terraform_labels           = {
          + "goog-terraform-provisioned" = "true"
```

The topic was created by Terraform, but the label the provider adds was never stored by the emulator, so
the import finds it missing and adds it. Against Google the label would be there and the line would not
appear. **And the price list will be created**, because the google provider cannot import a bucket object
at all: no `import` block is possible for it, and the plan's only proposal is to write it again. Here that
is harmless, since the content is the same. For a resource whose creation is not harmless, a resource type
with no import is a reason to keep the state's versions rather than a detail.

## Four habits that keep this lesson theoretical

1. **Versioning on the state bucket**, always, and a lifecycle rule rather than no history.
2. **No local state for anything shared.** A configuration starts with its backend, not after its first
   apply.
3. **One prefix per configuration, written once**, and reviewed like code when it changes: a changed
   prefix is a new, empty state that looks exactly like a working one until the plan says "create".
4. **A plan that proposes to create things that exist is a stop sign.** It means Terraform has lost track
   of them, and applying it turns a bookkeeping problem into a production one.
