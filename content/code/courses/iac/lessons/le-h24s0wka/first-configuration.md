---
title: A configuration is a directory
version: 2
---

Lesson 1 showed one Terraform file and asked you to trust it. This lesson takes it apart, and
builds the shop's network out of it, one block at a time.

Start with the picture most people arrive holding: that a `.tf` file is a script, and Terraform
runs it from the top down. It is not, and it does not. **Terraform reads every file ending in `.tf`
in a directory as one document, and that directory is called a configuration.** The file names
mean nothing to Terraform, and neither does the order of the blocks inside them: moving the VPC
into a file called `zzz.tf` changes nothing at all. Subdirectories are not read. A directory below
this one is a configuration of its own, which lesson 10 turns into a module.

Ana's network starts as two files in a new directory, `~/shop`. The first one, `versions.tf`, says
what the configuration needs before it can run:

```hcl
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

The `terraform` block holds settings for Terraform itself. `required_version` refuses to run on a
Terraform older than 1.10. `required_providers` names the plugins the configuration uses, and each
entry has three parts. The key, `aws`, is the **local name** the other files use. `source` says
where the plugin comes from: `hashicorp/aws` is short for `registry.terraform.io/hashicorp/aws`.
And `version` limits which releases are acceptable; `~> 6.0` means any 6.x and nothing from 7 on,
which the providers section takes apart.

The second file, `main.tf`, is the network:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "shop"
  }
}
```

**A `provider` block configures a plugin; a `resource` block asks for a thing to exist.** The
provider block here sets one argument, the region. The credentials are not in it, and they should
never be: the AWS provider finds them where the AWS CLI does, and in this lab that is the four
`AWS_` variables that lesson 1's `iac-env.sh` sets, which also point it at moto. That is why this file
would work unchanged against a real account.

The resource block carries two labels. `aws_vpc` is the **type**, defined by the provider, and
`shop` is the **name**, chosen by you. Together they make the address `aws_vpc.shop`, which is how
the rest of the configuration refers to this VPC, and how every message Terraform prints names it.
Inside the braces are **arguments**: `cidr_block` and `tags`, each a value you set. Two resources
may share a name as long as their types differ, so `aws_vpc.shop` and an `aws_s3_bucket.shop`
could live side by side.

The file names follow a convention rather than a rule: `versions.tf` for the `terraform` block,
`main.tf` for resources, and soon `variables.tf` and `outputs.tf`. Somebody opening a configuration
they have never seen knows where to look first.

With both files written, the obvious next step is to ask for a plan, and Terraform refuses:

```
ana@laptop:~/shop$ ls
main.tf
versions.tf
ana@laptop:~/shop$ terraform plan
╷
│ Error: Inconsistent dependency lock file
│ 
│ The following dependency selections recorded in the lock file are
│ inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/aws: required by this configuration but no version is selected
│ 
│ To make the initial dependency selections that will initialize the
│ dependency lock file, run:
│   terraform init
╵
```

**Nothing is installed yet.** Terraform on its own knows nothing about AWS. What a VPC is, which
arguments it takes and which API call creates one all live in the provider, a separate program
this directory does not have. The error names the command that fetches it, and that command is the
next section.
