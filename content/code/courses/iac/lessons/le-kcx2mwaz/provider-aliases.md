---
title: A second region, with a provider alias
version: 2
---

A `provider "aws"` block is one connection: one region, one set of credentials. Every resource
whose type starts with `aws_` uses it without being told, which is why nothing in the shop's
configuration so far has mentioned a provider at all. **To put a resource somewhere else, you
declare a second configuration of the same provider with an `alias`, and point the resource at it
with the `provider` meta-argument.**

There are ordinary reasons to want that. A copy of the shop's backups should not live in the same
region as the shop, or one regional outage takes both. Some AWS services insist on a region of
their own: a certificate for CloudFront has to be issued in `us-east-1`, wherever the rest of the
site runs. Ana wants a backup bucket in Ohio, and writes it in `backup.tf`:

```hcl
provider "aws" {
  alias  = "us"
  region = "us-east-2"
}

resource "aws_s3_bucket" "backup" {
  provider = aws.us
  bucket   = "shop-backup-ana"
}
```

The block without an alias stays the **default**, in `sa-east-1`. The new one is called `us`, and
the bucket chooses it with `provider = aws.us`. That is a reference, written without quotes, in
the form `<provider name>.<alias>`. The plan shows the region the bucket will be created in:

```
  # aws_s3_bucket.backup will be created
  + resource "aws_s3_bucket" "backup" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "shop-backup-ana"
      + bucket_domain_name          = (known after apply)
      + bucket_namespace            = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_region               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = "us-east-2"
```

And AWS confirms both halves, the bucket in Ohio and the VPC still only in São Paulo:

```
ana@laptop:~/shop/network$ aws s3api get-bucket-location --bucket shop-backup-ana
{
    "LocationConstraint": "us-east-2"
}
ana@laptop:~/shop/network$ aws ec2 describe-vpcs --region us-east-2 --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text
ana@laptop:~/shop/network$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].CidrBlock" --output text
10.20.0.0/16
```

## A region argument on the resource itself

Version 6 of the AWS provider, the one this course uses, added a `region` argument to most of its
resources. For "the same account, another region", that is now enough, with no second provider
block. Ana's `logs.tf`:

```hcl
resource "aws_s3_bucket" "logs" {
  region = "us-east-2"
  bucket = "shop-logs-ana"
}
```

```
ana@laptop:~/shop/network$ terraform apply -auto-approve -no-color | grep -E "^  # |region|^Apply"
  # aws_s3_bucket.logs will be created
      + bucket_region               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + region                      = "us-east-2"
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/network$ aws s3api get-bucket-location --bucket shop-logs-ana
{
    "LocationConstraint": "us-east-2"
}
```

So why keep aliases? Because a provider configuration carries more than a region. A second
account, a role to assume, other credentials, a different set of `default_tags`: all of those are
provider settings, and a resource argument cannot change them. When the difference is only the
region, the argument is shorter. When it is anything else, it is an alias. And not every provider has such an
argument; where it is missing, the alias is still the only way.

## When the alias is wrong

A misspelt alias fails before anything is planned. In `~/shop/try`, Ana replaces `main.tf` with a
bucket that names `aws.eu`, which was never declared:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "logs" {
  provider = aws.eu
  bucket   = "shop-archive-ana"
}
```

```
ana@laptop:~/shop/try$ terraform validate
╷
│ Error: Provider configuration not present
│ 
│ To work with aws_s3_bucket.logs its original provider configuration at
│ provider["registry.terraform.io/hashicorp/aws"].eu is required, but it has
│ been removed. This occurs when a provider configuration is removed while
│ objects created by that provider still exist in the state. Re-add the
│ provider configuration to destroy aws_s3_bucket.logs, after which you can
│ remove the provider configuration again.
╵
```

The message is written for a different situation, a configuration that was removed while
resources created through it are still in the state, and this directory has no state at all. The
part to read is the address, `provider["registry.terraform.io/hashicorp/aws"].eu`: Terraform
looked for a configuration called `eu` and found none, whether it was deleted or never written.

The removal it describes is real, too, and worth avoiding. A resource remembers which provider
configuration created it, so deleting an alias block while its resources still exist leaves
Terraform with no way to reach them, even to destroy them. Remove the resources first, then the
alias.

A module receives provider configurations from whoever calls it, through a `providers` argument on
the `module` block, rather than declaring its own. Lesson 10 explains why a module should leave
that to its caller.
