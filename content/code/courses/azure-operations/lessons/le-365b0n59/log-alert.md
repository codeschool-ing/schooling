---
title: A log search alert, and evaluating it yourself
version: 1
---

The shop's first rule fires when checkout is failing: more than 5% of checkouts in five minutes, as long
as there were at least ten, so that one failure among three requests at night does not page anybody.

```bicep
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
```

The query is ordinary KQL inside a `'''` multi-line string. It returns a row only when the condition
holds, and the rule's own condition is *more than 0 rows*. Writing it that way keeps the decision in the
query, where it can be read and tested, rather than split between the query and the rule's settings.

```
ana@laptop:~/azure/alerts$ bicep build checkout-alert.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/alerts$ jq -r '.resources[0].properties | [.evaluationFrequency, .windowSize, (.severity|tostring)] | @tsv' checkout-alert.json
PT5M	PT5M	1
```

It compiled; it was not deployed, and nothing will fire. But the question that matters, **would it have
fired on Thursday, and when**, can be answered exactly, because the rule is only its query run every five
minutes over the previous five. Run that query over each five-minute window of Thursday afternoon, in the
emulator, from `~/azure/kusto`:

```kql
// evaluate.kql: checkout-failing's query, run over each five-minute window of Thursday afternoon
AppRequests
| where Name == "POST /checkout"
| where TimeGenerated between (datetime(2026-10-15 16:50) .. datetime(2026-10-15 18:00))
| summarize total = count(), failed = countif(not(Success)) by window_end = bin(TimeGenerated, 5m) + 5m
| extend failed_pct = round(100.0 * failed / total, 1)
| extend fires = total >= 10 and failed_pct > 5
| order by window_end asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < evaluate.kql
window_end            total  failed  failed_pct  fires
2026-10-15T16:55:00Z  13     0       0.0         False
2026-10-15T17:00:00Z  10     0       0.0         False
2026-10-15T17:05:00Z  24     0       0.0         False
2026-10-15T17:10:00Z  13     9       69.2        True
2026-10-15T17:15:00Z  22     18      81.8        True
2026-10-15T17:20:00Z  19     14      73.7        True
2026-10-15T17:25:00Z  22     9       40.9        True
2026-10-15T17:30:00Z  16     11      68.8        True
2026-10-15T17:35:00Z  21     19      90.5        True
2026-10-15T17:40:00Z  15     9       60.0        True
2026-10-15T17:45:00Z  16     11      68.8        True
2026-10-15T17:50:00Z  18     3       16.7        True
2026-10-15T17:55:00Z  17     0       0.0         False
2026-10-15T18:00:00Z  17     0       0.0         False
```

The incident started at 17:05:12. **The evaluation that ended at 17:10 is the first to say yes**, with 9
of 13 checkouts failed, and the rule fires there: 14:10 in São Paulo. It stays fired, because
`autoMitigate` makes it stateful, until the evaluation ending at 17:55 comes back no, and then it resolves
on its own. One alert, one resolution, for a forty-minute incident.

Two things the emulator cannot show. In a workspace, logs take a few minutes to arrive, so the real rule
sees each window late, and a real alert fires a few minutes after this table says. And the evaluation at
17:25 is a reminder of why the threshold is low: 9 failures in 22 was still 41%, well over 5%, and a
threshold at 50% would have resolved the alert in the middle of the incident and fired it again five
minutes later.
