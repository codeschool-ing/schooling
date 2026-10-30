#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). vpn.tf is
# read out of the ```hcl fence of "ha-vpn" into a fresh ~/gcp/vpn; sla.py out
# of the example in "resilience-and-price". The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing. The
# shared secret is the word `placeholder-only`, and the prose says so.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: any gateway, tunnel, BGP
# session or Interconnect, and every price, which is read from the pricing
# pages.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

tf_dir vpn
tf_file "$HERE/ha-vpn.md" 1 vpn.tf
block novar
run 'terraform plan -input=false -no-color 2>&1 | tail -5'
block plan
run 'TF_VAR_shared_secret=placeholder-only terraform plan -input=false -no-color | grep -E "^Plan|# google|shared_secret|ip_range|peer_asn|asn "'
block asn
run "sed -i 's/asn = 64514/asn = 100/' vpn.tf"
run 'TF_VAR_shared_secret=placeholder-only terraform plan -input=false -no-color 2>&1 | grep -A1 "^Error"'

cd ~/gcp && at '~/gcp'
example "$HERE/resilience-and-price.md" sla.py > sla.py || exit 1
block sla
run 'python3 sla.py 99.9 0.05 99.99 0.10 99.9 4.856 99.99 9.712'
