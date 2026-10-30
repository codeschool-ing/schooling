#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). lb.tf is
# read out of the ```hcl fence of "the-chain" into a fresh ~/gcp/lb. The
# emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: any load balancer, certificate,
# backend or request, and every price, which is read from the pricing page.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

tf_dir lb
tf_file "$HERE/the-chain.md" 1 lb.tf
block plan
run 'terraform plan -input=false -no-color 2>&1 | grep -E "^Plan|^Error|# google"'
block graph
run "terraform graph | grep -- '->' | grep -v provider | sed 's/\\[root\\] //g; s/ (expand)//g; s/\"//g'"
