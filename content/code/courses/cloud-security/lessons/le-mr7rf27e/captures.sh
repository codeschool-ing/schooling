#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moto's checking is ON, started as the-long-lived-key's ```sh fence 1 says,
# with aws-foundations lesson 8's three-request bootstrap. with_key is
# the-long-lived-key's ```sh fence 2 and with_session is federation-instead's
# ```sh fence 1, defined in this shell as typed. trust-google.json is
# federation-instead's ```json fence 1.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set a shell variable or use a function are run in this
#     script's own shell by `keep`, which is what typing them into one terminal
#     does;
#   - the "nightly job in Google Cloud" is this terminal using the user's key.
#
# NOT PRODUCED HERE, and said so in the prose: Google Cloud itself (the job, its
# service account, the identity token, Google's logs); AWS's validation of the
# token and of the trust policy's condition (moto accepted a made-up token and
# ignores conditions); the source address CloudTrail would record; Azure; every
# hybrid link of "hybrid-links".
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

[ "$(sh_fences "$HERE/the-long-lived-key.md" 1)" = 'INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567' ] \
  || { echo "the-long-lived-key fence 1 changed"; exit 1; }
FILES='trust-google.json'
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT

block bootstrap
run 'aws iam create-user --user-name admin --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'key=$(aws iam create-access-key --user-name admin)'
run 'aws iam list-users'
keep 'export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)'
run 'aws sts get-caller-identity --query Arn --output text'

eval "$(sh_fences "$HERE/the-long-lived-key.md" 2)"

READ='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:ListBucket"],"Resource":["arn:aws:s3:::clinic-exports","arn:aws:s3:::clinic-exports/*"]}]}'

block setup
run 'aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api put-object --bucket clinic-exports --key 2026-10-23.csv --query ETag --output text'
run 'aws iam create-user --user-name reports-sync --query User.Arn --output text'
run "aws iam put-user-policy --user-name reports-sync --policy-name read-exports --policy-document '$READ'"
keep 'sync=$(aws iam create-access-key --user-name reports-sync)'

block nightly
keep 'with_key "$sync" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text'

block report
run 'aws iam generate-credential-report --query State --output text'
run 'aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,9,10,11,13'

block last-used
keep 'aws iam get-access-key-last-used --access-key-id "$(echo "$sync" | jq -r .AccessKey.AccessKeyId)"'

block lever-off
keep 'aws iam update-access-key --user-name reports-sync --access-key-id "$(echo "$sync" | jq -r .AccessKey.AccessKeyId)" --status Inactive'
keep 'with_key "$sync" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text'

block lever-delete
keep 'aws iam delete-access-key --user-name reports-sync --access-key-id "$(echo "$sync" | jq -r .AccessKey.AccessKeyId)"'
keep 'with_key "$sync" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text'

# ---- federation-instead: moto restarted without the count, as its ```sh fence 1
[ "$(sh_fences "$HERE/federation-instead.md" 1)" = 'moto_server -p 4567' ] \
  || { echo "federation-instead fence 1 changed"; exit 1; }
moto_fresh
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT
# a new terminal: env.sh read again, the administrator's key gone
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
. ~/aws/env.sh

fences json "$HERE/federation-instead.md" 1 > trust-google.json || exit 1
block bucket-again
run 'aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api put-object --bucket clinic-exports --key 2026-10-23.csv --query ETag --output text'

block role
run 'aws iam create-role --role-name reports-sync --assume-role-policy-document file://trust-google.json --query Role.Arn --output text'
run "aws iam put-role-policy --role-name reports-sync --policy-name read-exports --policy-document '$READ'"

block exchange
keep 's=$(aws sts assume-role-with-web-identity --no-sign-request --role-arn arn:aws:iam::123456789012:role/reports-sync --role-session-name nightly-export --web-identity-token not-a-real-token)'
keep "echo \"\$s\" | jq '.Credentials | {AccessKeyId, Expiration}'"

eval "$(sh_fences "$HERE/federation-instead.md" 2)"

block session
keep 'with_session "$s" aws sts get-caller-identity --query Arn --output text'
keep 'with_session "$s" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text'
