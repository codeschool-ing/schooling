#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Recorded in the lab lesson 1 built, against an empty moto with no permission
# checking. ~/.aws/config and ~/.aws/credentials are written by the lesson's own
# `aws configure set` commands, starting from none, and removed with the CLI's
# cache when the capture ends, so no later capture finds them. lab-creds.sh is
# read out of the lesson's ```sh fence and removed too. The files hold moto's
# placeholder keys `test`/`test` and nothing else.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - a line that sets a shell variable (STAGING=...) is printed with the prompt
#     and then applied to this script's own shell, which is what typing it at the
#     prompt does.
#
# NOT PRODUCED HERE, and said so in the prose: CloudShell, which needs an AWS
# account and a browser, and an `sso_session` profile signing in (lesson 11).
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
for f in ~/.aws/config ~/.aws/credentials; do
  [ -e "$f" ] && { echo "$f exists in the lab; refusing to overwrite it"; exit 1; }
done
trap 'moto_stop; rm -f ~/.aws/config ~/.aws/credentials ~/.aws/cli/cache/*.json ~/aws/lab-creds.sh' EXIT

sets() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*"; }

# ---- the-two-files ------------------------------------------------------------
block configure-set
run 'aws configure set aws_access_key_id test --profile lab'
run 'aws configure set aws_secret_access_key test --profile lab'
run 'aws configure set region us-east-1 --profile lab'
run 'aws configure set output json --profile lab'
run 'cat ~/.aws/credentials'
run 'cat ~/.aws/config'

block configure-get
run 'aws configure get region --profile lab'
run 'aws configure list-profiles'

block region-order
run 'aws ec2 describe-availability-zones --profile lab --query "AvailabilityZones[0].ZoneName" --output text'
run 'env -u AWS_DEFAULT_REGION aws ec2 describe-availability-zones --profile lab --query "AvailabilityZones[0].ZoneName" --output text'
run 'aws ec2 describe-availability-zones --profile lab --region us-west-2 --query "AvailabilityZones[0].ZoneName" --output text'

# ---- which-credentials ---------------------------------------------------------
block env-wins
run 'AWS_PROFILE=lab aws configure list'

block profile-flag
run 'aws configure list --profile lab'

block env-u
run 'env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY AWS_PROFILE=lab aws configure list'

block org
run 'aws organizations create-organization --feature-set ALL --query Organization.Id --output text'
run 'aws organizations create-account --account-name shop-staging --email aws+shop-staging@example.com --query CreateAccountStatus.[State,AccountId] --output text'
sets 'STAGING=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-staging\`].Id" --output text)'
export STAGING

block role-profile
run 'aws configure set role_arn arn:aws:iam::$STAGING:role/OrganizationAccountAccessRole --profile staging'
run 'aws configure set source_profile lab --profile staging'
run 'aws configure set role_session_name ana --profile staging'
run 'aws configure set output table --profile staging'
run 'aws sts get-caller-identity --profile staging'

block role-vpcs
run 'aws ec2 describe-vpcs --profile staging --query "Vpcs[].[OwnerId,CidrBlock]" --output text'
run 'aws ec2 describe-vpcs --query "Vpcs[].[OwnerId,CidrBlock]" --output text'
run 'ls ~/.aws/cli/cache/'

sh_fences "$HERE/which-credentials.md" 1 > "$LAB_ROOT/scratch/l25-lab-creds.sh" || exit 1
bash "$LAB_ROOT/scratch/l25-lab-creds.sh" || exit 1
rm -f "$LAB_ROOT/scratch/l25-lab-creds.sh"

block process
run 'sh ~/aws/lab-creds.sh'
run 'aws configure set credential_process "sh ~/aws/lab-creds.sh" --profile from-process'
run 'aws sts get-caller-identity --profile from-process'

block process-shell
run 'aws configure set credential_process "sh -c \"sh ~/aws/lab-creds.sh\"" --profile from-process'
run 'tail -2 ~/.aws/config'
run 'aws configure list --profile from-process'

# ---- query-and-output ----------------------------------------------------------
block query-filter
run 'aws iam list-policies --scope AWS --query "length(Policies)"'
run 'aws iam list-policies --scope AWS --query "Policies[?starts_with(PolicyName, \`AmazonS3\`)].PolicyName" --output text'

block outputs
run 'aws sts get-caller-identity --output json'
run 'aws sts get-caller-identity --output text'
run 'aws sts get-caller-identity --output yaml'
run 'aws iam list-policies --scope AWS --query "Policies[?starts_with(PolicyName, \`AmazonS3\`)].{name: PolicyName, versions: DefaultVersionId, attached: AttachmentCount}" --output table'

block dry-run
run 'aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.micro --dry-run; echo "exit $?"'
run 'aws ec2 describe-instances --query "length(Reservations)"'

block pages
run 'aws iam list-policies --scope AWS --query "length(Policies)" --debug 2>&1 | grep -c "Making request for OperationModel(name=ListPolicies"'
run 'aws iam list-policies --scope AWS --page-size 500 --query "length(Policies)" --debug 2>&1 | grep -c "Making request for OperationModel(name=ListPolicies"'

block max-items
run 'aws iam list-policies --scope AWS --max-items 2 --query "{names: Policies[].PolicyName, next: NextToken}"'
sets 'NEXT=$(aws iam list-policies --scope AWS --max-items 2 --output json | jq -r .NextToken)'
export NEXT
run 'aws iam list-policies --scope AWS --max-items 2 --starting-token $NEXT --query "Policies[].PolicyName"'
