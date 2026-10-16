#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Recorded in the lab lesson 1 built, against an empty moto with no permission
# checking. shop-check.py is read out of the lesson's schooling-example and
# removed from ~/aws when the capture ends.
#
# TRIMMED, and said so in the prose: every `--debug` transcript is cut down by
# the grep printed in its own command line, so what is cut is visible; nothing
# else is removed from any output.
#
# The signatures, dates and retry delays differ on every run.
#
# NOT PRODUCED HERE, and said so in the prose: the console, which needs an AWS
# account and a browser; CloudTrail (lookup-events answers 500 in moto 5.2.3);
# throttling, which moto never does.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
trap 'moto_stop; rm -f ~/aws/shop-check.py' EXIT

example "$HERE/protocols-and-sdks.md" shop-check.py > ~/aws/shop-check.py || exit 1

# ---- one-api ------------------------------------------------------------------
block debug-sts
run "aws sts get-caller-identity --debug 2>&1 | grep -oE \"'body': \\{[^}]*\\}|method=POST, url=[^,]*|'(Content-Type|X-Amz-Date|Authorization)': b'[^']*'\""

block canonical
run 'aws sts get-caller-identity --debug 2>&1 | grep -A9 "CanonicalRequest:" | sed "s/^.* - DEBUG - //"'

block curl
run "curl -s --aws-sigv4 \"aws:amz:sa-east-1:sts\" --user test:test -d 'Action=GetCallerIdentity&Version=2011-06-15' http://localhost:4567/; echo"
run "curl -s -o /dev/null -v --aws-sigv4 \"aws:amz:sa-east-1:sts\" --user test:test -d 'Action=GetCallerIdentity&Version=2011-06-15' http://localhost:4567/ 2>&1 | grep -iE \"^> (POST|authorization|x-amz-date)\""

# ---- protocols-and-sdks --------------------------------------------------------
block protocol-json
run "aws organizations create-organization --feature-set ALL --debug 2>&1 | grep -oE \"method=POST, url=[^,]*|'(Content-Type|X-Amz-Target)': b'[^']*'\""

block protocol-rest
run "aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --debug 2>&1 | grep -oE \"method=PUT, url=[^,]*|b'<CreateBucketConfiguration[^']*'\""

block protocol-query
run "aws ec2 describe-vpcs --debug 2>&1 | grep -oE \"'body': \\{[^}]*\\}\""

block boto3
run 'python3 -m pip show boto3 | grep -E "^(Name|Version|Required-by)"'
run 'which python3'

block program
run 'python3 shop-check.py'

# ---- retries-and-the-console ---------------------------------------------------
block retries
run "aws rolesanywhere list-trust-anchors --debug 2>&1 | grep -oE \"'amz-sdk-request': b'[^']*'|Retry needed, retrying request after delay of: [0-9.]*|reached max retries: [0-9]*\" | head -6"
block retries-one
run 'AWS_MAX_ATTEMPTS=1 aws rolesanywhere list-trust-anchors --debug 2>&1 | grep -c "Sending http request"'
