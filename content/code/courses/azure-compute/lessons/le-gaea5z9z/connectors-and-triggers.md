---
title: Connectors, connections and the trigger that starts a run
version: 1
---

The half of an integration that takes the longest to write is rarely the logic. It is signing in
to somebody else's service, refreshing the token, paging through its answers and backing off when
it says "too many requests". **A connector is that half, written once by Microsoft and offered as
operations a workflow can use**: each operation is a trigger, which starts a run, or an action,
which is a step in one. It is easy to picture a connector as a library inside the workflow. Most of
them are services somewhere else.

## Built-in and managed

Microsoft's documentation splits connectors in two. A **built-in** connector runs directly and
natively inside the Logic Apps runtime: the Recurrence trigger, the HTTP trigger and action, the
Request trigger that gives a workflow an address of its own, and the control and data actions of the
previous section, `If`, `Compose` and `Table` among them. A **managed** connector is deployed,
hosted and run by Microsoft in Azure, mostly as a proxy or wrapper around the API of the service it
reaches; the designer lists them under *Shared*, and they are billed at a *Standard* or an
*Enterprise* level. Office 365 Outlook, SQL Server, Service Bus and Blob Storage all have one, and
the documentation counts more than 1,400.

When there is no connector, the HTTP action is the general answer: `Get_orders` in the previous
section is one, calling an API nobody wrote a connector for.

## A connection is a resource of its own

A managed connector needs to be told whose account it acts for. That is a **connection**, and for a
managed connector it is a separate Azure resource, of type `Microsoft.Web/connections`, which the
documentation calls an *API connection*. It lives in the same resource group and region as the
workflow, and the workflow refers to it by its id. Save this as `~/azure/outlook.bicep`:

```bicep
// outlook.bicep
param location string = 'brazilsouth'

resource outlook 'Microsoft.Web/connections@2016-06-01' = {
  name: 'office365'
  location: location
  properties: {
    displayName: 'shop finance mailbox'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
    }
  }
}

output connectionId string = outlook.id
```

`api.id` names the managed connector, here `office365` in the region the workflow runs in, and the
connection is one use of it. Compile it, and read what the template says:

```
ana@laptop:~/azure$ bicep build outlook.bicep
ana@laptop:~/azure$ jq ".resources[0] | {type, name, api: .properties.api.id}" outlook.json
{
  "type": "Microsoft.Web/connections",
  "name": "office365",
  "api": "[subscriptionResourceId('Microsoft.Web/locations/managedApis', parameters('location'), 'office365')]"
}
```

**Two expression languages are now in the same file, and they run at different times.** The `[...]`
in `api` is an ARM template expression, evaluated once by Resource Manager when the file is
deployed. The `@...` strings in `daily-orders.bicep` are workflow expressions, carried through the
deployment untouched and evaluated on every run. A workflow parameter, `@parameters('shopUrl')`,
and a template parameter, `[parameters('location')]`, read different things.

The send itself is one more action in the true branch of `Any_orders`, after `Summary`. It is
written here as the workflow would carry it; it was not compiled into the workflow or run:

```json
{
  "Send_export": {
    "type": "ApiConnection",
    "runAfter": {"Summary": ["Succeeded"]},
    "inputs": {
      "host": {"connection": {"name": "@parameters('$connections')['office365']['connectionId']"}},
      "method": "post",
      "path": "/v2/Mail",
      "body": {
        "To": "finance@shop.example.com",
        "Subject": "Orders for @{outputs('Summary')['day']}",
        "Body": "<pre>@{body('Export')}</pre>"
      }
    }
  }
}
```

The workflow finds the connection through a definition parameter named `$connections`, which the
resource fills in with the connection's id, as it filled in `shopUrl`.

**The connection is the part of the workflow that is not in the file.** Office 365 signs in with
Microsoft Entra ID, so somebody has to sign in once and consent; the documentation says Logic Apps
then stores the access and refresh tokens, not the password, and refreshes the access token while
the refresh token stays valid. A refresh token can expire or be revoked, and a changed password
can invalidate it. The morning email then stops on the day it does, until somebody authorises the
connection again. Some connectors, though not every one, can use a managed
identity instead of a person's account, which `azure-foundations` lesson 8 explains.

## Throttling

A managed connector shares capacity, so each one has its own limits, listed on its reference page:
the documentation's example is the Service Bus connector, at up to 6,000 calls a minute. Above a
limit the call is answered with **429, too many requests**. The HTTP action's retry policy
retries 408, 429 and any 5xx answer, so a throttled call waits and tries again, and each try is an
execution billed like the first. A Consumption workflow also has a limit of its own, a number of
actions per rolling five minutes, raised by turning on its *high throughput* mode.

## Polling and push

A trigger starts a run in one of two ways. A **polling** trigger checks a service on a schedule
and starts a run when it finds something new: *when a file is added* on an FTP server is one. A
**push** trigger, also called a webhook trigger, subscribes to the service and gives it a callback
address, and the service calls it when something happens: the Request trigger is the plainest, a
URL that starts a run when somebody posts to it. Lesson 20's Event Grid delivers to a workflow that
way, and, as that lesson says, Azure validates the address itself.

The difference shows up on the bill. **A polling trigger's check is billed whether or not it finds
anything**: the pricing page says so of a trigger that checks an endpoint and is *Skipped*. A
trigger that checks every minute and finds an order twice a day is 1,440 checks for two runs. When
one check finds several items, the trigger's *Split On* setting, on by default for a trigger that
returns an array, starts one run for each item.

The Recurrence trigger in `daily-orders.bicep` is the simplest case: it calls nobody, and fires on
its schedule. Three details in it are the documentation's rules rather than style:

- **`timeZone` applies only together with `startTime`**, and the trigger accepts no UTC offset. Without
  a zone, a `startTime` is UTC, written with a final `Z`: six in the morning in São Paulo is
  `09:00:00Z`.
- The `hours` and `minutes` of a `schedule` apply only when the frequency is `Day` or `Week`. A
  managed connector's polling trigger ignores them and uses only its frequency and interval.
- **A Consumption workflow deployed disabled with a Recurrence trigger fires the moment it is
  enabled**, unless the trigger has a `startTime`. That is why the file has one.
