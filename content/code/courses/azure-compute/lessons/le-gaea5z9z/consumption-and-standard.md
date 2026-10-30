---
title: "Consumption and Standard: two products under one name"
version: 1
---

When you create a logic app you choose Consumption or Standard, and the choice looks like a
tier: the same thing, smaller or larger. **They are two products that read the same language.** A
Consumption logic app is one workflow running in a service that every Azure customer shares, billed
for each operation it runs. A Standard logic app is an app of the Functions family, running on
compute reserved for it, holding as many workflows as you put in it, and billed for that compute by
the hour whether or not anything runs. The definition of the previous sections runs on either.
Almost everything around it differs.

## What each one is

| | Consumption | Standard |
| --- | --- | --- |
| runs in | multitenant Logic Apps, shared by every customer | single-tenant Logic Apps, the runtime as an extension of the Azure Functions runtime |
| the resource | `Microsoft.Logic/workflows` | `Microsoft.Web/sites`, of kind `workflowapp`, on a plan |
| workflows per resource | one | several, sharing the app's compute |
| billed for | each execution of a trigger or action, after a free initial number of built-in ones | the plan's vCPU and memory, plus each call of a managed connector |
| kinds of workflow | stateful | stateful and stateless |
| a virtual network | no direct access | integration with a VNet, private endpoints |
| on a laptop | nothing | the runtime, through Visual Studio Code |

The documentation's own summary of Consumption is "easiest to get started, pay for what you use,
fully managed". Standard trades that for control. It has built-in versions of connectors such as
Service Bus, Event Hubs and SQL Server, which run in the same process as the workflow. It has a
static outbound address of its own, higher limits on run time and message size, and data that
stays in the region it was deployed to.

## Standard is an app on a plan

The resource type says which family a product belongs to. A Standard logic app is declared the way
lesson 18's web app is, a plan and a site on it. Save this as `~/azure/standard.bicep`:

```bicep
// standard.bicep
param location string = 'brazilsouth'

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'shop-workflows-plan'
  location: location
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
}

resource app 'Microsoft.Web/sites@2024-04-01' = {
  name: 'shop-workflows'
  location: location
  kind: 'functionapp,workflowapp'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      appSettings: [
        { name: 'APP_KIND', value: 'workflowApp' }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'dotnet' }
      ]
    }
  }
}
```

```
ana@laptop:~/azure$ bicep build standard.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, kind, sku}" standard.json
{"type":"Microsoft.Web/serverfarms","kind":null,"sku":{"name":"WS1","tier":"WorkflowStandard"}}
{"type":"Microsoft.Web/sites","kind":"functionapp,workflowapp","sku":null}
```

It compiles cleanly, and the template is not complete. The documentation lists `AzureWebJobsStorage`
as a required setting, a storage account's connection string, exactly as for the function apps of
lesson 15; it is left out here because it needs a storage account declared beside it. The other
three settings are the documentation's required values: `APP_KIND` is `workflowApp`, and the worker
runtime is `dotnet` for every Standard logic app. The workflows are not in this template: each is a
folder in the app's files with a `workflow.json` holding the same kind of definition, deployed as
the files of a function app are.

The CLI draws the same line between the two. Standard's commands are in the CLI itself, under
`az logicapp`, and they ask for an App Service plan; Consumption's are in an extension that this
lab never added:

```
ana@laptop:~/azure$ az logicapp create --help | grep -A3 -- "--plan -p"
    --plan -p                            : Name or resource id of the logicapp app service plan. Use
                                           'appservice plan create' to get one. If using an App
                                           Service plan from a different resource group, the full
                                           resource id must be used and not the plan name.
ana@laptop:~/azure$ az logic --help 2>&1 | head -1
ERROR: 'logic' is misspelled or not recognized by the system.
```

`az extension add --name logic` adds it. It is not run here: every command in it needs a
subscription.

The plan is the price. **Workflow Standard has three tiers, and the documentation gives their
size**: WS1 has 1 vCPU and 3.5 GB of memory, WS2 has 2 and 7 GB, WS3 has 4 and 14 GB. The plan is
billed for those resources whether its workflows run or not, as lesson 16's Premium plan is.

## Stateful and stateless

A Standard workflow is created as one of two kinds. A **stateful** workflow saves every action's
inputs, outputs and status to external storage, so its runs can be read afterwards and an
interrupted run can be resumed when the service comes back. A **stateless** workflow keeps them in
memory only. It is faster and cheaper, and the documentation gives it a run of five minutes by
default against a stateful one's 90 days. It also lists what a stateless workflow cannot do: it
takes only push triggers, so no Recurrence, and it does not poll a `202 Accepted`. A run interrupted
by an outage is lost, and the caller has to send it again. Every Consumption workflow is stateful.

## Run history is the debugger

In Azure there is no breakpoint and no log line of your own, so **the record of a run is how a
workflow is debugged**. A stateful workflow keeps one entry per run, with its status, and inside it
every action's status, inputs and outputs, as Azure saw them. A failed `Get_orders` shows the
request it sent and the answer it got; a `Skipped` action shows that something before it failed. The
trigger has a history of its own, where a polling check that found nothing is *Skipped* and started
no run. Consumption keeps runs for 90 days by default, counted from the start of the run.

A finished run can be **resubmitted** with the same inputs, from the start or from one action on,
in the portal. The documentation lists the conditions: the workflow must be stateful or have its
history turned on, the rerun uses the version of the definition the original run used even if it
has changed since, and an action that creates something creates it again. A stateless workflow
keeps no history unless it is turned on, for a while, to debug it.

## The arithmetic of an execution

**Consumption bills executions, so it pays to count them.** The documentation's rules are short:

- each trigger and each action that runs is one execution, whether the run succeeds or not;
  actions that never ran because the run stopped are not billed;
- a retry is another execution: an action that runs with 5 retries is billed as 6;
- a loop is billed per item: a `foreach` over 10 items with one action inside is 10 × 1, plus 1
  for the loop itself, so 11.

The shop's morning export is a trigger, `Get_orders`, `Any_orders`, `Export`, `Summary` and
`Send_export`: six executions a day, about 180 a month, more on a morning `Get_orders` is retried.
Whatever the price of one execution in your region, 180 of them is the kind of number Consumption
was built for, and a WS1 plan bills every hour of the month for the same six steps. Prices are on
Azure's pricing page and in the pricing calculator, and this course quotes none of them. Lesson 21
shows how to put real rates into a comparison of every option in this course.
