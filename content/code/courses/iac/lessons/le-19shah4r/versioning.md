---
title: Versioning what you publish
version: 1
---

A version number is a message from the module's author to everybody who calls it. The convention
almost every module uses is **semantic versioning**: `MAJOR.MINOR.PATCH`. A patch fixes something
without changing what callers see, a minor version adds something callers may ignore, and a major
version says that some caller somewhere will have to change their code. The convention only works
if the author knows what counts as a change callers see, and for a Terraform module that is wider
than it looks.

The obvious part of the interface is the variables and the outputs. **The less obvious part is the
address of every resource inside**, because every caller's state records it. Ana learns this from a
change she thinks is a tidy-up. She plans to add public subnets one day, so the existing ones should
be called `private`, and she pushes the rename to a branch:

```
ana@laptop:~/src/terraform-aws-network$ git diff
diff --git a/main.tf b/main.tf
index cc2a8ee..f257067 100644
--- a/main.tf
+++ b/main.tf
@@ -4,7 +4,7 @@ resource "aws_vpc" "this" {
   tags                 = { Name = var.name }
 }
 
-resource "aws_subnet" "this" {
+resource "aws_subnet" "private" {
   for_each = var.subnets
 
   vpc_id            = aws_vpc.this.id
diff --git a/outputs.tf b/outputs.tf
index ba4964c..6078538 100644
--- a/outputs.tf
+++ b/outputs.tf
@@ -5,5 +5,5 @@ output "vpc_id" {
 
 output "subnet_ids" {
   description = "The id of each subnet, keyed like var.subnets."
-  value       = { for k, s in aws_subnet.this : k => s.id }
+  value       = { for k, s in aws_subnet.private : k => s.id }
 }
```

Two lines, no variable and no output touched. A caller who tries the branch gets this:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # module.analytics.aws_subnet.private["a"] will be created
  # module.analytics.aws_subnet.this["a"] will be destroyed
  # (because aws_subnet.this is not in configuration)
  # module.shop.aws_subnet.private["a"] will be created
  # module.shop.aws_subnet.private["c"] will be created
  # module.shop.aws_subnet.this["a"] will be destroyed
  # (because aws_subnet.this is not in configuration)
  # module.shop.aws_subnet.this["c"] will be destroyed
  # (because aws_subnet.this is not in configuration)
Plan: 3 to add, 0 to change, 3 to destroy.
```

**Three subnets destroyed and three created, in two networks, to change a name nobody outside the
module ever saw.** From the state's point of view `module.shop.aws_subnet.this["a"]` disappeared from
the configuration and `module.shop.aws_subnet.private["a"]` appeared, and lesson 9 taught what the
plan does with that. On these empty subnets it costs new ids. On subnets with machines in them, AWS
refuses to delete a subnet that still has network interfaces, so the apply would stop halfway; on a
database's subnet group it is an outage.

Inside the module, a `moved` block says the two addresses are the same object. Lesson 4 used it in a
root configuration; in a module it is written by the author once and saves every caller:

```hcl
# v1.1.0 renamed aws_subnet.this to aws_subnet.private.
moved {
  from = aws_subnet.this
  to   = aws_subnet.private
}
```

Merged into `main` and tagged `v1.1.0`, it plans like this for the same caller:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # module.analytics.aws_subnet.this["a"] has moved to module.analytics.aws_subnet.private["a"]
  # module.shop.aws_subnet.this["a"] has moved to module.shop.aws_subnet.private["a"]
  # module.shop.aws_subnet.this["c"] has moved to module.shop.aws_subnet.private["c"]
Plan: 0 to add, 0 to change, 0 to destroy.
```

And each entry in the full plan shows that the object is the one that already exists:

```
  # module.analytics.aws_subnet.this["a"] has moved to module.analytics.aws_subnet.private["a"]
    resource "aws_subnet" "private" {
        id                                             = "subnet-80ae92981cef43bdb"
        tags                                           = {
            "Name" = "analytics-a"
        }
        # (21 unchanged attributes hidden)
    }
```

**Zero to add, zero to destroy: a minor version, as it should be.** The `moved` block stays in the
module for as long as any caller might upgrade from a version before it, which in practice means
until the next major version, when the author may decide to stop carrying it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three tags of the network module in a row. v1.0.0 is the first release, with the subnets at aws_subnet.this. v1.1.0 is a minor version: the subnets are renamed and a moved block comes with them, so a caller's plan is 0 to add and 0 to destroy, where without the block it was 3 to add and 3 to destroy. v2.0.0 is a major version: the variable cidr is renamed to cidr_block, and every caller has to edit a line.\"><defs><marker id=\"vs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"130.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">first release</text><rect x=\"60\" y=\"52\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">v1.0.0</text><text x=\"370.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">minor</text><rect x=\"300\" y=\"52\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">v1.1.0</text><text x=\"610.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">major</text><rect x=\"540\" y=\"52\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">v2.0.0</text><path d=\"M202 70 L297 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vs-ah-wire)\"></path><path d=\"M442 70 L537 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vs-ah-wire)\"></path><text x=\"130.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a VPC and its subnets</text><text x=\"130.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aws_subnet.this</text><text x=\"130.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">callers pin the tag</text><text x=\"370.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">subnets renamed, plus a</text><text x=\"370.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">moved { }</text><text x=\"370.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">0 to add, 0 to destroy</text><text x=\"370.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">without the block:</text><text x=\"370.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">3 to add, 3 to destroy</text><text x=\"610.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a variable renamed</text><text x=\"610.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cidr → cidr_block</text><text x=\"610.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">every caller edits a line</text></svg>", "caption": "What each tag asks of the callers. The rename with a moved block is a minor version; the rename of a variable cannot be hidden, so it is a major one."}
```

## A change that cannot be hidden

Some changes need every caller to act. Ana renames the variable `cidr` to `cidr_block`, the name the
`aws_vpc` resource itself uses:

```
ana@laptop:~/src/terraform-aws-network$ git diff
diff --git a/main.tf b/main.tf
index f257067..4cf5fb6 100644
--- a/main.tf
+++ b/main.tf
@@ -1,5 +1,5 @@
 resource "aws_vpc" "this" {
-  cidr_block           = var.cidr
+  cidr_block           = var.cidr_block
   enable_dns_hostnames = true
   tags                 = { Name = var.name }
 }
diff --git a/variables.tf b/variables.tf
index 84ff13e..4924107 100644
--- a/variables.tf
+++ b/variables.tf
@@ -3,13 +3,13 @@ variable "name" {
   description = "Name tag of the VPC, and the prefix of every subnet's Name."
 }
 
-variable "cidr" {
+variable "cidr_block" {
   type        = string
   description = "The VPC's address range, such as 10.20.0.0/16."
 
   validation {
-    condition     = can(cidrhost(var.cidr, 0))
-    error_message = "The cidr must be an IPv4 range such as 10.20.0.0/16."
+    condition     = can(cidrhost(var.cidr_block, 0))
+    error_message = "cidr_block must be an IPv4 range such as 10.20.0.0/16."
   }
 }
 
ana@laptop:~/src/terraform-aws-network$ git tag v2.0.0
ana@laptop:~/src/terraform-aws-network$ git push -q origin main v2.0.0
```

There is no `moved` for a variable: a caller passing `cidr` is passing an argument that no longer
exists. So this is `v2.0.0`, and the tag comes with a note saying what to do:

```
# Changelog

## v2.0.0

BREAKING: the variable `cidr` is now `cidr_block`, the name the aws_vpc
resource uses. Rename the argument in every module block that calls this one.

## v1.1.0

The subnets are `aws_subnet.private` instead of `aws_subnet.this`. A `moved`
block carries existing subnets across, so upgrading plans no changes.

## v1.0.0

A VPC and a map of subnets.
```

A caller who bumps the `ref` finds out at `init`, before any plan:

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing modules...
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0 for analytics...
- analytics in .terraform/modules/analytics
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0 for shop...
- shop in .terraform/modules/shop
╷
│ Error: Unsupported argument
│ 
│   on analytics.tf line 5, in module "analytics":
│    5:   cidr = "10.30.0.0/16"
│ 
│ An argument named "cidr" is not expected here.
╵
╷
│ Error: Unsupported argument
│ 
│   on main.tf line 18, in module "shop":
│   18:   cidr = "10.20.0.0/16"
│ 
│ An argument named "cidr" is not expected here.
╵
```

**That is the good kind of breaking change: loud, early, and pointing at the line to edit.** Ana
renames the argument in both calls, and the upgrade costs nothing in AWS:

```
ana@laptop:~/shop$ git diff -U0 | grep "^[-+] "
-  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.1.0"
+  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0"
-  cidr = "10.30.0.0/16"
+  cidr_block = "10.30.0.0/16"
-  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.1.0"
+  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0"
-  cidr = "10.20.0.0/16"
+  cidr_block = "10.20.0.0/16"
ana@laptop:~/shop$ terraform init | grep Downloading
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0 for shop...
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0 for analytics...
ana@laptop:~/shop$ terraform plan | grep "No changes"
No changes. Your infrastructure matches the configuration.
```

The list of what is breaking for a module follows from all this: removing or renaming a variable or
an output, adding a variable with no default, narrowing a variable's type, changing a resource's
address without a `moved` block, and raising the Terraform or provider version the module requires.
A default whose new value changes existing resources belongs on the list too, even though no
caller's code fails: their next plan does something they did not ask for. Callers protect
themselves by pinning a tag and moving it on purpose, reading the changelog and the plan when they
do, which is what Ana did here at each step.
