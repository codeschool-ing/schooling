#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Recorded in the lab lesson 1 built, against an empty moto with no permission
# checking. ~/.aws/config is read out of the fence in "the-cli-side" and removed
# when the capture ends, so that no later lesson's capture finds it.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - a line that sets a shell variable (INSTANCE=..., STORE=..., and the ids the
#     later commands use) is printed with the prompt and then applied to this
#     script's own shell, which is what typing it at the prompt does;
#   - `aws sso login` is run with --no-browser and only its error line is kept:
#     pointed at moto, its first request fails, and the HTML page moto returns
#     with the error is cut.
#
# NOT PRODUCED HERE, and said so in the prose: anything that needs a real
# Identity Center and a browser (`aws configure sso`, a successful
# `aws sso login`, the access portal, a SAML sign-in, SCIM provisioning), and
# the AWSReservedSSO_ roles, which moto 5.2.3 does not create.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
[ -e ~/.aws/config ] && { echo "~/.aws/config exists in the lab; refusing to overwrite it"; exit 1; }
trap 'moto_stop; rm -f ~/.aws/config; rm -rf ~/.aws/sso' EXIT

sets() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*"; }

fences json "$HERE/permission-sets.md" 1 > ~/aws/no-backups.json || exit 1
trap 'moto_stop; rm -f ~/.aws/config ~/aws/no-backups.json; rm -rf ~/.aws/sso' EXIT

# ---- permission-sets ----------------------------------------------------------
block instance
run 'aws sso-admin list-instances --query "Instances[].[InstanceArn,IdentityStoreId,Status]" --output text'

block org
run 'aws organizations create-organization --feature-set ALL --query Organization.Id --output text'
run 'aws organizations create-account --account-name shop-prod --email aws+shop-prod@example.com --query CreateAccountStatus.[State,AccountId] --output text'
run 'aws organizations create-account --account-name shop-staging --email aws+shop-staging@example.com --query CreateAccountStatus.[State,AccountId] --output text'
sets 'PROD=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-prod\`].Id" --output text)'
sets 'STAGING=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-staging\`].Id" --output text)'
export PROD STAGING
run 'echo $PROD $STAGING'

block variables
sets 'INSTANCE=$(aws sso-admin list-instances --query "Instances[0].InstanceArn" --output text)'
sets 'STORE=$(aws sso-admin list-instances --query "Instances[0].IdentityStoreId" --output text)'
export INSTANCE STORE

block permission-set
sets 'READONLY=$(aws sso-admin create-permission-set --instance-arn $INSTANCE --name ReadOnly --session-duration PT4H --description "Read everything, change nothing" --query PermissionSet.PermissionSetArn --output text)'
export READONLY
run 'echo $READONLY'
run 'aws sso-admin attach-managed-policy-to-permission-set --instance-arn $INSTANCE --permission-set-arn $READONLY --managed-policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess'
run 'aws sso-admin put-inline-policy-to-permission-set --instance-arn $INSTANCE --permission-set-arn $READONLY --inline-policy file://no-backups.json'
run 'aws sso-admin describe-permission-set --instance-arn $INSTANCE --permission-set-arn $READONLY --query "PermissionSet.[Name,SessionDuration]" --output text'

block developer
sets 'DEVELOPER=$(aws sso-admin create-permission-set --instance-arn $INSTANCE --name Developer --session-duration PT8H --query PermissionSet.PermissionSetArn --output text)'
export DEVELOPER
run 'aws sso-admin attach-managed-policy-to-permission-set --instance-arn $INSTANCE --permission-set-arn $DEVELOPER --managed-policy-arn arn:aws:iam::aws:policy/PowerUserAccess'

block people
sets 'BIA=$(aws identitystore create-user --identity-store-id $STORE --user-name bia --display-name "Bia" --name GivenName=Bia,FamilyName=Lima --emails Value=bia@example.com,Type=work,Primary=true --query UserId --output text)'
sets 'CAIO=$(aws identitystore create-user --identity-store-id $STORE --user-name caio --display-name "Caio" --name GivenName=Caio,FamilyName=Souza --emails Value=caio@example.com,Type=work,Primary=true --query UserId --output text)'
sets 'DEVS=$(aws identitystore create-group --identity-store-id $STORE --display-name developers --query GroupId --output text)'
sets 'DATA=$(aws identitystore create-group --identity-store-id $STORE --display-name data --query GroupId --output text)'
export BIA CAIO DEVS DATA
run 'aws identitystore create-group-membership --identity-store-id $STORE --group-id $DEVS --member-id UserId=$BIA --query MembershipId --output text'
run 'aws identitystore create-group-membership --identity-store-id $STORE --group-id $DATA --member-id UserId=$CAIO --query MembershipId --output text'
run 'aws identitystore list-users --identity-store-id $STORE --query "Users[].[UserName,UserId]" --output text'
run 'aws identitystore list-groups --identity-store-id $STORE --query "Groups[].[DisplayName,GroupId]" --output text'

block assign
run 'aws sso-admin create-account-assignment --instance-arn $INSTANCE --target-type AWS_ACCOUNT --target-id $STAGING --permission-set-arn $DEVELOPER --principal-type GROUP --principal-id $DEVS --query AccountAssignmentCreationStatus.Status --output text'
run 'aws sso-admin create-account-assignment --instance-arn $INSTANCE --target-type AWS_ACCOUNT --target-id $PROD --permission-set-arn $READONLY --principal-type GROUP --principal-id $DEVS --query AccountAssignmentCreationStatus.Status --output text'
run 'aws sso-admin create-account-assignment --instance-arn $INSTANCE --target-type AWS_ACCOUNT --target-id $PROD --permission-set-arn $READONLY --principal-type GROUP --principal-id $DATA --query AccountAssignmentCreationStatus.Status --output text'
run 'aws sso-admin list-account-assignments --instance-arn $INSTANCE --account-id $PROD --permission-set-arn $READONLY --query "AccountAssignments[].[PrincipalType,PrincipalId]" --output text'

block reserved
run 'env $(aws sts assume-role --role-arn arn:aws:iam::$PROD:role/OrganizationAccountAccessRole --role-session-name ana --query "Credentials.[join(\`=\`,[\`AWS_ACCESS_KEY_ID\`,AccessKeyId]),join(\`=\`,[\`AWS_SECRET_ACCESS_KEY\`,SecretAccessKey]),join(\`=\`,[\`AWS_SESSION_TOKEN\`,SessionToken])]" --output text) aws iam list-roles --query "Roles[].RoleName" --output text'
run 'aws sso-admin list-permission-sets-provisioned-to-account --instance-arn $INSTANCE --account-id $PROD'

# ---- the-cli-side -------------------------------------------------------------
mkdir -p ~/.aws
fences ini "$HERE/the-cli-side.md" 1 > ~/.aws/config || exit 1

block profiles
run 'aws configure list-profiles'

block no-token
run 'aws sts get-caller-identity --profile prod-readonly'

block login-moto
run 'aws sso login --profile prod-readonly --no-browser 2>&1 | grep -o "An error occurred ([0-9]*) when calling the [A-Za-z]* operation"'
