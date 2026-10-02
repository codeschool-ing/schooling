---
title: Providers beyond AWS, and their versions
version: 1
---

It is easy to come away from the first sections believing a provider means a cloud. **A provider
is any plugin that gives Terraform resource types to manage**, and several of the most used ones
never talk to a cloud at all. The shop needs a bucket for its images, and a bucket's name must be
unique across every AWS account in the world, so Ana gives it a random suffix. Two providers join
`aws` in `versions.tf`:

```
ana@laptop:~/shop$ git diff versions.tf
diff --git a/versions.tf b/versions.tf
index 208a27a..1cceb9e 100644
--- a/versions.tf
+++ b/versions.tf
@@ -6,5 +6,13 @@ terraform {
       source  = "hashicorp/aws"
       version = "~> 6.0"
     }
+    random = {
+      source  = "hashicorp/random"
+      version = "~> 3.8.0"
+    }
+    local = {
+      source  = "hashicorp/local"
+      version = "~> 2.9"
+    }
   }
 }
```

The resources that use them go in a file of their own:

```hcl
resource "random_id" "bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-${random_id.bucket.hex}"

  tags = {
    Environment = var.environment
  }
}

resource "local_file" "network_env" {
  filename = "${path.module}/network.env"
  content  = <<-EOT
    VPC_ID=${aws_vpc.shop.id}
    SUBNET_ID=${aws_subnet.web_a.id}
    BUCKET=${aws_s3_bucket.assets.bucket}
  EOT
}
```

`random_id` comes from **random**, and it calls nothing: the provider draws four random bytes
itself and keeps them in the state. That is the point of it. A suffix drawn on every plan would
rename the bucket on every plan; this one is drawn once, at creation, and stays the same until the
resource is destroyed. `local_file` comes from **local**, and it writes a file on the machine
Terraform runs on: three lines a shell script can `source`, with ids only AWS knew a moment
before.

A new provider needs installing before anything else runs, and Terraform says so before it plans
anything:

```
ana@laptop:~/shop$ terraform plan
╷
│ Error: Inconsistent dependency lock file
│ 
│ The following dependency selections recorded in the lock file are
│ inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/local: required by this configuration but no version is selected
│   - provider registry.terraform.io/hashicorp/random: required by this configuration but no version is selected
│ 
│ To update the locked dependency selections to match a changed
│ configuration, run:
│   terraform init -upgrade
╵
```

The message suggests `init -upgrade`, but a plain `init` is enough to add a provider, and it keeps
`aws` exactly where the lock file holds it:

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/random versions matching "~> 3.8.0"...
- Finding hashicorp/local versions matching "~> 2.9"...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/random v3.8.1...
- Installed hashicorp/random v3.8.1 (unauthenticated)
- Installing hashicorp/local v2.9.1...
- Installed hashicorp/local v2.9.1 (unauthenticated)
- Using previously-installed hashicorp/aws v6.67.0
```

The apply creates the three in the order their references demand: the suffix, then the bucket
named after it, then the file that names the bucket.

```
Plan: 3 to add, 0 to change, 0 to destroy.
random_id.bucket: Creating...
random_id.bucket: Creation complete after 0s [id=LvIL9g]
aws_s3_bucket.assets: Creating...
aws_s3_bucket.assets: Creation complete after 0s [id=shop-assets-2ef20bf6]
local_file.network_env: Creating...
local_file.network_env: Creation complete after 0s [id=7e6c26ee85afdb7031fa9435305563d6b82f4623]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

```
ana@laptop:~/shop$ cat network.env
VPC_ID=vpc-7327c901412b20229
SUBNET_ID=subnet-246685d4ada451bad
BUCKET=shop-assets-2ef20bf6
ana@laptop:~/shop$ terraform providers

Providers required by configuration:
.
├── provider[registry.terraform.io/hashicorp/aws] ~> 6.0
├── provider[registry.terraform.io/hashicorp/random] ~> 3.8.0
└── provider[registry.terraform.io/hashicorp/local] ~> 2.9

Providers required by state:

    provider[registry.terraform.io/hashicorp/random]

    provider[registry.terraform.io/hashicorp/aws]

    provider[registry.terraform.io/hashicorp/local]
```

`terraform providers` lists who asked for what, from the configuration and from the state. Each of
those three is a separate program, installed by `init`, and Terraform talks to each one the same
way, whatever it does with the request.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 260\" role=\"img\" aria-label=\"Terraform in the middle of three providers. Terraform reads the .tf files and keeps the state. It talks to each provider, a separate program installed by init. The aws provider calls the AWS API, which in this lab is moto. The random provider calls nothing: it computes its values itself. The local provider reads and writes files on the laptop.\"><defs><marker id=\"pl-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"pl-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"36\" width=\"170\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">terraform</text><text x=\"105.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads the .tf files</text><text x=\"105.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">plans, keeps the state</text><text x=\"105.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">knows no resource type</text><rect x=\"280\" y=\"48\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hashicorp/aws</text><path d=\"M190 70 L278 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-phosphor)\"></path><rect x=\"550\" y=\"48\" width=\"190\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the AWS API</text><text x=\"645.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(moto, in this lab)</text><path d=\"M460 70 L548 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-wire)\"></path><rect x=\"280\" y=\"114\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hashicorp/random</text><path d=\"M190 136 L278 136\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-phosphor)\"></path><rect x=\"550\" y=\"114\" width=\"190\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">nothing outside</text><text x=\"645.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">computes values itself</text><path d=\"M460 136 L548 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-wire)\"></path><rect x=\"280\" y=\"180\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hashicorp/local</text><path d=\"M190 202 L278 202\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-phosphor)\"></path><rect x=\"550\" y=\"180\" width=\"190\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the laptop's disk</text><text x=\"645.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reads and writes files</text><path d=\"M460 202 L548 202\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-wire)\"></path><text x=\"370.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">installed by init, one program each</text><text x=\"645.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what each one talks to</text></svg>", "caption": "Terraform knows how to plan and keep a state; every resource type comes from a provider, and a provider can talk to a cloud, to nothing, or to your own disk."}
```

## Version constraints

**A constraint is a range, and the lock file picks one version inside it.** Four forms cover
almost every case:

| constraint | accepts |
| --- | --- |
| `= 3.8.1` | exactly 3.8.1 |
| `>= 3.8` | 3.8 or anything newer, including 4.x and later |
| `~> 3.8` | 3.8 or newer, but not 4.0: the last number written may grow |
| `~> 3.8.0` | 3.8.0 or newer, but not 3.9: only the patch may grow |

Ana wrote `~> 3.8.0` for random, and the lab's mirror holds both 3.8.1 and 3.9.1, so init chose
3.8.1, the newest version the range allowed:

```
ana@laptop:~/shop$ grep -A2 "^provider" .terraform.lock.hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.67.0"
  constraints = "~> 6.0"
--
provider "registry.terraform.io/hashicorp/local" {
  version     = "2.9.1"
  constraints = "~> 2.9"
--
provider "registry.terraform.io/hashicorp/random" {
  version     = "3.8.1"
  constraints = "~> 3.8.0"
```

Then she widens the range to `~> 3.9`. **The lock file still says 3.8.1, which the new range
excludes, and Terraform refuses to guess** which of the two she meant:

```
ana@laptop:~/shop$ grep -A1 "hashicorp/random" versions.tf
      source  = "hashicorp/random"
      version = "~> 3.9"
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

**`init -upgrade` is the deliberate step**: it ignores what is locked, chooses again within every
constraint, and rewrites the lock file, which then shows up in `git diff` for a reviewer to see.

```
ana@laptop:~/shop$ terraform init -upgrade
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/local versions matching "~> 2.9"...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Finding hashicorp/random versions matching "~> 3.9"...
- Using previously-installed hashicorp/local v2.9.1
- Using previously-installed hashicorp/aws v6.67.0
- Installing hashicorp/random v3.9.1...
- Installed hashicorp/random v3.9.1 (unauthenticated)
```

```
ana@laptop:~/shop$ grep -A1 "hashicorp/random" .terraform.lock.hcl
provider "registry.terraform.io/hashicorp/random" {
  version     = "3.9.1"
```

The usual arrangement is a `~>` on the major version in the configuration, `~> 6.0` for AWS, and
the lock file pinning the exact release. A new major version of a provider is allowed to rename
or remove things, so moving to one is a decision you make after reading its upgrade guide, not
something that happens on a colleague's `init`.

One more provider idea, only named here: a configuration can configure the same provider twice,
for instance AWS in two regions, by giving the second `provider` block an `alias` and naming it
from a resource with `provider = aws.us`. Lesson 4 uses it.
