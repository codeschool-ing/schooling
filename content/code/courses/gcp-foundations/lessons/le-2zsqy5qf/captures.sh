#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). network.tf
# is read out of the ```hcl fences of "a-global-network" and "auto-or-custom"
# in turn, into a fresh ~/gcp/network, with the two corrections the prose asks
# for made by sed, and the staging subnet of "cutting-ranges" appended to it;
# ranges.py out of the example in "cutting-ranges". The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# REACHES GOOGLE: one block, `create`, which asks Compute Engine to create the
# network and is refused for want of a credential.
#
# NOT PRODUCED HERE, and said so in the prose: any network or subnet, and
# Google's refusal of an overlapping subnet at apply time.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

cd ~/gcp && at '~/gcp'
block help
run 'gcloud compute networks create --help | grep -A1 "subnet-mode=MODE$"'

tf_dir network
tf_file "$HERE/a-global-network.md" 1 network.tf
block defaults
run 'terraform plan -input=false -no-color | grep -E "^Plan:|# google|auto_create|routing_mode|mtu"'
tf_file "$HERE/auto-or-custom.md" 1 network.tf
block refused
run 'terraform plan -input=false -no-color 2>&1 | grep -E "^Error"'
sed -i 's/Planner_Santiago/planner-santiago/; s|10.11.0.0/33|10.11.0.0/20|' network.tf
block custom
run 'terraform plan -input=false -no-color | grep -E "^Plan:|# google|ip_cidr_range|auto_create|routing_mode"'
{ echo; fences hcl "$HERE/cutting-ranges.md" 1; } >> network.tf || exit 1
block overlap
run 'terraform plan -input=false -no-color | grep -E "^Plan:"'

cd ~/gcp && at '~/gcp'
example "$HERE/cutting-ranges.md" ranges.py > ranges.py || exit 1
block ranges
run 'python3 ranges.py sao-paulo=10.10.0.0/20 santiago=10.11.0.0/20 virginia=10.12.0.0/20; echo "exit $?"'
block clashes
run 'python3 ranges.py sao-paulo=10.10.0.0/20 staging=10.10.8.0/21 dev=10.158.0.0/20; echo "exit $?"'

net
block create
run 'gcloud compute networks create planner --subnet-mode=custom --bgp-routing-mode=global'
