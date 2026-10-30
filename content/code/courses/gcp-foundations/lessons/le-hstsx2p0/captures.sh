#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty emulator. deployer.tf is read out of the ```hcl fence of
# "impersonation" into a fresh ~/gcp/deployer.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# TWO BLOCKS REACH GOOGLE ITSELF, on purpose: `impersonate` lets gcloud ask
# the real IAM Credentials API for a token with the placeholder, and `curl`
# asks it directly. Both are refused, and quoted as Google sent them.
#
# NOT PRODUCED HERE, and said so in the prose: attaching an account, a token
# being minted, and anything about keys. No key, real or imitated, exists in
# this course.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
pubsub_fresh

net
block impersonate
run 'gcloud pubsub topics list --impersonate-service-account=deployer@planner-dev.iam.gserviceaccount.com'
block curl
run "curl -sS -X POST -H 'Authorization: Bearer placeholder' -H 'Content-Type: application/json' -d '{\"scope\": [\"https://www.googleapis.com/auth/cloud-platform\"], \"lifetime\": \"3600s\"}' https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/deployer@planner-dev.iam.gserviceaccount.com:generateAccessToken"

tf_dir deployer
tf_file "$HERE/impersonation.md" 1 deployer.tf
block plan
run "terraform plan -input=false -no-color | grep -E '^  # |      \\+ (account_id|email|member|role) |^Plan:'"
