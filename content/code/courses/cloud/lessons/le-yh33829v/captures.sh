#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of cloud, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   bash captures.sh            # from anywhere; it finds prices.py beside course.json
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE, AND LAMBDA IS NOT INVOLVED ANYWHERE
# BELOW. The handler of the section "a-function" is called as an ordinary Python
# function, on a laptop, with an event written by hand: that shows the contract
# between the platform and your code, not the platform. The bill and the
# crossover are arithmetic on lines of the AWS public price list, which prices.py
# reads at the offer versions pinned inside it (from ~/.cache/cloud-prices, filled
# by an earlier run). Nothing here is a bill.
#
# What is STAGED rather than typed, and not shown in the lesson: a scratch
# directory holding a copy of prices.py and the four small programs the lesson
# prints (handler.py, call_local.py, bill.py, crossover.py), written by this
# script exactly as the lesson shows them. The prompt shows that directory as
# ~/cloud, which is where a student would keep the files.
#
# Recorded 2026-09-28 on Ubuntu 24.04, Python 3.11, no cloud account and no
# credentials, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
COURSE=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp "$COURSE/prices.py" "$WORK/"
cd "$WORK" || exit 1
# what ana typed at her prompt, and everything it printed
run() { printf 'ana@laptop:~/cloud$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

cat > handler.py <<'PY'
import json

GREETING = "hello"
served = 0


def handler(event, context):
    global served
    served += 1
    params = event.get("queryStringParameters") or {}
    name = params.get("name", "world")
    body = {"message": f"{GREETING}, {name}", "served_by_this_copy": served}
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
PY

cat > call_local.py <<'PY'
from handler import handler

event = {
    "rawPath": "/hello",
    "queryStringParameters": {"name": "ana"},
    "requestContext": {"http": {"method": "GET"}},
}
print(handler(event, None))
print(handler({"rawPath": "/hello"}, None))
PY

cat > bill.py <<'PY'
# Lambda, x86, from `python3 prices.py lambda`: the same in both regions.
PER_MILLION_REQUESTS = 0.20
PER_GB_SECOND = 0.0000166667
FREE_REQUESTS = 1_000_000
FREE_GB_SECONDS = 400_000

requests = 3_000_000          # a month
memory_gb = 512 / 1024        # 512 MB
seconds = 0.120               # average billed duration

gb_seconds = requests * memory_gb * seconds
req_cost = requests / 1_000_000 * PER_MILLION_REQUESTS
gbs_cost = gb_seconds * PER_GB_SECOND
print(f"GB-seconds          {gb_seconds:>12,.0f}")
print(f"requests            {req_cost:>12.2f} USD")
print(f"GB-seconds          {gbs_cost:>12.2f} USD")
print(f"total, no free tier {req_cost + gbs_cost:>12.2f} USD")

req_left = max(0, requests - FREE_REQUESTS)
gbs_left = max(0, gb_seconds - FREE_GB_SECONDS)
free_total = req_left / 1_000_000 * PER_MILLION_REQUESTS + gbs_left * PER_GB_SECOND
print(f"total, free tier    {free_total:>12.2f} USD")
PY

cat > crossover.py <<'PY'
# us-east-1, from `python3 prices.py`: on demand, USD per hour.
T3_MEDIUM = 0.04160
ALB = 0.0225
HOURS = 730                   # a month, as AWS counts one

# One million requests at 512 MB and 120 ms, as in bill.py, no free tier.
per_million = 0.20 + 1_000_000 * (512 / 1024) * 0.120 * 0.0000166667

for label, month in [("one t3.medium", T3_MEDIUM * HOURS),
                     ("two t3.medium + ALB", (2 * T3_MEDIUM + ALB) * HOURS)]:
    crossover = month / per_million
    per_second = crossover * 1_000_000 / (HOURS * 3600)
    print(f"{label:<20} {month:7.2f} USD a month   "
          f"break-even {crossover:5.1f} million requests ({per_second:4.1f} a second)")
print(f"Lambda, per million  {per_million:7.2f} USD")
PY

block local
run 'python3 call_local.py'

block lambda
run 'python3 prices.py lambda'

block bill
run 'python3 bill.py'

block crossover
run 'python3 crossover.py'
