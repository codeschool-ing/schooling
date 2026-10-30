#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). billing.tf
# is read out of the ```hcl fence of "the-link" into a fresh ~/gcp/billing.
# The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# ONE BLOCK REACHES GOOGLE ITSELF: `accounts` asks the real Cloud Billing API
# for the caller's billing accounts with the placeholder token, and quotes the
# refusal.
#
# NOT PRODUCED HERE, and said so in the prose: a billing account, a link, an
# unlink, and any bill.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

net
block accounts
run 'gcloud billing accounts list'

tf_dir billing
tf_file "$HERE/the-link.md" 1 billing.tf
block plan
run "terraform plan -input=false -no-color | grep -E '^  # |      \\+ (billing_account|billing_account_id|role|member) |^Plan:'"
