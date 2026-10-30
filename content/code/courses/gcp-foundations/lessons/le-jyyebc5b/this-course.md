---
title: What this course is, and the Google Cloud it runs against
version: 1
---

This course is the ground floor of Google Cloud: **how the estate is arranged, who may do what in
it, what the bill says and how a packet gets from one place to another**. It assumes the `cloud`
course, or what it teaches, so a region, a virtual machine and an access policy are words you
already have. What this course adds is the way Google Cloud in particular builds them, under the
names its documentation, its command line and its job adverts use.

Twenty-six lessons, in four parts:

| lessons | what they cover |
|---|---|
| 1 to 4 | where things are, and what holds them: regions and zones, the resource hierarchy, projects, organisation policies |
| 5 to 10 | identity: principals, roles, how a request is judged, service accounts, federation without a key, the directory behind it all |
| 11 to 14 | money: billing accounts, budgets, reading a bill, and the export that says who spent what |
| 15 to 26 | the network, and the tools: the VPC, firewall rules, routes and NAT, sharing a network, DNS, load balancers, the road from a datacentre, the command line, Cloud Shell, the API under all of it, the inventory, and the three ways of driving one API |

## No Google account

**Nothing in this course needs a Google Cloud account, a card or a credential.** An account costs
money the moment something is left running, and a lesson recorded against one account would be the
record of one afternoon in it. So the lessons run against what Google itself publishes for working
without one:

- **the Google Cloud CLI**, `gcloud`, the real program, version 589.0.0;
- **the Pub/Sub emulator**, which Google ships as part of that CLI: a program on your own computer
  that answers the Pub/Sub API the way the service does;
- **Terraform**, with Google's own provider, which reads a description of an estate and says,
  without touching anything, exactly what it would ask Google to create.

The same arrangement serves the three Google Cloud courses that follow this one, `gcp-compute`,
`gcp-operations` and `gcp-data`. This lesson builds it once, and each of those courses opens by
checking that yours still answers.

::: track cloud-engineering
In your track `gcp-compute` and `gcp-operations` come next, and both run against the lab you build
here. Keep `~/gcp` when you finish: the next course checks it rather than building it again.
:::

::: track data
In your track `gcp-data` comes next, and it runs against the lab you build here. Keep `~/gcp` when
you finish: that course checks it rather than building it again.
:::

::: track devops
In your track this is the one Google Cloud course, so it has to stand on its own, and it does:
nothing in it waits for a later course to explain it.
:::

::: track *
If you go on to `gcp-compute`, `gcp-operations` or `gcp-data`, each runs against the lab you build
here. Keep `~/gcp` when you finish, and they will check it rather than build it again.
:::

## What the lab cannot do

**Most of Google Cloud has no emulator**, and a course that hid that would teach the wrong thing.
Google publishes emulators for a handful of data services, Pub/Sub among them. It publishes none for
the part this course is about: projects, folders and organisations, IAM, billing, networks, DNS,
load balancers. Nothing on your computer can answer `gcloud projects create` the way Google would, and
this course will not pretend that something does. So the lessons work in three registers, and each
section says which one it is in:

- **Run.** Every command in a terminal block was typed in a lab built exactly the way the next three
  sections tell you to build yours, and its output is pasted as the machine printed it. The prompt
  reads `ana@laptop:~/gcp$`. What runs is `gcloud` itself, the emulator, Terraform and its plans,
  and the real Google API refusing a request that carries no real credential, which it does in its
  own words.
- **Planned.** Terraform's Google provider knows every field of every resource this course meets,
  and `terraform plan` checks a description against all of them without contacting Google. A plan is
  a real answer from a real program. **It is not Google's answer**: a plan that passes can still be
  refused by an organisation policy, a quota or a missing permission, and the lessons say where.
- **Read.** What neither can show is taught from Google's documentation, and **the section says
  plainly that this part was not run**. There is no transcript in it and no output invented to fill
  one.

**There is no console in this course either.** No screenshots of it, and no drawing of one: a
console is redesigned on Google's schedule, and an imitation of it would be a fake. Where the
console matters, a lesson says in words what you will find there.

## A real account, if you want one

You never need one here. If you do want to try what you learnt against Google Cloud itself, the
section **"A real account, and the order to protect it in"** below says how to open one safely. It
puts protecting the account before anything else, for a reason: the first hour of a new account is
when it is cheapest to protect and most expensive to leave open.
