#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# The emulator, kql.py and requests.kql come from lesson 9's own blocks. Every
# query below is the one the lesson prints, run against that generated week.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
kusto_up && kusto_db
kusto_load le-ch185v14/loading.md:requests.kql
cd "$HOME/azure/kusto" || exit 1

block first
kq 'AppRequests | where Success == false | take 3'
kq 'AppRequests | where Sucess == false | take 3'
kq 'AppRequests | getschema | project ColumnName, ColumnType'

block filter
kq 'AppRequests | where TimeGenerated between (datetime(2026-10-15 17:00) .. 1h) and Name == "POST /checkout" and not(Success) | top 4 by TimeGenerated asc | project TimeGenerated, ResultCode, DurationMs'

block local
kq 'AppRequests | where Name == "POST /checkout" and not(Success) and DurationMs > 2000 | summarize started = min(TimeGenerated), ended = max(TimeGenerated), failures = count() | extend started_local = datetime_utc_to_local(started, "America/Sao_Paulo")'

block by-route
put thursday.kql <<'KQL'
// thursday.kql: how each route did on Thursday, in São Paulo's day
AppRequests
| where TimeGenerated between (datetime(2026-10-15 03:00) .. 1d)
| summarize requests = count(), failed = countif(not(Success)) by Name
| extend failed_pct = round(100.0 * failed / requests, 2)
| order by failed desc
KQL
run 'python3 kql.py < thursday.kql'

block percentiles
kq 'AppRequests | summarize avg = round(avg(DurationMs), 1), p50 = round(percentile(DurationMs, 50)), p95 = round(percentile(DurationMs, 95)), p99 = round(percentile(DurationMs, 99)) by Name'

block bins
put window.kql <<'KQL'
// window.kql: checkout, five minutes at a time, around Thursday afternoon
AppRequests
| where Name == "POST /checkout"
| where TimeGenerated between (datetime(2026-10-15 16:50) .. datetime(2026-10-15 18:00))
| summarize requests = count(), failed = countif(not(Success)), p95 = percentile(DurationMs, 95)
    by bin(TimeGenerated, 10m)
| order by TimeGenerated asc
KQL
run 'python3 kql.py < window.kql'

block join
put owners.kql <<'KQL'
// owners.kql: which team answers for each route's failures this week
let owners = datatable(Name: string, Team: string) [
    "GET /products", "catalogue",
    "GET /cart", "basket",
    "POST /cart", "basket",
    "POST /checkout", "payments"
];
AppRequests
| where not(Success)
| summarize failed = count() by Name
| join kind=leftouter owners on Name
| project Team, Name, failed
| order by failed desc
KQL
run 'python3 kql.py < owners.kql'

block parse
kq 'AppRequests | parse Name with Method " " Path | summarize requests = count() by Method'
lab_down
