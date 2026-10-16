#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moto's checking is ON, started as assuming's ```sh fence 1 says, with lesson
# 7's three-request bootstrap. with_key and with_session are assuming's ```sh
# fence 2, defined in this shell as typed. The trust policies are read out of
# the ```json fences (assuming 1, cross-account 1), and ~/.aws/config is written
# by cross-account's ```sh fence 1, as it stands.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set a shell variable or the terminal's keys are run in this
#     script's own shell by `keep`, which is what typing them into one
#     terminal does;
#   - the third party is played by a user `vendor` in the shop's own account,
#     as the prose says, because the lab has no account 444455556666;
#   - ~/.aws/config, the policy files and the CLI's cache of the profile's
#     session are removed at the end, so the shared lab home is left as it was.
#
# NOT PRODUCED HERE, and said so in the prose: AWS refusing a duration above the
# role's maximum, a missing external id, and a chained session over an hour;
# AWS accepting a role ARN or an account in a trust policy; AdministratorAccess
# on OrganizationAccountAccessRole; source identity and every CloudTrail record
# (moto answers lookup-events with HTTP 500).
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

[ "$(sh_fences "$HERE/assuming.md" 1)" = 'INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567' ] \
  || { echo "assuming fence 1 changed"; exit 1; }
# another lesson's capture may have left a ~/.aws/config in the shared lab home;
# it is put aside for this run, since the student's lab has none at this point
SAVED_CONFIG=
[ -e ~/.aws/config ] && { SAVED_CONFIG=$(mktemp); cp -p ~/.aws/config "$SAVED_CONFIG"; rm ~/.aws/config; }
FILES='deployer-trust.json monitoring-trust.json'
CACHE_BEFORE=$(ls ~/.aws/cli/cache 2>/dev/null)
cleanup() {
  moto_stop
  cd ~/aws && rm -f $FILES ~/.aws/config
  [ -n "$SAVED_CONFIG" ] && { cp -p "$SAVED_CONFIG" ~/.aws/config; rm -f "$SAVED_CONFIG"; }
  for f in $(ls ~/.aws/cli/cache 2>/dev/null); do
    grep -qxF "$f" <<<"$CACHE_BEFORE" || rm -f ~/.aws/cli/cache/"$f"
  done
}
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap cleanup EXIT

block bootstrap
run 'aws iam create-user --user-name admin --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'key=$(aws iam create-access-key --user-name admin)'
run 'aws iam list-users'
keep 'export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)'
run 'aws sts get-caller-identity --query Arn --output text'

eval "$(sh_fences "$HERE/assuming.md" 2)"

# ---- assuming ---------------------------------------------------------------------
fences json "$HERE/assuming.md" 1 > deployer-trust.json || exit 1
block role
run 'aws iam create-role --role-name deployer --assume-role-policy-document file://deployer-trust.json --query Role.Arn --output text'
run 'aws iam attach-role-policy --role-name deployer --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess'
run 'aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws iam create-user --user-name bia --query User.Arn --output text'
run "aws iam put-user-policy --user-name bia --policy-name assume-deployer --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::123456789012:role/deployer\"}]}'"
keep 'bia=$(aws iam create-access-key --user-name bia)'
run 'aws iam create-user --user-name caio --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'caio=$(aws iam create-access-key --user-name caio)'

block refusal
keep 'with_key "$caio" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name caio-try'
keep 's=$(with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy)'
keep 'with_session "$s" aws sts get-caller-identity --query Arn --output text'
keep 'with_session "$s" aws s3 ls'
keep 'with_session "$s" aws iam list-users'

block root-trust
run "aws iam create-role --role-name readonly --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::123456789012:root\"},\"Action\":\"sts:AssumeRole\"}]}' --query Role.Arn --output text"
run 'aws sts assume-role --role-arn arn:aws:iam::123456789012:role/readonly --role-session-name admin-try'

# ---- sessions ---------------------------------------------------------------------
block duration
keep 'with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --duration-seconds 600'
keep 'with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --duration-seconds 900 --query Credentials.Expiration --output text'
keep 'with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --duration-seconds 7200 --query Credentials.Expiration --output text'
run 'aws iam update-role --role-name deployer --max-session-duration 7200'
run 'aws iam get-role --role-name deployer --query Role.MaxSessionDuration'

block chain
run "aws iam create-role --role-name auditor --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::123456789012:role/deployer\"},\"Action\":\"sts:AssumeRole\"}]}' --query Role.Arn --output text"
run "aws iam put-role-policy --role-name deployer --policy-name chain-to-auditor --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::123456789012:role/auditor*\"}]}'"
keep 's=$(with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy)'
keep 'with_session "$s" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/auditor --role-session-name chained'
run "aws iam create-role --role-name auditor-session --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy\"},\"Action\":\"sts:AssumeRole\"}]}' --query Role.Arn --output text"
keep 'with_session "$s" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/auditor-session --role-session-name chained --duration-seconds 7200 --query "[AssumedRoleUser.Arn,Credentials.Expiration]" --output text'

block source-identity
keep 'with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --source-identity bia --query "{User:AssumedRoleUser.Arn,SourceIdentity:SourceIdentity}"'

# ---- cross-account ------------------------------------------------------------------
block org
run 'aws organizations create-organization --feature-set ALL --query Organization.MasterAccountId --output text'
run 'aws organizations create-account --account-name shop-prod --email aws+shop-prod@example.com --query "CreateAccountStatus.[AccountName,State,AccountId]" --output text'

block into-prod
keep 'prod=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-prod\`].Id" --output text)'
keep 's=$(aws sts assume-role --role-arn arn:aws:iam::$prod:role/OrganizationAccountAccessRole --role-session-name ana-admin)'
keep 'with_session "$s" aws sts get-caller-identity'
keep 'with_session "$s" aws ec2 describe-vpcs'
keep 'with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::$prod:role/OrganizationAccountAccessRole --role-session-name bia-try'

block nowhere
run 'aws sts assume-role --role-arn arn:aws:iam::111122223333:role/OrganizationAccountAccessRole --role-session-name nowhere --query AssumedRoleUser.Arn --output text'

fences json "$HERE/cross-account.md" 1 > monitoring-trust.json || exit 1
block monitoring
run 'aws iam create-role --role-name monitoring --assume-role-policy-document file://monitoring-trust.json --query Role.Arn --output text'
run 'aws iam create-user --user-name vendor --query User.Arn --output text'
run "aws iam put-user-policy --user-name vendor --policy-name assume-monitoring --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::123456789012:role/monitoring\"}]}'"
keep 'vendor=$(aws iam create-access-key --user-name vendor)'
keep 'with_key "$vendor" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/monitoring --role-session-name for-another-customer --external-id other-9q2m11 --query AssumedRoleUser.Arn --output text'
keep 'with_key "$vendor" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/monitoring --role-session-name for-the-shop --external-id shop-7f3k92 --query AssumedRoleUser.Arn --output text'
keep 'with_key "$vendor" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/monitoring --role-session-name no-id --query AssumedRoleUser.Arn --output text'

# typed into the same shell, where $prod is set
eval "$(sh_fences "$HERE/cross-account.md" 1)" || { echo "the config fence failed"; exit 1; }
block profile
run 'aws sts get-caller-identity --profile shop-prod'
run 'aws configure list --profile shop-prod'
run 'aws sts get-caller-identity --query Arn --output text'
