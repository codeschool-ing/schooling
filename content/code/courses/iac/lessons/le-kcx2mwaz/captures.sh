#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents, vpc-…, subnet-… and
# sg-…, are random, so a second run prints different ones.
#
# What is STAGED rather than typed, and not shown in the lesson: the files ana
# wrote (put below), whose contents the lesson shows in full; the moments
# between sections where she deletes a terraform.tfvars she was trying out, or
# a file she has finished with, which are the `quiet` lines; `terraform init`
# in each new directory, which lesson 2 already showed; the first apply in
# ~/shop/rules, whose plan the lesson does not need; and git's identity.
#
# A file the lesson shows in two versions is written by `rewrite`, below: put
# names a file by its path, so the later version is written under ~/.v/N/,
# quoted from there and copied over the real one. Terraform reads only the
# directory it runs in and never sees ~/.v.
#
# One arrangement of the lab is changed here, quietly, and changes nothing the
# lesson quotes: Terraform gets a provider cache of its own in /home/ana,
# filled from the same local mirror. The cache lab.sh shares between runs is
# rewritten by every `terraform init` of every run, and two runs at once made
# init fail with "text file busy" or a checksum mismatch.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

mkdir -p "$HOME/.tfcache"
cat > "$HOME/.terraformrc" <<'RC'
provider_installation {
  filesystem_mirror {
    path = "/opt/iac/mirror"
  }
}
plugin_cache_dir = "/home/ana/.tfcache"
RC
export TF_CLI_CONFIG_FILE=$HOME/.terraformrc

rewrite() { # N FILE <<'CODE'
  local here=$PWD
  mkdir -p "$HOME/.v/$1"
  (cd "$HOME/.v/$1" && put "$2")
  cp "$HOME/.v/$1/$2" "$here/$2"
}

quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
mkdir -p shop/network && cd shop/network

block count
put versions.tf <<'CODE'
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
put main.tf <<'CODE'
variable "subnets" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "public" {
  type    = bool
  default = true
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "app" {
  count = length(var.subnets)

  vpc_id     = aws_vpc.shop.id
  cidr_block = var.subnets[count.index]
  tags       = { Project = "shop" }
}

resource "aws_internet_gateway" "shop" {
  count = var.public ? 1 : 0

  vpc_id = aws_vpc.shop.id
}
CODE
put outputs.tf <<'CODE'
output "gateway" {
  value = aws_internet_gateway.shop[0].id
}
CODE
quiet 'terraform init'
block count-apply
run 'terraform apply -auto-approve'
block count-list
run 'terraform state list'
run 'echo "aws_subnet.app[1].cidr_block" | terraform console'
block count-zero
run 'terraform plan -var public=false'
block count-one
rewrite 1 outputs.tf <<'CODE'
output "gateway" {
  value = one(aws_internet_gateway.shop[*].id)
}
CODE
run 'terraform plan -var public=false'

block the-index-problem
put terraform.tfvars <<'CODE'
subnets = ["10.20.1.0/24", "10.20.3.0/24"]
CODE
run 'terraform plan'
quiet 'rm terraform.tfvars'

block for-each
mkdir -p ../scratch && cd ../scratch
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

variable "subnets" {
  type = map(string)
  default = {
    web = "10.20.1.0/24"
    app = "10.20.2.0/24"
    db  = "10.20.3.0/24"
  }
}

resource "aws_vpc" "scratch" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "scratch" }
}

resource "aws_subnet" "app" {
  for_each = var.subnets

  vpc_id     = aws_vpc.scratch.id
  cidr_block = each.value
  tags       = { Name = "scratch-${each.key}" }
}
CODE
quiet 'terraform init'
block for-each-apply
run 'terraform apply -auto-approve'
block for-each-list
run 'terraform state list'
block for-each-remove
put terraform.tfvars <<'CODE'
subnets = {
  web = "10.20.1.0/24"
  db  = "10.20.3.0/24"
}
CODE
run 'terraform plan'
quiet 'rm terraform.tfvars'
quiet 'terraform destroy -auto-approve'
block for-each-list-error
mkdir -p ../try && cd ../try
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "try" {
  for_each   = ["10.30.0.0/16", "10.31.0.0/16"]
  cidr_block = each.value
}
CODE
quiet 'terraform init'
run 'terraform plan'
cd ../network

block moved
rewrite 2 main.tf <<'CODE'
variable "subnets" {
  type = map(string)
  default = {
    web = "10.20.1.0/24"
    app = "10.20.2.0/24"
    db  = "10.20.3.0/24"
  }
}

variable "public" {
  type    = bool
  default = true
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "app" {
  for_each = var.subnets

  vpc_id     = aws_vpc.shop.id
  cidr_block = each.value
  tags       = { Project = "shop" }
}

resource "aws_internet_gateway" "shop" {
  count = var.public ? 1 : 0

  vpc_id = aws_vpc.shop.id
}
CODE
block moved-without
run 'terraform plan -no-color | grep -E "^  # |^Plan"'
block moved-file
put moved.tf <<'CODE'
moved {
  from = aws_subnet.app[0]
  to   = aws_subnet.app["web"]
}

moved {
  from = aws_subnet.app[1]
  to   = aws_subnet.app["app"]
}

moved {
  from = aws_subnet.app[2]
  to   = aws_subnet.app["db"]
}
CODE
block moved-plan
run 'terraform plan'
block moved-apply
run 'terraform apply -auto-approve'
run 'terraform state list'

block dynamic-blocks
put security.tf <<'CODE'
variable "web_ports" {
  type    = list(number)
  default = [80, 443]
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.shop.id

  dynamic "ingress" {
    for_each = var.web_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
CODE
block dynamic-apply
run 'terraform apply -auto-approve'
block dynamic-aws
run 'aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text'
block dynamic-more
run 'terraform plan -no-color -var "web_ports=[80, 443, 8443]" | grep -E "^  # |from_port|^Plan"'

block dynamic-rules
mkdir -p ../rules && cd ../rules
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

variable "web_ports" {
  type    = set(string)
  default = ["80", "443"]
}

resource "aws_vpc" "rules" {
  cidr_block = "10.50.0.0/16"
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.rules.id
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each = var.web_ports

  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
  cidr_ipv4         = "0.0.0.0/0"
}
CODE
quiet 'terraform init'
quiet 'terraform apply -auto-approve'
block dynamic-rules-plan
run 'terraform state list'
run 'terraform plan -no-color -var '"'"'web_ports=["80", "443", "8443"]'"'"' | grep -E "^  # |^Plan"'
cd ../network

block provider-aliases
put backup.tf <<'CODE'
provider "aws" {
  alias  = "us"
  region = "us-east-2"
}

resource "aws_s3_bucket" "backup" {
  provider = aws.us
  bucket   = "shop-backup-ana"
}
CODE
block aliases-apply
run 'terraform apply -auto-approve'
block aliases-where
run 'aws s3api get-bucket-location --bucket shop-backup-ana'
run 'aws ec2 describe-vpcs --region us-east-2 --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text'
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].CidrBlock" --output text'
block aliases-region
put logs.tf <<'CODE'
resource "aws_s3_bucket" "logs" {
  region = "us-east-2"
  bucket = "shop-logs-ana"
}
CODE
run 'terraform apply -auto-approve -no-color | grep -E "^  # |region|^Apply"'
run 'aws s3api get-bucket-location --bucket shop-logs-ana'
block aliases-missing
cd ../try
rewrite 4 main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "logs" {
  provider = aws.eu
  bucket   = "shop-archive-ana"
}
CODE
run 'terraform validate'
cd ../network

block choosing
mkdir -p ../routes && cd ../routes
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "routes" {
  cidr_block = "10.40.0.0/16"
}

resource "aws_subnet" "app" {
  for_each = { web = "10.40.1.0/24", db = "10.40.3.0/24" }

  vpc_id     = aws_vpc.routes.id
  cidr_block = each.value
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.routes.id
}

resource "aws_route_table_association" "app" {
  for_each = toset(values(aws_subnet.app)[*].id)

  subnet_id      = each.value
  route_table_id = aws_route_table.app.id
}
CODE
quiet 'terraform init'
block choosing-unknown
run 'terraform plan'
block choosing-fixed
rewrite 3 main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "routes" {
  cidr_block = "10.40.0.0/16"
}

resource "aws_subnet" "app" {
  for_each = { web = "10.40.1.0/24", db = "10.40.3.0/24" }

  vpc_id     = aws_vpc.routes.id
  cidr_block = each.value
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.routes.id
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.app.id
}
CODE
run 'terraform plan -no-color | grep -E "^  # |^Plan"'

# a last marker, so anything the lab prints while it tears down lands in no
# quoted block
block end
