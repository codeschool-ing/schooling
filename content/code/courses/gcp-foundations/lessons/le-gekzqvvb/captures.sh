#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), plus the two
# things the ```sh fence of "records" installs: dig and dnslib. If
# either is missing, that fence is run first, quietly, with `sudo` dropped
# when the script already runs as root. zones.tf is read out of the ```hcl
# fence of "zones" into a fresh ~/gcp/dns-zones, and googleapis.tf out of the
# two fences of "private-zones-and-forwarding"; the zone file and serve.py out
# of "records" into a fresh ~/gcp/dns. The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: the DNS
# server runs in the background with its output in a file, rather than in a
# second terminal; the block `serve` prints that file under the command that
# started it, which is what the second terminal shows. It answers from a zone
# file on 127.0.0.1:5353, and the prose says it is not Cloud DNS.
#
# REACHES THE INTERNET: one block, `public`, which asks the machine's resolver
# for storage.googleapis.com. The answer is public DNS, and the addresses in it
# change from run to run; no sentence of prose quotes them.
#
# NOT PRODUCED HERE, and said so in the prose: any managed zone or record set,
# delegation, DNSSEC, and the private answer from inside the planner network.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

if ! command -v dig > /dev/null || ! python3 -c 'import dnslib' 2> /dev/null; then
  { fences sh "$HERE/records.md" 1 | sed '/^mkdir/d'; } | { [ "$(id -u)" = 0 ] && sed 's/^sudo //' || cat; } \
    | bash > "$LAB_ROOT/install.log" 2>&1 || { cat "$LAB_ROOT/install.log"; exit 1; }
fi

tf_dir dns-zones
tf_file "$HERE/zones.md" 1 zones.tf
block zones
run 'terraform plan -input=false -no-color | grep -E "^Plan|# google|dns_name|name_servers|visibility|state"'

cd ~/gcp && at '~/gcp'
block import
run 'gcloud dns record-sets import --help | grep -A2 "zone-file-format$"'

rm -rf ~/gcp/dns && mkdir -p ~/gcp/dns && cd ~/gcp/dns || exit 1
at '~/gcp/dns'
fences ini "$HERE/records.md" 1 > planner.example.com.zone || exit 1
example "$HERE/records.md" serve.py > serve.py || exit 1
setsid python3 -u serve.py planner.example.com.zone > "$LAB_ROOT/dns.log" 2>&1 < /dev/null &
echo $! > "$LAB_ROOT/dns.pid"
for _ in $(seq 50); do grep -q answering "$LAB_ROOT/dns.log" && break; sleep 0.1; done
block serve
say 'ana@laptop:~/gcp/dns$ python3 serve.py planner.example.com.zone'
cat "$LAB_ROOT/dns.log"
block answers
run 'dig @127.0.0.1 -p 5353 +noall +answer planner.example.com A www.planner.example.com A planner.example.com MX planner.example.com TXT'
block nxdomain
run 'dig @127.0.0.1 -p 5353 nothing.planner.example.com A | grep -o "status: [A-Z]*"'
kill -- -"$(cat "$LAB_ROOT/dns.pid")" 2> /dev/null; rm -f "$LAB_ROOT/dns.pid"

cd ~/gcp/dns-zones && at '~/gcp/dns-zones'
{ fences hcl "$HERE/private-zones-and-forwarding.md" 1; echo; fences hcl "$HERE/private-zones-and-forwarding.md" 2; } > googleapis.tf || exit 1
block public
run 'getent hosts storage.googleapis.com | head -3'
block private
run 'terraform plan -input=false -no-color | grep -E "^Plan|# google|dns_name|ipv4_address"'
