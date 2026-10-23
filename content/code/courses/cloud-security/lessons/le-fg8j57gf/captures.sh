#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Terraform and Checkov are the ones lesson 12 installed, and its capture must
# have run first: it also leaves $LAB_ROOT/terraformrc, the provider mirror
# described in lesson 12's captures.sh, which this script uses the same way.
# ~/aws/clinic is rebuilt as lesson 12 leaves it: main.tf is the first ```hcl
# fence of lesson 12's "scanning". gate.sh is the schooling-example of
# "a-gate"; tablet.tf is the ```hcl fence of "a-gate" and then of
# "break-or-warn"; the trust policies are the ```json fences of "who-deploys".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the provider mirror and CHECKPOINT_DISABLE=1, as in lesson 12;
#   - `terraform init` is run without its output being quoted;
#   - the provider addresses S3 Control at 123456789012.localhost:4567 when it
#     applies a bucket. On Ubuntu 24.04, systemd-resolved answers any
#     *.localhost name with 127.0.0.1; the recording container has no such
#     resolver, so /etc/hosts carries that one name, as aws-operations did. The
#     prose says what to do on a machine that does not resolve it (WSL).
#
# NOT RUN, and said so in the prose: the exception with an end date in
# "break-or-warn" (it names resources this lab does not have), the GitHub
# Actions workflow, and everything AWS does with the token's claims (moto
# stores the trust policies' conditions and judges none of them).
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
L12=$HERE/../le-cj0jt7ym
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
export CHECKPOINT_DISABLE=1 TF_CLI_CONFIG_FILE=$LAB_ROOT/terraformrc
command -v terraform > /dev/null && command -v checkov > /dev/null && [ -f "$TF_CLI_CONFIG_FILE" ] \
  || { echo "no Terraform or Checkov in the lab: run lesson 12's captures.sh first"; exit 1; }

grep -q '123456789012.localhost' /etc/hosts || echo '127.0.0.1 123456789012.localhost' >> /etc/hosts

moto_fresh
rm -rf ~/aws/clinic && mkdir -p ~/aws/clinic
FILES='trust-plan.json trust-apply.json'
trap 'moto_stop; rm -rf ~/aws/clinic; cd ~/aws && rm -f $FILES' EXIT

# ---- a-gate ------------------------------------------------------------------
cd ~/aws/clinic && at '~/aws/clinic'
fences hcl "$L12/scanning.md" 1 > main.tf || exit 1
terraform init -input=false > /dev/null || { echo "terraform init failed"; exit 1; }
example "$HERE/a-gate.md" gate.sh > gate.sh || exit 1

block gate-pass
run 'bash gate.sh; echo "exit status $?"'

block apply
run 'terraform apply -no-color plan.bin | tail -1'
run 'bash gate.sh; echo "exit status $?"'

fences hcl "$HERE/a-gate.md" 1 > tablet.tf || exit 1
block gate-stop
run 'bash gate.sh; echo "exit status $?"'
bash -e <(sh_fences "$HERE/a-gate.md" 1) || exit 1

# ---- break-or-warn -----------------------------------------------------------
fences hcl "$HERE/break-or-warn.md" 1 > tablet.tf || exit 1
block gate-warn
run 'bash gate.sh; echo "exit status $?"'

# ---- who-deploys -------------------------------------------------------------
moto_fresh
cd ~/aws && at '~/aws'
fences json "$HERE/who-deploys.md" 1 > trust-plan.json || exit 1
fences json "$HERE/who-deploys.md" 2 > trust-apply.json || exit 1

block roles
run 'aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --query OpenIDConnectProviderArn --output text'
run 'aws iam create-role --role-name infra-plan --assume-role-policy-document file://trust-plan.json --query Role.Arn --output text'
run 'aws iam attach-role-policy --role-name infra-plan --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess'
run 'aws iam create-role --role-name infra-apply --assume-role-policy-document file://trust-apply.json --query Role.Arn --output text'
run "aws iam list-roles --query \"Roles[?starts_with(RoleName, 'infra-')].[RoleName,AssumeRolePolicyDocument.Statement[0].Condition.StringEquals.\\\"token.actions.githubusercontent.com:sub\\\"]\" --output text"
