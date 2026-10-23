#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moto is started empty and seeded, with its checking off. The account is built
# by where-is-the-data's ```sh fence 1; only-sao-paulo.json is a-guardrail's
# ```json fence 1. Both sections run against the same moto, as the student's
# would.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set or use a shell variable are run in this script's own
#     shell by `keep`, which is what typing them into one terminal does;
#   - only-sao-paulo.json is removed at the end.
#
# NOT RUN, and said so in the prose: AWS refusing LocationConstraint=us-east-1;
# the SCP refusing a request in a member account, and not applying in the
# management account (moto stores SCPs and enforces none); AWS Artifact; the
# Azure and Google Cloud region lists; everything legal.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

moto_fresh
trap 'moto_stop; cd ~/aws && rm -f only-sao-paulo.json' EXIT

bash -e <(sh_fences "$HERE/where-is-the-data.md" 1) || exit 1

block regions-sa
run "aws ec2 describe-regions --query \"Regions[?starts_with(RegionName, 'sa-')].RegionName\" --output text"

block inventory
run "for b in \$(aws s3api list-buckets --query \"Buckets[].Name\" --output text); do echo \"\$b \$(aws s3api get-bucket-location --bucket \"\$b\" --query LocationConstraint --output text) \$(aws s3api get-bucket-tagging --bucket \"\$b\" --query \"TagSet[?Key=='data-class'].Value\" --output text)\"; done"

block keys
run 'for r in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do n=$(aws kms list-keys --region "$r" --query "length(Keys)"); [ "$n" != 0 ] && echo "$r $n"; done'

fences json "$HERE/a-guardrail.md" 1 > only-sao-paulo.json || exit 1
block org
run 'aws organizations create-organization --feature-set ALL --query Organization.Id --output text'
keep 'root=$(aws organizations list-roots --query "Roots[0].Id" --output text)'
keep 'aws organizations enable-policy-type --root-id "$root" --policy-type SERVICE_CONTROL_POLICY --query "Root.PolicyTypes[].Status" --output text'
keep 'policy=$(aws organizations create-policy --name only-sao-paulo --type SERVICE_CONTROL_POLICY --description "Keep new resources in Brazil" --content file://only-sao-paulo.json --query Policy.PolicySummary.Id --output text)'
keep 'aws organizations attach-policy --policy-id "$policy" --target-id "$root"'
keep 'aws organizations list-policies-for-target --target-id "$root" --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text'

block eu-bucket
run 'aws s3api create-bucket --bucket clinic-test-eu --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1 --query Location --output text'
