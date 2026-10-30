#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: public.bicep from
# the ```bicep fence of "public-zones" and private.bicep from the one of
# "private-zones".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/dns is removed before the run.
#
# ONE COMMAND REACHES THE INTERNET: `dig portal.azure.com` asks the public
# DNS. The chain is chosen by Traffic Manager and Front Door at the moment of
# asking, so the block `dig-portal` is expected to differ between runs; the
# prose quotes only the kinds of link (trafficmanager.net, azurefd.net), not
# the hosts or the address.
#
# NOT PRODUCED HERE, and said so in the prose: `dig NS` and `dig SOA`, which
# the recording machine's resolver leaves unanswered; any zone, delegation or
# private resolution, which need Azure.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/dns

. <(sh_fences "$HERE/reading-answers.md" 1)
at '~/azure/dns'
block dig-portal
run 'dig portal.azure.com +noall +answer +nottlid'

put bicep "$HERE/public-zones.md" 1 public.bicep
block public
run 'az bicep build --file public.bicep --stdout | jq -c '"'"'(.resources[] | {type, name}), .outputs'"'"''

put bicep "$HERE/private-zones.md" 1 private.bicep
block private
run 'az bicep build --file private.bicep --stdout | jq -c '"'"'.resources[] | {type, name, registration: .properties.registrationEnabled}'"'"''
