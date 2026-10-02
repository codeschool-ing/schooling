---
title: Moving a resource from one state to another
version: 1
---

The split moved three entries with commands nobody reviewed. That was acceptable once, on a quiet
afternoon, with Ana doing both halves. **A move between two teams' states is a change to two
configurations, and it belongs in their files** where a pull request can show it. Lesson 6
promised one: the data team is taking over `shop-logs-dev`, which today sits in the app's state.

The first thing to know is what does *not* work. Lesson 4's `moved` block renames an address
inside one state; it has no way to name another state, so it cannot carry a resource across. A
move between states is always two operations, one in each configuration: **the old owner lets go,
and the new owner imports**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A sequence in three steps, left to right, for the bucket shop-logs-dev. Step 1: the app state manages it. Step 2: after the app applies a removed block with destroy = false, no state manages it. Step 3: after the data team applies an import block, the data state manages it. Underneath, the bucket in AWS is the same object throughout and is never touched.\"><defs><marker id=\"mv-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mv-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. before</text><rect x=\"20\" y=\"50\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app/terraform.tfstate</text><text x=\"120.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.logs</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. after removed</text><rect x=\"260\" y=\"50\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">in no state</text><text x=\"600.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3. after import</text><rect x=\"500\" y=\"50\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">data/terraform.tfstate</text><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.logs</text><path d=\"M222 90 L258 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-amber)\"></path><path d=\"M462 90 L498 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-phosphor)\"></path><text x=\"240.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">removed</text><text x=\"480.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">import</text><rect x=\"20\" y=\"180\" width=\"680\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in AWS: the same bucket all along</text><text x=\"360.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-logs-dev</text><text x=\"360.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">never in two states at once</text></svg>", "caption": "Moving a resource between states: let go in one, then import in the other. The bucket itself never moves."}
```

## First, let go

In the app, the bucket's block is deleted, and a `removed` block from lesson 6 says that deleting
it means "stop managing", not "destroy":

```hcl
removed {
  from = aws_s3_bucket.logs

  lifecycle {
    destroy = false
  }
}
```

```
ana@laptop:~/shop/app$ git diff main.tf
diff --git a/app/main.tf b/app/main.tf
index 72b1aa9..4b7913c 100644
--- a/app/main.tf
+++ b/app/main.tf
@@ -29,7 +29,3 @@ resource "aws_security_group" "web" {
 resource "aws_s3_bucket" "assets" {
   bucket = "shop-assets-dev"
 }
-
-resource "aws_s3_bucket" "logs" {
-  bucket = "shop-logs-dev"
-}
```

The plan is the one lesson 6 showed, a dot instead of a minus:

```
 # aws_s3_bucket.logs will no longer be managed by Terraform, but will not be destroyed
 # (destroy = false is set in the configuration)
 . resource "aws_s3_bucket" "logs" {
        id                          = "shop-logs-dev"
        tags                        = {}
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

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

The bucket is in AWS and in no state. That gap is deliberate, and the order is the point of the
recipe. Done the other way round, import first, the bucket would sit in two states for a while,
and two configurations managing one object is how one team's apply undoes another's: whichever
plans last puts its own idea of the bucket back. **Managed by nobody for an hour is safe; managed
by two is not.**

## Then, import

The data team's configuration is their own, with its own key in the same bucket. Its `main.tf`
declares the bucket exactly as the app did, with the backend inline this time:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "data/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
```

Declaring the bucket alone would give a plan with `1 to add`: this state has never heard of the
bucket, so Terraform would try to create it. One more block says the resource is already there, and which real object it is:

```hcl
import {
  to = aws_s3_bucket.logs
  id = "shop-logs-dev"
}
```

An `import` block names two things: `to`, the address in this configuration, and `id`, the object
in the cloud, in whatever form that resource type uses for imports. For a bucket the id is its
name; each resource's page in the provider documentation says what its import id looks like. The
plan reads the bucket and shows what will enter the state:

```
ana@laptop:~/data$ terraform plan
aws_s3_bucket.logs: Preparing import... [id=shop-logs-dev]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]

Terraform will perform the following actions:

  # aws_s3_bucket.logs will be imported
    resource "aws_s3_bucket" "logs" {
        acceleration_status         = null
        arn                         = "arn:aws:s3:::shop-logs-dev"
        bucket                      = "shop-logs-dev"
        bucket_domain_name          = "shop-logs-dev.s3.amazonaws.com"
        bucket_namespace            = "global"
        bucket_prefix               = null
        bucket_region               = "sa-east-1"
        bucket_regional_domain_name = "shop-logs-dev.s3.sa-east-1.amazonaws.com"
        force_destroy               = false
        hosted_zone_id              = "Z7KQH4QJS55SO"
        id                          = "shop-logs-dev"
        object_lock_enabled         = false
        policy                      = null
        region                      = "sa-east-1"
        request_payer               = null
        tags                        = {}
        tags_all                    = {}

        grant {
            id          = "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a"
            permissions = [
                "FULL_CONTROL",
            ]
            type        = "CanonicalUser"
            uri         = null
        }

        versioning {
            enabled    = false
            mfa_delete = false
        }
    }

Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

**`Plan: 1 to import, 0 to add, 0 to change, 0 to destroy`** is the line to read. It means the
bucket will enter the state, and that the block in `main.tf` already describes it as it is: had
the configuration disagreed with the real bucket, the same plan would also show a change, and the
team would see it before anything happened. The apply does what the plan said:

```
ana@laptop:~/data$ terraform apply -auto-approve | tail -n 4
aws_s3_bucket.logs: Importing... [id=shop-logs-dev]
aws_s3_bucket.logs: Import complete [id=shop-logs-dev]

Apply complete! Resources: 1 imported, 0 added, 0 changed, 0 destroyed.
ana@laptop:~/data$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
ana@laptop:~/data$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:10:08       5863 app/terraform.tfstate
2026-10-02 07:10:19       2475 data/terraform.tfstate
2026-10-02 07:10:03       6548 network/terraform.tfstate
```

The bucket now belongs to the data team's state, which has a key of its own beside the other two.
Nothing in AWS changed at any point. The `import` block has done its job once applied; keeping it
in the file does no harm, since Terraform skips an import whose address is already in the state,
and deleting it in a later commit is just tidying.

## When nobody reviews: state commands

The quick route still exists. Pulling both states, `terraform state mv -state-out` as in the split,
and pushing both back does the same in a minute. It is right for an emergency or a one-person
reorganisation, and it has the split's problems: nothing reviewed it, and both states had better be
locked against anyone else while it happens. Between two teams, the two blocks are the version
everybody can read.
