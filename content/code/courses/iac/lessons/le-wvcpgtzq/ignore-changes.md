---
title: ignore_changes, for an attribute somebody else owns
version: 1
---

Terraform assumes that it owns every argument it was given. If the real value differs from the
file, the file wins at the next apply. That is the cure for drift that lesson 1 described, and
most of the time it is exactly right. **Sometimes, though, a second system is supposed to change
an attribute**, and then Terraform undoing its work on every apply is the bug.

The shop's finance team runs a cost tool that walks the account and tags every instance it finds
with the cost centre it belongs to. It tagged `web` this morning. Ana's next plan, about something
else entirely, contains this:

```
ana@laptop:~/shop/app$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-620a9a42c64d1b9c4]
aws_subnet.a: Refreshing state... [id=subnet-47e7ab7e19d97ade4]
aws_security_group.web: Refreshing state... [id=sg-7bd9ca389f1f7168d]
aws_instance.web: Refreshing state... [id=i-6deb06a6fc79f194d]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_instance.web will be updated in-place
  ~ resource "aws_instance" "web" {
        id                                   = "i-6deb06a6fc79f194d"
      ~ tags                                 = {
          - "CostCenter" = "cc-4410" -> null
            "Name"       = "web"
        }
      ~ tags_all                             = {
          - "CostCenter" = "cc-4410" -> null
            # (1 unchanged element hidden)
        }
        # (39 unchanged attributes hidden)

        # (4 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

Terraform plans to delete the `CostCenter` tag, because the file says the tags are `Name = "web"`
and nothing else. Apply that and the cost tool puts it back tonight, and the next plan removes it
again. Two automated systems arguing over one value, every day, with every plan carrying a change
nobody asked for. The noise costs more than the tag: a reviewer who sees a tag change on every plan
stops reading tag changes.

## Telling Terraform to look away

`ignore_changes` lists attributes Terraform should leave alone after creating the resource. It
reads them, keeps them in the state, and stops comparing them with the file:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 0d2ae36..104bfa6 100644
--- a/main.tf
+++ b/main.tf
@@ -31,6 +31,7 @@ resource "aws_instance" "web" {
 
   lifecycle {
     create_before_destroy = true
+    ignore_changes        = [tags["CostCenter"]]
   }
 }
 
ana@laptop:~/shop/app$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-620a9a42c64d1b9c4]
aws_security_group.web: Refreshing state... [id=sg-7bd9ca389f1f7168d]
aws_subnet.a: Refreshing state... [id=subnet-47e7ab7e19d97ade4]
aws_instance.web: Refreshing state... [id=i-6deb06a6fc79f194d]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`tags["CostCenter"]` names one key of the map rather than the whole `tags` argument. Ana still owns
`Name`, and a change to it in the file is still applied; only the key the cost tool writes is
ignored.

**Ignore as little as possible.** `ignore_changes = [tags]` would also have silenced this plan, and
it would silence every future change Ana makes to the tags in the file, which would then look
applied and not be. `ignore_changes = all` exists too, and it turns a resource into something
Terraform creates once and never looks at again. Both are a way of hiding drift, which is the
opposite of what the tool is for.

## Where it belongs

The cases that justify it share a shape: another system owns the value, on purpose.

- An autoscaler changes an Auto Scaling group's `desired_capacity` all day; the file holds the
  starting value, and ignoring it stops every apply from resetting the fleet's size.
- A tag written by another tool, as here.
- An AMI chosen by a data source with `most_recent` (lesson 5): when a newer image appears, the
  plan replaces the instance. Ignoring `ami` keeps the running machine until somebody replaces it
  deliberately, with the next section's `-replace`.

What does not belong is a value a colleague changed by hand because the file was inconvenient.
That is drift with a permission slip. The right move there is to put the new value in the file, or
to put the old one back, and to talk to the colleague.

A last detail: `ignore_changes` only applies after creation. When the resource is created, or
replaced for some other reason, the ignored arguments are set from the file like any other.
