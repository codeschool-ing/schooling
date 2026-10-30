---
title: Alert processing rules: when nobody should hear
version: 1
---

**An alert processing rule changes what happens to alerts after they fire, without touching the rules
that fired them.** Its two common jobs are adding an action group to every alert in a scope, and
removing them all for a period. The second is maintenance:

```bicep
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
```

```
ana@laptop:~/azure/alerts$ bicep build maintenance.bicep; echo "exit status $?"
exit status 0
```

On Sunday 25 October, between 02:00 and 04:00 in São Paulo, the shop's SQL database is down for planned
maintenance, and checkout will fail. Without this rule, `checkout-failing` pages the on-call engineer at
02:05 for something everybody knew would happen. With it, **the alert still fires and is still recorded**;
only the notification is removed. That distinction is the reason to suppress here rather than by
disabling the alert rule: a disabled rule records nothing, so if something else breaks during the window
there is no trace of it, and a rule disabled for maintenance is a rule somebody forgets to enable again.

The schedule takes a Windows time-zone name, `E. South America Standard Time`, which is São Paulo's.
Getting the zone wrong is the classic mistake here: a window written in UTC silences 23:00 to 01:00 and
pages everybody at 02:05.

Processing rules are also where a team adds an action group to every alert in a subscription at once,
so that a new rule nobody wired to anything still reaches somebody. The shop has one: every severity 0
alert in the subscription also goes to the chat webhook, whatever its own rule says.
