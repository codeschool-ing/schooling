---
title: Create before destroy, and the name that gets in the way
version: 2
---

A replacement is two operations, and they have an order. **By default Terraform destroys the old
resource first and creates the new one after**, which is what `-/+ destroy and then create
replacement` says in so many words. Ana undoes the range edit with `git checkout main.tf`, makes
the image change from the last section again and applies it, keeping only the lines that report
progress. Then she commits it:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | grep -E "Destr|Creat"
aws_instance.web: Destroying... [id=i-f60bc6ad037ef6535]
aws_instance.web: Destruction complete after 10s
aws_instance.web: Creating...
aws_instance.web: Creation complete after 10s [id=i-2c8873777c5bd44a7]
```

Between `Destruction complete` and `Creation complete` there is no `web` instance at all. In the
lab that gap costs nothing, because moto runs no machine. On a real account it lasts as long as a
machine takes to boot and start serving, and the shop has no web server for all of it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 288\" role=\"img\" aria-label=\"Two timelines of the same replacement. In the first, the default, the old instance is destroyed, then for a while nothing exists, then the new one is created. In the second, with create_before_destroy, the new instance is created first, both exist for a moment, and only then is the old one destroyed.\"><defs><marker id=\"or-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the default: destroy, then create</text><text x=\"700.0\" y=\"34.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">-/+</text><rect x=\"20\" y=\"52\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">old instance</text><rect x=\"470\" y=\"52\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">new instance</text><rect x=\"262\" y=\"52\" width=\"196\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nothing exists</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">create_before_destroy: create, then destroy</text><text x=\"700.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">+/-</text><rect x=\"20\" y=\"158\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">old instance</text><rect x=\"300\" y=\"208\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">new instance</text><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><path d=\"M395 112 L700 112\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#or-ah-wire)\"></path><path d=\"M300 256 L300 262 L420 262 L420 256\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">both exist</text></svg>", "caption": "The same replacement in two orders. The default leaves a gap where neither exists; create_before_destroy closes it, and needs the two to coexist."}
```

## Turning the order around

`create_before_destroy` is a lifecycle argument, and lifecycle arguments live in a `lifecycle`
block inside the resource. They do not describe the resource to AWS; they tell Terraform how to
handle it. Ana adds one to `web` and commits it:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 1b1c85a..891f592 100644
--- a/main.tf
+++ b/main.tf
@@ -28,4 +28,8 @@ resource "aws_instance" "web" {
   instance_type = "t3.micro"
   subnet_id     = aws_subnet.a.id
   tags          = { Name = "web" }
+
+  lifecycle {
+    create_before_destroy = true
+  }
 }
```

and moves the instance back to the older image, which is another replacement:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | grep -E "then|Destr|Creat"
+/- create replacement and then destroy
aws_instance.web: Creating...
aws_instance.web: Creation complete after 10s [id=i-6deb06a6fc79f194d]
aws_instance.web (deposed object a7b0101c): Destroying... [id=i-2c8873777c5bd44a7]
aws_instance.web: Destruction complete after 10s
```

The symbol is now `+/-`, **create replacement and then destroy**. The new instance is created
first, and the old one is kept as a *deposed object*, an entry in the state that Terraform still
has to destroy, until the new one exists. If creating the replacement fails, the old one is never
touched.

## Two things that cannot exist twice

The price is that, for a moment, both exist. For an instance that is harmless. For anything whose
name must be unique, it is a collision. A security group's name must be unique within its VPC, so
Ana adds a group called `web`, with the same lifecycle setting, applies it and commits:

```
ana@laptop:~/shop/app$ git show --format= -U1
diff --git a/main.tf b/main.tf
index d5b3605..b6ac7a8 100644
--- a/main.tf
+++ b/main.tf
@@ -35 +35,11 @@ resource "aws_instance" "web" {
 }
+
+resource "aws_security_group" "web" {
+  name        = "web"
+  description = "web servers"
+  vpc_id      = aws_vpc.shop.id
+
+  lifecycle {
+    create_before_destroy = true
+  }
+}
```

Changing its description forces a replacement. Ana changes it to `the shop web servers` and runs
`terraform apply -auto-approve`, and the replacement is created first, under the name the old
group still holds. The end of what the apply prints:

```
Plan: 1 to add, 0 to change, 1 to destroy.
aws_security_group.web: Creating...
╷
│ Error: creating Security Group (web): operation error EC2: CreateSecurityGroup, https response error StatusCode: 400, RequestID: fDtrMqfbSnnexOm9LqLWCBSFqM2AssK7VE35L0t3S2csl1OKpO6x, api error InvalidGroup.Duplicate: The security group 'web' already exists
│ 
│   with aws_security_group.web,
│   on main.tf line 37, in resource "aws_security_group" "web":
│   37: resource "aws_security_group" "web" {
│ 
╵
```

AWS refused the second `web`, and nothing else happened: the old group is untouched, because
destroying it was the step after. **The fix is to stop fixing the name.** `name_prefix` gives
Terraform the start of the name and lets it add a unique suffix, so the old and the new group can
coexist for the moment the swap takes:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index b6ac7a8..0d2ae36 100644
--- a/main.tf
+++ b/main.tf
@@ -35,8 +35,8 @@ resource "aws_instance" "web" {
 }
 
 resource "aws_security_group" "web" {
-  name        = "web"
-  description = "web servers"
+  name_prefix = "web-"
+  description = "the shop web servers"
   vpc_id      = aws_vpc.shop.id
 
   lifecycle {
ana@laptop:~/shop/app$ terraform apply -auto-approve | grep -E "Destr|Creat"
aws_security_group.web: Creating...
aws_security_group.web: Creation complete after 0s [id=sg-7bd9ca389f1f7168d]
aws_security_group.web (deposed object 92705d6e): Destroying... [id=sg-873abb194bdcfb043]
aws_security_group.web: Destruction complete after 0s
ana@laptop:~/shop/app$ aws ec2 describe-security-groups --filters "Name=group-name,Values=web*" --query "SecurityGroups[].GroupName" --output text
web-1180f21630fc619080001bfd97
```

The order is the one the figure shows: create, then destroy the deposed object. The same applies
to anything with a unique name, a load balancer, an IAM role, a bucket; where the provider offers
a `name_prefix`, it is there for this. Ana commits the new name before going on.

**Why a security group is the usual case.** On a real account AWS refuses to delete a group that
is still attached to a running instance, so the default order would try to destroy first and fail.
The group in this lab is attached to nothing: moto lost an instance's list of groups when
the group was replaced, which AWS does not do, so the lesson leaves the attachment out rather
than quote a plan only moto would print. And one rule the documentation states: Terraform also
applies `create_before_destroy`, implicitly, to every resource the marked one depends on.
