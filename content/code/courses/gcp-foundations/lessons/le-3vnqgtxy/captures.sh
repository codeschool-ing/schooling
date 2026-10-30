#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). shared.tf is
# read out of the ```hcl fence of "shared-vpc" into a fresh ~/gcp/shared-vpc;
# peerings.json, reach.py and peering.tf out of "peering" into a fresh
# ~/gcp/peering. The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing. The
# networks and peerings are data a program applies Google's documented rules
# to; the prose says no network is involved.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: any host or service project,
# grant, network or peering, and Google's refusal of an overlapping peering.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

tf_dir shared-vpc
tf_file "$HERE/shared-vpc.md" 1 shared.tf
block shared
run 'terraform plan -input=false -no-color | grep -E "^Plan|# google|role|member"'

tf_dir peering
fences json "$HERE/peering.md" 1 > peerings.json || exit 1
example "$HERE/peering.md" reach.py > reach.py || exit 1
block pairs
run 'python3 reach.py planner partner'
run 'python3 reach.py partner analytics'
block acquired
run 'python3 reach.py planner acquired'
tf_file "$HERE/peering.md" 1 peering.tf
block peering
run 'terraform plan -input=false -no-color | grep -E "^Plan|# google|export_custom|import_custom"'
