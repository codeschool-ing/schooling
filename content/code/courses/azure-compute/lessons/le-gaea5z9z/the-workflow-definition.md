---
title: "The workflow definition: a JSON document behind the designer"
version: 1
---

Logic Apps is sold as integration without code, and the first thing anybody sees of it is a
designer: a canvas in the portal where a clock, an HTTP call and a condition are boxes joined by
arrows. That makes it easy to think the drawing is the program. **The drawing is a view of a JSON
document, and the document is the workflow.** The designer edits it, the portal's code view shows
it, and Azure runs it. Microsoft's documentation calls it the *workflow definition* and says it is
validated against the schema of the **Workflow Definition Language**, WDL for short.

So a workflow can be written without the designer, kept in a file and deployed like any other
resource, which is how this section writes one. Nothing of Logic Apps runs on a laptop: what runs
here is the Bicep compiler, and the section ends with what it checks and what it does not.

## The shape of a definition

A definition is an object with a handful of keys. `triggers` holds what starts a run, and a
workflow has at least one. `actions` holds the steps, each one named. `parameters` declares values
the definition reads at run time, and `outputs` declares what a run returns. `$schema` and
`contentVersion` name the language version and the definition's own. The schema reference gives
limits for some of them: at most 10 triggers, 50 parameters and 10 outputs.

An action has a `type`, its `inputs`, and a `runAfter` that says which actions must finish first
and with which statuses. **The order of the run is written in `runAfter`, not in the order of the
file**: a JSON object has no order, and the engine does not read one into it.

## The shop's morning export

Finance at the shop wants the orders in their inbox every morning at six. The first half of that
workflow calls the shop's order API, `GET /orders`, checks that it answered with something, and
turns the answer into CSV. Sending the email needs a connector, which is the next section. Save
this as `~/azure/daily-orders.bicep`:

```schooling-example
{"language": "bicep", "file": "daily-orders.bicep", "parts": [{"code": "// daily-orders.bicep\nparam location string = 'brazilsouth'\nparam shopUrl string = 'https://shop.example.com'\n\nresource dailyOrders 'Microsoft.Logic/workflows@2019-05-01' = {\n  name: 'shop-daily-orders'\n  location: location\n  properties: {\n    state: 'Enabled'\n    parameters: {\n      shopUrl: {\n        value: shopUrl\n      }\n    }\n", "note": "A Consumption logic app is one resource of type `Microsoft.Logic/workflows`, and it holds one workflow. `properties.parameters` fills in the workflow's own parameters at deployment: here the Bicep parameter `shopUrl` becomes the workflow parameter of the same name."}, {"code": "    definition: {\n      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'\n      contentVersion: '1.0.0.0'\n      parameters: {\n        shopUrl: {\n          type: 'String'\n          defaultValue: ''\n        }\n      }\n", "note": "Everything under `definition` is the Workflow Definition Language document, the one the designer draws. Its `parameters` are declared here and read at run time with `parameters('shopUrl')`, so the shop's address is not written into the workflow."}, {"code": "      triggers: {\n        Every_morning: {\n          type: 'Recurrence'\n          recurrence: {\n            frequency: 'Day'\n            interval: 1\n            startTime: '2026-11-02T06:00:00'\n            timeZone: 'E. South America Standard Time'\n            schedule: {\n              hours: [6]\n              minutes: [0]\n            }\n          }\n        }\n      }\n", "note": "The trigger. `frequency` and `interval` say once a day; `schedule` pins it to 06:00, and `timeZone`, the Windows name of Brasília time, makes that six o'clock in São Paulo rather than in UTC. A time zone counts only together with a `startTime`."}, {"code": "      actions: {\n        Get_orders: {\n          type: 'Http'\n          runAfter: {}\n          inputs: {\n            method: 'GET'\n            uri: '@{parameters(\\'shopUrl\\')}/orders'\n            retryPolicy: {\n              type: 'fixed'\n              count: 3\n              interval: 'PT1M'\n            }\n          }\n        }\n", "note": "An HTTP action, the shop's `GET /orders`. An empty `runAfter` makes it the first action. `@{...}` puts the value of an expression inside a string. The retry policy tries three more times, a minute apart, after a 408, a 429, a 5xx or a lost connection, enough for the API to come back from a deploy."}, {"code": "        Any_orders: {\n          type: 'If'\n          runAfter: {\n            Get_orders: ['Succeeded']\n          }\n          expression: {\n            and: [\n              {\n                greater: ['@length(body(\\'Get_orders\\'))', 0]\n              }\n            ]\n          }\n", "note": "A condition is an action of type `If`. It runs once `Get_orders` has ended in `Succeeded`, and its `expression` is a tree: `and` of one test, `greater` of the length of the response body and zero."}, {"code": "          actions: {\n            Export: {\n              type: 'Table'\n              runAfter: {}\n              inputs: {\n                format: 'CSV'\n                from: '@body(\\'Get_orders\\')'\n              }\n            }\n            Summary: {\n              type: 'Compose'\n              runAfter: {\n                Export: ['Succeeded']\n              }\n              inputs: {\n                day: '@{formatDateTime(convertFromUtc(utcNow(), \\'E. South America Standard Time\\'), \\'yyyy-MM-dd\\')}'\n                orders: '@length(body(\\'Get_orders\\'))'\n                csv: '@body(\\'Export\\')'\n              }\n            }\n          }\n", "note": "The true branch. `Export` turns the array of orders into CSV, one column for each property of an order. `Summary` is a Compose: it builds a value, the day in São Paulo, the count and the CSV, and does nothing else. Inside a branch, an empty `runAfter` means first in the branch."}, {"code": "          else: {\n            actions: {\n              No_orders: {\n                type: 'Compose'\n                runAfter: {}\n                inputs: 'no orders to send'\n              }\n            }\n          }\n        }\n      }\n      outputs: {}\n    }\n  }\n}\n", "note": "The false branch has a single Compose, so that a run on a day with no orders says so in its history instead of ending with nothing to show. `outputs` is empty: this workflow returns nothing to anybody."}]}
```

Every expression is a string in single quotes, and every single quote inside one is written `\'`.
That is Bicep's escaping, not the workflow's: the compiled template carries the plain `'`. Compile
it:

```
ana@laptop:~/azure$ bicep build daily-orders.bicep
ana@laptop:~/azure$ ls daily-orders.*
daily-orders.bicep
daily-orders.json
```

**No warnings, and a template beside the file.** The compiler checked the resource: the type and
API version are known to it, and `name`, `location`, `state`, `parameters` and `definition` are
properties a workflow has. `jq` reads the definition back out of the template, action by action:

```
ana@laptop:~/azure$ jq -c ".resources[0].properties.definition.actions | to_entries[] | {name: .key, type: .value.type, runAfter: .value.runAfter}" daily-orders.json
{"name":"Get_orders","type":"Http","runAfter":{}}
{"name":"Any_orders","type":"If","runAfter":{"Get_orders":["Succeeded"]}}
ana@laptop:~/azure$ jq -c ".resources[0].properties.definition.actions.Any_orders.actions | to_entries[] | {name: .key, runAfter: .value.runAfter}" daily-orders.json
{"name":"Export","runAfter":{}}
{"name":"Summary","runAfter":{"Export":["Succeeded"]}}
```

The two top-level actions and their order are all in the first output. `Get_orders` has an empty
`runAfter`, so it runs first, as soon as the trigger fires. `Any_orders` waits for `Get_orders` to
end in `Succeeded`. The second output is the true branch of the condition, whose actions have a
`runAfter` of their own. `Export` has an empty one, which inside a branch means it runs first
there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The run order of the workflow daily-orders, drawn from its runAfter entries. The trigger Every_morning, a Recurrence at 06:00 in São Paulo, starts the run. Get_orders, an HTTP GET with three retries a minute apart, has an empty runAfter and runs first. Any_orders, an If, runs after Get_orders succeeded and holds two branches. In the true branch, Export makes a CSV table and has an empty runAfter, so it runs first in its branch; Summary, a Compose, runs after Export succeeded. In the else branch, No_orders, a Compose, runs alone. A note says the order of the keys in the file is not the order of the run.\"><defs><marker id=\"ro-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"12\" y=\"100\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"82.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Every_morning</text><text x=\"82.0\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Recurrence</text><text x=\"82.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">06:00 in São Paulo</text><rect x=\"180\" y=\"100\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Get_orders</text><text x=\"255.0\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTP GET /orders</text><text x=\"255.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 retries, 1 min apart</text><path d=\"M154 130 L176 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ro-ah)\"></path><text x=\"166\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">runAfter: {}</text><rect x=\"392\" y=\"14\" width=\"316\" height=\"272\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"408\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Any_orders</text><text x=\"496\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">If: are there any orders?</text><path d=\"M332 130 L388 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ro-ah)\"></path><text x=\"360\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Succeeded</text><rect x=\"404\" y=\"48\" width=\"292\" height=\"132\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\" font-weight=\"600\">true</text><rect x=\"414\" y=\"92\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"474.0\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Export</text><text x=\"474.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Table, CSV</text><rect x=\"568\" y=\"92\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"628.0\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Summary</text><text x=\"628.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Compose</text><path d=\"M536 115 L564 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ro-ah)\"></path><text x=\"474\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">first in its branch</text><text x=\"628\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day, count, CSV</text><rect x=\"404\" y=\"192\" width=\"292\" height=\"82\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">else</text><rect x=\"414\" y=\"218\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"489.0\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">No_orders</text><text x=\"489.0\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Compose, a line</text><text x=\"16\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The file lists actions as keys of an object,</text><text x=\"16\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in any order. The arrows are runAfter.</text></svg>", "caption": "The run that daily-orders.bicep declares. Every arrow is a runAfter entry, and the boxes inside Any_orders are its two branches, each with an order of its own. Nothing here comes from the position of an action in the file."}
```

`Succeeded` is one of four statuses `runAfter` can name, beside `Failed`, `Skipped` and `TimedOut`.
The engine marks an action that fails `Failed` and every action waiting on it `Skipped`, so an
action that should run when something went wrong lists that status: `"runAfter": {"Get_orders":
["Failed", "TimedOut"]}` is the shape of an alert. An orchestrator in lesson 17 would write the same
idea in Python, as a `try` around a call.

## Expressions and functions

A value that is only known when the workflow runs is an **expression**: a string that starts with
`@`. The documentation's rule is that `"@parameters('myAge')"` returns the value with its own type,
a number if the parameter is a number, and `"@{parameters('myAge')}"` returns it as a string. Text
around an expression needs the braces: `@{parameters('shopUrl')}/orders` builds an address, and
the documentation marks the same expression written without them as incorrect.

Inside an expression there are functions, and the definition above uses seven of them:

| function | what it gives here |
| --- | --- |
| `parameters('shopUrl')` | the value the resource filled in at deployment |
| `body('Get_orders')` | the body of that action's response, the shop's array of orders |
| `length(...)` | how many items the array has |
| `greater(a, b)` | true if `a` is more than `b`, written in the condition as `"greater": [a, b]` |
| `utcNow()` | the time now, in UTC |
| `convertFromUtc(t, zone)` | the same moment in a Windows time zone, here São Paulo's |
| `formatDateTime(t, 'yyyy-MM-dd')` | the date in the format finance asked for |

`body('Export')` is the second of them again, reading another action. The reference groups the rest
by purpose: strings, collections, logic, conversion, maths, dates, URIs, JSON and XML, and
*workflow* functions such as `triggerBody()`, `item()` inside a loop, and `result()`, which returns
the results of the actions in a scope. One operator matters more than the others: `?` before a
property, as in `triggerBody()?['total']`, returns null when the property is missing instead of
failing the run.

To the compiler, all of that is text. Asked for every string in the definition that starts with
`@`:

```
ana@laptop:~/azure$ jq "[.resources[0].properties.definition | .. | strings | select(startswith(\"@\"))]" daily-orders.json
[
  "@{parameters('shopUrl')}/orders",
  "@length(body('Get_orders'))",
  "@body('Get_orders')",
  "@{formatDateTime(convertFromUtc(utcNow(), 'E. South America Standard Time'), 'yyyy-MM-dd')}",
  "@length(body('Get_orders'))",
  "@body('Export')"
]
```

Six strings, with the backslashes gone: in the template a quote is a plain `'`. The `greater` of
the condition is not among them, because it is a key of an object rather than a string. Whether the
function each string names exists is for Azure to decide, not the compiler.

## What the compiler does not read

**The compiler checks the resource around the definition and nothing inside it.** The resource
type declares `definition` as a value of any shape, so the words in it are not compared with
anything. Here are two copies of the file, one with a step misspelt in a `runAfter` and one with a
function misspelt in both places it is used:

```
ana@laptop:~/azure$ sed "s/Get_orders: \[/Get_order: [/" daily-orders.bicep > typo.bicep; bicep build typo.bicep
ana@laptop:~/azure$ sed "s/@length(/@lenght(/" daily-orders.bicep > lenght.bicep; bicep build lenght.bicep
ana@laptop:~/azure$ grep -c lenght lenght.json
2
```

Both compiled without a word, and the misspelt function is in the template, twice, ready to deploy.
The action named in the first `runAfter` does not exist, and no function called `lenght` exists
either. The Logic Apps service validates a definition when a workflow is saved, but what that
validation catches beyond the schema's shape the documentation does not list, and a laptop cannot
find out. **So in this lesson a clean compile proves the resource and says nothing about the
workflow.**

What the compiler does catch is its own language. A definition copied out of the portal's code view
uses double quotes, and Bicep has none:

```
ana@laptop:~/azure$ sed "s/'no orders to send'/\"no orders to send\"/" daily-orders.bicep > quotes.bicep; bicep build quotes.bicep; echo "exit $?"
/home/ana/azure/quotes.bicep(91,25) : Error BCP103: The following token is not recognized: """. Strings are defined using single quotes in bicep. [https://aka.ms/bicep/core-diagnostics#BCP103]
/home/ana/azure/quotes.bicep(91,25) : Error BCP009: Expected a literal value, an array, an object, a parenthesized expression, or a function call at this location. [https://aka.ms/bicep/core-diagnostics#BCP009]
/home/ana/azure/quotes.bicep(91,43) : Error BCP103: The following token is not recognized: """. Strings are defined using single quotes in bicep. [https://aka.ms/bicep/core-diagnostics#BCP103]
exit 1
ana@laptop:~/azure$ ls quotes.*
quotes.bicep
```

Those are errors rather than warnings: the exit status is 1, and no template was written. Bicep also
has `loadJsonContent('workflow.json')`, which reads a definition kept as a JSON file of its own into
the template at compile time, with no escaping. The check is the same either way: none.

Deploying the file is one command, not run in this course because it needs a subscription:

```sh
az deployment group create --resource-group shop-rg --template-file daily-orders.bicep --parameters shopUrl=https://shop.example.com
```
