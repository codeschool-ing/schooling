---
title: Keeping it, and alerting on it
version: 1
---

**Azure keeps the activity log for 90 days, viewable in the portal and by the command line, and then it is
gone.** An investigation into something that started four months ago, or an auditor asking about last
year, needs it kept elsewhere. A **diagnostic setting at the subscription** sends it to the workspace,
where it becomes the `AzureActivity` table this course has been querying, kept as long as the table's
retention says, which lesson 9 set to a year of long-term retention for exactly this table:

```bicep
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
```

It is a diagnostic setting like lesson 8's, with `targetScope = 'subscription'` because the activity log
belongs to the subscription, not to a resource. The categories chosen are the ones the shop reads:
`Administrative` is every write, delete and action; `Security`, `Policy` and `ServiceHealth` add Defender's
alerts, policy evaluations and Azure's own incidents.

**An activity log alert** fires on a matching record within minutes, with no query and no workspace,
which makes it the cheapest alert there is. The shop has one on every role assignment written in the
subscription:

```bicep
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
```

```
ana@laptop:~/azure/activity$ bicep build export.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/activity$ bicep build role-alert.bicep; echo "exit status $?"
exit status 0
```

Neither file was deployed. Role assignments are rare in a healthy subscription, so an alert on each one is
not noise: it is a second person seeing every change to who can do what, the same day. The shop adds two
more of the same shape, on deleting a Key Vault and on deleting a resource lock, the protections of lessons
17 and 7, because those are the changes an attacker makes first.
