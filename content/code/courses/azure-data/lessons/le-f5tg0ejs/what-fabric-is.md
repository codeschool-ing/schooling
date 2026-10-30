---
title: One product, one lake, one bill
version: 1
---

**Microsoft Fabric is not a service you deploy into a subscription, the way Synapse is.** It is one
product, run by Microsoft as software you sign in to, that puts the lake, the warehouse, Spark,
pipelines, streaming and Power BI behind one portal, one store and one bill. Lesson 16's Synapse
workspace was an Azure resource with pools you sized and paused. In Fabric you size one thing, a
capacity, and every workload draws from it.

**This section, and most of this lesson, is taught from Microsoft's documentation and was not
run.** No emulator answers any part of Fabric, and a tenant needs an organisational account. Two
things do run, and each says so where it happens: Terraform checks the declaration of a capacity
offline in the next section, and the sixth section writes the open file format Fabric stores, with
an open library, into Azurite.

## Four levels

Everything in Fabric sits in four levels, and most surprises with it come from confusing two of
them:

- **the tenant** is the organisation, the same Entra ID tenant `azure-foundations` lesson 2
  describes. There is one Fabric per tenant, and one OneLake.
- **a capacity** is the compute that is paid for. It is the one part of Fabric that is an Azure
  resource, created in a subscription and a region, and it has a size, from F2 to F2048. The next
  section is about it.
- **a workspace** is a folder of work with its own members and roles, assigned to one capacity.
  Moving a workspace to another capacity moves where its work is billed, and nothing else.
- **an item** is the thing made: a lakehouse, a warehouse, a notebook, a pipeline, a semantic model,
  a report. Each item that holds data keeps it in OneLake, in a folder named after the item.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"A Fabric tenant drawn as a dashed boundary. Inside it, two capacities: F2, holding the workspace quitanda-dev with the item sales.Lakehouse, and F64, holding the workspace quitanda-analytics with the items sales.Lakehouse, finance.Warehouse and orders.SemanticModel. Below both capacities, one OneLake spans the whole tenant, with a container per workspace and a folder per item, such as quitanda-analytics/sales.Lakehouse/Tables/orders.\" data-fig=\"l17-nesting\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"330\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the Fabric tenant: one per organisation</text><rect x=\"30\" y=\"44\" width=\"240\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"42\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">capacity</text><text x=\"258\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">F2</text><rect x=\"46\" y=\"76\" width=\"208\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"56\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workspace</text><text x=\"244\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-dev</text><rect x=\"62\" y=\"110\" width=\"176\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"150\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">sales.Lakehouse</text><rect x=\"290\" y=\"44\" width=\"400\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"302\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">capacity</text><text x=\"678\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">F64</text><rect x=\"306\" y=\"76\" width=\"368\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"316\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workspace</text><text x=\"664\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-analytics</text><rect x=\"322\" y=\"110\" width=\"200\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"422\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">sales.Lakehouse</text><rect x=\"322\" y=\"140\" width=\"200\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"422\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">finance.Warehouse</text><rect x=\"322\" y=\"170\" width=\"200\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"422\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders.SemanticModel</text><text x=\"598\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">items: each one</text><text x=\"598\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a folder in OneLake</text><text x=\"598\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a report reads</text><text x=\"598\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the tables beside it</text><rect x=\"30\" y=\"250\" width=\"660\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"42\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">OneLake: one per tenant, whatever the capacities</text><text x=\"42\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-dev/sales.Lakehouse/Tables/…</text><text x=\"320\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-analytics/sales.Lakehouse/Tables/orders/</text><text x=\"320\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-analytics/finance.Warehouse/Tables/…</text><text x=\"42\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one container per workspace</text><line x1=\"150\" y1=\"224\" x2=\"150\" y2=\"248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"/><line x1=\"422\" y1=\"200\" x2=\"422\" y2=\"248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"/></svg>", "caption": "A capacity pays for the work and a workspace groups the items. The data of every item, in every workspace, on every capacity, is in the one OneLake underneath."}
```

**A capacity is not a container for data.** Two capacities, one small for development and one
large for production, still write into the same OneLake, and a table in the development workspace
can be read from production through a shortcut, the subject of the section after next. What a
capacity separates is the bill and the noise: a heavy notebook in development cannot slow the
reports in production when the two are on different capacities, and can when they share one.

## What it replaces, and what it does not

**Fabric does not remove Azure's data services; it is another way to buy the same ideas.** A
Fabric warehouse plays the part of lesson 16's dedicated pool, without distributions to choose or a
pool to pause. A lakehouse plays the part of a storage account plus a Spark pool. Data Factory's
pipelines, lesson 19's subject, exist inside Fabric as well as on their own. A company can use
both, and many do: an ADLS Gen2 account that other systems already write to, read from Fabric
without copying.

**The trade is control for one bill.** On Azure's own services every piece is a resource with its
own size, its own network rules, its own price meter and its own Terraform. In Fabric only the
capacity is any of those, and everything else is managed inside the product, in the portal at
`app.fabric.microsoft.com`, by the Fabric administrators of the tenant. A team that wants every
decision in Terraform finds that most of Fabric is outside `azurerm`, which declares the capacity
and nothing inside it.
