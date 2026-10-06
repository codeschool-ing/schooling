---
title: Redshift
version: 1
---

**Amazon Redshift** is AWS's warehouse and the oldest of the three. It began as the classic shared-nothing
MPP cluster of lesson 7 and has moved, in steps, towards separating storage from compute. Today it comes in
two forms:

- **Provisioned clusters**: you choose a node type and a number of nodes, and pay for them by the hour while
  they exist. The current node family, RA3, keeps the data in managed storage backed by object storage and
  caches the hot part on the nodes' local disks, so storage and compute can be sized apart.
- **Redshift Serverless**: no cluster to choose. Capacity is measured in Redshift Processing Units, RPUs,
  scaled up and down by the service, and billed for the time it is used.

Inside, a provisioned cluster still looks like lesson 7's diagram: a **leader node** that receives the SQL,
plans it and combines results, and **compute nodes** that each hold a share of every table, divided further
into **slices**, one per processing unit, each working on its own rows.

That heritage is why Redshift, alone of the three, asks the modeller the questions lesson 7 asked: **which
column decides where each row lives, and in which order rows are stored.** It is the subject of the next
section.
