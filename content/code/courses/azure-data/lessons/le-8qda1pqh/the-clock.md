---
title: The clock: start-up, time to live and what an idle cluster costs
version: 1
---

**A Spark cluster takes minutes to start, and somebody pays for those minutes whichever tool asked
for it.** A data flow on a cold runtime waits for its cluster before it reads a row; a notebook on a
paused pool waits for its session. Both services let you keep the cluster warm, and both bill the
warmth. This section checks one declaration with Terraform, offline; the timings it discusses are
Microsoft's descriptions, and none was measured here.

## The runtime a data flow runs on

**A mapping data flow runs on the Azure integration runtime of lesson 19, on a Spark cluster that
runtime starts for it.** The runtime's settings decide the cluster: its compute type, its number of
cores, and its time to live. Add this file to `~/azure/tf/factory`, the directory lesson 19 left:

`runtime.tf`:

```hcl
resource "azurerm_data_factory_integration_runtime_azure" "flows" {
  name             = "ir-dataflows-brs"
  data_factory_id  = azurerm_data_factory.etl.id
  location         = "brazilsouth"
  compute_type     = "General"
  core_count       = 8
  time_to_live_min = 10
}
```

```
ana@laptop:~/azure/tf/factory$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/factory$ sed -i 's/core_count       = 8/core_count       = 4/' runtime.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/core_count       = 4/core_count       = 8/' runtime.tf
Error: expected core_count to be one of [8 16 32 48 80 144 272], got 4
ana@laptop:~/azure/tf/factory$ sed -i 's/"General"/"Small"/' runtime.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/"Small"/"General"/' runtime.tf
Error: expected compute_type to be one of ["ComputeOptimized" "General" "MemoryOptimized"], got Small
```

**Eight cores is the smallest cluster a data flow gets**, and sizes go up in steps from there. The
provider knows three compute types, and the two that matter are general purpose and memory
optimised, the second for large joins and aggregations. And `location` pins the runtime to
`brazilsouth`, lesson 19's point about where data is processed.

**`time_to_live_min` keeps the cluster alive after a data flow ends**, ten minutes here, so that the
next data flow that starts within those ten minutes finds it warm instead of waiting for a new one.
Without it, every data flow in a pipeline starts its own cluster, and a pipeline of four data flows in
sequence waits four times. With it, the cluster idles for up to ten minutes after the last one, and
those minutes are billed at the same rate as the work.

## The arithmetic of a night

Quitanda's night, if it were written as data flows: a cleaning flow and a summary flow, one after the
other, each doing about three minutes of work. Microsoft describes a cold cluster as taking several
minutes to start; take five as the round number to do the sum with, which is illustrative and was not
measured. At **an illustrative 0.30 USD per vCore-hour**, on 8 cores:

| arrangement | minutes the cluster is billed | vCore-hours | USD a night | USD a month |
|---|---:|---:|---:|---:|
| no time to live: two cold starts | 5 + 3 + 5 + 3 = 16 | 8 × 16 / 60 = 2.13 | 0.64 | 19.84 |
| ten minutes of time to live | 5 + 3 + 3 + 10 = 21 | 8 × 21 / 60 = 2.80 | 0.84 | 26.04 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 248\" role=\"img\" aria-label=\"Two timelines of billed cluster minutes for Quitanda's two data flows. With no time to live: five minutes starting, three working, five starting again, three working, 16 minutes. With ten minutes of time to live: five minutes starting, three working, three working, then ten minutes idle and warm, 21 minutes.\" data-fig=\"l20-clock\"><text x=\"188\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no time to live</text><text x=\"188\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two cold starts</text><rect x=\"200\" y=\"56\" width=\"108\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"310\" y=\"56\" width=\"64\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"376\" y=\"56\" width=\"108\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"486\" y=\"56\" width=\"64\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"560\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 min</text><text x=\"188\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ten minutes to live</text><text x=\"188\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one start, idle after</text><rect x=\"200\" y=\"126\" width=\"108\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"310\" y=\"126\" width=\"64\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"376\" y=\"126\" width=\"64\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"442\" y=\"126\" width=\"218\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"/><text x=\"670\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21 min</text><line x1=\"200\" y1=\"196\" x2=\"200\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"200\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"310\" y1=\"196\" x2=\"310\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"310\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"420\" y1=\"196\" x2=\"420\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"420\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><line x1=\"530\" y1=\"196\" x2=\"530\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"530\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15</text><line x1=\"640\" y1=\"196\" x2=\"640\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"640\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><line x1=\"200\" y1=\"196\" x2=\"662\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"431.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutes the cluster is billed, with the lesson's illustrative five-minute start</text><rect x=\"200\" y=\"14\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"218\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cluster starting</text><rect x=\"340\" y=\"14\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"358\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">data flow working</text><rect x=\"480\" y=\"14\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"/><text x=\"498\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">kept warm, idle</text></svg>", "caption": "The same two data flows, billed two ways. Keeping the cluster warm saved the second start and paid for ten idle minutes; for two flows back to back, that is the worse bet."}
```

**The time to live made this night dearer**, because the second flow started right after the first
and the ten idle minutes at the end cost more than the second start saved. It pays when several flows
start at different moments within the window, and costs when the pipeline is two steps long. The
setting is a bet on how close together the work arrives, and it is worth doing this sum with the real
price and the pipeline's real timings before making it.

## The same clock, for notebooks

**A Spark pool in Synapse pauses itself after a set number of idle minutes**, and a notebook that
starts on a paused pool waits for it to start, the same cold start under another name. The pool is
billed per vCore-hour while it runs, idle minutes included. **Fabric keeps starter pools warm**, so a
notebook session there starts in seconds and its time is paid out of the capacity of lesson 17, smoothed
over the day. **Databricks**, lesson 21, has the same choice in more forms: clusters that terminate
after idle minutes, pools of machines kept ready, and serverless compute where the provider keeps the
warmth and bills only the work.

The question is the same in each: **how many minutes a night does the cluster run while nobody is
using it, and what is that worth to the person waiting**. For a night that runs at three in the
morning, nobody is waiting, and a cold start is free in the sense that matters.
