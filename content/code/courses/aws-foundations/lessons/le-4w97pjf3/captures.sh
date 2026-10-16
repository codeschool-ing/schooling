#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# THIS LESSON TURNS ON MOTO'S CHECKING: moto starts with
# INITIAL_NO_AUTH_ACTION_COUNT=3 (checked against checking-on's ```sh fence 1)
# and the three bootstrap requests are the lesson's own. The policies are read
# out of the lesson's ```json fences (policy-grammar 1, inline-and-choosing 1),
# and with_key is checking-on's ```sh fence 2, defined in this shell as typed.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set a shell variable or the terminal's keys (`key=$(...)`,
#     `export ...`, `bia=$(...)`) are run in this script's own shell rather than
#     in a child, by `keep`, which is what typing them into one terminal does;
#   - the files the lesson asks the student to save are written from the
#     fences before the command that reads them, and removed at the end;
#   - the block `count-typo` is taken first, in a moto of its own started with
#     the same count, and then moto is restarted for the rest.
#
# NOT PRODUCED HERE, and said so in the prose: AWS refusing an identity policy
# with a Principal; `aws s3 ls s3://bucket` working against AWS.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

[ "$(sh_fences "$HERE/checking-on.md" 1)" = 'INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567' ] \
  || { echo "checking-on fence 1 changed"; exit 1; }
FILES='shop-assets-rw.json edu-uploads.json logo.txt'

# ---- a typo spends the count --------------------------------------------------
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
block count-typo
run 'aws iam create-user --user-name admin'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAcess'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
run 'aws iam create-access-key --user-name admin --query AccessKey.AccessKeyId'

# ---- the bootstrap ------------------------------------------------------------
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT
block bootstrap
run 'aws iam create-user --user-name admin --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'key=$(aws iam create-access-key --user-name admin)'
run 'aws iam list-users'
keep 'export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)'
run 'aws sts get-caller-identity'
run 'aws iam list-users --query "Users[].UserName"'

# with_key, as the lesson types it
eval "$(sh_fences "$HERE/checking-on.md" 2)"

# ---- AWS-managed --------------------------------------------------------------
block aws-count
run 'aws iam list-policies --scope AWS --query "length(Policies)"'
block readonly
run 'aws iam get-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --query "Policy.[DefaultVersionId,CreateDate,UpdateDate]" --output text'
block readonly-doc
run 'aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --version-id v188 --query "PolicyVersion.Document.Statement[].{Sid:Sid,Actions:length(Action),Resource:Resource}" --output table'
run 'aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --version-id v188 --query "PolicyVersion.Document.Statement[1].Action[?starts_with(@, \`s3:\`)]"'

# ---- customer-managed ---------------------------------------------------------
fences json "$HERE/policy-grammar.md" 1 > shop-assets-rw.json || exit 1
printf 'logo\n' > logo.txt
block buckets
run 'aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api put-object --bucket shop-assets --key logo.txt --body logo.txt --query ETag --output text'
run 'aws iam create-policy --policy-name shop-assets-rw --policy-document file://shop-assets-rw.json'

block bia
run 'aws iam create-user --user-name bia --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw'
keep 'bia=$(aws iam create-access-key --user-name bia)'

block as-bia
keep 'with_key "$bia" aws sts get-caller-identity --query Arn --output text'
keep 'with_key "$bia" aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text'
keep 'with_key "$bia" aws s3 cp s3://shop-assets/logo.txt -'
keep 'with_key "$bia" aws s3api put-object --bucket shop-assets --key banner.txt --body logo.txt --query ETag --output text'
keep 'with_key "$bia" aws s3api list-objects-v2 --bucket shop-backups'
keep 'with_key "$bia" aws s3 ls'
keep 'with_key "$bia" aws s3api delete-object --bucket shop-assets --key logo.txt'
keep 'with_key "$bia" aws iam list-users'

block s3-ls
run 'aws s3 ls s3://shop-assets'
run 'aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text'

block versions
run 'for i in 2 3 4 5; do aws iam create-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --policy-document file://shop-assets-rw.json --query "PolicyVersion.[VersionId,IsDefaultVersion]" --output text; done'
run 'aws iam create-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --policy-document file://shop-assets-rw.json'
run 'aws iam delete-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --version-id v1'

block versions-2
run 'aws iam delete-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --version-id v2'
run 'aws iam create-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --policy-document file://shop-assets-rw.json --set-as-default --query "PolicyVersion.[VersionId,IsDefaultVersion]" --output text'
run 'aws iam set-default-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --version-id v1'
run 'aws iam list-policy-versions --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --query "Versions[].[VersionId,IsDefaultVersion]" --output text'

# ---- inline ---------------------------------------------------------------------
fences json "$HERE/inline-and-choosing.md" 1 > edu-uploads.json || exit 1
block edu
run 'aws iam create-user --user-name edu --query User.Arn --output text'
run 'aws iam put-user-policy --user-name edu --policy-name storefront-uploads --policy-document file://edu-uploads.json'
run 'aws iam list-user-policies --user-name edu'
run 'aws iam list-attached-user-policies --user-name edu'

block edu-leaves
run 'aws iam delete-user --user-name edu'
run 'aws iam delete-user-policy --user-name edu --policy-name storefront-uploads'
run 'aws iam delete-user --user-name edu'
run 'aws iam get-user --user-name edu'

block principal
run "aws iam put-user-policy --user-name bia --policy-name with-principal --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"s3:ListBucket\",\"Resource\":\"arn:aws:s3:::shop-backups\"}]}'"
keep 'with_key "$bia" aws s3api list-objects-v2 --bucket shop-backups'
run 'aws iam delete-user-policy --user-name bia --policy-name with-principal'

block limits
run 'aws iam get-account-summary --query "SummaryMap.{PolicySizeQuota:PolicySizeQuota,UserPolicySizeQuota:UserPolicySizeQuota,GroupPolicySizeQuota:GroupPolicySizeQuota,AttachedPoliciesPerUserQuota:AttachedPoliciesPerUserQuota,VersionsPerPolicyQuota:VersionsPerPolicyQuota}"'
