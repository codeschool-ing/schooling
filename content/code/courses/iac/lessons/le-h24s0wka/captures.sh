#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents, vpc-… and sg-…, and
# the suffix random_id draws for the bucket, are random, so a second run prints
# different ones.
#
# What is STAGED rather than typed, and not shown in the lesson: the files ana
# wrote (put below), whose contents the lesson shows in full; the moments
# between sections where she moves terraform.tfvars aside and back, or edits a
# constraint, which are the `quiet` lines; and git's identity.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
mkdir -p shop && cd shop

block first-configuration
put versions.tf <<'CODE'
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
CODE
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "shop"
  }
}
CODE
block before-init
run 'ls'
run 'terraform plan'

block init
run 'terraform init'
block init-files
run 'ls -A'
run 'find .terraform -maxdepth 5'
block lock
run 'cat .terraform.lock.hcl'
block providers-lock
run 'terraform providers lock -platform=darwin_arm64'

block resources
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "shop"
  }
}

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "shop-web-a"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
CODE
block validate
run 'terraform validate'
block graph
run 'terraform graph'

block plan
run 'terraform plan'
block apply-no
answer 'terraform apply' no
block apply-yes
answer 'terraform apply' yes
block state-list
run 'terraform state list'
run 'aws ec2 describe-subnets --filters Name=tag:Name,Values=shop-web-a --query "Subnets[].[SubnetId,VpcId,CidrBlock]" --output text'
block apply-again
run 'terraform apply -auto-approve'

block variables
put variables.tf <<'CODE'
variable "environment" {
  description = "Which copy of the shop this is: dev or prod."
  type        = string
}

variable "vpc_cidr" {
  description = "The address range of the shop's VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "https_port" {
  description = "The port the web servers answer on."
  type        = number
  default     = 443
}
CODE
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "shop"
    Environment = var.environment
  }
}

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name        = "shop-web-a"
    Environment = var.environment
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  cidr_ipv4         = "0.0.0.0/0"
}
CODE
block missing
run 'terraform plan -input=false'
block prompted
answer 'terraform plan' dev
block tfvars
put terraform.tfvars <<'CODE'
environment = "dev"
CODE
run 'terraform plan'
block precedence
run 'echo var.environment | terraform console'
run 'echo var.environment | TF_VAR_environment=prod terraform console'
run 'echo var.environment | terraform console -var environment=prod'
block bad-type
run 'terraform plan -var https_port=https'
block apply-vars
run 'terraform apply -auto-approve'

block outputs
put outputs.tf <<'CODE'
output "vpc_id" {
  description = "The id AWS gave the shop's VPC."
  value       = aws_vpc.shop.id
}

output "web_subnet_id" {
  value = aws_subnet.web_a.id
}

output "web_security_group_id" {
  value = aws_security_group.web.id
}
CODE
run 'terraform apply -auto-approve'
block output-cmd
run 'terraform output'
run 'terraform output vpc_id'
run 'terraform output -raw vpc_id'
block output-json
run 'terraform output -json'
block output-use
run 'aws ec2 describe-vpcs --vpc-ids "$(terraform output -raw vpc_id)" --query "Vpcs[].Tags" --output text'
block output-missing
run 'terraform output bucket_name'

block providers
put versions.tf <<'CODE'
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}
CODE
put storage.tf <<'CODE'
resource "random_id" "bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-${random_id.bucket.hex}"

  tags = {
    Environment = var.environment
  }
}

resource "local_file" "network_env" {
  filename = "${path.module}/network.env"
  content  = <<-EOT
    VPC_ID=${aws_vpc.shop.id}
    SUBNET_ID=${aws_subnet.web_a.id}
    BUCKET=${aws_s3_bucket.assets.bucket}
  EOT
}
CODE
block new-provider-plan
run 'terraform plan'
block init-2
run 'terraform init'
block lock-2
run 'grep -A2 "^provider" .terraform.lock.hcl'
block apply-providers
run 'terraform apply -auto-approve'
block network-env
run 'cat network.env'
run 'terraform providers'
block constraint
quiet "sed -i 's/~> 3.8.0/~> 3.9/' versions.tf"
run 'grep -A1 "hashicorp/random" versions.tf'
run 'terraform plan'
block upgrade
run 'terraform init -upgrade'
run 'grep -A1 "hashicorp/random" .terraform.lock.hcl'

block destroy
answer 'terraform destroy' yes
block after-destroy
run 'ls'
run 'terraform state list'
run 'jq ".serial, (.resources | length)" terraform.tfstate'
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text'
run 'aws s3 ls'
block plan-after-destroy
run 'terraform plan'
