#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of cloud, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson, and the output under the program in "speed-of-light", was copied
# from running it, so the next person can run it and see what moved.
#
#   bash captures.sh            # from anywhere; prices.py is read out of lesson 1
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE, and nothing here was measured on a
# network. Three things are read, all published with no account and no key:
#   - prices.py, the AWS public price list at the offer versions pinned inside
#     it, from the cache in ~/.cache/cloud-prices;
#   - ip-ranges.json, the address ranges AWS publishes for firewall rules,
#     downloaded fresh by the curl below. It changes several times a week, so a
#     second run prints a different createDate and slightly different counts;
#   - partitions.json, the list of regions that ships INSIDE the AWS CLI v2
#     install (aws-cli/2.37.4), under dist/awscli/botocore/data/. The CLI was
#     run with no credentials and made no call to AWS.
# floor.py is arithmetic on coordinates written into it; it sends no packet.
#
# What is STAGED rather than typed, and not shown in the lesson: the price
# cache, already filled; a working directory shown as ~/cloud, holding prices.py
# and a copy of the CLI's partitions.json; and floor.py, written by the heredoc
# below and shown in the lesson as an annotated example.
#
# Recorded 2026-09-28 on Ubuntu 24.04, Python 3.11, jq 1.7, no cloud account
# and no credentials, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "$0")" && pwd)
COURSE=$(cd "$HERE/../.." && pwd)
AWSBIN=${AWSBIN:-/tmp/claude-0/-home-user-schooling/38751d58-75f6-5497-bf91-568c8cabc4c1/scratchpad/bin}
PARTITIONS_SRC=$(dirname "$(readlink -f "$AWSBIN/aws")")/../dist/awscli/botocore/data/partitions.json

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
. "$(cd "$(dirname "$0")/../.." && pwd)/from-lessons.sh"   # prices_py: the program as lesson 1 prints it
prices_py "$WORK" || exit 1
cp "$PARTITIONS_SRC" "$WORK/partitions.json"
cd "$WORK" || exit 1

# what ana typed at her prompt, and everything it printed
run() { printf 'ana@laptop:~/cloud$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
# The CLI is shown as ana typed it and run with NOTHING of the environment:
# env -i and an empty HOME, so no credentials and no configuration can reach it.
runaws() {
  printf 'ana@laptop:~/cloud$ aws %s\n' "$*"
  env -i HOME="$(mktemp -d)" PATH="$AWSBIN:/usr/bin:/bin" aws "$@" 2>&1 || true
}

block region-price
run "python3 prices.py ec2 | sed -n '1,17p'"

block transfer
run 'python3 prices.py transfer'

block ranges
run 'curl -s https://ip-ranges.amazonaws.com/ip-ranges.json -o ip-ranges.json'
run "jq '.prefixes[0]' ip-ranges.json"
run "jq -r '.createDate, (.prefixes | length), (.ipv6_prefixes | length)' ip-ranges.json"
run "jq '[.prefixes[].region] | unique | length' ip-ranges.json"
run "jq -r '[.prefixes[].region] | unique | .[] | select(startswith(\"sa-\"))' ip-ranges.json"

block unusual
run "jq -r '.prefixes[] | select(.region == \"GLOBAL\") | .service' ip-ranges.json | sort | uniq -c"
runaws --version
run "jq -r '.partitions[] | select(.id != \"aws\") | .id as \$p | .regions | to_entries[] | select(.key | test(\"global\") | not) | \"\\(\$p)  \\(.key)  \\(.value.description)\"' partitions.json | grep -v iso"
run "jq -rn --slurpfile a ip-ranges.json --slurpfile p partitions.json '([\$a[0].prefixes[].region] | unique) - [\$p[0].partitions[].regions | keys[]] | .[]'"
run "jq -r '.prefixes[] | select(.region == \"sa-west-1\") | .service' ip-ranges.json | sort | uniq -c"

block floor
cat > floor.py <<'PY'
from math import radians, sin, cos, asin, sqrt

EARTH_KM = 6371          # mean radius of the Earth
FIBRE_KM_PER_MS = 200    # light in glass: about two thirds of c

PLACES = {               # latitude, longitude in degrees
    'Sao Paulo': (-23.55, -46.63),
    'Fortaleza': (-3.72, -38.54),
    'Ashburn':   (39.04, -77.49),
    'Frankfurt': (50.11, 8.68),
}

def great_circle_km(a, b):
    lat1, lon1, lat2, lon2 = map(radians, (*a, *b))
    h = sin((lat2 - lat1) / 2) ** 2 + cos(lat1) * cos(lat2) * sin((lon2 - lon1) / 2) ** 2
    return 2 * EARTH_KM * asin(sqrt(h))

for dest in ('Fortaleza', 'Ashburn', 'Frankfurt'):
    km = great_circle_km(PLACES['Sao Paulo'], PLACES[dest])
    rtt_ms = 2 * km / FIBRE_KM_PER_MS
    print(f'Sao Paulo -> {dest:<10} {km:6.0f} km   round trip >= {rtt_ms:5.1f} ms')
PY
run 'python3 floor.py'
