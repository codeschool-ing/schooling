---
title: "terraform import: adopting a bucket somebody made by hand"
version: 2
---

The data team's import started from a resource that had been managed until a moment before, with a
block ready to copy. The usual case is less tidy. Bruno, who looks after the backups, made a bucket
by hand last week from his own machine, tagged it, and asked Ana to bring it under the shop's
configuration. These were his two commands; run them to make the same bucket in your moto:

```sh
aws s3api create-bucket --bucket shop-backups-dev --create-bucket-configuration LocationConstraint=sa-east-1
aws s3api put-bucket-tagging --bucket shop-backups-dev --tagging "TagSet=[{Key=Owner,Value=bruno},{Key=Purpose,Value=backups}]"
```

Nothing in any state knows the bucket exists:

```
ana@laptop:~/shop/app$ aws s3api get-bucket-tagging --bucket shop-backups-dev
{
    "TagSet": [
        {
            "Key": "Owner",
            "Value": "bruno"
        },
        {
            "Key": "Purpose",
            "Value": "backups"
        }
    ]
}
```

Before import blocks arrived in Terraform 1.5, the only way in was a command, and it is still in
every runbook and most answers you will find: `terraform import ADDRESS ID`. It does one thing,
immediately: **it reads the object from the cloud and writes it into the state at that address.**
It does not write configuration, and it will not run without some:

```
ana@laptop:~/shop/app$ terraform import aws_s3_bucket.backups shop-backups-dev
Error: resource address "aws_s3_bucket.backups" does not exist in the configuration.

Before importing this resource, please create its configuration in the root module. For example:

resource "aws_s3_bucket" "backups" {
  # (resource arguments)
}
```

The address has to exist in the configuration first, because the state entry has to belong to a
block. So Ana writes the smallest block that names the bucket, in a new file, `backups.tf`:

```hcl
resource "aws_s3_bucket" "backups" {
  bucket = "shop-backups-dev"
}
```

```
ana@laptop:~/shop/app$ terraform import aws_s3_bucket.backups shop-backups-dev
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 0s
aws_s3_bucket.backups: Importing from ID "shop-backups-dev"...
aws_s3_bucket.backups: Import prepared!
  Prepared aws_s3_bucket for import
aws_s3_bucket.backups: Refreshing state... [id=shop-backups-dev]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```

`Import successful!`, and the bucket is in the app's state. Notice what did not happen. There was no
plan and no question; nobody saw what entered the state before it was written. **The state now says
the bucket is managed by a block that does not describe it**, and the next plan is where that
shows:

```
ana@laptop:~/shop/app$ terraform plan
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 0s
aws_s3_bucket.backups: Refreshing state... [id=shop-backups-dev]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_s3_bucket.backups will be updated in-place
  ~ resource "aws_s3_bucket" "backups" {
        id                          = "shop-backups-dev"
      ~ tags                        = {
          - "Owner"   = "bruno" -> null
          - "Purpose" = "backups" -> null
        }
      ~ tags_all                    = {
          - "Owner"   = "bruno" -> null
          - "Purpose" = "backups" -> null
        }
        # (14 unchanged attributes hidden)

        # (2 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

Terraform compares the block with the bucket as imported, and the block says nothing about tags,
which to Terraform means "no tags". The plan would strip Bruno's two tags. The import was correct
and the configuration was incomplete, and the difference is a pending change waiting for somebody
to type `yes`. If that somebody is a pipeline that applies every merge automatically, the tags are
gone.

**The fix is always on the configuration side: make the block describe what exists**, and plan
until the plan is clean:

```
ana@laptop:~/shop/app$ cat backups.tf
resource "aws_s3_bucket" "backups" {
  bucket = "shop-backups-dev"
  tags = {
    Owner   = "bruno"
    Purpose = "backups"
  }
}
ana@laptop:~/shop/app$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`No changes`, and only now is the import finished. The order to remember is the reverse of
creating something: with a new resource you write the block and apply makes the world match it;
with an import the world is already there, and you edit the block until it matches the world.

## Why the block form replaced it

The command still works, and it is still the shortest way to adopt one object from a terminal. But
its three habits are the ones lesson 7 warned against in the state commands. It writes the shared
state **straight away**, outside any plan, so a mistaken id or address reaches the state with
nobody reviewing it. It takes **one resource per command**, so adopting fifty means fifty commands
in somebody's shell history. And it leaves **no trace in the repository**: the next person sees a
`backups.tf` and cannot tell whether Terraform created that bucket or adopted it.

An `import` block answers all three. It goes through a plan, where the import and any difference
show up side by side before anything is written; it can sit beside fifty others in one file; and
it is part of the commit that adds the resource. The last section of this lesson takes it further,
to a resource whose configuration nobody has written at all.
