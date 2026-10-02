#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of iac, as a script that produces
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
# random, so a second run prints different ones. The two AMI ids are moto's
# own sample images, the same on every run.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - every edit to a .tf file is made by sed or a heredoc that is not quoted,
#     and the lesson shows it as the `git diff` ana runs afterwards; a first
#     apply of each configuration, before the lesson starts talking about it,
#     is quiet too;
#   - the tag a cost tool adds to the instance in "ignore-changes", which is
#     the aws command marked below.
#
# Terraform's plugin cache is private to the run (TF_PLUGIN_CACHE_DIR below),
# because the lab's shared one is rewritten by every fresh `terraform init`
# and another lab running at the same time can catch it half written.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

export TF_PLUGIN_CACHE_DIR=$HOME/.tf-cache
mkdir -p "$TF_PLUGIN_CACHE_DIR"
quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'
commit() { quiet "git add -A && git commit -qm '$1'"; }

mkdir -p shop/app && cd shop/app
block app
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
quiet 'git init -q . && printf ".terraform/\n*.tfstate*\n" > .gitignore'
commit 'the shop network and web'

# ---- update-or-replace
block tag-change
quiet "sed -i 's/Name = \"shop-a\"/Name = \"shop-public-a\"/' main.tf"
run 'git diff'
run 'terraform plan'
quiet 'terraform apply -auto-approve'
commit 'rename the subnet'

block ami-change
quiet "sed -i 's/ami-1e749f67/ami-785db401/' main.tf"
run 'git diff'
run 'terraform plan | grep -E "replace|Plan:"'

block cidr-change
quiet 'git checkout -q main.tf'
quiet "sed -i 's|10.20.1.0/24|10.20.3.0/24|' main.tf"
run 'git diff'
run 'terraform plan | grep -E "replace|Plan:"'
quiet 'git checkout -q main.tf'

# ---- create-before-destroy
block replace-default
quiet "sed -i 's/ami-1e749f67/ami-785db401/' main.tf"
run 'terraform apply -auto-approve | grep -E "Destr|Creat"'
commit 'web on the new image'

block cbd-diff
quiet "sed -i 's/^  tags          = { Name = \"web\" }/&\n\n  lifecycle {\n    create_before_destroy = true\n  }/' main.tf"
run 'git diff'
commit 'web: create before destroy'
block cbd-apply
quiet "sed -i 's/ami-785db401/ami-1e749f67/' main.tf"
run 'terraform apply -auto-approve | grep -E "then|Destr|Creat"'
commit 'web back on the old image'

block sg-add
cat >> main.tf <<'CODE'

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id

  lifecycle {
    create_before_destroy = true
  }
}
CODE
quiet "sed -i 's/^  subnet_id     = aws_subnet.a.id/&\n  vpc_security_group_ids = [aws_security_group.web.id]/' main.tf"
quiet 'terraform fmt'
quiet 'terraform apply -auto-approve'
commit 'the web security group'
run 'git show --format= -U1'

block sg-duplicate
quiet "sed -i 's/description = \"web servers\"/description = \"the shop web servers\"/' main.tf"
run 'terraform apply -auto-approve'

block sg-prefix
quiet "sed -i 's/^  name        = \"web\"/  name_prefix = \"web-\"/' main.tf"
run 'git diff'
run 'terraform apply -auto-approve | grep -E "Destr|Creat|Modif"'
run 'aws ec2 describe-security-groups --filters "Name=group-name,Values=web*" --query "SecurityGroups[].GroupName" --output text'
commit 'web: name_prefix'
block debug-sg
quiet 'terraform apply -auto-approve'
run 'terraform plan -detailed-exitcode | grep -E "~|Plan:|No changes"'

# ---- ignore-changes
block tagged-by-hand
# STAGED: the finance team's cost tool tags every instance it finds.
ID=$(terraform state show -no-color aws_instance.web | awk '$1=="id"{gsub(/"/,"",$3); print $3}')
quiet "aws ec2 create-tags --resources $ID --tags Key=CostCenter,Value=cc-4410"
run 'terraform plan'

block ignore-diff
quiet "sed -i '0,/^    create_before_destroy = true/s//&\n    ignore_changes        = [tags[\"CostCenter\"]]/' main.tf"
quiet 'terraform fmt'
run 'git diff'
run 'terraform plan'
commit 'web: leave CostCenter to finance'

# ---- forcing-replacement
block replace-flag
run 'terraform plan -replace=aws_instance.web | grep -E "replace|Plan:"'
block taint
run 'terraform taint aws_instance.web'
run 'terraform plan | grep -E "replace|taint|Plan:"'
run 'terraform untaint aws_instance.web'

block release-add
cat >> main.tf <<'CODE'

variable "release" {
  type    = string
  default = "2026.10.1"
}
CODE
quiet "sed -i 's/^  tags                   = { Name = \"web\" }/  user_data              = \"#!\/bin\/sh\\\\n\/opt\/shop\/install \${var.release}\\\\n\"\n&/' main.tf"
quiet 'terraform fmt'
quiet 'terraform apply -auto-approve'
commit 'web installs a release at boot'
run 'git show --format= -U0'
block release-inplace
run 'terraform plan -var release=2026.10.2'

block trigger-diff
cat >> main.tf <<'CODE'

resource "terraform_data" "release" {
  input = var.release
}
CODE
quiet "sed -i '0,/^    ignore_changes        = \[tags\[\"CostCenter\"\]\]/s//&\n    replace_triggered_by  = [terraform_data.release]/' main.tf"
quiet 'terraform fmt'
quiet 'terraform apply -auto-approve'
commit 'web: a new release is a new machine'
run 'git show --format= -U0'
block trigger-plan
run 'terraform plan -var release=2026.10.2 | grep -E "replace|update|Plan:"'
block app-final
run 'cat main.tf'

# ---- depends-on
mkdir -p ../boot && cd ../boot
block boot
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "boot" {
  bucket = "shop-boot-dev"
}

resource "aws_s3_object" "script" {
  bucket  = aws_s3_bucket.boot.bucket
  key     = "boot.sh"
  content = "#!/bin/sh\necho configuring the web server\n"
}

resource "aws_instance" "web" {
  ami           = "ami-1e749f67"
  instance_type = "t3.micro"
  user_data     = "#!/bin/sh\naws s3 cp s3://shop-boot-dev/boot.sh - | sh\n"
}
CODE
quiet 'terraform init'
quiet 'git init -q . && printf ".terraform/\n*.tfstate*\n" > .gitignore'
commit 'boot from a script in a bucket'
block graph-1
run 'terraform graph'
block apply-boot
run 'terraform apply -auto-approve | grep -E "Creat"'
block depends-diff
quiet "sed -i 's/^  user_data     = .*/&\n\n  depends_on = [aws_s3_object.script]/' main.tf"
run 'git diff'
run 'terraform graph | grep -- "->"'
block reference-diff
quiet 'git checkout -q main.tf'
quiet "sed -i 's|s3://shop-boot-dev/boot.sh|s3://\${aws_s3_object.script.bucket}/\${aws_s3_object.script.key}|' main.tf"
run 'git diff'
run 'terraform graph | grep -- "->"'
quiet 'terraform destroy -auto-approve'

# ---- prevent-destroy and removed
mkdir -p ../assets && cd ../assets
block assets
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
CODE
quiet 'terraform init'
quiet 'terraform apply -auto-approve'
quiet 'git init -q . && printf ".terraform/\n*.tfstate*\n" > .gitignore'
commit 'the assets and logs buckets'

block destroy-refused
run 'terraform destroy'
block rename-refused
quiet "sed -i 's/shop-assets-dev/shop-assets-prod/' main.tf"
run 'terraform plan'
quiet 'git checkout -q main.tf'
block block-deleted
quiet "python3 -c 'import re,pathlib; p=pathlib.Path(\"main.tf\"); p.write_text(re.sub(r\"resource \\\"aws_s3_bucket\\\" \\\"assets\\\" \\{.*?\\n\\}\\n\\n\", \"\", p.read_text(), flags=re.S))'"
run 'git diff --stat'
run 'terraform plan | grep -E "will|because|Plan:"'
quiet 'git checkout -q main.tf'

block logs-deleted
quiet "python3 -c 'import re,pathlib; p=pathlib.Path(\"main.tf\"); p.write_text(re.sub(r\"\\n\\nresource \\\"aws_s3_bucket\\\" \\\"logs\\\" \\{.*?\\n\\}\\n\", \"\\n\", p.read_text(), flags=re.S))'"
run 'terraform plan | grep -E "will|because|Plan:"'
block removed-diff
cat >> main.tf <<'CODE'

removed {
  from = aws_s3_bucket.logs

  lifecycle {
    destroy = false
  }
}
CODE
run 'git diff'
run 'terraform plan'
block removed-apply
run 'terraform apply -auto-approve | tail -n 1'
run 'terraform state list'
run 'aws s3 ls'

cd && rm -rf .tf-cache shop/*/.terraform
