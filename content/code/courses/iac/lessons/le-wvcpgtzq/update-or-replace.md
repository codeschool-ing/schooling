---
title: Updated in place, or replaced
version: 1
---

A common first picture of Terraform is that editing a line edits the thing. Change the subnet's
range in the file and Terraform changes the subnet's range in AWS. **Sometimes that is what
happens, and sometimes Terraform destroys the resource and builds a new one in its place**, with a
new id, a new address and nothing of the old one's contents. Which of the two it will do is
decided by the provider, argument by argument, and the plan tells you before anything moves.

This lesson works on a small configuration in `~/shop/app`: the shop's VPC, one subnet and the
`web` instance. Ana applied it once already, quietly, and committed it to git:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_instance" "web" {
  ami           = "ami-1e749f67"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.a.id
  tags          = { Name = "web" }
}
```

The AMI ids are two of the sample images moto ships, an older and a newer Ubuntu. They are the
same on every run of the lab, so they can be quoted; the `vpc-…` and `i-…` ids in the plans below
are invented afresh each time.

## A change AWS can make in place

The first edit renames the subnet. A tag is metadata AWS can rewrite on a running resource, so the
plan says `~`, **update in-place**:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 12d07df..4158f47 100644
--- a/main.tf
+++ b/main.tf
@@ -20,7 +20,7 @@ resource "aws_subnet" "a" {
   vpc_id            = aws_vpc.shop.id
   cidr_block        = "10.20.1.0/24"
   availability_zone = "sa-east-1a"
-  tags              = { Name = "shop-a" }
+  tags              = { Name = "shop-public-a" }
 }
 
 resource "aws_instance" "web" {
ana@laptop:~/shop/app$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-620a9a42c64d1b9c4]
aws_subnet.a: Refreshing state... [id=subnet-47e7ab7e19d97ade4]
aws_instance.web: Refreshing state... [id=i-f60bc6ad037ef6535]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_subnet.a will be updated in-place
  ~ resource "aws_subnet" "a" {
        id                                             = "subnet-47e7ab7e19d97ade4"
      ~ tags                                           = {
          ~ "Name" = "shop-a" -> "shop-public-a"
        }
      ~ tags_all                                       = {
          ~ "Name" = "shop-a" -> "shop-public-a"
        }
        # (20 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

The id on the second line of the resource is the same before and after, and the summary counts
one change and nothing added or destroyed. This is the cheap kind of change.

## A change that forces a replacement

The next edit moves `web` to the newer image. An instance cannot swap the disk it booted from
while it runs, so the provider marks `ami` as an argument that cannot be updated. The full plan
is long, nearly all of it attributes becoming `(known after apply)`, so this time `grep` keeps the
lines that decide anything:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 4158f47..1b1c85a 100644
--- a/main.tf
+++ b/main.tf
@@ -24,7 +24,7 @@ resource "aws_subnet" "a" {
 }
 
 resource "aws_instance" "web" {
-  ami           = "ami-1e749f67"
+  ami           = "ami-785db401"
   instance_type = "t3.micro"
   subnet_id     = aws_subnet.a.id
   tags          = { Name = "web" }
ana@laptop:~/shop/app$ terraform plan | grep -E "replace|Plan:"
-/+ destroy and then create replacement
  # aws_instance.web must be replaced
      ~ ami                                  = "ami-1e749f67" -> "ami-785db401" # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

**`-/+` is a replacement, and `# forces replacement` names the argument responsible.** That
comment is the most useful line in a long plan: it answers *why* before you have scrolled. The
summary will read `1 to add, 0 to change, 1 to destroy`, which is how a replacement is counted.

## A replacement that spreads

A replacement gives the new resource a new id, and everything that references the old id has to
follow. Ana tries the subnet's range instead:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 4158f47..a4ba35f 100644
--- a/main.tf
+++ b/main.tf
@@ -18,7 +18,7 @@ resource "aws_vpc" "shop" {
 
 resource "aws_subnet" "a" {
   vpc_id            = aws_vpc.shop.id
-  cidr_block        = "10.20.1.0/24"
+  cidr_block        = "10.20.3.0/24"
   availability_zone = "sa-east-1a"
   tags              = { Name = "shop-public-a" }
 }
ana@laptop:~/shop/app$ terraform plan | grep -E "replace|Plan:"
-/+ destroy and then create replacement
  # aws_instance.web must be replaced
      ~ subnet_id                            = "subnet-47e7ab7e19d97ade4" -> (known after apply) # forces replacement
  # aws_subnet.a must be replaced
      ~ cidr_block                                     = "10.20.1.0/24" -> "10.20.3.0/24" # forces replacement
Plan: 2 to add, 0 to change, 2 to destroy.
```

One edited line, two replacements. The subnet's range cannot change in place, so the subnet is
replaced; its new id is `(known after apply)`, and an instance cannot move to another subnet
either, so `subnet_id` forces the instance out too. **The comment on the instance points at
`subnet_id`, not at anything Ana typed**, and that is the shape to watch for in review: a
replacement whose cause is two resources away.

What decides in-place or replace is the cloud API, as the provider models it. Tags, an instance's
type and a security group's rules have update calls; an AMI, a subnet's range, a bucket's name
and a security group's description do not. You do not need to memorise the list. You need to read
`-/+` and `# forces replacement` every time they appear, because a replaced instance loses
whatever was on its disk, and lesson 9 builds a check that fails a pipeline on exactly that.
