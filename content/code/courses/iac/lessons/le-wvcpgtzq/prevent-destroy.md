---
title: prevent_destroy, and what it does not prevent
version: 1
---

Some resources are cheap to lose and some are not. A replaced instance comes back from its image;
a destroyed bucket takes every object in it along. **`prevent_destroy` is a lifecycle argument
that makes Terraform refuse any plan that would destroy the resource.** It is a seat belt for the
handful of things whose loss is a bad day: the bucket with the shop's product images, a database,
the state bucket that lesson 7 creates.

Ana keeps the shop's buckets in their own configuration, `~/shop/assets`. The assets bucket
carries the setting; the logs bucket, which the last section of this lesson is about, does not:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
```

## The refusal

A `terraform destroy` here plans the destruction of both buckets, prints that plan in full, and
stops before asking anything:

```
Plan: 0 to add, 0 to change, 2 to destroy.
╷
│ Error: Instance cannot be destroyed
│ 
│   on main.tf line 5:
│    5: resource "aws_s3_bucket" "assets" {
│ 
│ Resource aws_s3_bucket.assets has lifecycle.prevent_destroy set, but the
│ plan calls for this resource to be destroyed. To avoid this error and
│ continue with the plan, either disable lifecycle.prevent_destroy or reduce
│ the scope of the plan using the -target option.
╵
```

**The whole run is refused, not just the protected resource.** The logs bucket, which has no
protection, was not destroyed either: Terraform does not apply part of a plan it has rejected.

A rename is caught the same way, because a bucket's name cannot change in place. Ana tries
`shop-assets-prod`:

```
-/+ destroy and then create replacement

Terraform planned the following actions, but then encountered a problem:

  # aws_s3_bucket.assets must be replaced
-/+ resource "aws_s3_bucket" "assets" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      ~ arn                         = "arn:aws:s3:::shop-assets-dev" -> (known after apply)
      ~ bucket                      = "shop-assets-dev" -> "shop-assets-prod" # forces replacement
```

The same error follows, word for word. This is the case that makes the setting worth having: the
change looks like an edit to one string, the plan calls it a replacement, and a reviewer who reads
only the diff would approve it. `prevent_destroy` turns a replacement nobody noticed into a plan
that cannot run.

## What it does not stop

**The setting lives in the resource block, so it protects the resource only while the block is
in the file.** Delete the whole block and the protection goes with it:

```
ana@laptop:~/shop/assets$ git diff --stat
 main.tf | 8 --------
 1 file changed, 8 deletions(-)
ana@laptop:~/shop/assets$ terraform plan | grep -E "will|because|Plan:"
Terraform will perform the following actions:
  # aws_s3_bucket.assets will be destroyed
  # (because aws_s3_bucket.assets is not in configuration)
Plan: 0 to add, 0 to change, 1 to destroy.
```

Eight lines removed, and the plan destroys the bucket with no complaint, `because
aws_s3_bucket.assets is not in configuration`. A careless refactor, or a merge that drops a file,
gets past `prevent_destroy` without trying.

Nor does it reach outside Terraform. Somebody with the right permissions can still delete the
bucket from the console or the CLI; Terraform will notice on its next plan and offer to create an
empty one. The protections against that are on the AWS side: IAM permissions that deny deleting
the bucket, and versioning on the bucket so a deleted object can be brought back. Lesson 7 turns
versioning on for the state bucket for the same reason.

And the error message itself names the escape hatch: remove the setting, or narrow the plan with
`-target`. Both are deliberate edits somebody makes on purpose, which is the point. When the bucket
really has to go, the change that removes `prevent_destroy` is a commit of its own, reviewed on
its own, before the commit that removes the bucket.
