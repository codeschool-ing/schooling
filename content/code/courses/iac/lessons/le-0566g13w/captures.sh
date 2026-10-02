#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents are random, and so are
# the timestamps in Checkov's and Trivy's log lines and the timings tfsec
# prints, so a second run prints different ones. Checkov runs its checks in
# parallel, and the order of its findings can differ between runs; the counts
# do not.
#
# THE LAB HAS NO NETWORK, and two of the scanners try to use one:
#   - Checkov asks Prisma Cloud's API for its guidelines on every run and logs a
#     traceback when it cannot. Every run after the first one shown passes
#     --skip-download, which is Checkov's own offline switch; it costs the
#     severities and the guide links, and the lesson says so.
#   - Trivy tries to download its checks bundle and falls back to the checks
#     compiled into the binary. --skip-check-update stops the attempt.
# tfsec makes no network call. Terrascan is not installed in the lab, and the
# lesson runs `terrascan version` to show exactly that.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the files ana wrote (put below), whose contents the lesson shows in full,
#     and her git commits, made quietly so a later change can be shown as a
#     diff;
#   - the rule a colleague added by hand in "what-a-scanner-sees", the aws
#     command marked below, as in lessons 1 and 7, and its removal afterwards;
#   - the edits whose result the lesson shows with `git diff`, written quietly;
#   - deleting tfplan and tfplan.json before "triage", so the directory scans
#     there read the configuration and not a leftover plan.
#
# One date depends on the day this runs: the expiry on a Trivy ignore comment
# in "suppressing" is 2027-03-31. Run this after that date and the finding the
# comment hides comes back, which is the point of an expiry.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

tfinit() {
  local i
  for i in 1 2 3 4 5 6; do
    terraform init -input=false "$@" >/dev/null 2>&1 && terraform providers schema -json >/dev/null 2>&1 && return 0
    sleep 5
  done
  echo "##### FAILED: terraform init $* in $PWD"; exit 1
}

quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'

mkdir -p shop && cd shop
quiet 'git init'

block base
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

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS from anywhere"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-123456789012"
  tags   = { Name = "shop-assets" }
}

resource "aws_ebs_volume" "data" {
  availability_zone = "sa-east-1a"
  size              = 20
  tags              = { Name = "shop-data" }
}
CODE
cat > .gitignore <<'CODE'
.terraform/
*.tfstate*
tfplan*
CODE
tfinit
quiet 'git add -A && git commit -qm "the shop network, a bucket and a volume"'
block apply
run 'terraform apply -auto-approve | tail -n 1'

block versions
run 'checkov --version'
run 'trivy --version'

block by-hand
# STAGED: what a colleague typed on another day, from another machine.
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=web --query 'SecurityGroups[0].GroupId' --output text)
quiet "aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 22 --cidr 0.0.0.0/0"
run 'aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text'
block by-hand-scan
run 'checkov -d . --skip-download --compact --check CKV_AWS_24'
# STAGED: the file wins, as in lesson 7.
quiet "aws ec2 revoke-security-group-ingress --group-id $SG --protocol tcp --port 22 --cidr 0.0.0.0/0"

block pr
put ssh.tf <<'CODE'
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH for maintenance"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}
CODE
quiet 'git add ssh.tf && git commit -qm "ssh for maintenance"'
block one-rule
run 'checkov -d . --skip-download --quiet --compact --check CKV_AWS_24'

block checkov-online
run 'checkov -d . 2>&1 | head -n 2'
block checkov-all
run 'checkov -d . --skip-download --quiet --compact'
block checkov-one
run 'checkov -d . --skip-download --quiet --check CKV_AWS_24'
block custom
(cd ~ && put policies/ssh_office.yaml <<'CODE'
metadata:
  id: "CKV2_SHOP_1"
  name: "SSH is only allowed from the office range"
  category: "NETWORKING"
definition:
  or:
    - cond_type: "attribute"
      resource_types: ["aws_vpc_security_group_ingress_rule"]
      attribute: "from_port"
      operator: "not_equals"
      value: 22
    - cond_type: "attribute"
      resource_types: ["aws_vpc_security_group_ingress_rule"]
      attribute: "cidr_ipv4"
      operator: "equals"
      value: "203.0.113.0/24"
CODE
)
block custom-run
run 'checkov -d . --skip-download --quiet --compact --external-checks-dir ~/policies --check CKV2_SHOP_1'

block trivy-online
run 'trivy config . 2>&1 | head -n 5'
block trivy-offline
run 'trivy config --skip-check-update . 2>&1 | head -n 4'
block trivy-list
run 'trivy config --skip-check-update -q . | grep -E "^(AWS-|Failures|[a-z]+\.tf )"'
block trivy-one
run 'trivy config --skip-check-update -q . | sed -n "/^ssh.tf/,\$p"'
block trivy-deprecated
run 'trivy config --skip-check-update -q --include-deprecated-checks . | grep -E "^AWS-008[89]"'

block tfsec-version
run 'tfsec --version'
block tfsec-run
run 'tfsec --no-colour . | grep -E "^(Result|  [a-z]+\.tf)"'
run 'tfsec --no-colour . | tail -n 3'
block legacy
mkdir -p ../legacy && cd ../legacy
put main.tf <<'CODE'
resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"

  ingress {
    description = "SSH for maintenance"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
CODE
block legacy-run
run 'tfsec --no-colour . | sed -n "/^Result/,/^  Resolution/p"'
cd ../shop
block terrascan
run 'terrascan version'

block suppress
# STAGED: the edit, shown below as a diff.
python3 - <<'PY'
import re
p = "main.tf"; s = open(p).read()
s = s.replace('''resource "aws_security_group" "web" {
''', '''resource "aws_security_group" "web" {
  #checkov:skip=CKV2_AWS_5:attached by the instances in the app configuration, not here
''')
s = s.replace('''resource "aws_s3_bucket" "assets" {
''', '''# SSE-S3 is enough for product photos; revisit when the shop has a KMS key
#trivy:ignore:AWS-0132:exp:2027-03-31
resource "aws_s3_bucket" "assets" {
  #checkov:skip=CKV_AWS_144:the photos are rebuilt from the repository, a second region is not worth paying for
  #checkov:skip=CKV2_AWS_62
''')
open(p, "w").write(s)
PY
run 'git diff'
block suppress-checkov
run 'checkov -d . --skip-download --compact --check CKV_AWS_144,CKV2_AWS_5,CKV2_AWS_62'
block suppress-trivy
run 'trivy config --skip-check-update -q . | grep -E "^(AWS-0132|Failures)"'
block expiry
run 'sed -i "s/exp:2027-03-31/exp:2026-03-31/" main.tf'
run 'trivy config --skip-check-update -q . | grep -E "^(AWS-0132|Failures)"'
quiet 'sed -i "s/exp:2026-03-31/exp:2027-03-31/" main.tf'
quiet 'git commit -qam "suppress three findings"'

block variable
# STAGED: the edit, shown below as a diff.
cat > ssh.tf <<'CODE'
variable "admin_cidr" {
  type        = string
  description = "The range SSH is allowed from."
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH for maintenance"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.admin_cidr
}
CODE
run 'git diff'
quiet 'git commit -qam "admin_cidr as a variable"'
block variable-scan
run 'checkov -d . --skip-download --compact --check CKV_AWS_24'
run 'trivy config --skip-check-update -q . | grep -c AWS-0107'
block tfvars
put maintenance.tfvars <<'CODE'
admin_cidr = "0.0.0.0/0"
CODE
block plan
run 'terraform plan -var-file=maintenance.tfvars -out tfplan | grep "^Plan:"'
run 'terraform show -json tfplan > tfplan.json'
block plan-checkov
run 'checkov -f tfplan.json --skip-download --quiet --check CKV_AWS_24 --repo-root-for-plan-enrichment .'
block plan-trivy
run 'trivy config --skip-check-update -q tfplan.json | grep -E "^AWS-0107"'
block var-file
run 'checkov -d . --skip-download --quiet --compact --check CKV_AWS_24 --var-file maintenance.tfvars --framework terraform'
block plan-fixed
run "echo 'admin_cidr = \"203.0.113.0/24\"' > maintenance.tfvars"
run 'terraform plan -var-file=maintenance.tfvars -out tfplan > /dev/null && terraform show -json tfplan > tfplan.json'
run 'checkov -f tfplan.json --skip-download --compact --check CKV_AWS_24'

block triage-counts
quiet 'rm -f tfplan tfplan.json'
run 'checkov -d . --skip-download --quiet --compact | sed -n 3p'
run 'trivy config --skip-check-update -q . | grep "^Failures"'
run 'tfsec --no-colour . | tail -n 2'
block triage-gate
run 'trivy config --skip-check-update -q --severity CRITICAL --exit-code 1 . > /dev/null; echo "exit $?"'
run 'trivy config --skip-check-update -q --severity HIGH,CRITICAL --exit-code 1 . > /dev/null; echo "exit $?"'
block triage-checkov
run 'checkov -d . --skip-download --quiet --compact --hard-fail-on HIGH > /dev/null; echo "exit $?"'
run 'checkov -d . --skip-download --quiet --compact --hard-fail-on CKV_AWS_24,CKV2_AWS_6 > /dev/null; echo "exit $?"'
block triage-disagree
run 'checkov -d . --skip-download --compact --check CKV_AWS_19 | grep -A1 assets'
run 'tfsec --no-colour . | grep -B4 "ID aws-s3-enable-bucket-encryption"'
block baseline
run 'checkov -d . --skip-download --quiet --compact --create-baseline | tail -n 1'
put backups.tf <<'CODE'
resource "aws_s3_bucket" "backups" {
  bucket = "shop-backups-123456789012"
}
CODE
block baseline-run
run 'checkov -d . --skip-download --quiet --compact --baseline .checkov.baseline; echo "exit $?"'
