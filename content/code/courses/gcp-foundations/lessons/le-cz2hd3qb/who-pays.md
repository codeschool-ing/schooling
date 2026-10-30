---
title: Who pays for what
version: 1
---

**A cost belongs to the project that owns the resource, and the project's billing account pays it.** That
one rule answers most questions, and the exceptions are where bills surprise people. Nothing in this
section was run: there is no bill in the lab, and the rules below are from Google's billing documentation.

## The ordinary case

A virtual machine in `planner-prod` is billed to `planner-prod`, and `planner-prod`'s billing account pays.
A Pub/Sub topic in `planner-dev` is billed to `planner-dev`. Labels, lesson 3, then divide each project's
costs by team or purpose inside the bill. One billing account paying for twenty projects gives one invoice
with twenty projects on it, which is the arrangement most companies want: **one account per legal entity
that pays**, many projects under it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l11-who-pays\" aria-label=\"One billing account, beside the tree rather than in it, paying for three projects in two different folders: planner-prod, planner-dev and planner-network. Each project carries its own costs: planner-prod its machines and the traffic they send, planner-dev its topics, planner-network the Cloud NAT gateway that the other projects' traffic goes through. Labels divide each project's costs by team inside the bill.\"><rect x=\"270.0\" y=\"16.0\" width=\"180.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">billing account</text><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">012345-6789AB-CDEF01</text><path d=\"M360.0 64.0 L110.0 116.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20.0\" y=\"116.0\" width=\"180.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-prod</text><text x=\"110.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">machines, and the</text><text x=\"110.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">traffic they send</text><path d=\"M360.0 64.0 L360.0 116.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"270.0\" y=\"116.0\" width=\"180.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-dev</text><text x=\"360.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">topics</text><path d=\"M360.0 64.0 L610.0 116.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"520.0\" y=\"116.0\" width=\"180.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-network</text><text x=\"610.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the Cloud NAT</text><text x=\"610.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gateway</text><text x=\"360.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">each project linked to one account</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">inside each project, labels divide the costs by team</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the account sits beside the folders, not in them</text></svg>", "caption": "The project carries the cost; its link says which account pays."}
```

## Where it gets interesting

- **Network traffic is billed to the project of the machine that sends it.** The pricing page of lesson 1
  says so in those words. A machine in `planner-prod` sending backups to Santiago pays the 0.14 per GiB,
  not the project that receives them.
- **A shared network splits the bill.** Lesson 18 puts the network in `planner-network` and the machines in
  the projects that use it. The machines, their disks and the traffic they send are billed to the projects
  they live in; resources that belong to the network itself, such as a Cloud NAT gateway or a VPN tunnel,
  are billed to `planner-network`. A team reading only its own project's bill does not see the NAT gateway
  its traffic goes through.
- **Some charges have no project.** Support plans and some marketplace purchases are billed to the billing
  account directly, and appear on the invoice outside every project.
- **Credits are applied before the total.** The free trial's credit, a promotional credit and the
  sustained-use discounts of lesson 13 appear as negative lines against the costs they reduce. A report that
  sums costs without credits overstates the bill; one that sums only the total cannot say what the credits
  covered.

## Several billing accounts

There are good reasons for more than one: **different legal entities**, each paying its own invoice; a
**reseller's sub-accounts**, one per customer, under the reseller's account; or a **sandbox account** with a
low budget and its own card, for experiments that should never land on the production invoice. There is a
bad reason too, splitting one company's costs by team, which labels and the export of lesson 14 do better
without moving any project.

The question "who pays for this?" therefore has two answers in Google Cloud: **which billing account**,
decided by the project's link, and **which team inside it**, decided by labels. The next three lessons are
about reading those two answers off a real bill.
