#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types every command into one terminal, so a variable or a
#     function set in one transcript is still there in the next. The capture
#     runs each block in a shell that starts from what the last one left;
#   - the five policy files are read out of the lesson's ```json fences (the
#     first of "inheritance", the four of "guardrails") into ~/aws/scp, as the
#     student saves them; ~/aws/scp, the profile in ~/.aws/config and the CLI's
#     cache of assumed-role credentials are removed at the end.
#
# NOT PRODUCED HERE, and said so in the prose: every refusal an SCP causes in
# AWS (moto enforces none), and AWS refusing to detach a target's last SCP.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
STATE=$(mktemp)
cleanup() { rm -f ~/.aws/config "$STATE"; rm -rf ~/.aws/cli/cache ~/aws/scp; }
rm -f ~/.aws/config; rm -rf ~/.aws/cli/cache ~/aws/scp
trap 'moto_stop; cleanup' EXIT

session() { # each argument one command at the prompt; state carries over
  local f; f=$(mktemp)
  {
    printf '. %q\n' "$STATE"
    for c in "$@"; do
      printf 'printf "%%s\\n" %q\n%s\n' "ana@laptop:~/aws\$ $c" "$c"
    done
    printf '{ declare -p $(compgen -v | grep -E "^[a-z][a-z_]*$"); declare -f; } > %q 2>/dev/null\n' "$STATE"
  } > "$f"
  bash "$f" 2>&1; rm -f "$f"
}

# ---- what-an-scp-is ------------------------------------------------------------
block setup
session 'account() { aws organizations list-accounts --query "Accounts[?Name=='"'"'$1'"'"'].Id" --output text; }' \
        'aws organizations create-organization --query Organization.Id --output text' \
        'root=$(aws organizations list-roots --query "Roots[0].Id" --output text)' \
        'workloads=$(aws organizations create-organizational-unit --parent-id $root --name Workloads --query OrganizationalUnit.Id --output text)' \
        'prod=$(aws organizations create-organizational-unit --parent-id $workloads --name Prod --query OrganizationalUnit.Id --output text)' \
        'sandbox=$(aws organizations create-organizational-unit --parent-id $root --name Sandbox --query OrganizationalUnit.Id --output text)' \
        'for a in shop-prod sandbox; do aws organizations create-account --email aws+$a@example.com --account-name $a --query "CreateAccountStatus.[AccountId,AccountName]" --output text; done' \
        'aws organizations move-account --account-id $(account shop-prod) --source-parent-id $root --destination-parent-id $prod' \
        'aws organizations move-account --account-id $(account sandbox) --source-parent-id $root --destination-parent-id $sandbox'

block enable
session 'aws organizations list-roots --query "Roots[0].PolicyTypes"' \
        'aws organizations enable-policy-type --root-id $root --policy-type SERVICE_CONTROL_POLICY --query Root.PolicyTypes' \
        'aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query "Policies[].[Id,Name,AwsManaged]" --output text' \
        'aws organizations describe-policy --policy-id p-FullAWSAccess --query Policy.Content --output text' \
        'for t in $root $workloads $prod $(account shop-prod); do echo "$t: $(aws organizations list-policies-for-target --target-id $t --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text)"; done'

# ---- inheritance ---------------------------------------------------------------
mkdir -p ~/aws/scp
fences json "$HERE/inheritance.md" 1 > ~/aws/scp/sandbox-allow-list.json || exit 1
block allowlist
session 'policy() { aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query "Policies[?Name=='"'"'$1'"'"'].Id" --output text; }' \
        'aws organizations create-policy --name sandbox-allow-list --type SERVICE_CONTROL_POLICY --description "What the sandbox may use" --content file://scp/sandbox-allow-list.json --query Policy.PolicySummary.Id --output text' \
        'aws organizations attach-policy --policy-id $(policy sandbox-allow-list) --target-id $sandbox' \
        'aws organizations detach-policy --policy-id p-FullAWSAccess --target-id $sandbox' \
        'for t in $root $sandbox $(account sandbox); do echo "$t: $(aws organizations list-policies-for-target --target-id $t --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text)"; done'

block lastone
session 'aws organizations detach-policy --policy-id $(policy sandbox-allow-list) --target-id $sandbox' \
        'aws organizations list-policies-for-target --target-id $sandbox --filter SERVICE_CONTROL_POLICY --query "Policies[].Name"' \
        'aws organizations attach-policy --policy-id $(policy sandbox-allow-list) --target-id $sandbox'

# ---- guardrails ----------------------------------------------------------------
n=1
for f in deny-leaving sa-east-1-only protect-security-services protect-deployer; do
  fences json "$HERE/guardrails.md" $n > ~/aws/scp/$f.json || exit 1
  n=$((n + 1))
done
block create
session 'for p in deny-leaving sa-east-1-only protect-security-services protect-deployer; do aws organizations create-policy --name $p --type SERVICE_CONTROL_POLICY --description "shop guardrail: $p" --content file://scp/$p.json --query Policy.PolicySummary.Id --output text; done' \
        'for p in deny-leaving sa-east-1-only protect-security-services; do aws organizations attach-policy --policy-id $(policy $p) --target-id $root; done' \
        'aws organizations attach-policy --policy-id $(policy protect-deployer) --target-id $workloads' \
        'aws organizations list-policies-for-target --target-id $root --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text' \
        'aws organizations list-targets-for-policy --policy-id $(policy protect-deployer) --query "Targets[].[Name,Type]" --output text'

block ignored
session 'aws configure set profile.shop-prod.role_arn arn:aws:iam::$(account shop-prod):role/OrganizationAccountAccessRole' \
        'aws configure set profile.shop-prod.credential_source Environment' \
        'aws configure set profile.shop-prod.role_session_name ana' \
        'aws --profile shop-prod ec2 create-vpc --cidr-block 10.99.0.0/16 --region us-east-1 --query Vpc.VpcId --output text'
