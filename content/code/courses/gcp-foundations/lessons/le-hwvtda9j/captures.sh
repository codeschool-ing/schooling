#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). policies.tf
# is read out of the ```hcl fence of "guardrails-for-planner" into a fresh
# ~/gcp/guardrails. The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: applying a policy, the effective
# policy Google computes, and a dry run's violations in the audit logs, which
# all need a Google organisation.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

tf_dir guardrails
tf_file "$HERE/guardrails-for-planner.md" 1 policies.tf
block plan
run 'terraform plan -input=false -out=plan.bin | tail -1'
run "terraform show -json plan.bin | jq -r '.resource_changes[].change.after | \"\\(.name)\\n  inherit_from_parent: \\(.spec[0].inherit_from_parent)\\n  allowed_values: \\(.spec[0].rules[0].values[0].allowed_values)\\n  dry run enforce: \\(.dry_run_spec[0].rules[0].enforce)\"'"
