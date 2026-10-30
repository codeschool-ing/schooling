---
title: Metrics, logs and the activity log
version: 1
---

**Azure Monitor is not one store; it is several, and they fill in different ways.** Getting that wrong
is how a team discovers, during its first incident, that the logs it wanted were never kept.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Three kinds of signal. Platform metrics flow from every resource into the metrics store automatically, kept 93 days. Resource logs are produced by every resource and discarded unless a diagnostic setting routes them to a Log Analytics workspace, a storage account or an event hub. The activity log records control-plane operations on the subscription, kept 90 days, and can also be routed to the workspace. Guest data from inside a virtual machine reaches the workspace through the Azure Monitor Agent and a data collection rule.\"><defs><marker id=\"ah-three\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"220\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">a resource</text><text x=\"105\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">platform metrics</text><text x=\"105\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">resource logs</text><text x=\"105\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">activity log</text><text x=\"105\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">inside a VM</text><rect x=\"500\" y=\"70\" width=\"200\" height=\"40\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">metrics store, 93 days</text><rect x=\"500\" y=\"160\" width=\"200\" height=\"50\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Log Analytics workspace</text><path d=\"M190 90 L498 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-three)\"></path><text x=\"345\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">automatic</text><path d=\"M190 140 L498 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-three)\"></path><text x=\"330\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">diagnostic setting</text><path d=\"M190 190 L498 185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-three)\"></path><text x=\"330\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">diagnostic setting</text><path d=\"M190 230 L498 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-three)\"></path><text x=\"345\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">agent + data collection rule</text><text x=\"345\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">otherwise discarded</text></svg>", "caption": "Metrics arrive by themselves. Logs arrive only where something routes them."}
```

**Platform metrics** are numbers every resource emits on its own: an App Service's requests and response
time, a storage account's transactions, a VM's CPU from the host's point of view. They are collected
with nothing to configure, at one-minute granularity for most resources, and kept for **93 days**. They
are cheap to keep and quick to query, and they answer "how much" and "how fast", never "which request".

**Resource logs** are the detailed record of what a resource did: each HTTP request an App Service
served, each query a database ran. Every resource produces them, and **Azure discards them unless a
diagnostic setting routes them somewhere**: a Log Analytics workspace to query, a storage account to keep
cheaply, an event hub to stream to another system. Nothing is routed by default, and nothing routed
before the setting existed can be recovered.

The **activity log** is the subscription's record of control-plane operations: who created, changed or
deleted what, through Resource Manager. Azure keeps it for **90 days** without asking; routing it to a
workspace keeps it longer and makes it queryable beside everything else, which lesson 21 relies on.

What happens **inside** a virtual machine, the guest's own counters and its system log, is none of
these. It is collected by the **Azure Monitor Agent** running in the VM, told what to collect by a
**data collection rule**. The last section of this lesson writes one.

All four end up, when you route them, in the same place: a **Log Analytics workspace**, where they become
tables you query in KQL. Lesson 9 is about the workspace and what it costs; lesson 10 is about the
language.
