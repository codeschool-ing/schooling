#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# Bicep only: the files are compiled and linted, never deployed. The resources
# they reference with `existing` (app-shop-api, log-shop, vm-shop-worker-1) do
# not exist anywhere; Bicep does not need them to, and the lesson says so.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
rm -rf "$HOME/azure/monitor" && mkdir -p "$HOME/azure/monitor" && cd "$HOME/azure/monitor" || exit 1

put diagnostics.bicep <<'BICEP'
// diagnostics.bicep
resource app 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'app-shop-api'
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: 'log-shop'
}

resource toWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-log-shop'
  scope: app
  properties: {
    workspaceId: workspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      { category: 'AppServiceHTTPLogs', enabled: true }
      { category: 'AppServiceConsoleLogs', enabled: true }
      { category: 'AppServiceAppLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}
BICEP

block diag
run 'bicep build diagnostics.bicep; echo "exit status $?"'
run "jq '.resources[0] | {type, scope, name}' diagnostics.json"

block diag-typo
run "sed 's/AppServiceHTTPLogs/AppServiceHttpLog/' diagnostics.bicep > typo.bicep && bicep build typo.bicep; echo \"exit status \$?\""

put dcr.bicep <<'BICEP'
// dcr.bicep
param workspaceId string

resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'dcr-shop-workers'
  location: 'brazilsouth'
  properties: {
    dataSources: {
      performanceCounters: [
        {
          name: 'cpu-and-memory'
          streams: [ 'Microsoft-Perf' ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\Processor Information(_Total)\\% Processor Time'
            '\\Memory\\Available Bytes'
          ]
        }
      ]
      syslog: [
        {
          name: 'system-log'
          streams: [ 'Microsoft-Syslog' ]
          facilityNames: [ 'daemon', 'syslog' ]
          logLevels: [ 'Warning', 'Error', 'Critical', 'Alert', 'Emergency' ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        { name: 'shop', workspaceResourceId: workspaceId }
      ]
    }
    dataFlows: [
      { streams: [ 'Microsoft-Perf' ], destinations: [ 'shop' ] }
      {
        streams: [ 'Microsoft-Syslog' ]
        destinations: [ 'shop' ]
        transformKql: 'source | where SyslogMessage !has "healthz" | project-away HostIP'
      }
    ]
  }
}
BICEP

block dcr
run 'bicep build dcr.bicep; echo "exit status $?"'
run "jq '.resources[0].properties.dataFlows' dcr.json"
