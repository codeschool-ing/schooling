---
title: Dependencies Terraform cannot see
version: 1
---

Terraform decides the order of operations from references. In lesson 2 the subnet named
`aws_vpc.shop.id`, so the VPC was created first, and nobody wrote that order down. **The graph is
built from expressions, so a dependency that is not in an expression does not exist for it**, and
everything with no path between it and something else is created at the same time, in parallel.

That is usually what you want, and it fails in one specific way: when a resource needs another
one through something Terraform does not read. In `~/shop/boot`, the `web` instance boots by
downloading a script from a bucket that the same configuration creates:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "boot" {
  bucket = "shop-boot-dev"
}

resource "aws_s3_object" "script" {
  bucket  = aws_s3_bucket.boot.bucket
  key     = "boot.sh"
  content = "#!/bin/sh\necho configuring the web server\n"
}

resource "aws_instance" "web" {
  ami           = "ami-1e749f67"
  instance_type = "t3.micro"
  user_data     = "#!/bin/sh\naws s3 cp s3://shop-boot-dev/boot.sh - | sh\n"
}
```

The object names the bucket through `aws_s3_bucket.boot.bucket`, a reference. The instance names it
inside a string, `s3://shop-boot-dev/boot.sh`, which is just text to Terraform. `terraform graph`
prints what Terraform knows, and it knows one edge:

```
ana@laptop:~/shop/boot$ terraform graph
digraph G {
  rankdir = "RL";
  node [shape = rect, fontname = "sans-serif"];
  "aws_instance.web" [label="aws_instance.web"];
  "aws_s3_bucket.boot" [label="aws_s3_bucket.boot"];
  "aws_s3_object.script" [label="aws_s3_object.script"];
  "aws_s3_object.script" -> "aws_s3_bucket.boot";
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three resources. Terraform sees one arrow, from the object to the bucket, because the object's configuration names the bucket. The instance's boot script downloads the object at boot, but it names it inside a string, so that dependency is drawn dashed: it exists in the world and not in Terraform's graph.\"><defs><marker id=\"hd-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hd-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"90\" width=\"190\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aws_s3_bucket.boot</text><rect x=\"290\" y=\"90\" width=\"190\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aws_s3_object.script</text><rect x=\"540\" y=\"90\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aws_instance.web</text><path d=\"M290 117 L232 117\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hd-ah-phosphor)\"></path><text x=\"261.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a reference</text><path d=\"M540 117 L482 117\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#hd-ah-amber)\"></path><text x=\"511.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a string at boot</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what Terraform orders: solid arrows only</text><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the dashed one is real and invisible to the graph</text></svg>", "caption": "A dependency Terraform cannot see: the boot script names the bucket in a string, so the graph has no arrow for it."}
```

So the apply starts the instance and the bucket together:

```
ana@laptop:~/shop/boot$ terraform apply -auto-approve | grep -E "Creat"
aws_instance.web: Creating...
aws_s3_bucket.boot: Creating...
aws_s3_bucket.boot: Creation complete after 1s [id=shop-boot-dev]
aws_s3_object.script: Creating...
aws_s3_object.script: Creation complete after 0s [id=shop-boot-dev/boot.sh]
aws_instance.web: Creation complete after 10s [id=i-bf711cb2e8c4a7945]
```

**The instance started before the bucket existed.** In the lab nothing boots, so nothing breaks.
On a real account the machine's first boot would race the upload. On the day the instance won,
it would start without its configuration: a failure that does not happen in testing and does
happen in production.

## `depends_on`

`depends_on` adds an edge by hand. It takes a list of resources, and the resource waits for all of
them:

```
ana@laptop:~/shop/boot$ git diff
diff --git a/main.tf b/main.tf
index 3cc6705..92a755c 100644
--- a/main.tf
+++ b/main.tf
@@ -16,4 +16,6 @@ resource "aws_instance" "web" {
   ami           = "ami-1e749f67"
   instance_type = "t3.micro"
   user_data     = "#!/bin/sh\naws s3 cp s3://shop-boot-dev/boot.sh - | sh\n"
+
+  depends_on = [aws_s3_object.script]
 }
ana@laptop:~/shop/boot$ terraform graph | grep -- "->"
  "aws_instance.web" -> "aws_s3_object.script";
  "aws_s3_object.script" -> "aws_s3_bucket.boot";
```

The graph now has the edge, and the instance is created after the object, which is after the
bucket. **That is all `depends_on` does, and it has a cost.** It says *wait* and not *why*: the
next person to read the file sees a dependency with no visible reason and either keeps it forever
or deletes it as clutter. Everything it lists has to finish before the resource starts, so a
long list turns a parallel apply into a queue. And on a data source it delays the read until apply
whenever the dependency has changes pending, which lesson 5 showed as `(known after apply)` where
nothing was really unknown.

## A reference is better

Here there was a reference to make. The instance does depend on the object's bucket and key, so it
can say so in the string:

```
ana@laptop:~/shop/boot$ git diff
diff --git a/main.tf b/main.tf
index 3cc6705..6b7b783 100644
--- a/main.tf
+++ b/main.tf
@@ -15,5 +15,5 @@ resource "aws_s3_object" "script" {
 resource "aws_instance" "web" {
   ami           = "ami-1e749f67"
   instance_type = "t3.micro"
-  user_data     = "#!/bin/sh\naws s3 cp s3://shop-boot-dev/boot.sh - | sh\n"
+  user_data     = "#!/bin/sh\naws s3 cp s3://${aws_s3_object.script.bucket}/${aws_s3_object.script.key} - | sh\n"
 }
ana@laptop:~/shop/boot$ terraform graph | grep -- "->"
  "aws_instance.web" -> "aws_s3_object.script";
  "aws_s3_object.script" -> "aws_s3_bucket.boot";
```

The same edge, and no `depends_on`. The dependency is now in the expression that has it, the
bucket's name is written once instead of twice, and renaming the bucket renames it in the boot
script too. Reach for `depends_on` when there is truly nothing to reference: a policy that must be
attached before a service can use a role, or a resource whose effect on another is invisible in
both of their arguments. When you do, leave a comment beside it saying what it waits for.
