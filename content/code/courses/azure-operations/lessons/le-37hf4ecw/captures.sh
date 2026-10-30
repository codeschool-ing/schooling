#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# AzureActivity and IncidentLog are written by the course, as the lesson says:
# eleven changes in the shape of the activity log, and eight lines of an
# incident channel. The callers are documentation names and addresses
# (example.com, 198.51.100.0/24, 203.0.113.0/24) and an invented application id. AppRequests is lesson 9's generated week.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
kusto_up && kusto_db
kusto_load le-ch185v14/loading.md:requests.kql le-37hf4ecw/timeline.md:activity.kql le-37hf4ecw/timeline.md:incident-log.kql
cd "$HOME/azure/kusto" || exit 1

put measures.kql <<'KQL'
// measures.kql: when it started, when somebody knew, when it stopped
let started = toscalar(AppRequests | where Name == "POST /checkout" and not(Success) and DurationMs > 2000 | summarize min(TimeGenerated));
let ended = toscalar(AppRequests | where Name == "POST /checkout" and not(Success) and DurationMs > 2000 | summarize max(TimeGenerated));
let paged = toscalar(IncidentLog | where Who == "pager" | summarize min(TimeGenerated));
let fixed = toscalar(IncidentLog | where What startswith "scaled" | summarize min(TimeGenerated));
print to_detect = paged - started, to_mitigate = fixed - started, customers_affected_for = ended - started
KQL
block measures
run 'python3 kql.py < measures.kql'

put timeline.kql <<'KQL'
// timeline.kql: three sources, one clock, in São Paulo time
let since = datetime(2026-10-15 16:30);
let until = datetime(2026-10-15 18:30);
union
    (AzureActivity | where TimeGenerated between (since .. until)
        | project TimeGenerated, Source = "activity", Event = strcat(Caller, " ", OperationNameValue, " ", ActivityStatusValue, " ", tostring(Properties.sku))),
    (AppRequests | where Name == "POST /checkout" and TimeGenerated between (since .. until)
        | summarize failed = countif(not(Success)) by TimeGenerated = bin(TimeGenerated, 10m)
        | where failed > 0
        | project TimeGenerated, Source = "requests", Event = strcat(failed, " checkouts failed in 10 minutes")),
    (IncidentLog | project TimeGenerated, Source = "channel", Event = strcat(Who, ": ", What))
| project Local = format_datetime(datetime_utc_to_local(TimeGenerated, "America/Sao_Paulo"), "HH:mm"), Source, Event
| order by Local asc
KQL
block timeline
run 'python3 kql.py < timeline.kql'
lab_down
