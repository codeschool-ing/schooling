---
title: What this course is, and the Azure it runs against
version: 1
---

This course is the ground floor of Azure: **how a tenant is divided, who may do what inside it, what
the bill says and how a packet gets from one place to another**. It assumes the `cloud` course, or
what it teaches, so a region, a virtual machine and an access policy are words you already have.
What this course adds is the way Microsoft in particular builds them, under the names its
documentation, its command line and its job adverts use.

Twenty-six lessons, in four parts:

| lessons | what they cover |
|---|---|
| 1 to 5 | where things are, and the containers that hold them: regions, the tenant and its hierarchy, moving resources, Azure Policy, landing zones |
| 6 to 12 | identity: Microsoft Entra ID, service principals, managed identities, role-based access, elevation on demand, conditional access, and the bridge to an office's own directory |
| 13 to 15 | money: budgets, reading a bill, and tags that say who spent what |
| 16 to 26 | the network, and the tools: virtual networks, filters, routes, private endpoints, peering, DNS, load balancers, the road from a datacentre, the command line and the API under it |

## No Azure account, and nothing pretending to be one

**Nothing in this course needs an Azure account, a card or a key.** An account costs money the
moment something is left running, and a lesson recorded against one account would be the record of
one afternoon in it. So the course is built from what runs on your own computer without one.

That is less than you might hope, and it is better to know now. **No program imitates Azure Resource
Manager**, the service every request to create, change or delete something in Azure goes through.
Microsoft publishes emulators for a handful of data services, and the `azure-data` course uses
them; for subscriptions, identities, permissions, networks and bills there is nothing. A course that
wrote a script to answer like Azure and called the answers Azure's would be teaching from a forgery,
so this one does not.

What does run, here and on your machine:

- **the real Azure CLI**, `az`, which knows every command and every parameter, checks what you type,
  and refuses anything that needs an account before it sends a byte;
- **Bicep**, Microsoft's language for describing Azure resources, whose compiler turns a file into
  the exact JSON Resource Manager would receive. Most of what this course builds, it builds in
  Bicep and compiles;
- **Terraform**, with Microsoft's providers for Azure and for Entra ID, which checks a configuration
  against every resource's real schema;
- **the Azure Identity library**, which shows in order every way a program looks for credentials;
- and three things on the internet that answer anybody: **Microsoft Entra ID's sign-in endpoints**,
  which refuse a made-up tenant in their own words, **the public DNS**, where Azure's name servers
  answer, and the published copy of **Azure Policy's built-in definitions**.

**Where a lesson needs Azure itself, it teaches from Microsoft's documentation and says plainly that
the part was not run**: no transcript, and no output written to look like one. Out of the 134
sections in this course, 49 show a transcript or compile a file in the lab; the others are read,
with the lab's answers quoted where they exist. Every command and every line of output in a
terminal was run in a lab built exactly the way the next three sections tell you to build yours.
The prompt reads `ana@laptop:~/azure$`.

The same lab serves the three Azure courses that follow this one, `azure-compute`,
`azure-operations` and `azure-data`. This lesson builds it once, and each of those courses opens by
checking that yours still answers, and adds what it needs.

::: track cloud-engineering
In your track `azure-compute` and `azure-operations` come next, and both start from the lab you
build here. Keep `~/azure` when you finish: the next course checks it rather than building it again.
:::

::: track data
In your track `azure-data` comes next, and it starts from the lab you build here. Keep `~/azure`
when you finish: that course checks it rather than building it again.
:::

::: track devops
In your track this is the one Azure course, so it has to stand on its own, and it does: nothing in
it waits for a later course to explain it.
:::

::: track *
If you go on to `azure-compute`, `azure-operations` or `azure-data`, each starts from the lab you
build here. Keep `~/azure` when you finish, and they will check it rather than build it again.
:::

## What compiling is not

A Bicep file that compiles, or a Terraform configuration that validates, is **a file with the right
shape**. It is not a resource that exists, and three things only Azure can say stay unsaid:

- **whether you are allowed to.** Permissions are judged by Resource Manager when the request
  arrives. Lessons 4, 9 and 10 teach how that judgement works from the documentation;
- **whether the values make sense together.** A subnet larger than its network, a name somebody
  else already took, a size the region does not sell: the compiler checks the type of a value, and
  Azure checks the value;
- **what it costs.** Microsoft publishes its prices through a public API that needs no account.
  Lesson 1's last section shows a short program that reads it, and **the machine this course was
  recorded on could not reach that API**, so no price in these lessons was read by that program.
  Where a lesson needs a number to reason with, it says where the number came from.

## A real account, if you want one

You never need one here. If you do want to try what you learnt against Azure itself, the section
**"A real account, and the order to protect it in"** below says how to open one safely. It puts
protecting the account before anything else, for a reason: the first hour of a new account is when
it is cheapest to protect and most expensive to leave open.
