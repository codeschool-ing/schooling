#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents, vpc-… and i-…, the
# bucket's suffix and the timings in "Creation complete after 1s" are different
# on every run, so a second run prints different ones. The AMI ids are two of
# the sample images moto ships, and are the same every time.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the files ana wrote (put below), whose contents the lesson shows in full,
#     and the first apply of them, which lesson 2 already showed and which is
#     quiet here;
#   - every edit to main.tf and versions.tf, made with a quiet sed or cat and
#     shown in the lesson as the `git diff` that follows it;
#   - the git housekeeping: the repository, its commits, and the switch to the
#     `hotfix` branch and back in "saved-plans", which the prose describes.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'
quiet 'git config --global advice.detachedHead false'
commit() { quiet "git add -A && git commit -qm '$1'"; }

mkdir -p shop && cd shop

block base
put versions.tf <<'CODE'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.0"
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
  tags       = { Name = "shop" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-b" }
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

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "203.0.113.0/24"
}

resource "aws_instance" "web" {
  ami                    = "ami-1e749f67"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.a.id
  vpc_security_group_ids = [aws_security_group.web.id]
  tags                   = { Name = "web" }
}

resource "aws_iam_role" "web" {
  name = "web"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
CODE
quiet 'terraform init'
quiet 'terraform apply -auto-approve'
quiet 'git init -q . && printf ".terraform/\n*.tfstate*\ntfplan*\n" > .gitignore'
commit 'the shop network, web and its role'
run 'terraform state list'

# ---- reading-a-plan: one edit that uses every symbol
block edit
quiet "sed -i 's/Name = \"shop-a\"/Name = \"shop-public-a\"/' main.tf"
quiet "sed -i 's/ami-1e749f67/ami-785db401/' main.tf"
quiet "python3 - <<'PY'
import re
p = 'main.tf'; s = open(p).read()
s = re.sub(r'resource \"aws_subnet\" \"b\" \{.*?\n\}\n\n', '', s, flags=re.S)
open(p, 'w').write(s)
PY"
cat >> main.tf <<'CODE'

resource "aws_s3_bucket" "assets" {
  bucket_prefix = "shop-assets-"
}

data "aws_iam_policy_document" "assets_read" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]
  }
}

resource "aws_iam_role_policy" "web_assets" {
  name   = "assets-read"
  role   = aws_iam_role.web.id
  policy = data.aws_iam_policy_document.assets_read.json
}

resource "random_password" "db" {
  length = 24
}
CODE
run 'git diff'
block plan
run 'terraform plan'

# ---- saved-plans
block save
run 'terraform plan -out=tfplan | tail -n 6'
run 'terraform show tfplan | tail -n 3'
run 'unzip -l tfplan'
commit 'shop: public subnet, new image, assets bucket'
quiet 'git branch change'

# meanwhile, on main: a hotfix that tags the VPC, applied first
block hotfix
quiet 'git checkout -q -b hotfix HEAD~1'
quiet "sed -i 's/tags       = { Name = \"shop\" }/tags       = { Name = \"shop\", Owner = \"ana\" }/' main.tf"
run 'git diff'
run 'terraform apply -auto-approve | tail -n 3'
commit 'tag the VPC with its owner'
quiet 'git checkout -q change'
block stale
run 'git log --format=%s -1'
run 'terraform apply tfplan'
block serials
run 'unzip -p tfplan tfstate | jq .serial'
run 'jq .serial terraform.tfstate'
block replan
quiet 'git rebase -q hotfix'
run 'git log --format=%s -2'
run 'terraform plan -out=tfplan | tail -n 6'

# ---- plan-json, on the fresh saved plan, before it is applied
block json-actions
run "terraform show -json tfplan | jq -c '.resource_changes[] | {address, actions: .change.actions}'"
block json-format
run "terraform show -json tfplan | jq '{format_version, terraform_version, n: (.resource_changes | length)}'"
block guard-file
put check-plan.sh <<'CODE'
#!/bin/sh
# Refuse a saved plan that deletes anything, replacements included.
set -eu
plan=${1:-tfplan}
deletes=$(terraform show -json "$plan" | jq -r '
  .resource_changes[]
  | select(.change.actions | index("delete"))
  | "\(.change.actions | join(","))  \(.address)"')
if [ -n "$deletes" ]; then
  echo "refused: this plan deletes"
  echo "$deletes"
  exit 1
fi
echo "ok: this plan deletes nothing"
CODE
quiet 'chmod +x check-plan.sh'
block guard-refuses
run './check-plan.sh tfplan; echo "exit $?"'
block detailed
run 'terraform plan -detailed-exitcode > /dev/null; echo "exit $?"'

# ---- apply the saved plan
block apply-saved
run 'terraform apply tfplan'
run 'terraform plan -detailed-exitcode > /dev/null; echo "exit $?"'
commit 'applied'

# ---- what-to-look-for
block widen
quiet "sed -i 's|cidr_ipv4         = \"203.0.113.0/24\"|cidr_ipv4         = \"0.0.0.0/0\"|' main.tf"
quiet "sed -i 's|actions   = \\[\"s3:GetObject\"\\]|actions   = [\"s3:*\"]|' main.tf"
run 'git diff'
run 'terraform plan'
quiet 'git checkout -q main.tf'

block upgrade
quiet "sed -i 's/version = \"~> 3.8.0\"/version = \"~> 3.9\"/' versions.tf"
run 'git diff versions.tf'
run 'terraform plan'
run 'terraform init -upgrade | grep -i random'
run 'git diff .terraform.lock.hcl'
quiet 'git checkout -q versions.tf .terraform.lock.hcl'
quiet 'terraform init -upgrade'

# ---- partial-apply
block typo
cat >> main.tf <<'CODE'

resource "aws_security_group" "batch" {
  name        = "batch"
  description = "batch workers"
  vpc_id      = aws_vpc.shop.id
}

resource "aws_subnet" "c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.30.3.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-c" }
}

resource "aws_instance" "batch" {
  ami                    = "ami-785db401"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.c.id
  vpc_security_group_ids = [aws_security_group.batch.id]
  tags                   = { Name = "batch" }
}
CODE
run 'git diff'
quiet 'terraform plan -out=tfplan'
run './check-plan.sh tfplan; echo "exit $?"'
block partial
run 'terraform apply tfplan; echo "exit $?"'
block after-partial
run 'terraform state list'
run 'terraform plan -no-color | grep -E "^  #|Plan:"'
block spent
run 'terraform apply tfplan; echo "exit $?"'
block fix
quiet "sed -i 's|10.30.3.0/24|10.20.3.0/24|' main.tf"
run 'git diff'
run 'terraform apply -auto-approve | tail -n 6'
commit 'batch workers in subnet c'

# ---- targeting
block two-changes
quiet "python3 - <<'PY'
p = 'main.tf'; s = open(p).read()
i = s.index('resource \"aws_instance\" \"batch\"')
s = s[:i] + s[i:].replace('t3.micro', 't3.small', 1)
open(p, 'w').write(s)
PY"
quiet "sed -i 's/{ Name = \"shop\", Owner = \"ana\" }/{ Name = \"shop\", Owner = \"ana\", Project = \"shop\" }/' main.tf"
cat >> main.tf <<'CODE'

resource "aws_subnet" "d" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.4.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-d" }
}
CODE
run 'git diff'
block target-plan
run 'terraform plan -target=aws_subnet.d'
block target-apply
run 'terraform apply -target=aws_subnet.d -auto-approve'
block after-target
run 'terraform plan -no-color | grep -E "^  #|Plan:"'
run 'terraform apply -auto-approve | tail -n 1'
