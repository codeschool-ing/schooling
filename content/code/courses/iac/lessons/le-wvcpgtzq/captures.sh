#!/usr/bin/env bash
# draft
. "$(dirname "$0")/../../capture.sh"
quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'

mkdir -p shop/app && cd shop/app
block app-files
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

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_instance" "web" {
  ami           = "ami-1e749f67"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.a.id
  tags          = { Name = "web" }
}
CODE
quiet 'terraform init'
quiet 'terraform apply -auto-approve'
quiet 'git init -q . && printf ".terraform/\n*.tfstate*\n" > .gitignore && git add . && git commit -qm "the shop network and web"'

block tag-change
quiet "sed -i 's/Name = \"shop-a\"/Name = \"shop-public-a\"/' main.tf"
run 'git diff'
run 'terraform plan'
quiet 'terraform apply -auto-approve && git commit -qam "rename subnet"'

block ami-change
quiet "sed -i 's/ami-1e749f67/ami-785db401/' main.tf"
run 'git diff'
run 'terraform plan'
quiet 'git checkout -q main.tf'

block cidr-change
quiet "sed -i 's|10.20.1.0/24|10.20.3.0/24|' main.tf"
run 'terraform plan'
quiet 'git checkout -q main.tf'
