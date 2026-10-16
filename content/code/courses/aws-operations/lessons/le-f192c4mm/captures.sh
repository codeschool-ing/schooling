#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# hour.py and burn.py are read out of the lesson. The traffic is synthetic: a
# fixed thousand requests a minute, with errors in the minutes hour.py names.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf slo && mkdir slo && cd slo || exit 1
moto_up
student_env
from_lesson "$HERE/burn-rate.md" hour.py > hour.py
from_lesson "$HERE/burn-rate.md" burn.py > burn.py

block ongoing
run 'python3 hour.py ongoing'
run 'python3 burn.py ongoing'
block recovered
run 'python3 hour.py recovered'
run 'python3 burn.py recovered'

put math.json <<'EOF2'
[
  {"Id": "errors", "MetricStat": {"Metric": {"Namespace": "Shop", "MetricName": "Errors", "Dimensions": [{"Name": "Service", "Value": "ongoing"}]}, "Period": 300, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "requests", "MetricStat": {"Metric": {"Namespace": "Shop", "MetricName": "Requests", "Dimensions": [{"Name": "Service", "Value": "ongoing"}]}, "Period": 300, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "sli", "Expression": "100 * (1 - errors / requests)", "Label": "availability, %"}
]
EOF2
block math
run "aws cloudwatch get-metric-data --metric-data-queries file://math.json --start-time \$(date -u -d '-30 min' +%FT%TZ) --end-time \$(date -u +%FT%TZ) --query 'MetricDataResults[].[Id,Label,length(Values)]' --output text"
