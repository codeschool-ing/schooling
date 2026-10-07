---
title: Describing the result instead of the steps
version: 2
---

Back to the third question from the network built by hand: what happens if Ana runs `network.sh` again? She finds
out on the day somebody asks her to "make sure the network is set up", and does the obvious thing:

```
ana@laptop:~/shop$ sh network.sh
created vpc-1ce5b143bd4c0c7c9, subnet-1eec27a2a90b91dd5 and sg-073d775b8001602b6
ana@laptop:~/shop$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-1dc5b2f02877661dd	10.20.0.0/16
vpc-1ce5b143bd4c0c7c9	10.20.0.0/16
```

**Two VPCs, both called `shop`, both with the same range.** The script did exactly what it says.
Every line in it is an instruction to create, and AWS is happy to create a second network beside
the first. A script like this is **imperative**: it lists the steps, and running the steps again
repeats them.

Making the script safe to repeat is possible, and it is a lot of work. Before every create it would
have to ask whether the thing exists already, and then decide what to do when it exists *but
differs*: a VPC with another range, a security group with a rule too many. Each of those branches
is code somebody writes, tests and gets wrong.

A **declarative** description turns the problem around. It does not say what to do; it says what
should exist, and leaves the steps to a program. Here is the same VPC, described for Terraform,
which lesson 2 takes apart line by line:

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
  tags       = { Name = "shop-tf" }
}
```

In a new directory Terraform needs `terraform init` first, which downloads the AWS provider and
which lesson 2 reads line by line. Then the first `terraform apply` finds no such VPC and creates
it. Look at the last lines:

```
Plan: 1 to add, 0 to change, 0 to destroy.
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 0s [id=vpc-72a78e48826631670]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

The second one compares the description with what exists, finds them equal and does nothing:

```
ana@laptop:~/shop-tf$ terraform apply -auto-approve
aws_vpc.shop: Refreshing state... [id=vpc-72a78e48826631670]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

And there is still exactly one:

```
ana@laptop:~/shop-tf$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-tf --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-72a78e48826631670	10.20.0.0/16
```

That property has a name you will meet in every lesson of this course: **idempotency**. An
operation is idempotent when doing it twice leaves the world as doing it once did. `network.sh` is
not; `terraform apply` is, because it never runs a step blindly. It reads, compares, and then makes
only the difference.

**Declarative has a price.** Terraform can only compare what it knows how to
read, so it needs to remember which real VPC belongs to which line of the file. That memory is the
**state**, and lessons 7 and 8 are about what happens when it is lost, shared or wrong. The script
needed no memory because it never asked anything.
