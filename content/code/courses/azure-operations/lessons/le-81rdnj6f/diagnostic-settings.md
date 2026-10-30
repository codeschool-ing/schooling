---
title: A diagnostic setting, written down
version: 1
---

**A diagnostic setting is a resource of its own, attached to the resource whose logs it routes.** It
names the destination and the categories, and it is a resource like any other, so the shop declares it
in Bicep beside the app rather than clicking it into the portal, where the next person to look will not
know it exists:

```bicep
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
```

Read the shape. The app and the workspace are declared `existing`: this file does not create them, it
refers to them, and Bicep needs neither to exist to compile. **`scope: app`** is what attaches the setting
to the app; it becomes an extension resource of the site rather than a resource in the group:

```
ana@laptop:~/azure/monitor$ bicep build diagnostics.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/monitor$ jq '.resources[0] | {type, scope, name}' diagnostics.json
{
  "type": "Microsoft.Insights/diagnosticSettings",
  "scope": "[resourceId('Microsoft.Web/sites', 'app-shop-api')]",
  "name": "to-log-shop"
}
```

**The categories are the decision.** An App Service offers several: HTTP logs, console output, the
application's own logs, audit logs, platform logs. Each one routed is ingested and billed, and lesson 9
puts a price on that. The shop routes three, and `AllMetrics` as well, which copies platform metrics
into the workspace's `AzureMetrics` table, where they can be joined with logs.

**`logAnalyticsDestinationType: 'Dedicated'`** sends each category to a table of its own,
`AppServiceHTTPLogs`, `AppServiceConsoleLogs`, with typed columns. The alternative is the old shared
`AzureDiagnostics` table, where every resource type's columns pile up side by side; new settings should
be `Dedicated` wherever a resource supports it.

And the limit of compiling. A misspelt category compiles cleanly:

```
ana@laptop:~/azure/monitor$ sed 's/AppServiceHTTPLogs/AppServiceHttpLog/' diagnostics.bicep > typo.bicep && bicep build typo.bicep; echo "exit status $?"
exit status 0
```

The category names are plain strings to Bicep. Resource Manager refuses an unknown category at
deployment, so the mistake does not reach production silently, but it is found in the pipeline's deploy
stage, not at build. The same lesson as lesson 4, met again: **compiling proves shape, not values.**
