#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents, vpc-… and i-…, are
# random, so a second run prints different ones. The AMI id is one of moto's
# own sample images, the same on every run. Dates come from the day the script
# runs, so the expiry dates in "ephemeral-environments" move with it.
#
# THE PRICES ARE NOT READ HERE. The lab has no network, and the AWS price list
# is a download. The figures in price.py are lines of the cloud course's sheet,
# content/code/courses/cloud/prices.py, copied as that course quotes them: the
# sa-east-1 column, at the offer versions it pins (AmazonEC2 20260925174521,
# AmazonVPC 20260917190528). The arithmetic is done in the run.
#
# Infracost is NOT run: it needs an API key and its own pricing service, which
# the lab cannot reach. The lesson says so and shows no output for it.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - edits to a .tf file made by sed, shown as the `git diff` ana runs, and a
#     quiet apply after a plan the lesson has already shown;
#   - in "orphans", a volume and an address a colleague made by hand, which
#     are the aws commands marked below;
#   - in "ephemeral-environments", the preview environment for pr-17, created
#     quietly with an expiry date already in the past, as if ten days ago.
#   - in "budgets", nothing is applied: against moto the apply of a budget with
#     an alert never finishes (moto stores the budget, then answers the
#     provider's read of the alert's subscribers with an internal error, and
#     the provider retries), so the lesson shows the plan.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'
commit() { quiet "git add -A && git commit -qm '$1'"; }

mkdir -p shop && cd shop

# ---- pricing-a-plan
put main.tf <<'CODE'
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
CODE
put network.tf <<'CODE'
resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-public-a" }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-private-c" }
}

resource "aws_internet_gateway" "shop" {
  vpc_id = aws_vpc.shop.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

# lets the private subnet reach the internet without being reachable from it
resource "aws_nat_gateway" "shop" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.shop]
}
CODE
put web.tf <<'CODE'
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-1e749f67"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private_c.id

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "web-${count.index}" }
}
CODE
put price.py <<'CODE'
#!/usr/bin/env python3
"""What a plan adds to the monthly bill, at list price.

    terraform show -json tfplan | python3 price.py
"""
import json
import sys

HOURS = 730  # an average month: 8,760 hours a year over 12

# sa-east-1, USD, from the cloud course's prices.py
# (offers AmazonEC2 20260925174521 and AmazonVPC 20260917190528)
INSTANCE_PER_HOUR = {"t3.micro": 0.01680, "t3.medium": 0.06720, "m7i.large": 0.16065}
NAT_PER_HOUR = 0.0930
IPV4_PER_HOUR = 0.0050
GP3_PER_GB_MONTH = 0.1520


def monthly(kind, v):
    """USD a month for one resource, or None if the sheet has no line for it."""
    if kind == "aws_instance":
        disk = sum(d["volume_size"] for d in v["root_block_device"])
        return INSTANCE_PER_HOUR[v["instance_type"]] * HOURS + disk * GP3_PER_GB_MONTH
    if kind == "aws_nat_gateway":
        return NAT_PER_HOUR * HOURS
    if kind == "aws_eip":
        return IPV4_PER_HOUR * HOURS
    return None


total, unpriced = 0.0, []
for rc in json.load(sys.stdin)["resource_changes"]:
    actions = rc["change"]["actions"]
    if actions in (["no-op"], ["read"]):
        continue
    before, after = (rc["change"][k] for k in ("before", "after"))
    old = monthly(rc["type"], before) if before else 0.0
    new = monthly(rc["type"], after) if after else 0.0
    if old is None or new is None:
        unpriced.append(rc["address"])
        continue
    total += new - old
    print(f"{rc['address']:22} {'/'.join(actions):8} {old:8.2f} -> {new:8.2f}")
print(f"{'change per month, USD':41} {total:+8.2f}")
if unpriced:
    print("no line on the sheet:", ", ".join(unpriced))
CODE
quiet 'printf ".terraform/\n*.tfstate*\ntfplan\n" > .gitignore'
quiet 'git init -q .'
quiet 'terraform init'
commit 'the shop: network and two web servers'
block plan-summary
run 'terraform plan -no-color -out tfplan | grep -E "will be created|Plan:"'
block plan-json
run "terraform show -json tfplan | jq -c '.resource_changes[] | select(.type == \"aws_instance\") | [.address, .change.actions[0], .change.after.instance_type]'"
block price-first
run 'terraform show -json tfplan | python3 price.py'
quiet 'terraform apply -auto-approve tfplan'

# ---- infracost: the same idea as a diff on a change
block bigger-diff
quiet "sed -i 's/t3.medium/m7i.large/' web.tf"
run 'git diff'
block bigger-price
run 'terraform plan -no-color -out tfplan | grep -E "will be updated|instance_type|Plan:"'
run 'terraform show -json tfplan | python3 price.py'
quiet 'git checkout -q web.tf'
quiet 'rm -f tfplan'

# ---- tags
block tags
put main.tf <<'CODE'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "tags" {
  description = "Applied to every resource this configuration creates."
  type        = map(string)

  validation {
    condition = alltrue([
      for k in ["Owner", "Project", "Environment", "CostCenter"] : contains(keys(var.tags), k)
    ])
    error_message = "The tags must include Owner, Project, Environment and CostCenter."
  }
}

provider "aws" {
  region = "sa-east-1"

  default_tags {
    tags = var.tags
  }
}
CODE
put terraform.tfvars <<'CODE'
tags = {
  Owner       = "ana"
  Project     = "shop"
  Environment = "prod"
  CostCenter  = "cc-4410"
}
CODE
block tags-plan
run 'terraform plan -no-color | grep -E "will be updated|Plan:"'
block tags-plan-one
run "terraform plan -no-color | sed -n '/aws_nat_gateway.shop will be updated/,/^\$/p'"
quiet 'terraform apply -auto-approve'
commit 'tag everything for the bill'
block tags-read
run 'aws ec2 describe-instances --filters Name=tag:Name,Values=web-0 --query "Reservations[0].Instances[0].Tags" --output table'
block tags-missing
run "terraform plan -var 'tags={Owner=\"ana\", Project=\"shop\", Environment=\"prod\"}'"

# ---- orphans
# STAGED: what a colleague typed for an export, from his own machine, and
# forgot: a 100 GB volume and an address that never got attached.
quiet 'aws ec2 create-volume --size 100 --availability-zone sa-east-1a --volume-type gp3'
quiet 'aws ec2 allocate-address --domain vpc'
block orphans-tagged
run 'aws resourcegroupstaggingapi get-resources --resource-type-filters ec2:volume --query "ResourceTagMappingList[].ResourceARN"'
block orphans-volumes
run "aws ec2 describe-volumes --output json | jq -r '.Volumes[] | select((.Tags // []) | length == 0) | [.VolumeId, .State, .Size, .Size * 0.1520] | @tsv'"
block orphans-addresses
run "aws ec2 describe-addresses --output json | jq -r '.Addresses[] | select((.AssociationId // \"\") == \"\") | [.AllocationId, .PublicIp, ((.Tags // []) | length)] | @tsv'"

# ---- ephemeral-environments
cd ~ && mkdir -p shop-preview && cd shop-preview
put main.tf <<'CODE'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "expires" {
  description = "The day after which this environment may be destroyed, YYYY-MM-DD. Set by the pipeline."
  type        = string
}

provider "aws" {
  region = "sa-east-1"

  default_tags {
    tags = {
      Owner       = "ana"
      Project     = "shop"
      Environment = terraform.workspace # pr-17, pr-21, …
      CostCenter  = "cc-4410"
      Expires     = var.expires
    }
  }
}

resource "aws_instance" "web" {
  ami           = "ami-1e749f67"
  instance_type = "t3.medium"

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

resource "aws_eip" "web" {
  domain   = "vpc"
  instance = aws_instance.web.id
}
CODE
cp ~/shop/price.py .
quiet 'terraform init'
# STAGED: the preview of pull request 17, created ten days ago and never destroyed.
quiet 'terraform workspace new pr-17'
quiet "terraform apply -auto-approve -var expires=$(date -d '-3 days' +%F)"
block preview-new
run 'terraform workspace new pr-21'
block preview-plan
run 'terraform plan -no-color -var "expires=$(date -d +7days +%F)" -out tfplan | grep -E "will be created|Expires|Plan:"'
block preview-price
run 'terraform show -json tfplan | python3 price.py'
quiet 'terraform apply -auto-approve tfplan'
put expired.sh <<'CODE'
#!/bin/sh
# Every resource whose Expires tag is a day before today.
aws resourcegroupstaggingapi get-resources --tag-filters Key=Expires --output json |
  jq -r --arg today "$(date +%F)" '
    .ResourceTagMappingList[]
    | (.Tags | from_entries) as $t
    | select($t.Expires < $today)
    | [$t.Environment, $t.Expires, (.ResourceARN | split(":")[5])]
    | @tsv'
CODE
block expired
run 'sh expired.sh'
block destroy-17
run 'terraform workspace select pr-17'
run 'terraform destroy -auto-approve -var expires=$(date +%F) | tail -1'
block after-destroy
run 'sh expired.sh'
run 'aws ec2 describe-instances --filters Name=tag:Environment,Values=pr-17 --query "Reservations[].Instances[].State.Name" --output text'

# ---- budgets
cd ~/shop
put budget.tf <<'CODE'
resource "aws_budgets_budget" "shop" {
  name         = "shop-monthly"
  budget_type  = "COST"
  limit_amount = "300"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # only what carries the tag Project = shop
  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Project$shop"]
  }

  notification {
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["ana@example.com"]
  }

  notification {
    notification_type          = "FORECASTED"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["ana@example.com"]
  }
}
CODE
block budget-plan
run "terraform plan -no-color | sed -n '/Terraform will perform/,\$p'"
