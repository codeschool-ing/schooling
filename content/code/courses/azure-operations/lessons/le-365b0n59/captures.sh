#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# The Bicep is compiled and never deployed: no alert fires, no e-mail is sent.
# What a log search alert would have decided is computed by running its own
# query over five-minute windows in the Kusto emulator, against lesson 9's week.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
rm -rf "$HOME/azure/alerts" && mkdir -p "$HOME/azure/alerts" && cd "$HOME/azure/alerts" || exit 1

put checkout-alert.bicep <<'BICEP'
// checkout-alert.bicep
param workspaceId string
param actionGroupId string

resource checkoutFailing 'Microsoft.Insights/scheduledQueryRules@2023-12-01' = {
  name: 'checkout-failing'
  location: 'brazilsouth'
  properties: {
    displayName: 'Checkout failing'
    severity: 1
    enabled: true
    scopes: [ workspaceId ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
            AppRequests
            | where Name == "POST /checkout"
            | summarize total = count(), failed = countif(not(Success))
            | extend failed_pct = 100.0 * failed / total
            | where total >= 10 and failed_pct > 5
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [ actionGroupId ]
    }
  }
}
BICEP

block alert-build
run 'bicep build checkout-alert.bicep; echo "exit status $?"'
run "jq -r '.resources[0].properties | [.evaluationFrequency, .windowSize, (.severity|tostring)] | @tsv' checkout-alert.json"

put action-group.bicep <<'BICEP'
// action-group.bicep
resource onCall 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-shop-oncall'
  location: 'Global'
  properties: {
    groupShortName: 'shoponcall'
    enabled: true
    emailReceivers: [
      { name: 'on-call', emailAddress: 'oncall@example.com', useCommonAlertSchema: true }
    ]
    webhookReceivers: [
      { name: 'chat', serviceUri: 'https://chat.example.com/hooks/shop', useCommonAlertSchema: true }
    ]
  }
}
BICEP

block ag-build
run 'bicep build action-group.bicep; echo "exit status $?"'

put maintenance.bicep <<'BICEP'
// maintenance.bicep
resource quietDuringMaintenance 'Microsoft.AlertsManagement/actionRules@2021-08-08' = {
  name: 'quiet-during-db-maintenance'
  location: 'Global'
  properties: {
    enabled: true
    scopes: [ resourceGroup().id ]
    actions: [
      { actionType: 'RemoveAllActionGroups' }
    ]
    schedule: {
      timeZone: 'E. South America Standard Time'
      effectiveFrom: '2026-10-25T02:00:00'
      effectiveUntil: '2026-10-25T04:00:00'
    }
    description: 'Planned SQL maintenance: alerts still fire and are recorded; nobody is paged.'
  }
}
BICEP

block apr-build
run 'bicep build maintenance.bicep; echo "exit status $?"'

# ---- what the rule would have decided ---------------------------------------
kusto_up && kusto_db
kusto_load le-ch185v14/loading.md:requests.kql
cd "$HOME/azure/kusto" || exit 1
put evaluate.kql <<'KQL'
// evaluate.kql: checkout-failing's query, run over each five-minute window of Thursday afternoon
AppRequests
| where Name == "POST /checkout"
| where TimeGenerated between (datetime(2026-10-15 16:50) .. datetime(2026-10-15 18:00))
| summarize total = count(), failed = countif(not(Success)) by window_end = bin(TimeGenerated, 5m) + 5m
| extend failed_pct = round(100.0 * failed / total, 1)
| extend fires = total >= 10 and failed_pct > 5
| order by window_end asc
KQL
block evaluate
run 'python3 kql.py < evaluate.kql'
lab_down
