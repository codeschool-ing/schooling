#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). routes.json
# is read out of the ```json fence of "routes" and route.py out of its example,
# into a fresh ~/gcp/routes; nat.tf out of the ```hcl fence of "cloud-nat" into
# ~/gcp/nat; subnet.tf out of the ```hcl fence of "private-google-access" into
# ~/gcp/pga. The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing. The
# routes are data a program applies Google's documented order to; the prose
# says no network is involved.
#
# REACHES THE INTERNET: one block, `names`, which asks the machine's resolver
# for two of Google's names. The answers are public DNS, sorted, because the
# resolver hands the four addresses of each name out in rotating order.
#
# NOT PRODUCED HERE, and said so in the prose: any route, router, NAT or
# subnet, and any packet.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

rm -rf ~/gcp/routes && mkdir -p ~/gcp/routes && cd ~/gcp/routes || exit 1
at '~/gcp/routes'
fences json "$HERE/routes.md" 1 > routes.json || exit 1
example "$HERE/routes.md" route.py > route.py || exit 1
block pick
run 'python3 route.py 10.11.3.4 8.8.8.8 199.36.153.9 192.168.4.20'
block noway
run "jq 'map(select(.name != \"default-route\"))' routes.json > r.json && mv r.json routes.json"
run 'python3 route.py 8.8.8.8 199.36.153.9'

tf_dir nat
tf_file "$HERE/cloud-nat.md" 1 nat.tf
block nat
run 'terraform plan -input=false -no-color | grep -E "^Plan|# google|min_ports|nat_ip_allocate|dest_range|next_hop_gateway|enable_endpoint|udp_idle|tcp_established"'

cd ~/gcp && at '~/gcp'
block names
run 'getent hosts private.googleapis.com restricted.googleapis.com | sort'

tf_dir pga
tf_file "$HERE/private-google-access.md" 1 subnet.tf
block pga
run 'terraform plan -input=false -no-color | grep -E "^Plan|private_ip_google_access"'
