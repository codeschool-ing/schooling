---
title: Dev and prod, and what keeps them apart
version: 1
---

An **environment** is a complete copy of the infrastructure, built from the same code for a
different purpose. The shop has two. `dev` is where Ana tries a change first, and it can be small
and cheap and broken for an afternoon. `prod` is what customers reach, and it is bigger: two
availability zones instead of one, and in a configuration with machines, larger ones and more of
them. **Same code, different values.** That much everybody agrees on.

The idea people arrive with is that the values are the whole difference: one configuration, one
`.tfvars` file per environment, and the right file passed to each command. Ana writes it that way.
The variables:

```hcl
variable "environment" {
  description = "Which environment these values are for: dev or prod."
  type        = string
}

variable "cidr" {
  description = "The VPC's address range."
  type        = string
}

variable "azs" {
  description = "The availability zones that get a public subnet."
  type        = list(string)
}
```

The configuration names everything after `var.environment` and builds one public subnet per zone,
with `for_each` from lesson 4 and `cidrsubnet` from lesson 3:

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

locals {
  name = "shop-${var.environment}"
  tags = { Project = "shop", Environment = var.environment }
}

resource "aws_vpc" "shop" {
  cidr_block = var.cidr
  tags       = merge(local.tags, { Name = local.name })
}

resource "aws_subnet" "public" {
  for_each          = { for i, az in var.azs : az => i }
  vpc_id            = aws_vpc.shop.id
  cidr_block        = cidrsubnet(var.cidr, 8, each.value + 1)
  availability_zone = each.key
  tags              = merge(local.tags, { Name = "${local.name}-${each.key}" })
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = merge(local.tags, { Name = "web" })

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

And one file of values for each environment:

```hcl
environment = "dev"
cidr        = "10.21.0.0/16"
azs         = ["sa-east-1a"]
```

```hcl
environment = "prod"
cidr        = "10.20.0.0/16"
azs         = ["sa-east-1a", "sa-east-1c"]
```

The backend is the S3 bucket from lesson 7, with one key, `shop/terraform.tfstate`. She applies
dev:

```
ana@laptop:~/shop$ terraform apply -var-file=dev.tfvars -auto-approve | tail -n 1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Then she asks for a plan with the production values, expecting a second network beside the first:

```
ana@laptop:~/shop$ terraform plan -var-file=prod.tfvars -no-color | grep -E "^  #|# forces|^Plan:"
  # aws_security_group.web must be replaced
      ~ vpc_id                 = "vpc-1a70c993b12a8438e" -> (known after apply) # forces replacement
  # aws_subnet.public["sa-east-1a"] must be replaced
      ~ cidr_block                                     = "10.21.1.0/24" -> "10.20.1.0/24" # forces replacement
      ~ vpc_id                                         = "vpc-1a70c993b12a8438e" -> (known after apply) # forces replacement
  # aws_subnet.public["sa-east-1c"] will be created
  # aws_vpc.shop must be replaced
      ~ cidr_block                           = "10.21.0.0/16" -> "10.20.0.0/16" # forces replacement
Plan: 4 to add, 0 to change, 3 to destroy.
```

**Terraform does not see a second environment. It sees the first one, described differently.**
The state holds one VPC, the dev one, and the configuration now says that VPC should be
`10.20.0.0/16`. A VPC's range cannot change in place, so the plan replaces it, and everything inside
it with it: three resources destroyed, four created. Applied, this would not create production. It
would turn dev into production, and the next apply with `dev.tfvars` would turn it back.

The values were never the problem. **What makes two environments two is that each has its own
state**, so that a plan for one cannot even see the other's resources. That is the isolation the
rest of this lesson is about, and it is worth stating what it buys before looking at how:

- a mistake in dev, applied, damages dev and nothing else;
- a plan for prod reads prod's state and lists only prod's changes;
- each state has its own lock, so a long apply in dev never blocks an urgent fix in prod.

There are three common ways to give each environment its state, and the next sections take them
in turn: **workspaces**, which keep one directory and switch the state underneath it; **one
directory per environment**, each with its own backend key; and **Terragrunt**, a tool that
generates the second arrangement for you. They differ in where the choice of environment lives,
and that turns out to be the question that matters.

Isolation also has a layer below the state. Two states in the same AWS account, reached with the
same credentials, are separated by Terraform's bookkeeping and nothing else; whoever can apply dev
can, with one wrong command, apply prod. Many organisations put prod in **its own AWS account**,
with credentials that dev's pipeline does not have. This course has one emulated account, so the
lessons cannot show that layer, but every arrangement below works with it.

Ana destroys the dev network before trying the first of the three:

```
ana@laptop:~/shop$ terraform destroy -var-file=dev.tfvars -auto-approve | tail -n 1
Destroy complete! Resources: 3 destroyed.
```
