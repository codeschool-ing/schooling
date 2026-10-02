#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of iac, as a script that produces
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
# sg-…, are random, and so is a state's lineage, so a second run prints
# different ones.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the starting point, the shop as lesson 7 left it plus the two buckets of
#     lesson 6: the state bucket with versioning, one configuration in ~/shop
#     whose state is the S3 key shop/terraform.tfstate, applied once. The
#     lesson shows its main.tf in full;
#   - the files ana and the data team wrote (put below), whose contents the
#     lesson shows in full, and the git commits, made quietly;
#   - the bucket and the security group a colleague made by hand, for
#     "import-command" and "import-blocks": the aws commands marked below.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

tfinit() { # a quiet init that fails the script loudly, never silently
  terraform init -input=false "$@" >/dev/null 2>&1 || { echo "##### FAILED: terraform init $* in $PWD"; exit 1; }
}

BUCKET=shop-tfstate-123456789012
quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'

# STAGED: the state bucket, as lesson 7 made it.
quiet "aws s3api create-bucket --bucket $BUCKET --create-bucket-configuration LocationConstraint=sa-east-1"
quiet "aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled"

mkdir -p shop && cd shop

block one-big-state
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

# The network: made once, changed a few times a year.
resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-c" }
}

# The application: changed every week.
resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
CODE
put backend.tf <<'CODE'
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "shop/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
CODE
tfinit
quiet 'terraform apply -auto-approve'
quiet 'printf ".terraform/\n*.tfstate\n*.tfstate.*\n" > .gitignore'
quiet 'git init -q && git add . && git commit -qm "the shop, in one state"'
block big-list
run 'terraform state list'
run "aws s3 ls --recursive s3://$BUCKET"
block big-plan
quiet "sed -i 's/bucket = \"shop-assets-dev\"/bucket = \"shop-assets-dev\"\\n  tags   = { Owner = \"ana\" }/' main.tf"
run 'git diff'
run 'terraform plan -no-color | grep -E "Refreshing|^  #|^Plan"'
quiet 'git checkout -q main.tf'

block splitting
mkdir -p network app
quiet 'git mv main.tf backend.tf app/'
cd network
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

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-c" }
}
CODE
put outputs.tf <<'CODE'
output "vpc_id" {
  description = "The shop's VPC."
  value       = aws_vpc.shop.id
}

output "vpc_cidr" {
  description = "The VPC's address range."
  value       = aws_vpc.shop.cidr_block
}

output "public_subnet_ids" {
  description = "One public subnet per availability zone."
  value       = [aws_subnet.public_a.id, aws_subnet.public_c.id]
}
CODE
put backend.tf <<'CODE'
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "network/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
CODE
cd ../app
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

data "aws_vpc" "shop" {
  tags = { Name = "shop" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = data.aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
CODE
run "sed -i 's|key          = \"shop/terraform.tfstate\"|key          = \"app/terraform.tfstate\"|' backend.tf"
cd ..
block tree
run 'tree --noreport -I .terraform'
block pull
cd app
run 'terraform init -backend=false > /dev/null'
cd ..
run 'mkdir split && cd split'
cd split
run "aws s3 cp s3://$BUCKET/shop/terraform.tfstate shop.tfstate"
block state-mv
run 'terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_vpc.shop aws_vpc.shop'
run 'terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_subnet.public_a aws_subnet.public_a'
run 'terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_subnet.public_c aws_subnet.public_c'
run 'terraform state list -state=shop.tfstate'
run 'terraform state list -state=network.tfstate'
block push-network
cd ../network
tfinit
run 'terraform state push ../split/network.tfstate'
run 'terraform plan'
block push-app
cd ../app
tfinit
run 'terraform state push ../split/shop.tfstate'
run 'terraform plan'
block two-keys
run "aws s3 rm s3://$BUCKET/shop/terraform.tfstate"
run "aws s3 ls --recursive s3://$BUCKET"
run 'rm -r ../split'
cd ..
quiet 'git add . && git commit -qm "split the network from the app"'

echo "##### EXPLORE"
cd app
run 'terraform state list'
