---
title: Five kinds of lock-in, and where each compute choice sits
version: 1
---

Lock-in is usually spoken of as one thing, a trap a provider sets and a careful team avoids. **It
is five different things, each bought with something you wanted**, and a compute choice carries
some of them and not others. Talking about them separately is what turns "we are locked in to
Azure" from a mood into a list somebody can price.

## The API surface: what your code says

Code written against a provider's interface has to be rewritten to leave it, and this course has
written a good deal of it. The functions of lesson 15 are decorated with Azure's own names: a
queue trigger, a blob output binding, an `AzureWebJobsStorage` setting. The host reads those
decorators and does the retries, the poison queue and the scaling, and no other platform reads
them. The orchestrator of lesson 17 is written against the Durable Functions library and keeps its
history in tables in a storage account, and its replay rules are that library's rules. A Logic Apps
workflow (lesson 19) is a JSON document in Microsoft's workflow definition language, and its
connectors, such as the connection to Outlook that somebody had to sign in to, exist only inside
Logic Apps.

The less obvious API is the one around a container. The image of lesson 7 is portable, and the
files that run it are not: the container group's YAML, the Container App's scale rules and
revisions in Bicep (lesson 8), the App Service plan, site and slot (lesson 18). Each is a format
one Azure service reads.

What you get for it is real. **API lock-in is the price of a managed feature**: the trigger, the
retry and the dead-letter queue that somebody else wrote and operates. The more of the work the
platform does, the more of your code takes the platform's shape, and lesson 15 made that trade on
purpose.

## Data, and the price of moving it

Data is heavy in two senses. Moving it out of Azure is billed by the gigabyte, and moving it
takes time, during which two copies have to be kept in step. The shop's orders, which lesson 21
moved out of memory into a database, and its report files on an Azure Files share get heavier
every month they stay.

This kind belongs to the storage rather than to the compute: the database weighs the same
whether Container Apps or AKS reads it. What the compute decides is how close the code has to
stay to the data. A Container App in `brazilsouth` reading a database in `brazilsouth` crosses no border. Move the app to another provider and leave the database behind, and every query becomes a request across the internet, slower and billed by the gigabyte on the way out.

## Identity: who Entra says you are

The shop's code holds no secret for the storage account, the queue or the registry. Lesson 15 described the function app connecting with a managed identity, and lesson 13 let a pod in AKS present a
Kubernetes token and get an Entra ID token back. Behind every one of those connections is a role
assignment, `azure-foundations` lesson 9's RBAC, naming an identity that exists only in Entra.

That is the safest arrangement this course teaches, and it is also a dependency. **Leaving moves
every connection at once**: each one that Entra vouched for has to be vouched for by something
else, or become the static secret lesson 13 spent a section taking away. Lesson 13 shows where the
line falls. The projected service-account token is Kubernetes' own and travels with the cluster;
the federated credential and the exchange are Entra's and stay behind.

## Operations: what your team knows and the tools it uses

A team that has spent two years with `az`, Bicep and Azure Monitor has knowledge that does not
travel whole. The concepts do, which is why this course teaches them by name: a scale rule, a
revision, a node pool and a slot all have equivalents elsewhere. The details, the failure modes
and the reflexes at three in the morning do not. Nor do the tools: the Bicep files that declare
everything, the queries saved in a Log Analytics workspace, the alerts that page somebody.

**Operational lock-in is the one nobody draws on a diagram**, and for a small team it is often
the largest, because a move costs weeks of three people learning instead of building. It also runs
in both directions. A team of Kubernetes specialists asked to run everything on Functions is
locked out of its own experience as surely as a Functions team is locked in.

## Contracts: what you signed

A reservation or a savings plan buys a lower rate for a commitment of one or three years. A
reservation is for a particular resource, size and region; a savings plan for compute is a fixed
spend per hour that applies across virtual machines, Container Instances, Container Apps, App
Service and the Functions Premium plan, among others. **It is the only kind of lock-in with an end
date written on it**, and the only one that is purely financial: nothing in the code changes.

The two are not equally firm. Microsoft's documentation, read on 2026-10-30, says a savings plan
can't be cancelled, refunded or exchanged for a reservation. A reservation can be exchanged, or
refunded up to a total of 50,000 USD of cancelled commitment in a rolling twelve months. A
three-year savings plan signed in a service's first month is a bet that the service will still
spend that much on Azure compute in its thirty-sixth.

## Where each choice sits

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 378\" role=\"img\" aria-label=\"A table of judgements with seven compute choices as rows and three kinds of lock-in as columns. API: Virtual Machines low, Container Instances low, Container Apps some, AKS low, App Service some, Functions high, Logic Apps high. Operations: Virtual Machines low, Container Instances low, Container Apps some, AKS high, App Service low, Functions some, Logic Apps some. Contract: if you commit for the first five rows, Premium plan only for Functions, none listed for Logic Apps. A note says data and identity are left out because they belong to what the code connects to.\"><text x=\"300\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">API: what your files say</text><text x=\"460\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">operations: what you know</text><text x=\"620\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">contract: what you signed</text><text x=\"30\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Virtual Machines</text><rect x=\"230\" y=\"50\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"390\" y=\"50\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"550\" y=\"50\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Container Instances</text><rect x=\"230\" y=\"94\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"390\" y=\"94\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"550\" y=\"94\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Container Apps</text><rect x=\"230\" y=\"138\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"390\" y=\"138\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"550\" y=\"138\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">AKS</text><rect x=\"230\" y=\"182\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"390\" y=\"182\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">high</text><rect x=\"550\" y=\"182\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App Service</text><rect x=\"230\" y=\"226\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"390\" y=\"226\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"550\" y=\"226\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Functions</text><rect x=\"230\" y=\"270\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">high</text><rect x=\"390\" y=\"270\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"550\" y=\"270\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Premium plan only</text><text x=\"30\" y=\"332\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Logic Apps</text><rect x=\"230\" y=\"314\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"331\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">high</text><rect x=\"390\" y=\"314\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"331\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"550\" y=\"314\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"331\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">none listed</text><text x=\"30\" y=\"364\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">data and identity are left out: they belong to what the code connects to, whatever compute runs it</text></svg>", "caption": "A judgement, row by row: the more a service does for you, the more of your files take its shape. Contracts attach to the bill, wherever a savings plan reaches."}
```

The figure is a judgement, not a measurement, and every row can be argued with. An AKS cluster
that leans on the Application Gateway controller of lesson 14 and on workload identity has more API lock-in than its row says. A fleet of virtual machines built from a gallery image with Azure's
extensions in it has more than its row says. What it shows is the pattern. **The more a service
does for you, the more of your code takes its shape**, and the operational knowledge follows the
service rather than the code. Contracts read the same in every row a savings plan covers, because
they attach to the bill and not to the platform. Of Functions' plans only Premium is on Microsoft's
list, and Logic Apps is not on it at all.

Two consequences carry into the rest of the lesson. Lock-in is a cost to weigh against what it
buys, beside the running cost and the effort to migrate that lesson 21 put in its comparison. And
the API kind can be reduced in one place, the files and the code between your rules and the
provider, which is the next section.
