---
title: "Google Cloud: projects, one network, data and Kubernetes"
version: 1
---

Google came to selling infrastructure from the other end. Its first cloud product, App Engine in
2008, was a platform in the sense of lesson 1: you uploaded an application and Google ran it, with
no machine for you to see. Virtual machines came later, with Compute Engine. Two things Google
built for itself long before it sold them are still what it is known for: **handling very large
amounts of data, and running containers on many machines at once.**

## The project is the box

At Google Cloud, every resource belongs to a **project**. You create a project, link it to a
billing account that pays for it, and build inside it. A project has an id you choose once, such
as `shop-prod-2291`, and that id cannot be changed afterwards, so it is worth choosing well.

Projects can be grouped into folders under an **organisation**, which is tied to the company's
domain. Shutting a project down stops everything inside it at once, and the project is kept for
thirty days in case it was a mistake before it is deleted for good.

Put the three providers' boxes side by side and the difference is in how many levels there are,
not in the idea:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Three columns of nested boxes. AWS: an organization, dashed because it is optional, holds an account, which holds the resources. Azure: a tenant holds a subscription, which holds a resource group, which holds the resources. Google Cloud: an organization holds a folder, dashed because it is optional, which holds a project, which holds the resources. The innermost box of each column is highlighted.\"><defs><marker id=\"unt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">AWS</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"232\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">organization</text><rect x=\"34\" y=\"74\" width=\"172\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"44\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">account</text><rect x=\"44\" y=\"104\" width=\"152\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a VM</text><rect x=\"44\" y=\"130\" width=\"152\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a disk</text><rect x=\"44\" y=\"156\" width=\"152\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a bucket</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Azure</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"232\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">tenant (Entra ID)</text><rect x=\"274\" y=\"74\" width=\"172\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"284\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">subscription</text><rect x=\"288\" y=\"108\" width=\"144\" height=\"148\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"298\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resource group</text><rect x=\"298\" y=\"138\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a VM</text><rect x=\"298\" y=\"164\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a disk</text><rect x=\"298\" y=\"190\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a bucket</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Google Cloud</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"232\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">organization</text><rect x=\"514\" y=\"74\" width=\"172\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"524\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">folder</text><rect x=\"528\" y=\"108\" width=\"144\" height=\"148\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"538\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">project</text><rect x=\"538\" y=\"138\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a VM</text><rect x=\"538\" y=\"164\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a disk</text><rect x=\"538\" y=\"190\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a bucket</text></svg>", "caption": "The box every resource must sit in is highlighted: an account, a resource group, a project. Dashed boxes are optional. The bill attaches to the account, to the subscription, and to a billing account linked to each project."}
```

## One network across the world

This is the difference that changes designs. In AWS a VPC belongs to one region, and so does an
Azure virtual network: a machine in São Paulo and a machine in Frankfurt are on two networks, and
joining them is extra work that lesson 6 names. **In Google Cloud a VPC network is global.** Its
subnets are regional, but one network holds all of them, so a machine in São Paulo
(`southamerica-east1`) and one in Belgium (`europe-west1`) are on the same private network, with no
connection between two networks to build. Firewall rules still decide what may pass.

That does not make the distance shorter: a packet from São Paulo to Belgium still crosses an ocean,
and lesson 9 measures what that costs. What it removes is the plumbing.

## Data and Kubernetes

**BigQuery** is the product that reputation for data rests on. It is a data
warehouse that runs SQL over very large tables with no server to size: you load the data, run a
query, and pay for the data the query reads or for capacity reserved in advance. It is the
serverless idea of lesson 8, applied to analytics.

**Kubernetes came out of Google.** It was designed by Google engineers from what they had learnt
running Borg, the company's internal system for placing containers on machines, and released as
open source in 2014. Google's managed version, GKE, was among the first, and it keeps a reputation
for following the project closely. All three hyperscalers sell managed Kubernetes now, and so do
DigitalOcean and Akamai; the `kubernetes` course is where it is taught.

Google Cloud's regions follow a pattern: a continent and a direction, then a number. The São Paulo
region is `southamerica-east1`. Its functions product was called Cloud Functions until 2024 and is
now **Cloud Run functions**, part of Cloud Run, its service for running containers without managing
servers; older tutorials use the old name.

The `gcp-foundations` course builds on this one with the console, the `gcloud` command and the
organisation's policies. What to keep from here: **the project is the box, the network is global,
and Google's strongest arguments are data and Kubernetes.**
