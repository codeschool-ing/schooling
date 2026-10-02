---
title: Letting go of a resource without destroying it
version: 1
---

Sometimes a resource should leave a configuration and stay in the world. The data team is taking
over the shop's logs: they will manage `shop-logs-dev` from their own configuration, and lesson 8
shows how they will import it there. Ana's configuration has to stop managing the bucket **without
deleting it**, and deleting the block is the obvious move and the wrong one:

```
ana@laptop:~/shop/assets$ terraform plan | grep -E "will|because|Plan:"
Terraform will perform the following actions:
  # aws_s3_bucket.logs will be destroyed
  # (because aws_s3_bucket.logs is not in configuration)
Plan: 0 to add, 0 to change, 1 to destroy.
```

To Terraform, a resource that is in the state and missing from the file is a resource you want
gone. That is the same mechanism that bypassed `prevent_destroy` four sections ago, and here it
would delete a bucket another team is about to depend on.

## The `removed` block

Terraform 1.7 added a block that says the other thing. It names the address that is leaving, and
its own `lifecycle` says whether the real object goes with it:

```
ana@laptop:~/shop/assets$ git diff
diff --git a/main.tf b/main.tf
index b16c15f..111c62c 100644
--- a/main.tf
+++ b/main.tf
@@ -10,6 +10,10 @@ resource "aws_s3_bucket" "assets" {
   }
 }
 
-resource "aws_s3_bucket" "logs" {
-  bucket = "shop-logs-dev"
+removed {
+  from = aws_s3_bucket.logs
+
+  lifecycle {
+    destroy = false
+  }
 }
```

The plan that follows has a symbol of its own:

```
ana@laptop:~/shop/assets$ terraform plan
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:

Terraform will perform the following actions:

 # aws_s3_bucket.logs will no longer be managed by Terraform, but will not be destroyed
 # (destroy = false is set in the configuration)
 . resource "aws_s3_bucket" "logs" {
        id                          = "shop-logs-dev"
        # (15 unchanged attributes hidden)

        # (2 unchanged blocks hidden)
    }

Plan: 0 to add, 0 to change, 0 to destroy.
╷
│ Warning: Some objects will no longer be managed by Terraform
│ 
│ If you apply this plan, Terraform will discard its tracking information for
│ the following objects, but it will not delete them:
│  - aws_s3_bucket.logs
│ 
│ After applying this plan, Terraform will no longer manage these objects.
│ You will need to import them into Terraform to manage them again.
╵
```

**`will no longer be managed by Terraform, but will not be destroyed`**, with a dot instead of a
minus, and a summary of zero changes, because nothing in AWS will change. The warning says the
one consequence plainly: from now on Terraform has forgotten the bucket, and managing it again
means importing it.

Ana applies and checks both sides:

```
ana@laptop:~/shop/assets$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/assets$ terraform state list
aws_s3_bucket.assets
ana@laptop:~/shop/assets$ aws s3 ls
2026-10-02 06:53:18 shop-logs-dev
2026-10-02 06:53:18 shop-assets-dev
```

The state lists only the assets bucket; AWS still has both. That is the whole operation: one
entry taken out of the state, and nothing touched in the cloud.

## Why a block and not a command

`terraform state rm` does the same to the state, and lesson 7 shows it. The difference is the one
that separated `-replace` from `taint` two sections ago, in the other direction: **`state
rm` is a command somebody runs on the shared state, and nobody reviews it.** A `removed` block is a
change to the file. It goes through a pull request, shows up in the plan as exactly what it is,
and works the same for every colleague and every pipeline that applies the configuration
afterwards.

Once applied, the block has done its job, and it can be deleted in a later commit. Leaving it does
no harm, and it records in the file why the bucket stopped being there.
