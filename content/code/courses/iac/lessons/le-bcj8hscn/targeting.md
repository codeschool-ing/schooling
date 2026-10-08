---
title: Targeting one resource, and why it is not a habit
version: 2
---

`-target` limits a plan to one address and whatever it depends on. It sounds like precision, a way
to apply just the part you are sure of. **Terraform's own warning calls it a tool for exceptional
situations**, and the reason is visible the first time you use it.

Ana has three changes waiting in `main.tf`. A new subnet `d` is needed today. A `Project` tag on
the VPC is housekeeping. And the batch instance moves to a bigger type, which she wants to do in
the evening, when no job is running:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index 15f2e65..ef2de0f 100644
--- a/main.tf
+++ b/main.tf
@@ -4,7 +4,7 @@ provider "aws" {
 
 resource "aws_vpc" "shop" {
   cidr_block = "10.20.0.0/16"
-  tags       = { Name = "shop", Owner = "ana" }
+  tags       = { Name = "shop", Owner = "ana", Project = "shop" }
 }
 
 resource "aws_subnet" "a" {
@@ -92,8 +92,15 @@ resource "aws_subnet" "c" {
 
 resource "aws_instance" "batch" {
   ami                    = "ami-785db401"
-  instance_type          = "t3.micro"
+  instance_type          = "t3.small"
   subnet_id              = aws_subnet.c.id
   vpc_security_group_ids = [aws_security_group.batch.id]
   tags                   = { Name = "batch" }
 }
+
+resource "aws_subnet" "d" {
+  vpc_id            = aws_vpc.shop.id
+  cidr_block        = "10.20.4.0/24"
+  availability_zone = "sa-east-1c"
+  tags              = { Name = "shop-d" }
+}
```

She asks for the subnet alone, with `terraform plan -target=aws_subnet.d`. The end of the plan:

```
  # aws_vpc.shop will be updated in-place
  ~ resource "aws_vpc" "shop" {
        id                                   = "vpc-bf1e4c53969619f51"
      ~ tags                                 = {
            "Name"    = "shop"
            "Owner"   = "ana"
          + "Project" = "shop"
        }
      ~ tags_all                             = {
          + "Project" = "shop"
            # (2 unchanged elements hidden)
        }
        # (19 unchanged attributes hidden)
    }

Plan: 1 to add, 1 to change, 0 to destroy.
╷
│ Warning: Resource targeting is in effect
│ 
│ You are creating a plan with the -target option, which means that the
│ result of this plan may not represent all of the changes requested by the
│ current configuration.
│ 
│ The -target option is not for routine use, and is provided only for
│ exceptional situations such as recovering from errors or mistakes, or when
│ Terraform specifically suggests to use it as part of an error message.
╵
```

The plan is for the subnet, which is above this excerpt, **and for the VPC's tag**, which she did
not ask for. Subnet `d` names `aws_vpc.shop.id`, so the VPC is a dependency, and a target brings
its dependencies along with whatever is pending on them. The instance resize, which nothing about
the subnet depends on, is left out. So the targeted plan is neither "only what I named" nor
"everything in the file": it is a slice of the graph, and the slice is decided by references you
may not have in mind.

She applies it anyway, since a tag is harmless, with `terraform apply -target=aws_subnet.d
-auto-approve`, and Terraform adds a second warning at the end:

```
aws_vpc.shop: Modifying... [id=vpc-bf1e4c53969619f51]
aws_vpc.shop: Modifications complete after 0s [id=vpc-bf1e4c53969619f51]
aws_subnet.d: Creating...
aws_subnet.d: Creation complete after 0s [id=subnet-d13af5782a2f49e4a]
╷
│ Warning: Resource targeting is in effect
│ 
│ You are creating a plan with the -target option, which means that the
│ result of this plan may not represent all of the changes requested by the
│ current configuration.
│ 
│ The -target option is not for routine use, and is provided only for
│ exceptional situations such as recovering from errors or mistakes, or when
│ Terraform specifically suggests to use it as part of an error message.
╵
╷
│ Warning: Applied changes may be incomplete
│ 
│ The plan was created with the -target option in effect, so some changes
│ requested in the configuration may have been ignored and the output values
│ may not be fully updated. Run the following command to verify that no other
│ changes are pending:
│     terraform plan
│ 
│ Note that the -target option is not suitable for routine use, and is
│ provided only for exceptional situations such as recovering from errors or
│ mistakes, or when Terraform specifically suggests to use it as part of an
│ error message.
╵

Apply complete! Resources: 1 added, 1 changed, 0 destroyed.
```

**"Applied changes may be incomplete" is the price.** The configuration in the file and the
infrastructure now disagree on purpose, and they will keep disagreeing until somebody runs a full
plan:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|Plan:"
  # aws_instance.batch will be updated in-place
Plan: 0 to add, 1 to change, 0 to destroy.
```

The resize is still pending. In this case Ana knows it is, and applies it in the evening with a
plain `terraform apply`. The danger is the day nobody knows: a targeted apply leaves changes
behind with no record that they were left, and the next person to run a full plan meets them
mixed into their own change, unreviewed.

## When it is the right tool

The warning names the cases, and they share a shape: **something is broken and the full plan
cannot help**.

- Recovering from a mistake, when one resource must be fixed before anything else can be planned
  sensibly, for example recreating a resource somebody deleted by hand while the rest of the plan
  is unsafe to apply yet.
- When Terraform itself suggests it in an error. A `for_each` over values that are only known
  after apply cannot be planned in one step, and the error says to apply the things those values
  come from first with `-target`.
- A large configuration in an incident, when a full plan takes long enough to matter and the fix
  is one resource.

Each of those is followed by a full plan and apply as soon as it is safe, so the drift `-target`
created lives for minutes. **If you reach for `-target` every week, the configuration is telling
you something**: two things that change on different schedules are sharing one state. Splitting
them, as lesson 8 did with the network and the application, gives each its own plan, and then a
full plan of either is the small, precise thing `-target` was pretending to be.
