#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moto's checking is ON, started as a-trail's ```sh fence 1 says, with lesson
# 6's three-request admin bootstrap. The JSON files are read out of the lesson's
# own ```json fences: trail-bucket-policy.json and selectors.json (a-trail 1
# and 2), trail.json (reading-records 1), keep-the-trail.json
# (protecting-the-trail 1). with_key is protecting-the-trail's ```sh fence 1,
# defined in this shell as typed.
#
# trail.json IS NOT A RECORDING. moto 5.2.3 records no CloudTrail events
# (lookup-events answers HTTP 500, the trail's bucket stays empty, both shown),
# so the records the lesson reads are a file written for the course in the
# record format of AWS's documentation, abridged, with documentation addresses.
# The prose says so before showing it. The jq runs over it are real.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set a shell variable or the terminal's keys are run in this
#     script's own shell by `keep`, which is what typing them into one
#     terminal does;
#   - the files the lesson asks the student to save are written from the
#     fences, and removed at the end.
#
# NOT PRODUCED HERE, and said so in the prose: any CloudTrail record or
# delivered log file, event history, AWS's InsufficientS3BucketPolicyException,
# the organisation trail and its SCP, S3 Object Lock, digest files and
# validate-logs, the metric filter and alarm, and everything about Azure and
# Google Cloud.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

[ "$(sh_fences "$HERE/a-trail.md" 1)" = 'INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567' ] \
  || { echo "a-trail fence 1 changed"; exit 1; }
FILES='trail-bucket-policy.json selectors.json trail.json keep-the-trail.json'
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT
fences json "$HERE/a-trail.md" 1 > trail-bucket-policy.json || exit 1
fences json "$HERE/a-trail.md" 2 > selectors.json || exit 1
fences json "$HERE/reading-records.md" 1 > trail.json || exit 1
fences json "$HERE/protecting-the-trail.md" 1 > keep-the-trail.json || exit 1
eval "$(sh_fences "$HERE/protecting-the-trail.md" 1)"

block bootstrap
run 'aws iam create-user --user-name admin --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'key=$(aws iam create-access-key --user-name admin)'
run 'aws iam list-users'
keep 'export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)'
run 'aws sts get-caller-identity --query Arn --output text'

block bucket
run 'aws s3api create-bucket --bucket clinic-trail --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api put-bucket-policy --bucket clinic-trail --policy file://trail-bucket-policy.json'

block create
run 'aws cloudtrail create-trail --name clinic-trail --s3-bucket-name clinic-trail --is-multi-region-trail --enable-log-file-validation'

block selectors
run 'aws cloudtrail put-event-selectors --trail-name clinic-trail --advanced-event-selectors file://selectors.json --query "AdvancedEventSelectors[].Name"'
run 'aws cloudtrail start-logging --name clinic-trail'

block status
run 'aws cloudtrail get-trail-status --name clinic-trail'

block empty
sleep 2
run 'aws s3 ls s3://clinic-trail --recursive'
run 'aws cloudtrail lookup-events --max-results 5 2>&1 | head -2'

# ---- reading-records -------------------------------------------------------------
block count
run "jq -r '.Records[] | .eventName' trail.json | sort | uniq -c"
block who
run "jq -c '.Records[] | select(.eventName | test(\"BucketPolicy\")) | {eventTime, eventName, user: .userIdentity.userName, ip: .sourceIPAddress, bucket: .requestParameters.bucketName}' trail.json"
block policy
run "jq -c '.Records[] | select(.eventName == \"PutBucketPolicy\") | .requestParameters.bucketPolicy.Statement[] | {Principal, Action}' trail.json"
block anonymous
run "jq -r '.Records[] | select(.userIdentity.accountId == \"ANONYMOUS_PRINCIPAL\") | [.eventTime, .sourceIPAddress, .requestParameters.key, (.errorCode // \"served\")] | @tsv' trail.json"
block refused
run "jq -r '.Records[] | select(.errorCode) | [.eventTime, (.userIdentity.userName // .userIdentity.accountId), .eventName, .errorCode] | @tsv' trail.json"

# ---- protecting-the-trail --------------------------------------------------------
block caio
run 'aws iam create-user --user-name caio --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
run 'aws iam put-user-policy --user-name caio --policy-name keep-the-trail --policy-document file://keep-the-trail.json'
keep 'caio=$(aws iam create-access-key --user-name caio)'
keep 'with_key "$caio" aws cloudtrail stop-logging --name clinic-trail'
keep 'with_key "$caio" aws cloudtrail get-trail-status --name clinic-trail --query IsLogging'
keep 'with_key "$caio" aws cloudtrail describe-trails --query "trailList[].[Name,IsMultiRegionTrail,LogFileValidationEnabled]" --output text'
