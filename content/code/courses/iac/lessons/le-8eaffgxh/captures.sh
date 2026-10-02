#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents, vpc-…, subnet-…,
# sg-…, i-… and the ami-… of an image somebody baked, are random, so a second
# run prints different ones. The images moto ships for Amazon and Canonical
# have fixed ids and carry the moment moto started as their creation date.
#
# What is STAGED rather than typed, and not shown as a session in the lesson:
#   - the network team's VPC and subnets, made by the script put under
#     ~/network-team and run quietly before Ana starts. The lesson shows the
#     script, because "what exists and who made it" is the point.
#   - the image team's two images, shop-web-20260915 and later
#     shop-web-20261001, made with create-image from a throwaway instance.
#   - the network team's second VPC, a staging copy also tagged Name=shop,
#     which is what breaks Ana's lookup in "not-found".
#   - the files ana wrote (put below), whose contents the lesson shows in full.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

quiet 'git config --global user.name Ana && git config --global user.email ana@example.com'

# ---------------------------------------------------------------- the network team
mkdir -p network-team && cd network-team
put create-network.sh <<'CODE'
#!/bin/sh
# The shared network, created by the network team with the AWS CLI.
# Ana's configuration does not create these and must not destroy them.
set -e
VPC=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop},{Key=Environment,Value=prod},{Key=Owner,Value=network}]' \
  --query Vpc.VpcId --output text)
aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.1.0/24 --availability-zone sa-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=shop-public-a},{Key=Tier,Value=public}]' > /dev/null
aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.2.0/24 --availability-zone sa-east-1c \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=shop-public-c},{Key=Tier,Value=public}]' > /dev/null
CODE
quiet 'sh create-network.sh'
cd ..

mkdir -p shop/app && cd shop/app

# ---------------------------------------------------------------- reading
block reading
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

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "region" {
  value = data.aws_region.current.region
}
CODE
quiet 'terraform init'
block reading-apply
run 'terraform apply -auto-approve'
block reading-state
run 'terraform state list'

# ---------------------------------------------------------------- shared-network
block shared-describe
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock,Tags[?Key==\`Owner\`]|[0].Value]" --output text'
put network.tf <<'CODE'
data "aws_vpc" "shop" {
  tags = {
    Name = "shop"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shop.id]
  }
  tags = {
    Tier = "public"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = data.aws_vpc.shop.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpc_cidr" {
  value = data.aws_vpc.shop.cidr_block
}

output "public_subnets" {
  value = length(data.aws_subnets.public.ids)
}
CODE
block shared-plan
run 'terraform plan'
block shared-apply
run 'terraform apply -auto-approve'
block shared-destroy
run 'terraform plan -destroy'

# ---------------------------------------------------------------- filters
# STAGED: the image team bakes the shop's web image. Its contents do not
# matter here; moto copies a record.
BASE=$(aws ec2 run-instances --image-id ami-1e749f67 --instance-type t3.micro --query 'Instances[0].InstanceId' --output text)
quiet "aws ec2 create-image --instance-id $BASE --name shop-web-20260915"
block filters-images
run 'aws ec2 describe-images --owners self --query "Images[].[Name,ImageId]" --output text'
put image.tf <<'CODE'
data "aws_ami" "web" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["shop-web-*"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.web.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
}

output "web_image" {
  value = data.aws_ami.web.name
}
CODE
block filters-apply
run 'terraform apply -auto-approve'
# STAGED: two weeks later the image team publishes a new build.
sleep 2
quiet "aws ec2 create-image --instance-id $BASE --name shop-web-20261001"
quiet "aws ec2 terminate-instances --instance-ids $BASE"
block filters-new
run 'aws ec2 describe-images --owners self --query "Images[].[Name,ImageId]" --output text'
block filters-plan
run 'terraform plan'
put image.tf <<'CODE'
variable "web_image" {
  description = "The exact image the web server runs. Changing it is a deliberate diff."
  type        = string
  default     = "shop-web-20260915"
}

data "aws_ami" "web" {
  owners = ["self"]

  filter {
    name   = "name"
    values = [var.web_image]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.web.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
}

output "web_image" {
  value = data.aws_ami.web.name
}
CODE
block filters-pinned
run 'terraform plan'

# ---------------------------------------------------------------- when-read
put subnet.tf <<'CODE'
resource "aws_subnet" "app" {
  vpc_id            = data.aws_vpc.shop.id
  cidr_block        = "10.20.3.0/24"
  availability_zone = "sa-east-1a"
  tags = {
    Name = "shop-app-a"
    Tier = "app"
  }
}

data "aws_availability_zone" "app" {
  name = aws_subnet.app.availability_zone
}

data "aws_subnets" "app" {
  tags = {
    Tier = "app"
  }
}

output "app_zone_id" {
  value = data.aws_availability_zone.app.zone_id
}

output "app_subnets" {
  value = data.aws_subnets.app.ids
}
CODE
block when-plan
run 'terraform plan'
block when-apply
run 'terraform apply -auto-approve'
block when-again
run 'terraform plan'
quiet 'terraform apply -auto-approve'
put subnet.tf <<'CODE'
resource "aws_subnet" "app" {
  vpc_id            = data.aws_vpc.shop.id
  cidr_block        = "10.20.3.0/24"
  availability_zone = "sa-east-1a"
  tags = {
    Name  = "shop-app-a"
    Tier  = "app"
    Owner = "ana"
  }
}

data "aws_availability_zone" "app" {
  name = aws_subnet.app.availability_zone
}

data "aws_subnets" "app" {
  tags = {
    Tier = "app"
  }
  depends_on = [aws_subnet.app]
}

output "app_zone_id" {
  value = data.aws_availability_zone.app.zone_id
}

output "app_subnets" {
  value = data.aws_subnets.app.ids
}
CODE
block when-depends
run 'terraform plan'
quiet 'terraform apply -auto-approve'

# ---------------------------------------------------------------- policy-documents
put office-cidrs.txt <<'CODE'
203.0.113.0/28
198.51.100.32/29
CODE
put bucket.tf <<'CODE'
resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-${data.aws_caller_identity.current.account_id}"
}

data "aws_iam_policy_document" "assets" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.assets.arn, "${aws_s3_bucket.assets.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "OfficeReadsObjects"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = split("\n", trimspace(data.local_file.office.content))
    }
  }
}

data "local_file" "office" {
  filename = "${path.module}/office-cidrs.txt"
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets.json
}
CODE
quiet 'terraform init'
block policy-plan
run 'terraform plan'
block policy-apply
run 'terraform apply -auto-approve'
block policy-json
run 'aws s3api get-bucket-policy --bucket shop-assets-123456789012 --query Policy --output text | jq .'

# ---------------------------------------------------------------- not-found
block notfound-vpc
mkdir -p ../probe && cd ../probe
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

data "aws_vpc" "prod" {
  tags = {
    Name = "shop-prod"
  }
}
CODE
quiet 'terraform init'
run 'terraform plan'
block notfound-ami
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

data "aws_ami" "web" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["shop-web-*"]
  }
}
CODE
run 'terraform plan'
block notfound-plural
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

data "aws_subnets" "private" {
  tags = {
    Tier = "private"
  }
}

output "private_subnets" {
  value = data.aws_subnets.private.ids
}
CODE
run 'terraform apply -auto-approve'
cd ../app
# STAGED: the network team builds a staging copy of the network, and copies
# its tags along with everything else.
quiet "aws ec2 create-vpc --cidr-block 10.30.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop},{Key=Environment,Value=staging},{Key=Owner,Value=network}]'"
block notfound-two
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[CidrBlock,Tags[?Key==\`Environment\`]|[0].Value]" --output text'
run 'terraform plan'
put network.tf <<'CODE'
data "aws_vpc" "shop" {
  tags = {
    Name        = "shop"
    Environment = "prod"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shop.id]
  }
  tags = {
    Tier = "public"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = data.aws_vpc.shop.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpc_cidr" {
  value = data.aws_vpc.shop.cidr_block
}

output "public_subnets" {
  value = length(data.aws_subnets.public.ids)
}
CODE
block notfound-fixed
run 'terraform plan'
