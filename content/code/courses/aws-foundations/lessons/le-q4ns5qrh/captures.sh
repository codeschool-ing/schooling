#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Recorded in the lab lesson 1 built, against moto started as lesson 7 starts it:
# INITIAL_NO_AUTH_ACTION_COUNT=3, and an `admin` user bootstrapped in exactly
# three requests. upload-erp.json, mfa-to-delete.json, mfa-flipped.json and
# key-ages.py are read out of the lesson's own fences; they and sales.csv are
# removed from ~/aws when the capture ends.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - a line that sets shell variables (read -r ..., which keeps a secret off the
#     screen) is printed with the prompt and then applied to this script's own
#     shell, which is what typing it at the prompt does; the variables are then
#     exported so that the child shells `run` starts can expand them;
#   - "wait a week" between deactivating and deleting the old key is not waited.
#
# NOT PRODUCED HERE, and said so in the prose: a session with MFA (moto's
# get-session-token returns credentials its own checking refuses), CloudTrail's
# lookup-events (500 in moto 5.2.3), GitHub's secret scanning and push
# protection, git-secrets, and AWS attaching the quarantine policy on its own.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap 'moto_stop; rm -f ~/aws/upload-erp.json ~/aws/mfa-to-delete.json ~/aws/mfa-flipped.json ~/aws/key-ages.py ~/aws/sales.csv' EXIT

sets() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*"; }

fences json "$HERE/rotation.md" 1 > ~/aws/upload-erp.json || exit 1
example "$HERE/rotation.md" key-ages.py > ~/aws/key-ages.py || exit 1
fences json "$HERE/limits-and-leaks.md" 1 > ~/aws/mfa-to-delete.json || exit 1
fences json "$HERE/limits-and-leaks.md" 2 > ~/aws/mfa-flipped.json || exit 1

# ---- rotation -----------------------------------------------------------------
block bootstrap
run 'aws iam create-user --user-name admin --query User.Arn --output text'
sets 'read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY < <(aws iam create-access-key --user-name admin --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)'
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
run 'aws sts get-caller-identity --query Arn --output text'

block erp-user
run 'aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws iam create-user --user-name erp-sync --query User.Arn --output text'
run 'aws iam put-user-policy --user-name erp-sync --policy-name upload-erp --policy-document file://upload-erp.json'
sets 'read -r OLD_ID OLD_SECRET < <(aws iam create-access-key --user-name erp-sync --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)'
export OLD_ID OLD_SECRET
run 'echo $OLD_ID'

block erp-upload
run "printf 'order,total_cents\n1001,4990\n' > sales.csv"
run 'AWS_ACCESS_KEY_ID=$OLD_ID AWS_SECRET_ACCESS_KEY=$OLD_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv'

block second-key
sets 'read -r NEW_ID NEW_SECRET < <(aws iam create-access-key --user-name erp-sync --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)'
export NEW_ID NEW_SECRET
run 'aws iam list-access-keys --user-name erp-sync --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text'
run 'aws iam create-access-key --user-name erp-sync --query AccessKey.AccessKeyId --output text'

block switch
run 'AWS_ACCESS_KEY_ID=$NEW_ID AWS_SECRET_ACCESS_KEY=$NEW_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv'
run 'aws iam get-access-key-last-used --access-key-id $OLD_ID --query "AccessKeyLastUsed.[LastUsedDate,ServiceName]" --output text'
run 'aws iam get-access-key-last-used --access-key-id $NEW_ID --query "AccessKeyLastUsed.[LastUsedDate,ServiceName]" --output text'

block deactivate
run 'aws iam update-access-key --user-name erp-sync --access-key-id $OLD_ID --status Inactive'
run 'aws iam list-access-keys --user-name erp-sync --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text'
run 'AWS_ACCESS_KEY_ID=$OLD_ID AWS_SECRET_ACCESS_KEY=$OLD_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv'

block delete
run 'aws iam delete-access-key --user-name erp-sync --access-key-id $OLD_ID'
run 'AWS_ACCESS_KEY_ID=$OLD_ID AWS_SECRET_ACCESS_KEY=$OLD_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv'

block report
run 'aws iam generate-credential-report --query State --output text'
sleep 1
run 'aws iam generate-credential-report --query State --output text'
run 'aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,9,10,11,14'

block ages
run 'aws iam get-credential-report --query Content --output text | base64 -d | python3 key-ages.py'

# ---- limits-and-leaks ---------------------------------------------------------
block dani
run 'aws iam create-user --user-name dani --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess'
run 'aws iam put-user-policy --user-name dani --policy-name mfa-to-delete --policy-document file://mfa-to-delete.json'
sets 'read -r DANI_ID DANI_SECRET < <(aws iam create-access-key --user-name dani --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)'
export DANI_ID DANI_SECRET
run 'AWS_ACCESS_KEY_ID=$DANI_ID AWS_SECRET_ACCESS_KEY=$DANI_SECRET aws s3api list-objects-v2 --bucket shop-backups --query "Contents[].Key" --output text'
run 'AWS_ACCESS_KEY_ID=$DANI_ID AWS_SECRET_ACCESS_KEY=$DANI_SECRET aws s3 rm s3://shop-backups/erp/sales.csv'

block flipped
run 'aws iam put-user-policy --user-name dani --policy-name mfa-to-delete --policy-document file://mfa-flipped.json'
run 'AWS_ACCESS_KEY_ID=$DANI_ID AWS_SECRET_ACCESS_KEY=$DANI_SECRET aws s3 rm s3://shop-backups/erp/sales.csv'

block quarantine
run 'aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[].[Effect,length(Action)]" --output text'
run 'aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[0].Action" --output text | tr "\t" "\n" | cut -d: -f1 | sort | uniq -c | sort -rn | head -5'

block respond
run 'aws iam update-access-key --user-name dani --access-key-id $DANI_ID --status Inactive'
run 'aws iam attach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3'
run 'aws iam list-attached-user-policies --user-name dani --query "AttachedPolicies[].PolicyName" --output text'
