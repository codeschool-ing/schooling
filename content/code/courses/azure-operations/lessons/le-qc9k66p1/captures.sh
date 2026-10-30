#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# AppRequests comes from lesson 9's requests.kql and AppDependencies from this
# lesson's dependencies.kql, both extracted from the lessons. Nothing here is
# Application Insights: the tables have its names and the columns this course
# uses, and live metrics, which need a running application, are not shown.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
kusto_up && kusto_db
kusto_load le-ch185v14/loading.md:requests.kql
cd "$HOME/azure/kusto" || exit 1

block load
from_lesson "$HERE/the-tables.md" dependencies.kql > dependencies.kql
run 'python3 kql.py < dependencies.kql | cut -c1-80'
kq 'AppDependencies | summarize calls = count(), failed = countif(not(Success)) by DependencyType, Target'

block one-request
put one-request.kql <<'KQL'
// one-request.kql: everything recorded for the first failed checkout of the incident
let op = toscalar(
    AppRequests
    | where Name == "POST /checkout" and not(Success) and DurationMs > 2000
    | top 1 by TimeGenerated asc
    | project OperationId);
union
    (AppRequests | where OperationId == op | extend Kind = "request", Target = "shop-api"),
    (AppDependencies | where OperationId == op | extend Kind = "dependency")
| project TimeGenerated, OperationId, Kind, Name, Target, ResultCode, DurationMs
KQL
run 'python3 kql.py < one-request.kql'

block cause
put cause.kql <<'KQL'
// cause.kql: what the failed requests' calls answered, during the incident
AppRequests
| where TimeGenerated between (datetime(2026-10-15 17:00) .. 1h) and not(Success)
| join kind=inner AppDependencies on OperationId
| summarize failed_requests = dcount(OperationId) by DependencyType, Target, DependencyResult = ResultCode1
KQL
run 'python3 kql.py < cause.kql'
kq 'AppDependencies | where DependencyType == "SQL" | summarize calls = count(), failed = countif(not(Success)), p95 = round(percentile(DurationMs, 95)) by bin(TimeGenerated, 1d)'

block sampling
put sampled.kql <<'KQL'
// sampled.kql: the same week as a 25% sample would have stored it
.set-or-replace SampledRequests <|
AppRequests
| where abs(hash(OperationId, 4)) == 0
| extend ItemCount = 4
KQL
run 'python3 kql.py < sampled.kql | cut -c1-80'
kq 'SampledRequests | summarize rows = count(), requests = sum(ItemCount), failed_rows = countif(not(Success)), failed = sumif(ItemCount, not(Success))'
kq 'AppRequests | summarize rows = count(), requests = sum(ItemCount), failed_rows = countif(not(Success)), failed = sumif(ItemCount, not(Success))'
lab_down
