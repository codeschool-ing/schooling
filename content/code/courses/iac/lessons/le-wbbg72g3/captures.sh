#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of iac, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# The AWS in these sessions is moto, emulated on the laptop (lab.sh says how),
# and it starts empty on every run. Ids that AWS invents, vpc-… and subnet-…,
# are random, so a second run prints different ones; the lesson quotes none of
# them in its prose.
#
# What is STAGED rather than typed, and not shown in the lesson: the files ana
# wrote (put below), whose contents the lesson shows; `terraform init`, whose
# output is lesson 2's subject; and removing the file with the deliberate typo
# once its error has been shown. Where a file is written a second time, `put
# ./name` keeps both versions apart in the output, and the lesson quotes each.
#
# One arrangement of the lab is changed here and not in a lesson: the provider
# cache is private to this run (TF_PLUGIN_CACHE_DIR), because the cache lab.sh
# shares between runs is rewritten by every `terraform init`, and a run started
# at the same moment as another failed on it with "text file busy".
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

export TF_PLUGIN_CACHE_DIR=$HOME/.plugin-cache
mkdir -p "$TF_PLUGIN_CACHE_DIR" shop && cd shop
con() { run "echo '$1' | terraform console${2:+ $2}"; }

block syntax
put main.tf <<'CODE'
# The shop's network, as Terraform describes it.
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

/* One VPC for the whole shop.
   Its subnets are in network.tf. */
resource "aws_vpc" "shop" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true // the machines get DNS names
  tags = {
    Name  = "shop"
    Owner = var.owner
  }
}
CODE
put owner.tf.json <<'CODE'
{
  "variable": {
    "owner": {
      "type": "string",
      "default": "ana",
      "description": "Who answers for these resources."
    }
  }
}
CODE
quiet 'terraform init'
block validate
run 'ls'
run 'terraform validate'
block typo
put subnet.tf <<'CODE'
resource "aws_subnet" "a" {
  vpc_id     = aws_vpc.shop.id
  cidr_block = 10.20.1.0/24
}
CODE
run 'terraform validate'
quiet 'rm subnet.tf'

block expressions
put variables.tf <<'CODE'
variable "environment" {
  type        = string
  default     = "dev"
  description = "dev or prod."
}

variable "network" {
  type = object({
    cidr   = string
    azs    = list(string)
    public = optional(bool, false)
  })
  default = {
    cidr = "10.20.0.0/16"
    azs  = ["sa-east-1a", "sa-east-1c"]
  }
}
CODE
block console-1
con 'var.environment'
con 'var.environment == "prod" ? 3 : 1'
con '"shop-${var.environment}"'
con 'aws_vpc.shop.cidr_block'
block boot
put boot.tf <<'CODE'
locals {
  boot_script = <<-EOT
    #!/bin/sh
    echo "shop ${var.environment}" > /etc/motd
    echo "owner: ${var.owner}" >> /etc/motd
  EOT
}
CODE
con 'local.boot_script'
block directive
con '"shop-${var.environment}%{ if var.environment == "prod" } (reviewed)%{ endif }"'
con '"shop-${var.environment}%{ if var.environment == "prod" } (reviewed)%{ endif }"' '-var environment=prod'

block functions
con 'cidrsubnet("10.20.0.0/16", 8, 1)'
con 'cidrsubnet("10.20.0.0/16", 8, 2)'
con 'cidrhost("10.20.1.0/24", 10)'
block functions-2
con 'format("%s-%s", "shop", var.environment)'
con 'join(", ", var.network.azs)'
con 'merge({ Project = "shop", Owner = "ana" }, { Owner = "bruno" })'
block lookup
con 'lookup({ dev = "t3.micro", prod = "t3.large" }, var.environment)'
con 'lookup({ dev = "t3.micro", prod = "t3.large" }, "staging")'
con 'lookup({ dev = "t3.micro", prod = "t3.large" }, "staging", "t3.small")'
block try
con 'var.network.nat'
con 'try(var.network.nat, false)'
con 'can(cidrnetmask("10.20.0.0/33"))'
block provider-fn
con 'provider::aws::arn_parse("arn:aws:s3:::shop-assets")'

block locals
put locals.tf <<'CODE'
locals {
  name = "shop-${var.environment}"

  common_tags = {
    Project     = "shop"
    Owner       = var.owner
    Environment = var.environment
  }
}
CODE
put network.tf <<'CODE'
resource "aws_subnet" "a" {
  vpc_id                  = aws_vpc.shop.id
  cidr_block              = cidrsubnet(var.network.cidr, 8, 1)
  availability_zone       = var.network.azs[0]
  map_public_ip_on_launch = var.network.public
  tags                    = merge(local.common_tags, { Name = "${local.name}-a" })
}

resource "aws_subnet" "c" {
  vpc_id                  = aws_vpc.shop.id
  cidr_block              = cidrsubnet(var.network.cidr, 8, 2)
  availability_zone       = var.network.azs[1]
  map_public_ip_on_launch = var.network.public
  tags                    = merge(local.common_tags, { Name = "${local.name}-c" })
}
CODE
put ./main.tf <<'CODE'
# The shop's network, as Terraform describes it.
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

/* One VPC for the whole shop.
   Its subnets are in network.tf. */
resource "aws_vpc" "shop" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true // the machines get DNS names
  tags                 = merge(local.common_tags, { Name = local.name })
}
CODE
block tags
run 'grep -n "tags" *.tf'
block apply
run 'terraform apply -auto-approve'
block local-var
run 'terraform plan -var name=shop-test'

block types
con 'var.network'
con 'type(var.network)'
block convert
con '"5" + 1'
con 'tonumber("three")'
con 'toset(["sa-east-1c", "sa-east-1a", "sa-east-1c"])'
block wrong-type
put wrong.tfvars <<'CODE'
network = {
  cidr = "10.20.0.0/16"
  azs  = "sa-east-1a"
}
CODE
run 'terraform plan -var-file=wrong.tfvars'
quiet 'rm wrong.tfvars'

block for
con '[for az in var.network.azs : "${local.name}-${az}"]'
con '{ for i, az in var.network.azs : az => cidrsubnet(var.network.cidr, 8, i + 1) }'
con '[for az in var.network.azs : az if endswith(az, "c")]'
block group
con '{ for az in var.network.azs : substr(az, 0, 9) => az }'
con '{ for az in var.network.azs : substr(az, 0, 9) => az... }'
block splat
con '[aws_subnet.a, aws_subnet.c][*].cidr_block'
block outputs
put outputs.tf <<'CODE'
output "subnet_cidrs" {
  value = {
    for s in [aws_subnet.a, aws_subnet.c] : s.tags["Name"] => s.cidr_block
  }
}
CODE
run 'terraform apply -auto-approve'
run 'terraform output subnet_cidrs'

block validation
put ./variables.tf <<'CODE'
variable "environment" {
  type        = string
  default     = "dev"
  description = "dev or prod."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment is dev or prod; the shop has no other."
  }
}

variable "network" {
  type = object({
    cidr   = string
    azs    = list(string)
    public = optional(bool, false)
  })
  default = {
    cidr = "10.20.0.0/16"
    azs  = ["sa-east-1a", "sa-east-1c"]
  }

  validation {
    condition     = can(cidrsubnet(var.network.cidr, 8, 2))
    error_message = "The network needs a CIDR range with room for /24 subnets, such as 10.20.0.0/16."
  }
}
CODE
block bad-env
run 'terraform plan -var environment=staging'
block bad-cidr
run "terraform plan -var 'network={ cidr = \"10.20.0.0/26\", azs = [\"sa-east-1a\", \"sa-east-1c\"] }'"
block bucket
put bucket.tf <<'CODE'
locals {
  bucket = "${local.name}-assets-${var.owner}"
}

resource "aws_s3_bucket" "assets" {
  bucket = local.bucket

  lifecycle {
    precondition {
      condition     = length(local.bucket) <= 63
      error_message = "Bucket names stop at 63 characters; ${local.bucket} has ${length(local.bucket)}."
    }
    postcondition {
      condition     = self.region == "sa-east-1"
      error_message = "The shop's files stay in São Paulo."
    }
  }
}
CODE
block bad-bucket
run 'terraform plan -var owner=ana-and-everybody-else-on-the-platform-team-of-the-shop'
block bucket-ok
run 'terraform apply -auto-approve'
block check
put checks.tf <<'CODE'
check "two_zones" {
  assert {
    condition     = length(distinct(var.network.azs)) >= 2
    error_message = "With one zone, the shop goes down with that zone."
  }
}
CODE
run "terraform plan -var 'network={ cidr = \"10.20.0.0/16\", azs = [\"sa-east-1a\", \"sa-east-1a\"] }'"

quiet 'rm -rf "$TF_PLUGIN_CACHE_DIR" .terraform'
