#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# CostDaily is lesson 24's cost.kql, generated and declared so. The budget is
# compiled and never created. series_decompose_anomalies is the Kusto engine's
# own function, run by the emulator; Cost Management's anomaly alerts are not.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
mkdir -p "$HOME/azure/budget" && cd "$HOME/azure/budget" || exit 1

put budget.bicep <<'BICEP'
// budget.bicep
param actionGroupId string

resource monthly 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'rg-shop-monthly'
  properties: {
    category: 'Cost'
    amount: 1800
    timeGrain: 'Monthly'
    timePeriod: { startDate: '2026-11-01' }
    notifications: {
      actualOver80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [ 'finops@example.com' ]
        contactGroups: [ actionGroupId ]
      }
      forecastOver100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [ 'finops@example.com' ]
        contactGroups: [ actionGroupId ]
      }
    }
  }
}
BICEP

block budget
run 'bicep build budget.bicep; echo "exit status $?"'
run "jq -r '.resources[0].properties.notifications | to_entries[] | [.key, .value.thresholdType, (.value.threshold|tostring)] | @tsv' budget.json"

kusto_up && kusto_db
kusto_load le-bwn2ccbr/cost-export.md:cost.kql
cd "$HOME/azure/kusto" || exit 1

block daily
kq 'CostDaily | where Date >= datetime(2026-10-01) | summarize cost = round(sum(Cost), 2) by Date | order by Date asc'

put anomalies.kql <<'KQL'
// anomalies.kql: the daily total as a series, and the days the engine calls anomalous
CostDaily
| make-series cost = sum(Cost) default = 0 on Date from datetime(2026-08-20) to datetime(2026-10-19) step 1d
| extend (flag, score, expected) = series_decompose_anomalies(cost, 2.5)
| mv-expand Date to typeof(datetime), cost to typeof(real), flag to typeof(int), score to typeof(real), expected to typeof(real)
| where flag != 0
| project Date, cost = round(cost, 2), expected = round(expected, 2), score = round(score, 1)
KQL
block anomalies
run 'python3 kql.py < anomalies.kql'

put usual.kql <<'KQL'
// usual.kql: each day against the median of the fourteen days before it
let daily = CostDaily | summarize cost = sum(Cost) by Date;
daily
| extend k = 1
| join kind=inner (daily | project before = Date, earlier = cost | extend k = 1) on k
| where before between ((Date - 14d) .. (Date - 1d))
| summarize cost = take_any(cost), usual = percentile(earlier, 50) by Date
| extend ratio = round(cost / usual, 3)
| where Date >= datetime(2026-10-05)
| project Date, cost = round(cost, 2), usual = round(usual, 2), ratio, flag = ratio > 1.05
| order by Date asc
KQL
block usual
run 'python3 kql.py < usual.kql'

put which.kql <<'KQL'
// which.kql: the week before the jump against the week after, by meter
CostDaily
| where Date between (datetime(2026-10-02) .. datetime(2026-10-15))
| extend week = iff(Date < datetime(2026-10-09), "before", "after")
| summarize cost = sum(Cost) by MeterCategory, week
| evaluate pivot(week, sum(cost))
| extend change = round(after - before, 2), before = round(before, 2), after = round(after, 2)
| order by change desc
| take 3
KQL
block which
run 'python3 kql.py < which.kql'
lab_down
