---
title: What a reviewer looks for
version: 1
---

A guard catches deletes. **The most dangerous change in this lesson deletes nothing**, and a
reviewer who reads only the summary line would wave it through. Ana edits two lines, one in the
SSH rule and one in the bucket policy:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index cc59f60..ef46b27 100644
--- a/main.tf
+++ b/main.tf
@@ -33,7 +33,7 @@ resource "aws_vpc_security_group_ingress_rule" "ssh" {
   ip_protocol       = "tcp"
   from_port         = 22
   to_port           = 22
-  cidr_ipv4         = "203.0.113.0/24"
+  cidr_ipv4         = "0.0.0.0/0"
 }
 
 resource "aws_instance" "web" {
@@ -62,7 +62,7 @@ resource "aws_s3_bucket" "assets" {
 
 data "aws_iam_policy_document" "assets_read" {
   statement {
-    actions   = ["s3:GetObject"]
+    actions   = ["s3:*"]
     resources = ["${aws_s3_bucket.assets.arn}/*"]
   }
 }
```

And the plan:

```
  # aws_iam_role_policy.web_assets will be updated in-place
  ~ resource "aws_iam_role_policy" "web_assets" {
        id          = "web:assets-read"
        name        = "assets-read"
      ~ policy      = jsonencode(
          ~ {
              ~ Statement = [
                  ~ {
                      ~ Action   = "s3:GetObject" -> "s3:*"
                        # (2 unchanged attributes hidden)
                    },
                ]
                # (1 unchanged attribute hidden)
            }
        )
        # (2 unchanged attributes hidden)
    }

  # aws_vpc_security_group_ingress_rule.ssh will be updated in-place
  ~ resource "aws_vpc_security_group_ingress_rule" "ssh" {
      ~ cidr_ipv4              = "203.0.113.0/24" -> "0.0.0.0/0"
        id                     = "sgr-b7e88ab5e67d5b3a9"
        # (8 unchanged attributes hidden)
    }

Plan: 0 to add, 2 to change, 0 to destroy.
```

Two `~`, zero destroys, and the guard would pass it. In practice the plan opens SSH on `web` to
every address on the internet, where it was open to one office range. It also lets the instance's
role do anything to the bucket's objects, delete them included, where it could only read them.
Nothing in the symbols ranks those above a tag change. **A widening is an update in place**, and only a person
who reads the values sees it.

Notice how much help the plan gives here. `cidr_ipv4` shows the old value and the new one side by
side, and the policy, which is a JSON string, is not shown as one long string replaced by another:
Terraform decodes it and shows the one key that changed, `Action`. That is the difference to read.

## The change that is not in `main.tf`

Some changes never appear in a resource block. Ana raises the version constraint on the `random`
provider, and the next plan refuses to run:

```
ana@laptop:~/shop$ git diff versions.tf
diff --git a/versions.tf b/versions.tf
index fd2116b..79bd152 100644
--- a/versions.tf
+++ b/versions.tf
@@ -6,7 +6,7 @@ terraform {
     }
     random = {
       source  = "hashicorp/random"
-      version = "~> 3.8.0"
+      version = "~> 3.9"
     }
   }
 }
ana@laptop:~/shop$ terraform plan
╷
│ Error: Inconsistent dependency lock file
│ 
│ The following dependency selections recorded in the lock file are
│ inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/random: locked version selection 3.8.1 doesn't match the updated version constraints "~> 3.9"
│ 
│ To update the locked dependency selections to match a changed
│ configuration, run:
│   terraform init -upgrade
╵
```

The lock file pins the exact version every run uses, and it stays pinned until somebody asks:

```
ana@laptop:~/shop$ terraform init -upgrade | grep -i random
- Finding hashicorp/random versions matching "~> 3.9"...
- Installing hashicorp/random v3.9.1...
- Installed hashicorp/random v3.9.1 (unauthenticated)
│   - hashicorp/random
ana@laptop:~/shop$ git diff .terraform.lock.hcl
diff --git a/.terraform.lock.hcl b/.terraform.lock.hcl
index 9a76a4c..ff14c76 100644
--- a/.terraform.lock.hcl
+++ b/.terraform.lock.hcl
@@ -10,9 +10,9 @@ provider "registry.terraform.io/hashicorp/aws" {
 }
 
 provider "registry.terraform.io/hashicorp/random" {
-  version     = "3.8.1"
-  constraints = "~> 3.8.0"
+  version     = "3.9.1"
+  constraints = "~> 3.9"
   hashes = [
-    "h1:Eexl06+6J+s75uD46+WnZtpJZYRVUMB0AiuPBifK6Jc=",
+    "h1:g40qr7yDmIpaur4SsK5BcOda3HSo1RJ6zHVMqN4EJ+0=",
   ]
 }
```

**The lock file's diff is the provider upgrade**, and it belongs in the same review as the code.
A new provider version can change defaults, add attributes, and occasionally turn an update into a
replacement on the next plan, so it is reviewed as a change of its own, not slipped in beside
another one. Two details here are the lab's: its mirror records only an `h1:` hash, where the
public registry would add `zh:` lines for every platform, and installs the provider
`(unauthenticated)`. Lesson 2 says why.

## A reviewer's checklist

None of this needs a tool. It needs a habit of reading the plan in the same order every time:

| look for | where it shows | why it matters |
| --- | --- | --- |
| a replacement of something that holds data | `-/+` and `# forces replacement` on a database, a volume, a bucket | the new one starts empty |
| any destroy you did not intend | `-` and `(because … is not in configuration)` | a renamed or deleted block destroys |
| a rule or a policy getting wider | `~` on `cidr_ipv4`, `0.0.0.0/0`, `Action`, `*` | it passes every count and every guard |
| addresses that shift | the same type destroyed at `[1]` and created at `[0]` | the index problem from lesson 4 |
| a provider or module version change | the diff of `.terraform.lock.hcl` | new behaviour arrives with no edit to a resource |
| counts that do not match the change you meant | the `Plan:` line | the change touched more than the diff suggests |

The last row is where to start. **Before reading a plan, say what you expect it to say**: "one
update, nothing else". Then the plan is a check of your understanding rather than a text you
skim, and a `2 to destroy` you did not predict is a question with an answer somewhere in the body.

Ana throws the two widening edits away with `git checkout`, and they are never applied.
