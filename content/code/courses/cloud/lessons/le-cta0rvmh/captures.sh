#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of cloud, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   python3 -m venv ~/moto-venv && ~/moto-venv/bin/pip install 'moto[server]'
#   MOTO_VENV=~/moto-venv AWS_BIN=/path/to/aws-cli/v2/bin bash captures.sh
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE. Two things are captured, and neither
# is a cloud:
#
#   - prices.py reads the AWS public price list, which AWS publishes as JSON with
#     no account and no key, at the offer versions pinned inside it. The files are
#     cached in ~/.cache/cloud-prices after the first run. Nothing here is a bill.
#
#   - moto (5.2.3 when this was recorded) is a Python program that IMITATES the S3
#     API on the laptop. moto_server listens on 127.0.0.1:5000 and answers the same
#     HTTP requests S3 answers, so the real AWS CLI (aws-cli/2.37.4) can be pointed
#     at it. It says nothing about S3's latency, durability or price, and nothing
#     it prints left this machine. The credentials are the literal word "test",
#     which moto accepts and AWS would not.
#
# The CLI runs under env -i, so NOTHING from the recording machine's environment
# reaches it: only the variables the transcript shows being exported.
#
# What is STAGED rather than typed, and not shown in the lesson: the price cache,
# already filled; moto_server started in the background with its log going to
# moto.log; the two files that get uploaded (a 100-byte cat.jpg and a 6-byte
# report.txt) written into a scratch directory. The prompt shows ~/cloud whatever
# directory the command ran in.
#
# The timestamps in the listings and the version ids moto makes up change on every
# run; the lesson quotes the run recorded below and says so where it matters.
#
# Recorded 2026-09-28 on Ubuntu 24.04, Python 3.11, no cloud account and no
# credentials, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
COURSE=$(cd "$(dirname "$0")/../.." && pwd)
MOTO_VENV=${MOTO_VENV:?set MOTO_VENV to a venv with moto[server] installed}
AWS_BIN=${AWS_BIN:?set AWS_BIN to the directory holding the aws binary}

block() { printf '##### %s\n' "$1"; }
show() { printf 'ana@laptop:~/cloud$ %s\n' "$*"; }
# what ana typed at her prompt, and everything it printed
run() { show "$*"; bash -c "$*" 2>&1 || true; }
# the AWS CLI with nothing of this machine's environment but what the
# transcript exports
EXPORTS='AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=sa-east-1 AWS_ENDPOINT_URL=http://127.0.0.1:5000'
awsrun() {
  show "$*"
  # shellcheck disable=SC2086
  env -i HOME="$WORK" TZ="$TZ" LC_ALL=C.UTF-8 PATH="$AWS_BIN:/usr/bin:/bin" $EXPORTS \
    bash -c "$*" 2>&1 || true
}

. "$(cd "$(dirname "$0")/../.." && pwd)/from-lessons.sh"   # prices_py: the program as lesson 1 prints it
SHEET=$(mktemp -d)   # the student's ~/cloud, holding prices.py
prices_py "$SHEET" || exit 1
cd "$SHEET" || exit 1

block prices-storage
run 'python3 prices.py storage'

block prices-ebs
run "python3 prices.py ec2 | grep -A3 '^EBS'"

# ---- moto: an imitation of the S3 API on 127.0.0.1 --------------------------
WORK=$(mktemp -d)
trap 'kill "$MOTO_PID" 2>/dev/null; rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1
"$MOTO_VENV/bin/moto_server" -p 5000 > moto.log 2>&1 &
MOTO_PID=$!
for _ in $(seq 40); do curl -s -o /dev/null http://127.0.0.1:5000/ && break; sleep 0.25; done
head -c 100 /dev/zero | tr '\0' 'x' > cat.jpg
printf 'hello\n' > report.txt

block s3-by-hand
show "export $EXPORTS"
awsrun 'aws s3 mb s3://ana-uploads'
awsrun 'aws s3 cp --no-progress cat.jpg s3://ana-uploads/photos/2026/cat.jpg'
awsrun 'aws s3 cp --no-progress report.txt s3://ana-uploads/reports/q3.txt'
awsrun 'aws s3 ls s3://ana-uploads'
awsrun 'aws s3 ls s3://ana-uploads --recursive'
awsrun "aws s3api list-objects-v2 --bucket ana-uploads --query 'Contents[].Key'"

block rename
awsrun 'aws s3 mv --no-progress s3://ana-uploads/reports/q3.txt s3://ana-uploads/reports/2026-q3.txt'
run "grep -o '[A-Z]* /ana-uploads/reports[^ ]*' moto.log"

block versioning
awsrun 'aws s3api put-bucket-versioning --bucket ana-uploads --versioning-configuration Status=Enabled'
awsrun 'aws s3 cp --no-progress report.txt s3://ana-uploads/notes.txt'
run "echo 'hello, again' > report.txt"
awsrun 'aws s3 cp --no-progress report.txt s3://ana-uploads/notes.txt'
awsrun 'aws s3 rm s3://ana-uploads/notes.txt'
awsrun 'aws s3 ls s3://ana-uploads/notes.txt'
awsrun "aws s3api list-object-versions --bucket ana-uploads --prefix notes.txt --query 'Versions[].[Key,Size,IsLatest]' --output text"
awsrun "aws s3api list-object-versions --bucket ana-uploads --prefix notes.txt --query 'DeleteMarkers[].[Key,VersionId,IsLatest]' --output text"
# the marker's id is whatever moto made up; it is read here and typed below the
# way somebody copies it off the line above
MARKER=$(env -i HOME="$WORK" PATH="$AWS_BIN:/usr/bin:/bin" $EXPORTS aws s3api list-object-versions \
  --bucket ana-uploads --prefix notes.txt --query 'DeleteMarkers[0].VersionId' --output text)
awsrun "aws s3api delete-object --bucket ana-uploads --key notes.txt --version-id $MARKER"
awsrun 'aws s3 cp s3://ana-uploads/notes.txt -'
