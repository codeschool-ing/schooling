#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# trace.py and waterfall.py are read out of the lesson. There are no services:
# trace.py writes the segments two services would write, with fixed durations,
# and sends them to moto's X-Ray.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf traces && mkdir traces && cd traces || exit 1
moto_up
student_env
from_lesson "$HERE/../le-a4hvmgna/prices.md" price.py > price.py
from_lesson "$HERE/segments.md" trace.py > trace.py
from_lesson "$HERE/segments.md" waterfall.py > waterfall.py

block send
run 'TRACE=$(python3 trace.py); echo "$TRACE"'
TRACE=$(aws xray get-trace-summaries --start-time $(date -d '-5 min' +%s) --end-time $(date -d '+1 min' +%s) --query 'TraceSummaries[0].Id' --output text)
block summaries
run "aws xray get-trace-summaries --start-time \$(date -d '-5 min' +%s) --end-time \$(date -d '+1 min' +%s) --query 'TraceSummaries[].[Id,Duration,ResponseTime]' --output text"
block waterfall
run "python3 waterfall.py $TRACE"
block sampling
run 'aws xray get-sampling-rules 2>&1 | grep -m1 ERROR'
block price
run 'python3 price.py AWSXRay TracesStored'
