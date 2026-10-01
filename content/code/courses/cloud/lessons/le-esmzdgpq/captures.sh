#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of cloud, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson, all of them in the section "reading-a-price-list", was copied
# from running it.
#
#   bash captures.sh            # from anywhere; it finds prices.py beside course.json
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE. Everything below reads the AWS public
# price list, which AWS publishes as JSON with no account and no key. The index
# is fetched live, so its count of offers and its publicationDate are readings
# of the day; the offer files are the versions pinned in prices.py. Nothing here
# is a bill, and nothing here was run against Azure, Google Cloud, DigitalOcean,
# Hetzner or Akamai: they publish their prices as web pages, not as a file this
# course could pin.
#
# What is STAGED rather than typed, and not shown in the lesson: the price cache
# in ~/.cache/cloud-prices, already filled by an earlier run of prices.py (the
# EC2 file for sa-east-1 alone is about 280 MB). The prompt shows the course
# directory as ~/cloud, which is where a student would keep prices.py.
#
# Recorded 2026-09-28 on Ubuntu 24.04, Python 3.11, curl and jq, no cloud
# account and no credentials, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")/../.." || exit 1
# what ana typed at her prompt, and everything it printed
run() { printf 'ana@laptop:~/cloud$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

IDX=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json
LAMBDA=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSLambda/20260919002359/sa-east-1/index.json

block index
run "curl -s $IDX | jq '.offers | length'"
run "curl -s $IDX | jq -r '.publicationDate'"
run "curl -s $IDX | jq -r '.offers | keys[]' | grep -E '^(AmazonEC2|AmazonS3|AWSLambda)\$'"
run "curl -s $IDX | jq '.offers.AWSLambda'"

block products
run "curl -s $LAMBDA | jq '.products | length'"
run "jq '.products | length' ~/.cache/cloud-prices/AmazonEC2-20260925174521-sa-east-1.json"

block ec2
run "python3 prices.py ec2 | sed -n '1,17p'"
run "python3 -c 'print(round(0.16065 / 0.10080, 2))'"

# The schooling-example in "reading-a-price-list": the program, written into a
# scratch directory exactly as the lesson prints it, and run. Its output is the
# example's "output".
block compare
T=$(mktemp -d)
cat > "$T/compare.py" <<'PY'
HOURS = 730  # 24 * 365 / 12

m7i_large = {  # USD per hour, Linux, on demand
    'sa-east-1': 0.16065,
    'us-east-1': 0.10080,
}

for region, hourly in m7i_large.items():
    print(f'{region}  {hourly * HOURS:7.2f} USD a month')

print(f'ratio      {m7i_large["sa-east-1"] / m7i_large["us-east-1"]:.2f}')
PY
( cd "$T" && run 'python3 compare.py' )
rm -rf "$T"
