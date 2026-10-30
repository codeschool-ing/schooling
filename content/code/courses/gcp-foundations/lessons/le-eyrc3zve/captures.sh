#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). firewall.tf
# is read out of the two ```hcl fences of "targets" in turn, into a fresh
# ~/gcp/firewall; rules.json out of the ```json fence of "packet-walks" and
# walk.py out of its example. The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing. The
# packets are arguments to a program that applies Google's documented order to
# a list of rules; the prose says no network is involved.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: any firewall rule, firewall
# policy or packet.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

tf_dir firewall
tf_file "$HERE/targets.md" 1 firewall.tf
block refused
run 'terraform plan -input=false -no-color 2>&1 | grep -E "^Error|conflicts"'
tf_file "$HERE/targets.md" 2 firewall.tf
block planned
run 'terraform plan -input=false -no-color | grep -E "^Plan|priority|direction"'

fences json "$HERE/packet-walks.md" 1 > rules.json || exit 1
example "$HERE/packet-walks.md" walk.py > walk.py || exit 1
block health
run 'python3 walk.py 35.191.4.20 sa:web 8080'
run 'python3 walk.py 203.0.113.9 sa:web 8080'
block ssh
run 'python3 walk.py 35.235.240.7 sa:web 22'
run 'python3 walk.py 35.235.240.7 sa:web,tag:frozen 22'
block tie
run "sed -i 's/\"priority\": 900/\"priority\": 1000/' rules.json"
run 'python3 walk.py 35.235.240.7 sa:web,tag:frozen 22'
block db
run 'python3 walk.py sa:web sa:db 5432'
run 'python3 walk.py sa:reports sa:db 5432'
