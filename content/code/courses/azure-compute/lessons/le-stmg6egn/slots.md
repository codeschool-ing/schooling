---
title: "Slots: the same app at a second address"
version: 1
---

A deployment slot sounds like a second environment: a staging copy of the shop on machines of its
own, kept apart from production. **A slot is a live app on the same plan, with its own host name
and its own settings.** It runs on the plan's instances, as section 02's figure drew, and
Microsoft charges nothing extra for it, because the instances are already paid for. What it gives
the shop is a place to put `shop:1.1`, with production's machines and production's network, where
the developers can call it before any customer does. The production app is itself a slot, the one
called `production`, which is why the next section can swap the two. This section is the slot in
the shop's file, compiled with two mistakes the compiler catches and one it does not; the slot
itself is read from Microsoft's documentation, and none was created.

## How many, and where

Slots exist from the Standard tier up, five per app on Standard and 20 on Premium and Isolated,
by the limits page read on 2026-10-30. Free and Basic have none. The count also holds a plan in
place: an app with more than five slots cannot be scaled down to Standard until some are deleted.

Each slot has its own host name, the app's name and the slot's joined by a hyphen,
`shop-sp-staging.azurewebsites.net` beside `shop-sp.azurewebsites.net`. The documentation limits
the app's name to 40 characters and the slot's to 19 so that the two fit in a DNS label together.
A slot is reachable from the internet like the app. Closing it to everyone but the developers is
an access restriction on the slot, an IP rule, which is what the documentation points to for it.

**A new slot has no content**, even when it clones its configuration from another. The CLI's
`--configuration-source` copies settings and nothing else:

```
ana@laptop:~/azure$ az webapp deployment slot create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --configuration-source '
 --configuration-source : Source slot to clone configurations from. Use web app's name to refer to the production slot. 
ana@laptop:~/azure$ az webapp config appsettings set --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --slot-settings ' | sed 's/ Global Policy Arguments//'
 --slot-settings : Space-separated appsettings in KEY=VALUE format. Use @{file} to load from a file. Given setting are added to the configuration and marked as Deployment slot setting by default. 
```

The second command is the CLI's way to make a setting *sticky*, which is the idea the rest of this
section is about.

## Each slot has its own settings

In the file, `staging` is a resource of its own, `Microsoft.Web/sites/slots`, with `site` as its
parent and a `siteConfig` of its own. It runs `shop:1.1` where production runs `shop:1.0`, and it
repeats every app setting, because nothing a slot has is inherited at run time. Its `SHOP_ENV` is
`staging`, where production's is `production`.

That last setting is the interesting one. Suppose `SHOP_ENV` decides which payment gateway the shop
calls, the real one or the gateway's sandbox. When the next section swaps the slots, the content
that was in staging moves into production. If its settings moved with it, the new production would
arrive still saying `staging` and send every customer's card to the sandbox. **A sticky setting
stays with the slot, not with the content**, and the file declares one in a resource with a fixed
name, `slotConfigNames`, on the app rather than on the slot:

```
ana@laptop:~/azure$ jq '.resources[3].properties' shop-web.json
{
  "appSettingNames": [
    "SHOP_ENV"
  ]
}
```

Names listed there stay where they are during a swap, and the REST API's description of the
resource says the list is valid for all deployment slots in an app. Connection strings
have a list of their own beside it, `connectionStringNames`. The compiler knows the resource well
enough to catch two slips. A wrong name for the configuration, and the list written as a single
string:

```
ana@laptop:~/azure$ sed "s/'slotConfigNames'/'slotSettings'/" shop-web.bicep > name.bicep
ana@laptop:~/azure$ bicep build name.bicep
/home/ana/azure/name.bicep(76,9) : Warning BCP088: The property "name" expected a value of type "'appsettings' | 'authsettings' | 'authsettingsV2' | 'azurestorageaccounts' | 'backup' | 'connectionstrings' | 'logs' | 'metadata' | 'pushsettings' | 'slotConfigNames' | 'web'" but the provided value is of type "'slotSettings'". Did you mean "'appsettings'"? [https://aka.ms/bicep/core-diagnostics#BCP088]
ana@laptop:~/azure$ sed -n '/appSettingNames/,/]/p' shop-web.bicep
    appSettingNames: [
      'SHOP_ENV'
    ]
ana@laptop:~/azure$ sed "/appSettingNames: \[/,/]/c\    appSettingNames: 'SHOP_ENV'" shop-web.bicep > list.bicep
ana@laptop:~/azure$ bicep build list.bicep
/home/ana/azure/list.bicep(78,22) : Warning BCP036: The property "appSettingNames" expected a value of type "null | string[]" but the provided value is of type "'SHOP_ENV'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

The first warning is worth reading whole: `Microsoft.Web/sites/config` is a closed list of eleven
names, and the compiler prints them. Its "did you mean" guesses `appsettings`, which is the
nearest spelling and the wrong resource; the right one is in the list, a few names further on.

## What travels and what stays

Not only the settings you mark. Microsoft's documentation splits an app's configuration into
what follows the content across a swap and what stays with the slot, and the split is fixed:

| follows the content | stays with the slot |
| --- | --- |
| app settings and connection strings not marked sticky | settings and connection strings marked sticky |
| language and platform settings, WebSockets | custom domain names, non-public certificates and TLS settings |
| mounted storage, handler and path mappings, WebJobs content | scale settings, WebJobs schedules |
| hybrid connections, service endpoints, the CDN | managed identities, virtual network integration, IP restrictions |
| public certificates | publishing endpoints, Always On, diagnostic logs, CORS, HTTPS only |

**The right-hand column is the slot's identity**: its addresses, its certificates, who may reach
it, which network it is on, and the identity it uses to reach other things. A managed identity
that may read production's Key Vault stays on production, and the code that arrives there uses it
from the moment of the switch. Five of the right-hand items, IP restrictions, Always On,
diagnostic logs, CORS and the protocol settings, were swapped once; the documentation keeps a
setting, `WEBSITE_OVERRIDE_PRESERVE_DEFAULT_STICKY_SLOT_SETTINGS`, that restores the old behaviour
for all five or none.

## A slot on a plan that has none

The tier rule is the plan's, the slot is the site's, and the two are separate resources. The
compiler checks each against its own type and never the pair:

```
ana@laptop:~/azure$ sed "s/name: 'P1v3'/name: 'B1'/" shop-web.bicep > basic.bicep
ana@laptop:~/azure$ bicep build basic.bicep
ana@laptop:~/azure$ jq -c '[.resources[0].sku.name, .resources[2].type]' basic.json
["B1","Microsoft.Web/sites/slots"]
```

**A `B1` plan with a slot compiles without a word**, and the template has both. Basic has no
slots, so Azure refuses this file at deployment; where in the deployment and in what words is
Azure's to say, it needs a subscription, and no message is quoted here. A sixth slot on Standard
is the same kind of mistake. A file can be correct for every type it names and still ask for something
the tier does not sell.

## Sending some customers to a slot

A slot can also take a share of production's traffic before any swap, which is lesson 8's traffic
splitting with a different mechanism. `az webapp traffic-routing set --distribution staging=10`
sends a tenth of the visitors at production's address to staging, chosen at random. The choice is
then kept in a cookie, `x-ms-routing-name`, for an hour, so one customer does not alternate
between versions on every page. A link with `?x-ms-routing-name=staging` lets somebody opt in on
purpose, and `self` names production. Not run in this course: it needs a subscription.

Lesson 8 split traffic between revisions of one app, by weight, with labels for direct addresses.
Here the unit is the slot, the share is a percentage on production's address, and the slot has its
own address anyway. The section after this one uses the slot the way it is most often used: not
to share traffic, but to swap.
