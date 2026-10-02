#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents, vpc-… and sg-…, are
# random, and so are the git commit ids, so a second run prints different ones.
#
# THERE IS NO CI SERVICE HERE. The two workflow files (GitHub Actions and
# GitLab CI) are written by ana below and never run: the lab has no GitHub and
# no GitLab. What they call, ci.sh, is run, each time in a fresh clone under
# ~/ci/ standing in for a runner. A bare repository, ~/git/shop.git, stands in
# for the remote, and copying tfplan from one clone to another stands in for
# the artifact a runner uploads and the next job downloads.
#
# What is STAGED rather than typed, and not shown in the lesson: the state
# bucket, made as lesson 7 made it; the files ana wrote (put below), whose
# contents the lesson shows; and the commits and pushes that stand for merged
# pull requests, which are the git commands marked below. In the block
# no-input, `sleep 30 |` stands in for a runner whose input nobody closes and
# `timeout 5` for the time limit a CI job has.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'
quiet 'git config --global advice.detachedHead false'

# STAGED: the state bucket, as lesson 7 made it.
quiet 'aws s3api create-bucket --bucket shop-tfstate-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1'
quiet 'aws s3api put-bucket-versioning --bucket shop-tfstate-123456789012 --versioning-configuration Status=Enabled'
quiet 'git init -q --bare git/shop.git'

mkdir -p shop && cd shop
quiet 'git init -q && git remote add origin ~/git/shop.git'

block files
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
  tags       = { Name = "shop", Environment = var.environment }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

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
CODE
put variables.tf <<'CODE'
variable "environment" {
  type        = string
  description = "Which environment this state describes."
}
CODE
put prod.tfvars <<'CODE'
environment = "prod"
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
put .gitignore <<'CODE'
.terraform/
*.tfstate
*.tfstate.*
tfplan
plan.txt
CODE
put ci.sh <<'CODE'
#!/bin/sh
# The pipeline's steps, written once. The workflow files decide when each
# stage runs and with which credentials; what a stage does is written here,
# so a laptop can run exactly what a runner runs.
set -eux
export TF_IN_AUTOMATION=1

case "$1" in
check)
  terraform fmt -check -recursive
  terraform init -input=false -backend=false
  terraform validate
  ;;
scan)
  trivy config --quiet --skip-check-update \
    --severity HIGH,CRITICAL --exit-code 1 .
  ;;
plan)
  terraform init -input=false
  terraform plan -input=false -lock-timeout=5m \
    -var-file=prod.tfvars -out=tfplan
  terraform show -no-color tfplan > plan.txt
  ;;
apply)
  terraform init -input=false
  terraform apply -input=false -lock-timeout=5m tfplan
  ;;
esac
CODE
put .github/workflows/terraform.yml <<'CODE'
# Illustrative: written for lesson 15 and never run by it. Every step calls
# ci.sh, which the lesson does run.
name: terraform

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: terraform-${{ github.ref }}
  cancel-in-progress: false

jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false
      - uses: aquasecurity/setup-trivy@81e514348e19b6112ce2a7e3ecbafe19c1e1f567 # v0.3.1
        with:
          version: v0.75.0
      - run: ./ci.sh check
      - run: ./ci.sh scan

  plan:
    needs: check
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false
      - uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: arn:aws:iam::123456789012:role/shop-plan
          aws-region: sa-east-1
      - run: ./ci.sh plan
      - if: github.event_name == 'pull_request'
        env:
          GH_TOKEN: ${{ github.token }}
          PR: ${{ github.event.pull_request.number }}
        run: |
          { echo '~~~'; cat plan.txt; echo '~~~'; } > comment.md
          gh pr comment "$PR" --body-file comment.md
      - if: github.event_name == 'push'
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: tfplan
          path: tfplan
          retention-days: 3

  apply:
    if: github.event_name == 'push'
    needs: plan
    runs-on: ubuntu-24.04
    environment: production
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false
      - uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: arn:aws:iam::123456789012:role/shop-apply
          aws-region: sa-east-1
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: tfplan
      - run: ./ci.sh apply
CODE
put .gitlab-ci.yml <<'CODE'
# Illustrative: written for lesson 15 and never run by it. Every job calls
# ci.sh, which the lesson does run.
stages: [check, plan, apply]

default:
  image:
    name: hashicorp/terraform:1.16.4
    entrypoint: [""]

.aws:
  id_tokens:
    AWS_WEB_IDENTITY_TOKEN:
      aud: sts.amazonaws.com
  before_script:
    - echo "$AWS_WEB_IDENTITY_TOKEN" > "$CI_BUILDS_DIR/web-identity-token"
    - export AWS_WEB_IDENTITY_TOKEN_FILE="$CI_BUILDS_DIR/web-identity-token"
    - export AWS_REGION=sa-east-1

check:
  stage: check
  script:
    - ./ci.sh check

scan:
  stage: check
  image:
    name: aquasec/trivy:0.75.0
    entrypoint: [""]
  script:
    - ./ci.sh scan

plan:
  stage: plan
  extends: .aws
  variables:
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/shop-plan
  script:
    - ./ci.sh plan
  artifacts:
    paths: [tfplan, plan.txt]
    expire_in: 3 days

apply:
  stage: apply
  extends: .aws
  variables:
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/shop-apply
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
  environment: production
  resource_group: production
  needs: [plan]
  script:
    - ./ci.sh apply
CODE
quiet 'chmod +x ci.sh'
quiet 'terraform init -input=false'
# STAGED: the first commit, pushed to the remote.
quiet 'git add -A && git commit -qm "shop: network and pipeline" && git push -q origin main'

block parse
run "python3 -c 'import yaml; print(list(yaml.safe_load(open(\".github/workflows/terraform.yml\"))[\"jobs\"]))'"
run "python3 -c 'import yaml; print([k for k, v in yaml.safe_load(open(\".gitlab-ci.yml\")).items() if \"script\" in v])'"

# Run 1: the pipeline for the first commit on main.
cd ~
block run1-clone
run 'git clone -q git/shop.git ci/run-1'
cd ci/run-1
run 'git log --oneline -1'
block run1-check
run './ci.sh check'
block run1-scan
run './ci.sh scan'
block run1-plan
run './ci.sh plan'
block run1-files
run 'ls'
run 'tail -n 1 plan.txt'
block automation
run 'TF_IN_AUTOMATION= terraform plan -input=false -var-file=prod.tfvars | tail -n 6'
run 'TF_IN_AUTOMATION=1 terraform plan -input=false -var-file=prod.tfvars | tail -n 3'
block no-input
run 'sleep 30 | timeout 5 terraform plan; echo "exit $?"'
run 'terraform plan -input=false; echo "exit $?"'

# STAGED: a pull request adding an Owner tag, merged while run 1 waits for
# its approval.
cd ~/shop
quiet "sed -i 's/{ Name = \"shop\", Environment = var.environment }/{ Name = \"shop\", Environment = var.environment, Owner = \"ana\" }/' main.tf"
quiet 'terraform fmt'
quiet 'git commit -qam "shop: Owner tag on the VPC" && git push -q origin main'

# Run 2: the pipeline for that commit, planned before run 1 applied.
cd ~
block run2-plan
run 'git clone -q git/shop.git ci/run-2'
cd ci/run-2
run 'git log --oneline -1'
run './ci.sh plan 2>&1 | grep -E "# aws|Plan:"'

# Run 1's apply job, approved.
cd ~
block run1-apply
run 'git clone -q git/shop.git ci/run-1-apply'
cd ci/run-1-apply
run 'git log --oneline -1'
run 'cp ../run-1/tfplan .'
run './ci.sh apply'
block run1-applied
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].Tags[].Key" --output text'
run 'grep -c Owner main.tf'

# Run 2's apply job, approved after run 1's.
cd ~
block run2-apply
quiet 'git clone -q git/shop.git ci/run-2-apply'
cd ci/run-2-apply
quiet 'cp ../run-2/tfplan .'
run './ci.sh apply'
block run2-replan
cd ~/ci/run-2
run './ci.sh plan 2>&1 | grep -E "# aws|Plan:"'
quiet 'cp tfplan ../run-2-apply/'
cd ../run-2-apply
run './ci.sh apply 2>&1 | tail -n 1'
block vpcs
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text'

# The laptop: a change tried out, not committed.
cd ~/shop
quiet 'git pull -q origin main'
quiet "sed -i 's#10.20.1.0/24#10.20.3.0/24#' main.tf"
block laptop
run 'git status --short'
run 'git diff --stat'
run 'terraform plan -var-file=prod.tfvars | grep -E "# aws|forces replacement|Plan:"'
quiet 'git checkout -q main.tf'

# A pull request that opens SSH to the world: the scan stops it.
quiet 'git checkout -qb ssh'
put ssh.tf <<'CODE'
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  description       = "SSH"
  security_group_id = aws_security_group.web.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
CODE
quiet 'git add ssh.tf && git commit -qm "web: SSH for debugging" && git push -q origin ssh'
cd ~
block pr-scan
run 'git clone -q -b ssh git/shop.git ci/pr-ssh'
cd ci/pr-ssh
run './ci.sh check 2>&1 | tail -n 2'
run './ci.sh scan; echo "exit $?"'

# The roles the pipeline assumes: a configuration of their own, applied once
# by an administrator.
cd ~
mkdir -p ci-roles && cd ci-roles
block roles-file
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

locals {
  repo   = "repo:example/shop"
  bucket = "arn:aws:s3:::shop-tfstate-123456789012"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Who may become each role: a job of this repository, and for apply
# only a job running in the production environment.
data "aws_iam_policy_document" "trust" {
  for_each = {
    plan  = ["${local.repo}:pull_request", "${local.repo}:ref:refs/heads/main"]
    apply = ["${local.repo}:environment:production"]
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value
    }
  }
}

resource "aws_iam_role" "ci" {
  for_each             = data.aws_iam_policy_document.trust
  name                 = "shop-${each.key}"
  assume_role_policy   = each.value.json
  max_session_duration = 3600
}

# plan reads the network and the state, and writes only the lock file
resource "aws_iam_role_policy" "plan" {
  name = "plan"
  role = aws_iam_role.ci["plan"].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:Describe*"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = local.bucket },
      { Effect = "Allow", Action = ["s3:GetObject"], Resource = "${local.bucket}/shop/*" },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.bucket}/shop/terraform.tfstate.tflock"
      },
    ]
  })
}

# apply changes the network and writes the state
resource "aws_iam_role_policy" "apply" {
  name = "apply"
  role = aws_iam_role.ci["apply"].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:*"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = local.bucket },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.bucket}/shop/*"
      },
    ]
  })
}
CODE
quiet 'terraform init -input=false'
block roles-apply
run 'terraform apply -auto-approve | tail -n 1'
block roles-trust
run 'aws iam get-role --role-name shop-apply --query Role.AssumeRolePolicyDocument'
run 'aws iam list-role-policies --role-name shop-plan --output text'
