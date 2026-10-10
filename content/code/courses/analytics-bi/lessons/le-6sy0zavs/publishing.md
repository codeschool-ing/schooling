---
title: Publishing, sharing and keeping it fresh
version: 1
---

A report on one person's computer is a draft. It becomes useful when it is **published** to the
Power BI service, where other people open it in a browser, and that step is where Power BI stops
being free.

## Licences, in words

The details and prices change, and Microsoft's own pages are the reference. The shape, at the time
of writing:

- **Power BI Desktop is free**, and so is building reports in it.
- **Publishing and sharing need a paid licence per person.** The standard one is *Power BI Pro*;
  people who share a report with each other each need one.
- **A capacity** — a block of computing an organisation buys, now sold as part of Microsoft Fabric —
  changes the arithmetic for readers: above a certain size, people who only read reports need no
  licence of their own, and the authors still do.

This is the cost lesson 1 warned about, and the reason no lesson of this course depends on it.

## Workspaces and apps

Reports are published into a **workspace**, a shared folder with members who may edit, contribute
or only read. Teams usually keep one workspace per subject — sales, finance — and publish a
finished, read-only selection of its reports to the people who need them as an **app**. A report
published to somebody's personal workspace, *My workspace*, is visible only to them, and is the
first place good reports go to be forgotten.

## Refresh, and the gateway

A model in Import mode is a copy, and a copy goes stale. The service can **refresh** it on a
schedule, by running the Power Query steps again against the source. That only works if the service
can reach the source. A database on the internet it can reach; a database inside a company's
network, or inside your virtual machine, it cannot, and the bridge is the **on-premises data
gateway**: a program installed on a computer inside the network, which the service asks to run the
refresh on its behalf. Without one, a published report from a private database shows the data as it
was on the day it was published, for as long as anybody looks at it.

## One model, many reports

The semantic model can be published once and used by many reports, including reports built by other
people in the service. That is lesson 3's idea in Power BI's terms: **the measures are written once,
in the model, and every report on it inherits the same definition of net revenue.** A company where
every analyst publishes a `.pbix` with its own copy of the model has forty definitions of revenue
again, in a tool that makes them look identical.
