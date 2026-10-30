---
title: Action groups: who hears about it
version: 1
---

**An alert rule does not know who to tell; it names one or more action groups, and they do.** An action
group is a reusable list of receivers, so the twelve rules that should wake the on-call engineer all name
one group, and changing who is on call is one edit rather than twelve.

```bicep
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
```

```
ana@laptop:~/azure/alerts$ bicep build action-group.bicep; echo "exit status $?"
exit status 0
```

The receivers here are an e-mail address and a **webhook**, an HTTPS endpoint that receives the alert as
JSON, which is how alerts reach a chat channel, a paging service or the shop's own automation. Both
addresses are from the documentation ranges: `example.com` belongs to nobody. Action groups also offer
SMS and voice calls, a push to the Azure mobile app, and actions that run code: an Azure Function, a
Logic App, an Automation runbook. SMS and voice are billed per message and per call, and both have
limits per number per hour, which is one reason to keep them for severity 0 and 1.

**`useCommonAlertSchema: true`** makes every alert arrive in one JSON shape, whatever kind of rule fired
it. Without it, a metric alert and a log search alert arrive in different shapes, and every consumer has
to understand both. Turn it on everywhere; there is no reason not to.

What decides whether the on-call engineer trusts the page is not the action group; it is the rule. An
action group that receives a page a day for things nobody acts on trains the person holding the phone to
ignore it. Lesson 14 is about choosing the rules so that a page means a customer is affected.
