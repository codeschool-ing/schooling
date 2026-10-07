#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of cloud, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson, all of them in the section "the-seam", was copied from running it.
#
#   bash captures.sh            # from anywhere; prices.py is read out of lesson 1
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE. prices.py reads the AWS public price
# list, which AWS publishes as JSON with no account and no key, at the offer
# versions pinned inside it; the files are cached in ~/.cache/cloud-prices after
# the first run. The curl below fetches ONE of those same pinned files, the
# data-transfer offer for sa-east-1 (about 1.5 MB), to show how its tiers are
# written. egress.py is the lesson's own arithmetic on four lines of the sheet.
# Nothing here is a bill and nothing here reaches an account.
#
# What is STAGED rather than typed, and not shown in the lesson: a scratch
# directory standing in for ~/cloud, holding a copy of prices.py and the
# egress.py that the section shows in full; and the price cache, already filled
# by an earlier run of prices.py.
#
# Recorded 2026-09-28 on Ubuntu 24.04, Python 3.11, jq 1.7, no cloud account and
# no credentials, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
COURSE=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
. "$(cd "$(dirname "$0")/../.." && pwd)/from-lessons.sh"   # prices_py: the program as lesson 1 prints it
prices_py "$W" || exit 1
cat > "$W/egress.py" <<'PY'
import sys

# sa-east-1, out to the internet, USD per GB, from `prices.py transfer`
TIERS = [
    (10 * 1024, 0.150),    # first 10 TB
    (40 * 1024, 0.138),    # next 40 TB
    (100 * 1024, 0.126),   # next 100 TB
    (None, 0.114),         # over 150 TB
]
tb = float(sys.argv[1])
left = tb * 1024           # the tiers are written in GB, 1,024 to a TB
total = 0.0
for size, price in TIERS:
    gb = left if size is None else min(left, size)
    if gb <= 0:
        break
    cost = gb * price
    print(f'{gb:>9,.0f} GB x {price:.3f} = {cost:>10,.2f}')
    total += cost
    left -= gb
print(f'{"total":>20} = {total:>10,.2f} USD')
PY
cd "$W" || exit 1
# what ana typed at her prompt, and everything it printed
run() { printf 'ana@laptop:~/cloud$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

block transfer
run 'python3 prices.py transfer'

block tiers
run 'curl -s -o dt.json https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSDataTransfer/20260916132208/sa-east-1/index.json'
run "jq -r '(.products[] | select(.attributes.usagetype == \"SAE1-DataTransfer-Out-Bytes\") | .sku) as \$s | [.terms.OnDemand[\$s][].priceDimensions[]] | sort_by(.beginRange | tonumber)[] | [.beginRange, .endRange, .description] | join(\"  \")' dt.json"

block egress
run 'python3 egress.py 50'
run 'python3 egress.py 200'
