#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). pool.tf is
# written twice into a fresh ~/gcp/federation, as the student edits it, from
# the two ```hcl fences of "a-pool-for-ci". credentials.json is written by
# the ```sh fence of "the-credential-file", run as it stands. The emulator is
# not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: the file
# gcloud writes ends without a newline, and the block `cat` adds one so that
# the transcript ends on its own line. The token file the configuration names, /tmp/github-token, does not exist
# and is not read: create-cred-config only records the path.
#
# ONE BLOCK REACHES GOOGLE ITSELF: `sts` sends a token exchange to the real
# Security Token Service with the text not-a-real-token, and quotes the
# refusal.
#
# NOT PRODUCED HERE, and said so in the prose: a pool, a provider, a token
# from GitHub and a successful exchange.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
SEC=$HERE/a-pool-for-ci.md

tf_dir federation
tf_file "$SEC" 1 pool.tf
block validate
run 'terraform validate -no-color'
tf_file "$SEC" 2 pool.tf
block plan
run "terraform plan -input=false -no-color | grep -E '^  # |attribute_condition|issuer_uri|      \\+ role|^Plan:'"

sh_fences "$HERE/the-credential-file.md" 1 | bash -e > /dev/null 2>&1 || { echo "create-cred-config failed"; exit 1; }
block cat
run 'cat credentials.json'
echo   # the file has no final newline; the terminal's next prompt would follow it
block sts
run "curl -sS -X POST https://sts.googleapis.com/v1/token -H 'Content-Type: application/json' -d '{\"grantType\": \"urn:ietf:params:oauth:grant-type:token-exchange\", \"audience\": \"//iam.googleapis.com/projects/415104041262/locations/global/workloadIdentityPools/ci-pool/providers/github\", \"scope\": \"https://www.googleapis.com/auth/cloud-platform\", \"requestedTokenType\": \"urn:ietf:params:oauth:token-type:access_token\", \"subjectTokenType\": \"urn:ietf:params:oauth:token-type:jwt\", \"subjectToken\": \"not-a-real-token\"}'"
