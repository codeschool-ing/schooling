---
title: The provider, and whose credentials it uses
version: 1
---

`iac` taught Terraform against moto from its first lesson: providers, state, a remote backend and a
lock. This lesson and the next are about the part that only shows up once the provider points at a
real account that other people also change: whose identity Terraform acts with, where the state lives,
and how it is protected. Terraform goes into `~/.local/bin`, at the version `iac` used:

```sh
cd ~/aws
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -o -q terraform.zip terraform -d ~/.local/bin && rm terraform.zip
```

On an Arm computer the file is `terraform_1.16.4_linux_arm64.zip`.

```
ana@laptop:~/aws/tf/bootstrap$ terraform version
Terraform v1.16.4
on linux_amd64
```

## Where the credentials come from

The provider block in this lesson names no key, and it should not. The AWS provider looks for
credentials in a fixed order, the same order the AWS command line uses, and takes the first it finds:

1. **environment variables**: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, which is how this
   course gives it moto's `test` pair;
2. **a profile** in `~/.aws/config` and `~/.aws/credentials`, chosen with `AWS_PROFILE` or `profile`
   in the block; with IAM Identity Center, `aws sso login` fills the profile with short-lived
   credentials, which `aws-foundations` lesson 11 sets up;
3. **the machine's own role**: an EC2 instance profile, an ECS task role, a CodeBuild project's role,
   which is how a pipeline should run Terraform.

**A key written into the provider block is a key in the repository**, and the repository outlives
every rotation. The order above is the reason it is never needed: on a laptop the profile supplies
credentials, in a pipeline the role does.

## The shop's provider

```hcl
# shop/main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region            = "sa-east-1"
  s3_use_path_style = true

  default_tags {
    tags = {
      team       = "shop"
      managed-by = "terraform"
    }
  }
}

resource "aws_sns_topic" "alerts" {
  name = "shop-alerts"
}
```

`s3_use_path_style` is for moto: it makes the provider address a bucket as `localhost:4567/bucket`
rather than `bucket.localhost:4567`. Against AWS it is left out. The endpoint itself comes from
`AWS_ENDPOINT_URL`, the variable the command line uses, which the provider reads too.

**`default_tags` puts the same tags on every resource the provider creates** that accepts tags, with
nothing written per resource:

```
ana@laptop:~/aws/tf/shop$ terraform apply -auto-approve -input=false -no-color | grep -E '^(aws_|Apply)'
aws_sns_topic.alerts: Creating...
aws_sns_topic.alerts: Creation complete after 0s [id=arn:aws:sns:sa-east-1:123456789012:shop-alerts]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/tf/shop$ aws sns list-tags-for-resource --resource-arn arn:aws:sns:sa-east-1:123456789012:shop-alerts --query 'Tags[].[Key,Value]' --output text
team	shop
managed-by	terraform
```

The topic was created with two tags nobody wrote on it. Lesson 24 is about why every resource needs
an owner it can be traced to; this block is the cheapest way to have one, because a resource cannot
be created through this provider without it.

## One role per environment

Teams with several accounts (production, staging, a sandbox per person) usually run one Terraform
configuration per account, with the provider assuming a role in each:

```hcl
provider "aws" {
  region = "sa-east-1"
  assume_role {
    role_arn = "arn:aws:iam::210987654321:role/terraform-deploy"
  }
}
```

The credentials found by the order above are then used only to assume that role, and everything
Terraform does in the account is done as the role, which is what CloudTrail records in lesson 20.
That block was not run here: it needs a second account to point at.
