#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moto is started empty and seeded, with its checking off. The account is built
# by the-faults' ```sh fence 1, run in this script's own shell (so `$sg` stays
# set, as it would in the student's terminal). scan.py is the code parts of the
# schooling-example in "a-scanner", and accepted.txt is from-finding-to-fix's
# ```sh fence 1.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that use a shell variable are run in this script's own shell by
#     `keep`, which is what typing them into one terminal does;
#   - the files the lesson asks the student to write are removed at the end.
#
# NOT RUN, and said so in the prose: enable-mfa-device against AWS (moto takes
# any two codes); AWS Config, Security Hub, Defender for Cloud, Security Command
# Center, Prowler and ScoutSuite, which are taught from their documentation.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

moto_fresh
trap 'moto_stop; cd ~/aws && rm -f scan.py accepted.txt' EXIT

eval "$(sh_fences "$HERE/the-faults.md" 1)"

block faults-list
run 'aws s3api list-buckets --query "Buckets[].Name" --output text'
run 'aws iam list-users --query "Users[].UserName" --output text'
run 'aws ec2 describe-security-groups --query "SecurityGroups[].[GroupId,GroupName]" --output text'

example "$HERE/a-scanner.md" scan.py > scan.py || exit 1
block scan-1
run 'python3 scan.py; echo "exit $?"'

bash -e <(sh_fences "$HERE/from-finding-to-fix.md" 1) || exit 1
block fixes
run "aws s3api put-bucket-encryption --bucket clinic-exports --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}'"
keep 'aws ec2 revoke-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return'
run 'aws iam enable-mfa-device --user-name bia --serial-number arn:aws:iam::123456789012:mfa/bia --authentication-code1 123456 --authentication-code2 654321'

block scan-2
run 'python3 scan.py; echo "exit $?"'

block drift
keep 'aws ec2 authorize-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return'
run 'python3 scan.py; echo "exit $?"'
