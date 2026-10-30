---
title: The workspace, and the two halves it is split into
version: 1
---

**Azure Databricks is Databricks' Spark platform, sold and billed through Azure as an Azure service,
and a workspace is where everything in it happens.** Notebooks, jobs, clusters, SQL warehouses and
the catalogue of tables all belong to a workspace, and a workspace is an Azure resource in a resource
group, created like any other. This section and most of this lesson are taught from Microsoft's and
Databricks' documentation and were not run; the third section checks a workspace's declaration with
Terraform, offline.

## Two planes

**A workspace is split between Databricks' side and yours**, and knowing which half a thing lives in
answers most questions about security and cost:

- **the control plane** runs in an Azure account that Databricks operates: the web application, the
  notebooks' text, the job scheduler, the cluster manager and the catalogue's metadata. You never see
  its machines.
- **the classic compute plane** runs in your subscription: the virtual machines of every cluster,
  their disks and their network. The data the clusters read stays in your storage accounts, and the
  machines that read it are billed to you by Azure.
- **the serverless compute plane** runs in Databricks' account, in the same region: compute that
  Databricks starts and keeps warm for you, and bills as one line, with no machine of yours behind it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"Two dashed boundaries. On the left, Databricks' Azure account holds the control plane, with the web application, the notebooks' text, the job scheduler, the cluster manager and the catalogue metadata, and the serverless compute plane, warm compute Databricks runs and bills as one line in DBUs. On the right, your subscription holds the classic compute plane, the clusters' machines in a managed resource group or in two subnets of your network, billed by Azure plus DBUs, and your storage account stquitandalakeprd, read where it is by either compute plane. The classic machines connect outwards to the control plane.\" data-fig=\"l21-planes\"><defs><marker id=\"l21-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Databricks' Azure account</text><rect x=\"40\" y=\"54\" width=\"290\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"185\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">control plane</text><text x=\"185\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">web application, notebooks' text</text><text x=\"185\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">job scheduler, cluster manager</text><text x=\"185\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">catalogue metadata</text><rect x=\"40\" y=\"168\" width=\"290\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"185\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">serverless compute plane</text><text x=\"185\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">warm compute Databricks runs</text><text x=\"185\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">billed as one line, in DBUs</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"382\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">your subscription</text><rect x=\"390\" y=\"54\" width=\"290\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"535\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">classic compute plane</text><text x=\"535\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cluster machines, in a managed resource group</text><text x=\"535\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">or in two subnets of your network</text><text x=\"535\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">billed by Azure, plus DBUs</text><rect x=\"390\" y=\"168\" width=\"290\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"535\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">your storage</text><text x=\"535\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">stquitandalakeprd</text><text x=\"535\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read where it is, by either compute plane</text><line x1=\"535\" y1=\"150\" x2=\"535\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21-ah)\"/><line x1=\"330\" y1=\"210\" x2=\"388\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21-ah)\"/><line x1=\"388\" y1=\"100\" x2=\"332\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" marker-end=\"url(#l21-ah)\"/><text x=\"359\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">outwards</text></svg>", "caption": "Where each part of a workspace runs. The data never moves into Databricks' account; what changes between classic and serverless is whose machines read it, and who bills for them."}
```

**The classic compute plane lives in a managed resource group** that the workspace creates, with a
name you choose or one Azure makes up. You can see its machines there and you cannot change them: a
deny assignment stops anybody, owners included, from editing what Databricks manages. That is the
first surprise for a team new to Databricks, and the right one, because a machine somebody "fixed" by
hand is a cluster that fails in a way nobody can explain.

## The network

**By default a workspace creates its own virtual network inside the managed resource group.** For a
company that wants the clusters inside its own network, next to a private endpoint of the storage
account, or behind its firewall, Azure Databricks supports **VNet injection**: the workspace is given
two subnets of a virtual network you own, delegated to Databricks, and puts the clusters' machines in
them. With **secure cluster connectivity**, `no_public_ip` in Terraform, the machines have no public
address at all, and open their connection to the control plane outwards.

**VNet injection is decided when the workspace is created** and cannot be added afterwards, which is
why the next section declares it from the start. Two subnets that are too small cap how many
machines the workspace can ever run, and Databricks' documentation has a table of sizes for that
arithmetic.

## The tiers

A workspace has a pricing tier, which Terraform calls its `sku`: `standard`, `premium` or `trial`.
**Premium is the one this lesson assumes**, because Unity Catalog, the subject of the sixth section,
and the finer access controls on clusters, jobs and notebooks need it. The tier changes the price of
every DBU, the unit the fifth section prices.
