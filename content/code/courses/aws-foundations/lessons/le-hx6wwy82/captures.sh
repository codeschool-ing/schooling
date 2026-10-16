#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types every command into one terminal, so a variable set in
#     one transcript is still there in the next. The capture does the same by
#     running each block in a shell that starts from what the last one left:
#     its variables and functions are written to a file and read back;
#   - the two shell functions `ou` and `account` are read out of the ```sh fence
#     of "the-tree" and defined before the first block, as the student types
#     them before the first command that uses them;
#   - the profile the lesson writes goes into the lab's ~/.aws/config, removed
#     at the end with the CLI's cache of assumed-role credentials.
#
# ONE COMMAND READS THE PUBLIC PRICE LIST, from the cache lesson 1 filled.
#
# NOT PRODUCED HERE, and said so in the prose: a bill (moto has none), an
# invitation accepted by another account (moto has no handshakes), and
# enabling all features on a billing-only organisation.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
STATE=$(mktemp)
cleanup() { rm -f ~/.aws/config "$STATE"; rm -rf ~/.aws/cli/cache; }
rm -f ~/.aws/config; rm -rf ~/.aws/cli/cache
trap 'moto_stop; cleanup' EXIT
sh_fences "$HERE/the-tree.md" 1 > "$STATE" || exit 1

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

# ---- the-tree ------------------------------------------------------------------
block org
session 'aws organizations create-organization --query "Organization.[Id,FeatureSet,MasterAccountId]" --output text' \
        'aws organizations list-roots --query "Roots[].[Id,Name]" --output text'

block ous
session 'root=$(aws organizations list-roots --query "Roots[0].Id" --output text)' \
        'for name in Security Workloads Sandbox; do aws organizations create-organizational-unit --parent-id $root --name $name --query "OrganizationalUnit.[Id,Name]" --output text; done' \
        'workloads=$(ou $root Workloads)' \
        'for name in Prod Staging; do aws organizations create-organizational-unit --parent-id $workloads --name $name --query "OrganizationalUnit.[Id,Name]" --output text; done'

block accounts
session 'for a in shop-prod shop-staging security log-archive sandbox; do aws organizations create-account --email aws+$a@example.com --account-name $a --query "CreateAccountStatus.[AccountId,AccountName]" --output text; done' \
        'aws organizations list-children --parent-id $root --child-type ACCOUNT --query "Children[].Id" --output text'

block moves
session 'aws organizations move-account --account-id $(account shop-prod) --source-parent-id $root --destination-parent-id $(ou $workloads Prod)' \
        'aws organizations move-account --account-id $(account shop-staging) --source-parent-id $root --destination-parent-id $(ou $workloads Staging)' \
        'for a in security log-archive; do aws organizations move-account --account-id $(account $a) --source-parent-id $root --destination-parent-id $(ou $root Security); done' \
        'aws organizations move-account --account-id $(account sandbox) --source-parent-id $root --destination-parent-id $(ou $root Sandbox)'

block check
session 'aws organizations list-children --parent-id $root --child-type ACCOUNT --query "Children[].Id" --output text' \
        'aws organizations list-accounts-for-parent --parent-id $(ou $root Security) --query "Accounts[].[Id,Name]" --output text' \
        'aws organizations list-parents --child-id $(account shop-prod) --query "Parents[].[Id,Type]" --output text' \
        'aws organizations list-parents --child-id $(ou $workloads Prod) --query "Parents[].[Id,Type]" --output text'

block describe
session 'aws organizations describe-organization' \
        'aws organizations list-roots --query "Roots[0].PolicyTypes"'

# ---- consolidated-billing ------------------------------------------------------
block price
session 'python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-DataTransfer-Out-Bytes'

block nobill
session 'aws ce get-cost-and-usage --time-period Start=2026-09-01,End=2026-10-01 --granularity MONTHLY --metrics UnblendedCost --group-by Type=DIMENSION,Key=LINKED_ACCOUNT'

# ---- the-management-account ----------------------------------------------------
block role
session 'aws configure set profile.shop-prod.role_arn arn:aws:iam::$(account shop-prod):role/OrganizationAccountAccessRole' \
        'aws configure set profile.shop-prod.credential_source Environment' \
        'aws configure set profile.shop-prod.role_session_name ana' \
        'aws --profile shop-prod iam get-role --role-name OrganizationAccountAccessRole --query "Role.AssumeRolePolicyDocument"' \
        'aws --profile shop-prod iam list-attached-role-policies --role-name OrganizationAccountAccessRole'

block invite
session 'aws organizations invite-account-to-organization --target Id=111122223333,Type=ACCOUNT'
