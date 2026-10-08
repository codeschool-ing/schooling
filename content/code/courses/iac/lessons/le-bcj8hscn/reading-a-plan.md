---
title: Reading a plan, symbol by symbol
version: 2
---

The plan in lesson 2 only created things, so every line began with `+` and the summary said it all.
That is the easy case, and it builds a bad habit: reading the last line and trusting it. **A plan
is a list of resources, each with exactly one action, and the summary is a count of those actions
that loses the reasons.** The reasons are in the body, and a review reads the body.

The shop's configuration for this lesson lives in `~/shop`, in two files. `versions.tf` names the
providers, `random` among them:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.0"
    }
  }
}
```

`main.tf` holds the network, `web` with its security group and two rules, and the role `web` runs
as:

```hcl
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

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-b" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "203.0.113.0/24"
}

resource "aws_instance" "web" {
  ami                    = "ami-1e749f67"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.a.id
  vpc_security_group_ids = [aws_security_group.web.id]
  tags                   = { Name = "web" }
}

resource "aws_iam_role" "web" {
  name = "web"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
```

Ana applied it once and committed it. To start from the same place, run these in `~/shop`; this
`.gitignore` keeps saved plans out of Git as well as the state:

```sh
terraform init
terraform apply -auto-approve
git init -q . && printf ".terraform/\n*.tfstate*\ntfplan*\n" > .gitignore
git add -A && git commit -qm 'the shop network, web and its role'
```

The two AMI ids are sample images that moto ships, and AWS has no images with those ids. On a real
account you would put a real image's id in their place, looked up with a data source as lesson 5
did.

To see all of them at once, Ana makes four edits in one go to the shop's configuration: she
renames subnet `a`, moves the `web` instance to a newer image, deletes subnet `b`, and adds an
assets bucket, a policy that lets `web` read it, and a password for a database that comes later:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index 5c3e89a..bda5b76 100644
--- a/main.tf
+++ b/main.tf
@@ -11,14 +11,7 @@ resource "aws_subnet" "a" {
   vpc_id            = aws_vpc.shop.id
   cidr_block        = "10.20.1.0/24"
   availability_zone = "sa-east-1a"
-  tags              = { Name = "shop-a" }
-}
-
-resource "aws_subnet" "b" {
-  vpc_id            = aws_vpc.shop.id
-  cidr_block        = "10.20.2.0/24"
-  availability_zone = "sa-east-1c"
-  tags              = { Name = "shop-b" }
+  tags              = { Name = "shop-public-a" }
 }
 
 resource "aws_security_group" "web" {
@@ -44,7 +37,7 @@ resource "aws_vpc_security_group_ingress_rule" "ssh" {
 }
 
 resource "aws_instance" "web" {
-  ami                    = "ami-1e749f67"
+  ami                    = "ami-785db401"
   instance_type          = "t3.micro"
   subnet_id              = aws_subnet.a.id
   vpc_security_group_ids = [aws_security_group.web.id]
@@ -62,3 +55,24 @@ resource "aws_iam_role" "web" {
     }]
   })
 }
+
+resource "aws_s3_bucket" "assets" {
+  bucket_prefix = "shop-assets-"
+}
+
+data "aws_iam_policy_document" "assets_read" {
+  statement {
+    actions   = ["s3:GetObject"]
+    resources = ["${aws_s3_bucket.assets.arn}/*"]
+  }
+}
+
+resource "aws_iam_role_policy" "web_assets" {
+  name   = "assets-read"
+  role   = aws_iam_role.web.id
+  policy = data.aws_iam_policy_document.assets_read.json
+}
+
+resource "random_password" "db" {
+  length = 24
+}
```

`terraform plan` opens with a legend that lists only the symbols this plan uses. This one uses five:

```
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
  ~ update in-place
  - destroy
-/+ destroy and then create replacement
 <= read (data resources)
```

| symbol | what Terraform will do | in this plan |
| --- | --- | --- |
| `+` | create a new object | the bucket, the role policy, the password |
| `~` | change the object where it is | subnet `a`, whose tag changes |
| `-` | destroy the object | subnet `b` |
| `-/+` | destroy it, then create a replacement | the `web` instance |
| `<=` | read a data source | the policy document |

The body is sorted by address, data sources first, and **every resource opens with a comment line
saying what will happen to it and, when it is not obvious, why**. The replacement says so twice,
in the comment and next to the argument responsible:

```
  # aws_instance.web must be replaced
-/+ resource "aws_instance" "web" {
      ~ ami                                  = "ami-1e749f67" -> "ami-785db401" # forces replacement
```

`# forces replacement` is the line to find. The AMI cannot change on a running instance, so the
provider declares that argument immutable, and everything else in the block is a consequence:
the new instance will have a new id, a new private address and a new root volume. Lesson 6 is
about which arguments do this and how to change the order to `+/-`.

The destroy carries its reason too:

```
  # aws_subnet.b will be destroyed
  # (because aws_subnet.b is not in configuration)
  - resource "aws_subnet" "b" {
```

**Deleting a block from the file is how you ask Terraform to destroy something**, and the plan
says that is what happened. The same line appears when a resource was renamed rather than deleted,
which is the case that surprises people; lesson 4 showed `moved` blocks for it.

The data source has a different verb:

```
  # data.aws_iam_policy_document.assets_read will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "assets_read" {
      + id            = (known after apply)
      + json          = (known after apply)
      + minified_json = (known after apply)

      + statement {
          + actions   = [
              + "s3:GetObject",
            ]
          + resources = [
              + (known after apply),
            ]
        }
    }
```

A data source is normally read while planning, and you never see it in the body. This one names
the bucket's ARN, which does not exist until the bucket does, so the read is put off to the apply
and **`(known after apply)` spreads to everything built from it**: the policy text, and the role
policy that uses it. That marker means a value nobody can know until the apply; lesson 2 met it
on ids. Lesson 5 explains when a read is deferred.

A different marker hides a value that does exist:

```
  # random_password.db will be created
  + resource "random_password" "db" {
      + bcrypt_hash = (sensitive value)
      + id          = (known after apply)
      + length      = 24
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + numeric     = true
      + result      = (sensitive value)
      + special     = true
      + upper       = true
    }
```

`(sensitive value)` means the provider flagged the attribute as secret, so the plan does not print
it. It does not mean the value is kept anywhere safer, and lesson 12 shows exactly where it ends
up.

Then the summary:

```
Plan: 4 to add, 1 to change, 2 to destroy.
```

Count it against the body. The bucket, the role policy and the password are three adds; the new
`web` instance is the fourth. Subnet `b` is one destroy; the old `web` instance is the second.
**A replacement is counted twice, once in each column**, and the data source is not counted at
all. So `2 to destroy` cannot tell you whether two things are going away or one thing is being
rebuilt. Only the `#` lines can.
