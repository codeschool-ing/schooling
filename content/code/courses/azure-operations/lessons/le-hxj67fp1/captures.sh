#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# Every number in the lesson is computed here by the Kusto emulator, over
# lesson 9's generated week. The objective (99.5% of checkouts, over the week)
# is the course's choice for the shop, stated in the lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
kusto_up && kusto_db
kusto_load le-ch185v14/loading.md:requests.kql
cd "$HOME/azure/kusto" || exit 1

put sli.kql <<'KQL'
// sli.kql: two indicators for checkout, per day: availability and speed
AppRequests
| where Name == "POST /checkout"
| summarize valid = count(), available = countif(Success), fast = countif(Success and DurationMs <= 1000)
    by day = bin(datetime_utc_to_local(TimeGenerated, "America/Sao_Paulo"), 1d)
| extend availability = round(100.0 * available / valid, 2), speed = round(100.0 * fast / valid, 2)
| order by day asc
KQL
block sli
run 'python3 kql.py < sli.kql'

put budget.kql <<'KQL'
// budget.kql: the week's error budget for checkout availability, at an objective of 99.5%
let objective = 99.5;
AppRequests
| where Name == "POST /checkout"
| summarize valid = count(), bad = countif(not(Success))
| extend allowed = round(valid * (100.0 - objective) / 100, 0)
| extend spent_pct = round(100.0 * bad / allowed, 1), left = allowed - bad
KQL
block budget
run 'python3 kql.py < budget.kql'

put burn.kql <<'KQL'
// burn.kql: how fast checkout spent its budget, hour by hour on Thursday afternoon
let objective = 99.5;
AppRequests
| where Name == "POST /checkout"
| where TimeGenerated between (datetime(2026-10-15 15:00) .. datetime(2026-10-15 20:00))
| summarize valid = count(), bad = countif(not(Success)) by hour = bin(TimeGenerated, 1h)
| extend error_rate = round(100.0 * bad / valid, 2)
| extend burn_rate = round(error_rate / (100.0 - objective), 1)
| order by hour asc
KQL
block burn
run 'python3 kql.py < burn.kql'

put two-windows.kql <<'KQL'
// two-windows.kql: the page condition, evaluated every 5 minutes: both windows burning over 14.4
let objective = 99.5;
let checkout = AppRequests | where Name == "POST /checkout";
range evaluated from datetime(2026-10-15 17:00) to datetime(2026-10-15 19:00) step 5m
| extend k = 1
| join kind=inner (checkout | extend k = 1) on k
| where TimeGenerated > evaluated - 1h and TimeGenerated <= evaluated
| summarize long_rate = 100.0 * countif(not(Success)) / count(),
    short_rate = 100.0 * countif(not(Success) and TimeGenerated > evaluated - 5m) / max_of(countif(TimeGenerated > evaluated - 5m), 1)
    by evaluated
| extend long_burn = round(long_rate / (100.0 - objective), 1), short_burn = round(short_rate / (100.0 - objective), 1)
| extend page = long_burn > 14.4 and short_burn > 14.4
| project evaluated, long_burn, short_burn, page
| order by evaluated asc
KQL
block two-windows
run 'python3 kql.py < two-windows.kql'
lab_down
