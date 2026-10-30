---
title: Integration runtimes: where the copy actually happens
version: 1
---

**An integration runtime is the machinery that runs a factory's activities, and choosing one is
choosing which network the data travels through.** The factory itself only stores definitions and
schedules; when a copy starts, it is an integration runtime that opens the source, reads, converts
and writes. There are three kinds. This section is taught from Microsoft's documentation and was not
run.

## The Azure integration runtime

**The Azure integration runtime is managed by Microsoft, runs in Azure, and is there in every factory
without being created**: it is the `AutoResolveIntegrationRuntime` that a linked service uses when it
names no other. It reaches anything with a public endpoint, and with a managed virtual network turned
on it reaches stores through private endpoints instead, which is the arrangement a company that has
closed its storage accounts to the internet needs.

**A copy on it is sized in data integration units, DIUs**, Microsoft's measure of processor, memory
and network for one copy. Data Factory picks a number per copy unless you set one, and a large copy
between two cloud stores gets faster, roughly in proportion, with more of them, up to the point where
the source or the sink cannot keep up. DIUs are also what the copy is billed by, per DIU-hour, which
makes the setting a choice between a fast night and a cheap one.

"AutoResolve" means the runtime runs in a region Data Factory chooses, near the sink. For Quitanda,
whose stores are all in `brazilsouth`, that is where the copy runs. A company that must be able to say
in which country its data was processed is safer with an Azure runtime pinned to a region, which
`azurerm_data_factory_integration_runtime_azure` declares with its `location`.

## The self-hosted integration runtime

**A self-hosted integration runtime is software you install on a Windows machine of your own, inside
the network where a store lives that Azure cannot reach.** Quitanda's old stock system runs on a SQL
Server in the warehouse in Guarulhos, behind the company's firewall. The factory cannot open a
connection into that network, so a machine inside it runs the runtime, which opens connections
outwards, over HTTPS, to Data Factory, asks for work, reads the SQL Server next to it, and sends the
rows to Azure. Nothing has to be opened in the firewall for traffic coming in.

What it costs is the machine: you install it, patch it, keep it running, and make sure a reboot on the
night of the load does not become a missed day. Microsoft documents up to four nodes for one
self-hosted runtime, so that one machine can fail and the copy still runs; the same machines can
serve several factories. The runtime's software updates itself by default, which is worth knowing
before the first time a copy changes behaviour overnight.

## The Azure-SSIS integration runtime

**The third kind exists for one reason: SQL Server Integration Services packages.** A company that
spent ten years writing SSIS packages on its own servers can run them unchanged on a cluster of Azure
machines that Data Factory manages, started and stopped like a pool, billed per node per hour while it
runs. It is a way of moving a legacy to the cloud without rewriting it, and a new pipeline has no
reason to use it.

## Choosing

| the store is | the runtime |
|---|---|
| an Azure service or anything with a public endpoint | the Azure runtime, as it comes |
| an Azure service closed to the internet, behind a private endpoint | the Azure runtime with a managed virtual network |
| on a company's own network, or a virtual network the factory cannot reach | a self-hosted runtime, on a machine inside that network |
| an SSIS package somebody already wrote | the Azure-SSIS runtime |

A single pipeline can use more than one: Quitanda's stock copy runs on the self-hosted runtime in
Guarulhos and lands in the lake, and the copy that follows, from raw to curated, runs on the Azure
runtime, because nothing in it ever leaves Azure.
