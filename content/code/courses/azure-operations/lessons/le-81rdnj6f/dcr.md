---
title: Data collection rules, and filtering before you pay
version: 1
---

**A data collection rule tells the Azure Monitor Agent what to collect, and where to send it.** The shop
runs two worker VMs for its order exports. Their CPU and memory counters, and the warnings and worse from
their system log, are collected by one rule:

```bicep
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
```

It has the three parts every rule has. **`dataSources`** says what to read: two performance counters
every 60 seconds, and syslog messages from two facilities at `Warning` and above, which already leaves out
the `Info` and `Debug` chatter. **`destinations`** names the workspace. **`dataFlows`** connects a stream
of data to a destination, and is where the interesting line is:

```
ana@laptop:~/azure/monitor$ bicep build dcr.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/monitor$ jq '.resources[0].properties.dataFlows' dcr.json
[
  {
    "streams": [
      "Microsoft-Perf"
    ],
    "destinations": [
      "shop"
    ]
  },
  {
    "streams": [
      "Microsoft-Syslog"
    ],
    "destinations": [
      "shop"
    ],
    "transformKql": "source | where SyslogMessage !has \"healthz\" | project-away HostIP"
  }
]
```

**`transformKql` is a KQL query that runs on every record as it arrives, before it is stored.**
`source` is the incoming stream. This one drops messages about health-check requests, which arrive every
few seconds and say nothing, and removes the `HostIP` column, which the shop has no use for. Rows a
transformation drops are not ingested and not billed; Microsoft's documentation also describes a
processing charge where a transformation filters out a large share of the data, and that is worth
checking on the price page before relying on it as free. The other use is privacy: a column with an
e-mail address in it can be removed or masked here, before it is ever written.

A rule does nothing until it is **associated** with machines, with a resource of type
`dataCollectionRuleAssociations` on each VM, and the agent has to be installed on them. Neither was done
here, because there are no VMs; the file was compiled and checked, and the KQL inside it is the language
of the next two lessons.
