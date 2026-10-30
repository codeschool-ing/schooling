---
title: "Autoscale: a rule, a window and a cooldown"
version: 1
---

The picture to replace is "when the CPU passes 70%, add a machine". **An autoscale rule never acts
on one reading.** It reads a metric sampled once a minute, combines the samples over a window of
several minutes, compares that one number with the threshold, and only then acts; and after acting,
it waits. Each of those is a number you write, and what the shop's scale set does at lunchtime is
arithmetic on them.

## A setting, its profiles and its rules

Autoscale is not a property of the scale set. It is a resource of its own,
`Microsoft.Insights/autoscalesettings`, which belongs to Azure Monitor and points at the resource it
scales, and a resource has one autoscale setting at most. So the shop's goes in a file of its own.
Save it as `shop-autoscale.bicep`:

```schooling-example
{"language": "bicep", "file": "shop-autoscale.bicep", "parts": [{"code": "// shop-autoscale.bicep\nparam location string = 'brazilsouth'\n\nresource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-11-01' existing = {\n  name: 'shop-vmss'\n}\n\n", "note": "A file of its own, because an autoscale setting is a resource of its own. It names the scale set as `existing`, so it is deployed after the scale set."}, {"code": "var cpuRules = [\n  {\n    metricTrigger: {\n      metricName: 'Percentage CPU'\n      metricResourceUri: vmss.id\n      timeGrain: 'PT1M'\n      statistic: 'Average'\n      timeWindow: 'PT10M'\n      timeAggregation: 'Average'\n      operator: 'GreaterThan'\n      threshold: 70\n    }\n    scaleAction: {\n      direction: 'Increase'\n      type: 'ChangeCount'\n      value: '2'\n      cooldown: 'PT10M'\n    }\n  }\n", "note": "The scale-out rule, kept in a variable so both profiles share it. Each minute, average Percentage CPU over the instances; each time the engine runs, average the last ten of those minutes; above 70, add two instances; then leave this rule idle for ten minutes after any scale action."}, {"code": "  {\n    metricTrigger: {\n      metricName: 'Percentage CPU'\n      metricResourceUri: vmss.id\n      timeGrain: 'PT1M'\n      statistic: 'Average'\n      timeWindow: 'PT10M'\n      timeAggregation: 'Average'\n      operator: 'LessThan'\n      threshold: 30\n    }\n    scaleAction: {\n      direction: 'Decrease'\n      type: 'ChangeCount'\n      value: '1'\n      cooldown: 'PT10M'\n    }\n  }\n]\n\n", "note": "The scale-in rule, the same measurement read the other way: below 30, remove one. The gap between 30 and 70 is what keeps the two rules from undoing each other."}, {"code": "resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {\n  name: 'shop-autoscale'\n  location: location\n  properties: {\n    enabled: true\n    targetResourceUri: vmss.id\n    predictiveAutoscalePolicy: {\n      scaleMode: 'ForecastOnly'\n    }\n", "note": "One setting for the scale set. `ForecastOnly` asks for a predictive forecast without letting it act."}, {"code": "    profiles: [\n      {\n        name: 'black-friday'\n        capacity: {\n          minimum: '6'\n          maximum: '12'\n          default: '6'\n        }\n        rules: cpuRules\n        fixedDate: {\n          timeZone: 'E. South America Standard Time'\n          start: '2026-11-27T00:00:00'\n          end: '2026-11-28T23:59:00'\n        }\n      }\n", "note": "A fixed-date profile for Black Friday, with a higher floor. For those two days, in São Paulo time written with Windows' name for that zone, it is used instead of the default profile."}, {"code": "      {\n        name: 'normal'\n        capacity: {\n          minimum: '3'\n          maximum: '12'\n          default: '3'\n        }\n        rules: cpuRules\n      }\n    ]\n  }\n}\n", "note": "The profile for every other day: never fewer than three instances, one per zone, and never more than twelve."}]}
```

A setting holds **profiles**, up to 20, and each time the engine runs it uses exactly one. There are
three kinds. A **fixed-date** profile has a start and an end, like the shop's Black Friday. A
**recurrence** profile repeats on days of the week from a start time and runs until the next profile
starts. The **default** profile has neither and runs whenever no other applies; a setting has one.
They are tried in that order, fixed date first, and the first that fits is the one used.

Each profile carries a **capacity**: a minimum and a maximum the engine never goes past, and a
**default**, which matters only when the metric cannot be read. Then, if the scale set has fewer
instances than the default, autoscale raises it to the default, and if it has more, it does not scale
in. The shop's default of three is the count it trusts with no information.

Each profile also carries up to 10 **rules**, and a rule is a metric trigger and a scale action:

| part | the shop's value | what it means |
| --- | --- | --- |
| `timeGrain` | `PT1M` | one sample a minute |
| `statistic` | `Average` | each sample averages the instances |
| `timeWindow` | `PT10M` | look back ten minutes |
| `timeAggregation` | `Average` | average the ten samples |
| `operator`, `threshold` | `GreaterThan`, `70` | compare that number with 70 |
| `direction`, `type`, `value` | `Increase`, `ChangeCount`, `2` | add two instances |
| `cooldown` | `PT10M` | this rule waits ten minutes after a scale action |

`type` takes `ChangeCount`, which adds or removes that many; `PercentChangeCount`, that percentage of
the current count; and `ExactCount`, which sets the count to the value. The API's own description lists a
fourth, `ServiceAllowedNextValue`, which the documentation read for this lesson does not explain. The
cooldown belongs to each rule: after any scale action, a rule may act again once its own cooldown
has passed, whichever rule caused the action.

```
ana@laptop:~/azure$ bicep build shop-autoscale.bicep
ana@laptop:~/azure$ jq -c ".resources[0].properties.profiles[] | {name, capacity, fixedDate}" shop-autoscale.json
{"name":"black-friday","capacity":{"minimum":"6","maximum":"12","default":"6"},"fixedDate":{"timeZone":"E. South America Standard Time","start":"2026-11-27T00:00:00","end":"2026-11-28T23:59:00"}}
{"name":"normal","capacity":{"minimum":"3","maximum":"12","default":"3"},"fixedDate":null}
```

Clean, and both profiles are there with their capacities. The fixed date is `null` on `normal`,
which is what makes it the default profile.

## Lunchtime, worked through

Suppose the shop's three instances sit at 40% CPU all morning, and lunchtime orders arrive at 12:00
and take each of them to 90%. A minute's sample is the average over the instances, so the sample for
12:01 is 90, and so is every sample after it.

At 12:01 the window holds nine samples of 40 and one of 90: (9 × 40 + 90) / 10 = 45. Each minute
swaps a 40 for a 90 and adds 5. At 12:06 the window holds six samples of 90 and four of 40, which
is (6 × 90 + 4 × 40) / 10 = 70, and 70 is not greater than 70. **At 12:07 it is 75, and the rule
fires, seven minutes after the load arrived.** The engine runs every 30 to 60 seconds, which can add
up to a minute, and the two new instances then have to boot before they serve anything.

Say they serve from 12:10. The same load spread over five instances is 3 × 90 / 5 = 54% each, between
the two thresholds, so the shop should settle at five. Whether it does depends on the cooldown.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A chart of Percentage CPU from 11:58 to 12:22. Each minute’s sample is 40 until 12:00, 90 from 12:01 to 12:09, and 54 from 12:10, when five instances share the load. The ten-minute average rises from 40 and passes the threshold of 70 at 12:07, reading 75, when two instances are added. At 12:12, where a five-minute cooldown would end, the average still reads 79.2. At 12:17, where the ten-minute cooldown ends, it reads 61.2. The scale-in threshold of 30 is never reached.\"><defs><marker id=\"sw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"63.8\" y=\"160\" width=\"14\" height=\"80\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"85.4\" y=\"160\" width=\"14\" height=\"80\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"107\" y=\"160\" width=\"14\" height=\"80\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"128.6\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150.2\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"171.8\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"193.4\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"215\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"236.6\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258.2\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"279.8\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"301.4\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"323\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"344.6\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"366.2\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"387.8\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"409.4\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"431\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"452.6\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"474.2\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"495.8\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"517.4\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"539\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"560.6\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"582.2\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M60 240 L608 240\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sw-ah)\"></path><path d=\"M60 240 L60 40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"54\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"54\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"54\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><path d=\"M114 240 L114 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"114\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M222 240 L222 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"222\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:05</text><path d=\"M330 240 L330 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"330\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:10</text><path d=\"M438 240 L438 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"438\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:15</text><path d=\"M546 240 L546 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"546\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:20</text><path d=\"M60 100 L600 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"606\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">out above 70</text><path d=\"M60 180 L600 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"606\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in below 30</text><path d=\"M70.8 160 L92.4 160 L114 160 L135.6 150 L157.2 140 L178.8 130 L200.4 120 L222 110 L243.6 100 L265.2 90 L286.8 80 L308.4 70 L330 67.2 L351.6 74.4 L373.2 81.6 L394.8 88.8 L416.4 96 L438 103.2 L459.6 110.4 L481.2 117.6 L502.8 124.8 L524.4 132 L546 132 L567.6 132 L589.2 132\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M265.2 20 L265.2 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"265.2\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">+2 instances</text><circle cx=\"265.2\" cy=\"90\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"272.2\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\" font-weight=\"600\">75</text><path d=\"M373.2 32 L373.2 76.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"373.2\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">5-min cooldown ends</text><circle cx=\"373.2\" cy=\"81.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"380.2\" y=\"72.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\" font-weight=\"600\">79.2</text><path d=\"M481.2 44 L481.2 112.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"481.2\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">10-min cooldown ends</text><circle cx=\"481.2\" cy=\"117.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"488.2\" y=\"108.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\" font-weight=\"600\">61.2</text><rect x=\"70\" y=\"278\" width=\"14\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each minute’s sample</text><path d=\"M300 284 L322 284\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"328\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the ten-minute average</text></svg>", "caption": "The shop’s lunchtime, minute by minute. The average lags the samples by design: it reaches 70 seven minutes after the load did, and it still carries the minutes from before the new instances for most of a window afterwards, which is why the cooldown is as long as the window."}
```

With a five-minute cooldown, the rule could act again at 12:12. The window then covers 12:03 to
12:12: seven samples of 90 from before the new instances served, and three of 54, which is
(7 × 90 + 3 × 54) / 10 = 79.2. **That is above 70, so a five-minute cooldown adds two more instances
to answer a load that two had already answered.** At seven instances, 270 / 7 = 38.6%, not below 30,
so the two extra stay until lunch is over. With the file's ten minutes the rule is next eligible at
12:17, when the window holds two samples of 90 and eight of 54: 61.2, and nothing happens. What the
arithmetic says in general is that **a scale-out cooldown at least as long as the window keeps a rule
from reading the minutes before its own last action**, and that the boot time has to be added to
it. How long the shop's image takes to boot is the one number here you have to measure.

In the evening the load falls to 120 percentage points over the five instances, 24% each. That is
below 30, so the scale-in rule removes one: 120 / 4 = 30%, which is not *less than* 30, and the shop
stays at four.

## Several rules, and flapping

Most profiles have more than one rule, and the engine combines them unevenly on purpose. **It scales
out if any scale-out rule fires, and scales in only if every scale-in rule fires.** When several
scale-out rules fire it takes the largest new count, and when the scale-in rules agree it removes the
fewest instances any of them asks for.

**Flapping** is a scale action that causes the opposite one. Microsoft's example is one instance at
56% CPU, a rule that adds one above 50% and another that removes one below 30%. At two instances the
average is 28%, below 30, and removing one would put it back at 56%. To stop that loop, autoscale
checks every scale-in before doing it: it estimates the metric at the smaller count, and if that
would set off a scale-out, it skips the scale-in or removes fewer than the rule asked. Scale-outs are
never checked this way, and always go ahead. The cure is a margin between the thresholds. The shop's
30 and 70 are more than a factor of two apart, which is why one instance more or less cannot carry the
average from one side to the other.

## Predictive autoscale

A forecast is the other way to get ahead of a load. **Predictive autoscale learns the scale set's CPU
pattern and adds instances before the predicted rise**, up to an hour ahead. Microsoft documents its
limits: virtual machine scale sets only, the Percentage CPU metric with Average aggregation only,
scale-out only, at least seven days of history, and a rolling window of 15 days of it. It also needs
an ordinary scale-out rule on Percentage CPU to exist, which the shop has. The CLI lists its modes:

```
ana@laptop:~/azure$ az monitor autoscale create --help | tr -s "[:space:]" " " | grep -o "\-\-scale-mode : [^.]*\. Allowed values: [A-Za-z, ]*\."
--scale-mode : The predictive autoscale mode. Allowed values: Disabled, Enabled, ForecastOnly.
```

The shop's file starts at `ForecastOnly`, which draws the forecast without acting on it, so it can be
compared with what really happened before `Enabled` is trusted. A monthly or yearly peak is not
something it learns, and the Black Friday profile is there for exactly that.

## What the compiler lets through

Three mistakes, typed into a copy: the cooldown written as a number of minutes, the window shortened
to two minutes, and a minimum of thirteen in a profile whose maximum is twelve:

```
ana@laptop:~/azure$ sed -e "0,/cooldown: 'PT10M'/s//cooldown: 10/" -e "0,/timeWindow: 'PT10M'/s//timeWindow: 'PT2M'/" -e "s/minimum: '3'/minimum: '13'/" shop-autoscale.bicep > autoscale-wrong.bicep
ana@laptop:~/azure$ diff shop-autoscale.bicep autoscale-wrong.bicep
15c15
<       timeWindow: 'PT10M'
---
>       timeWindow: 'PT2M'
24c24
<       cooldown: 'PT10M'
---
>       cooldown: 10
74c74
<           minimum: '3'
---
>           minimum: '13'
ana@laptop:~/azure$ bicep build autoscale-wrong.bicep
/home/ana/azure/autoscale-wrong.bicep(64,16) : Warning BCP036: The property "cooldown" expected a value of type "string" but the provided value in source declaration "cpuRules" is of type "10". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**The compiler caught one of the three.** It reported the cooldown at line 64, where `cpuRules` is
used, rather than at the line where the `10` was typed, because what it checks is the value arriving
in a profile. The two-minute window and the minimum above the maximum compiled cleanly: one is a
well-formed duration, the others are well-formed strings. The ranges are in the API's own
description, which travels inside the CLI's Python package:

```
ana@laptop:~/azure$ grep -h -A2 ":ivar time_window:" venv/lib/python3.12/site-packages/azure/mgmt/monitor/models/_models_py3.py
    :ivar time_window: the range of time in which instance data is collected. This value must be
     greater than the delay in metric collection, which can vary from resource-to-resource. Must be
     between 12 hours and 5 minutes. Required.
ana@laptop:~/azure$ grep -h -A1 ":ivar cooldown:" venv/lib/python3.12/site-packages/azure/mgmt/monitor/models/_models_py3.py
    :ivar cooldown: the amount of time to wait since the last scaling action before this action
     occurs. It must be between 1 week and 1 minute in ISO 8601 format. Required.
```

So `PT2M` is outside what the API states, and Resource Manager is where it would be refused. A
minimum above the maximum is not stated as a rule anywhere in what was read for this lesson, and it is
exactly the kind of number to check by eye.
