#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moto's checking is ON, started as the-rule's ```sh fence 1 says, with lesson
# 7's three-request bootstrap. with_key and with_session are the-rule's ```sh
# fence 2, defined in this shell as typed. The policies saved to files are read
# out of the lesson's ```json fences (boundaries 1, resources-and-conditions 1).
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set a shell variable or the terminal's keys are run in this
#     script's own shell by `keep`, which is what typing them into one
#     terminal does;
#   - put-user-permissions-boundary makes moto answer HTTP 500; the error page
#     the command line prints is quoted as it came;
#   - the files the lesson asks the student to save are written from the
#     fences, and removed at the end.
#
# NOT PRODUCED HERE, and said so in the prose: everything AWS would refuse that
# moto allowed (the boundary, the session policy, the bucket policy, the MFA
# condition); the delegation policy being judged as AWS judges it; the cross-
# account rule; the policy simulator and IAM Access Analyzer (moto: HTTP 500).
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

[ "$(sh_fences "$HERE/the-rule.md" 1)" = 'INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567' ] \
  || { echo "the-rule fence 1 changed"; exit 1; }
FILES='delegate-roles.json keep-assets.json'
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT

block bootstrap
run 'aws iam create-user --user-name admin --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'key=$(aws iam create-access-key --user-name admin)'
run 'aws iam list-users'
keep 'export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)'
run 'aws sts get-caller-identity --query Arn --output text'

eval "$(sh_fences "$HERE/the-rule.md" 2)"

block setup
run 'aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api put-object --bucket shop-assets --key logo.png --query ETag --output text'
run 'aws s3api put-object --bucket shop-backups --key orders-2026-10-15.dump --query ETag --output text'
run 'aws iam create-user --user-name caio --query User.Arn --output text'
keep 'caio=$(aws iam create-access-key --user-name caio)'

block implicit
keep 'with_key "$caio" aws s3 ls'
keep 'with_key "$caio" aws iam list-users'

block allow
run 'aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess'
keep 'with_key "$caio" aws s3 ls'
keep 'with_key "$caio" aws s3api list-objects-v2 --bucket shop-backups --query "Contents[].Key" --output text'

block deny
run "aws iam put-user-policy --user-name caio --policy-name no-backups --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Deny\",\"Action\":\"s3:*\",\"Resource\":[\"arn:aws:s3:::shop-backups\",\"arn:aws:s3:::shop-backups/*\"]}]}'"
keep 'with_key "$caio" aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text'
keep 'with_key "$caio" aws s3api list-objects-v2 --bucket shop-backups --query "Contents[].Key" --output text'

# ---- boundaries -----------------------------------------------------------------
block boundary-policy
run "aws iam create-policy --policy-name s3-only-boundary --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:*\",\"Resource\":\"*\"}]}' --query Policy.Arn --output text"
run 'aws iam create-user --user-name dani --permissions-boundary arn:aws:iam::123456789012:policy/s3-only-boundary --query User.PermissionsBoundary'
run 'aws iam put-user-permissions-boundary --user-name dani --permissions-boundary arn:aws:iam::123456789012:policy/s3-only-boundary'

block boundary-role
run "aws iam create-role --role-name app-admin --permissions-boundary arn:aws:iam::123456789012:policy/s3-only-boundary --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::123456789012:user/admin\"},\"Action\":\"sts:AssumeRole\"}]}' --query Role.PermissionsBoundary"
run 'aws iam attach-role-policy --role-name app-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/app-admin --role-session-name try-boundary)'
keep 'with_session "$r" aws sts get-caller-identity --query Arn --output text'
keep 'with_session "$r" aws iam list-users --query "Users[].UserName" --output text'
keep 'with_session "$r" aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text'

block session-policy
keep "r=\$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/app-admin --role-session-name narrowed --policy '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Deny\",\"Action\":\"iam:*\",\"Resource\":\"*\"}]}')"
keep 'with_session "$r" aws iam list-users --query "Users[].UserName" --output text'

fences json "$HERE/boundaries.md" 1 > delegate-roles.json || exit 1
block delegation
run "aws iam create-policy --policy-name app-boundary --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:*\",\"logs:*\"],\"Resource\":\"*\"}]}' --query Policy.Arn --output text"
run 'aws iam create-policy --policy-name delegate-roles --policy-document file://delegate-roles.json --query Policy.Arn --output text'
run 'aws iam create-user --user-name bia --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::123456789012:policy/delegate-roles'
keep 'bia=$(aws iam create-access-key --user-name bia)'
keep "with_key \"\$bia\" aws iam create-role --role-name app-web --permissions-boundary arn:aws:iam::123456789012:policy/app-boundary --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}'"

# ---- resources and conditions -----------------------------------------------------
fences json "$HERE/resources-and-conditions.md" 1 > keep-assets.json || exit 1
block bucket-policy
run 'aws s3api put-bucket-policy --bucket shop-assets --policy file://keep-assets.json'
run 'aws s3api get-bucket-policy --bucket shop-assets --query Policy --output text'
run 'aws s3api delete-object --bucket shop-assets --key logo.png'
run 'aws s3api delete-bucket --bucket shop-assets'
run 'aws s3 ls'

block condition-region
run "aws iam put-user-policy --user-name caio --policy-name only-sao-paulo --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Deny\",\"Action\":\"*\",\"Resource\":\"*\",\"Condition\":{\"StringNotEquals\":{\"aws:RequestedRegion\":\"sa-east-1\"}}}]}'"
keep 'echo $AWS_DEFAULT_REGION'
keep 'with_key "$caio" aws s3 ls'
run 'aws iam delete-user-policy --user-name caio --policy-name only-sao-paulo'
keep 'with_key "$caio" aws s3 ls'

block condition-mfa
run "aws iam put-user-policy --user-name dani --policy-name buckets-with-mfa --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:ListAllMyBuckets\",\"Resource\":\"*\",\"Condition\":{\"Bool\":{\"aws:MultiFactorAuthPresent\":\"true\"}}}]}'"
keep 'dani=$(aws iam create-access-key --user-name dani)'
keep 'with_key "$dani" aws s3 ls'
run 'aws iam list-mfa-devices --user-name dani'
