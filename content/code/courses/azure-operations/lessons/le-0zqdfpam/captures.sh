#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# AzureActivity is lesson 15's activity.kql, eleven changes written by the
# course. The Bicep is compiled and never deployed.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
kusto_up && kusto_db
kusto_load le-37hf4ecw/timeline.md:activity.kql
cd "$HOME/azure/kusto" || exit 1

block one
kq 'AzureActivity | where Resource == "sttestana01"'

block who
kq 'AzureActivity | where OperationNameValue endswith "/DELETE" | project TimeGenerated, Caller, CallerIpAddress, ResourceGroup, Resource'
kq 'AzureActivity | where Resource startswith "sql-shop" | project TimeGenerated, Caller, ActivityStatusValue, sku = tostring(Properties.sku), before = tostring(Properties.previousSku)'

block by-caller
kq 'AzureActivity | summarize changes = count(), failed = countif(ActivityStatusValue == "Failure"), operations = make_set(tostring(split(OperationNameValue, "/")[-1])) by Caller | order by changes desc'

block access
kq 'AzureActivity | where OperationNameValue startswith "MICROSOFT.AUTHORIZATION/" | project TimeGenerated, Caller, OperationNameValue, Properties'

cd "$HOME/azure" && mkdir -p activity && cd activity || exit 1
put export.bicep <<'BICEP'
// export.bicep
targetScope = 'subscription'

param workspaceId string

resource toWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'activity-to-log-shop'
  properties: {
    workspaceId: workspaceId
    logs: [
      { category: 'Administrative', enabled: true }
      { category: 'Security', enabled: true }
      { category: 'Policy', enabled: true }
      { category: 'ServiceHealth', enabled: true }
    ]
  }
}
BICEP

put role-alert.bicep <<'BICEP'
// role-alert.bicep
param actionGroupId string

resource roleChanges 'Microsoft.Insights/activityLogAlerts@2023-01-01-preview' = {
  name: 'role-assignment-written'
  location: 'Global'
  properties: {
    enabled: true
    scopes: [ subscription().id ]
    condition: {
      allOf: [
        { field: 'category', equals: 'Administrative' }
        { field: 'operationName', equals: 'Microsoft.Authorization/roleAssignments/write' }
        { field: 'status', equals: 'Succeeded' }
      ]
    }
    actions: {
      actionGroups: [ { actionGroupId: actionGroupId } ]
    }
  }
}
BICEP

block bicep
run 'bicep build export.bicep; echo "exit status $?"'
run 'bicep build role-alert.bicep; echo "exit status $?"'
lab_down
