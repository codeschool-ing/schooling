#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of iac, as a script that produces
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
# and it starts empty on every run apart from the default VPC moto creates in
# every region, as AWS does. Ids that AWS invents, vpc-… and subnet-…, and the
# request ids in an API error, are random, so a second run prints different
# ones; the lesson quotes none of them in its prose.
#
# What is STAGED rather than typed, and not shown in the lesson: the files ana
# wrote (put below), whose contents the lesson shows; `terraform init`, whose
# output is lesson 2's subject, except the one run in "end-to-end"; three edits
# made with sed and undone the same way, each marked STAGED below: a mistyped
# argument for `validate` to find, a colleague's change to the subnet names
# for a test to catch, and a validation rule loosened to show a test noticing;
# and the removal of a test file that was only there to show an error. Where a
# file is written a second time, `put ./name` keeps both versions apart in the
# output.
#
# Several commands run with AWS_ENDPOINT_URL pointing at port 4567, where
# nothing listens: that is how the lesson shows which tests need AWS and which
# do not, and it is typed, not staged.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

mkdir -p shop/modules/network && cd shop/modules/network

block module
put versions.tf <<'CODE'
terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
CODE
put variables.tf <<'CODE'
variable "name" {
  type        = string
  description = "Prefix for every Name tag."
}

variable "cidr" {
  type        = string
  description = "The VPC's range, such as 10.20.0.0/16."

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "cidr must be an IPv4 range such as 10.20.0.0/16."
  }
}

variable "subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "One subnet per key: its range and its availability zone."
}
CODE
put main.tf <<'CODE'
data "aws_availability_zones" "here" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "${var.name}-${each.key}" }

  lifecycle {
    precondition {
      condition     = contains(data.aws_availability_zones.here.names, each.value.az)
      error_message = "Zone ${each.value.az} is not one this region offers."
    }
  }
}
CODE
put outputs.tf <<'CODE'
output "vpc_id" {
    value = aws_vpc.this.id
}

output "subnet_ids" {
  value = {for k, s in aws_subnet.this: k => s.id}
}
CODE

block fmt
run 'terraform fmt -check -diff; echo "exit $?"'
run 'terraform fmt'
run 'terraform fmt -check; echo "exit $?"'

block validate-no-init
run 'terraform validate'
quiet 'terraform init'
block validate-ok
run 'terraform validate'

block validate-typo
# STAGED: the mistyped argument, put in and taken out again with sed
quiet "sed -i 's/^  cidr_block           = var.cidr/  cidr_blocks          = var.cidr/' main.tf"
run 'terraform validate'
quiet "sed -i 's/^  cidr_blocks          = var.cidr/  cidr_block           = var.cidr/' main.tf"

block test-plan
put tests/plan.tftest.hcl <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

variables {
  name = "shop"
  cidr = "10.20.0.0/16"
  subnets = {
    a = { cidr = "10.20.1.0/24", az = "sa-east-1a" }
    c = { cidr = "10.20.2.0/24", az = "sa-east-1c" }
  }
}

run "one_subnet_per_entry" {
  command = plan

  assert {
    condition     = length(aws_subnet.this) == 2
    error_message = "Expected one subnet per entry in var.subnets."
  }

  assert {
    condition     = aws_subnet.this["c"].availability_zone == "sa-east-1c"
    error_message = "Subnet c is not in sa-east-1c."
  }
}

run "names_carry_the_prefix" {
  command = plan

  variables {
    name = "shop-dev"
  }

  assert {
    condition     = aws_subnet.this["a"].tags.Name == "shop-dev-a"
    error_message = "Subnet a is called ${aws_subnet.this["a"].tags.Name}."
  }
}
CODE
run 'terraform test'

block test-regression
# STAGED: a colleague's change to the subnets' Name tag, undone afterwards
quiet "sed -i 's/Name = \"\${var.name}-\${each.key}\"/Name = \"\${var.name}-subnet-\${each.key}\"/' main.tf"
run 'grep -n "Name =" main.tf'
run 'terraform test'
quiet "sed -i 's/Name = \"\${var.name}-subnet-\${each.key}\"/Name = \"\${var.name}-\${each.key}\"/' main.tf"

block test-unknown
put tests/link.tftest.hcl <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "subnet_is_in_the_vpc" {
  command = plan

  assert {
    condition     = aws_subnet.this["a"].vpc_id == aws_vpc.this.id
    error_message = "Subnet a is not in the module's VPC."
  }
}
CODE
run 'terraform test -filter=tests/link.tftest.hcl'
# STAGED: the file only existed to show that error
quiet 'rm tests/link.tftest.hcl'

block mocks-need-aws
run 'AWS_ENDPOINT_URL=http://localhost:4567 terraform test'

block mocks-empty
put tests/unit.tftest.hcl <<'CODE'
mock_provider "aws" {}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "subnet_is_in_the_vpc" {
  assert {
    condition     = aws_subnet.this["a"].vpc_id == aws_vpc.this.id
    error_message = "Subnet a is not in the module's VPC."
  }
}
CODE
run 'AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/unit.tftest.hcl'

block mocks-override
put ./tests/unit.tftest.hcl <<'CODE'
mock_provider "aws" {}

override_data {
  target = data.aws_availability_zones.here
  values = {
    names = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  }
}

override_resource {
  target = aws_vpc.this
  values = {
    id = "vpc-0123456789abcdef0"
  }
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "subnet_is_in_the_vpc" {
  assert {
    condition     = aws_subnet.this["a"].vpc_id == "vpc-0123456789abcdef0"
    error_message = "Subnet a is in ${aws_subnet.this["a"].vpc_id}."
  }

  assert {
    condition     = output.subnet_ids["a"] == aws_subnet.this["a"].id
    error_message = "The output does not carry subnet a's id."
  }
}
CODE
run 'AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/unit.tftest.hcl'
block mocks-verbose
run 'AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/unit.tftest.hcl -verbose'

block rules
put tests/rules.tftest.hcl <<'CODE'
mock_provider "aws" {}

override_data {
  target = data.aws_availability_zones.here
  values = {
    names = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  }
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "cidr_without_a_mask" {
  command = plan

  variables {
    cidr = "10.20.0.0"
  }

  expect_failures = [var.cidr]
}

run "zone_from_another_region" {
  command = plan

  variables {
    subnets = { a = { cidr = "10.20.1.0/24", az = "us-east-1a" } }
  }

  expect_failures = [aws_subnet.this]
}
CODE
run 'AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/rules.tftest.hcl'

block rules-broken
# STAGED: the validation rule loosened, and put back afterwards
quiet "sed -i 's|condition     = can(cidrnetmask(var.cidr))|condition     = can(regex(\"^[0-9./]+\$\", var.cidr))|' variables.tf"
run 'grep -n "condition" variables.tf'
run 'AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/rules.tftest.hcl'
quiet "sed -i 's|condition     = can(regex(\"^\[0-9./\]+\$\", var.cidr))|condition     = can(cidrnetmask(var.cidr))|' variables.tf"

block e2e
mkdir -p tests/aws
put tests/aws/main.tf <<'CODE'
# A helper module for the tests: it reads the VPC back from AWS.
variable "vpc_id" {
  type = string
}

data "aws_vpc" "built" {
  id = var.vpc_id
}

data "aws_subnets" "built" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}
CODE
put tests/e2e.tftest.hcl <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

variables {
  name = "shop-e2e"
  cidr = "10.20.0.0/16"
  subnets = {
    a = { cidr = "10.20.1.0/24", az = "sa-east-1a" }
    c = { cidr = "10.20.2.0/24", az = "sa-east-1c" }
  }
}

run "build" {
  command = apply

  assert {
    condition     = alltrue([for s in aws_subnet.this : s.vpc_id == aws_vpc.this.id])
    error_message = "A subnet landed outside the module's VPC."
  }
}

run "aws_agrees" {
  module {
    source = "./tests/aws"
  }

  variables {
    vpc_id = run.build.vpc_id
  }

  assert {
    condition     = data.aws_vpc.built.cidr_block == "10.20.0.0/16"
    error_message = "AWS reports the VPC as ${data.aws_vpc.built.cidr_block}."
  }

  assert {
    condition     = length(data.aws_subnets.built.ids) == 2
    error_message = "AWS reports ${length(data.aws_subnets.built.ids)} subnets in the VPC."
  }
}
CODE
block e2e-init
run 'terraform init'
block e2e-run
run 'terraform test -filter=tests/e2e.tftest.hcl'
block e2e-after
run 'aws ec2 describe-vpcs --query "Vpcs[].[CidrBlock,IsDefault]" --output text'

block range
put tests/range.tftest.hcl <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

variables {
  name    = "shop-range"
  cidr    = "10.20.0.0/16"
  subnets = { b = { cidr = "10.30.1.0/24", az = "sa-east-1a" } }
}

run "plan_accepts_it" {
  command = plan
}

run "apply_refuses_it" {
  command = apply
}
CODE
run 'terraform test -filter=tests/range.tftest.hcl'
run 'aws ec2 describe-vpcs --query "Vpcs[].[CidrBlock,IsDefault]" --output text'

block range-rule
put ./variables.tf <<'CODE'
variable "name" {
  type        = string
  description = "Prefix for every Name tag."
}

variable "cidr" {
  type        = string
  description = "The VPC's range, such as 10.20.0.0/16."

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "cidr must be an IPv4 range such as 10.20.0.0/16."
  }
}

variable "subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "One subnet per key: its range and its availability zone."

  validation {
    # The subnet's first address, cut to the VPC's prefix, is the VPC's own
    # network address. If var.cidr is itself broken, its rule says so.
    condition = try(alltrue([
      for s in values(var.subnets) :
      cidrhost("${split("/", s.cidr)[0]}/${split("/", var.cidr)[1]}", 0) == cidrhost(var.cidr, 0)
    ]), true)
    error_message = "Every subnet must lie inside the VPC's range, ${var.cidr}."
  }
}
CODE
put ./tests/rules.tftest.hcl <<'CODE'
mock_provider "aws" {}

override_data {
  target = data.aws_availability_zones.here
  values = {
    names = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  }
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "cidr_without_a_mask" {
  command = plan

  variables {
    cidr = "10.20.0.0"
  }

  expect_failures = [var.cidr]
}

run "zone_from_another_region" {
  command = plan

  variables {
    subnets = { a = { cidr = "10.20.1.0/24", az = "us-east-1a" } }
  }

  expect_failures = [aws_subnet.this]
}

run "subnet_outside_the_vpc" {
  command = plan

  variables {
    subnets = { b = { cidr = "10.30.1.0/24", az = "sa-east-1a" } }
  }

  expect_failures = [var.subnets]
}
CODE
block range-rule-show
run 'tail -n 10 variables.tf'
run 'tail -n 9 tests/rules.tftest.hcl'
block range-rule-run
run 'rm tests/range.tftest.hcl'
run 'AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/rules.tftest.hcl'

block all
run 'terraform test'
block test-help
run 'terraform test -h'
block layout
run 'tree'
