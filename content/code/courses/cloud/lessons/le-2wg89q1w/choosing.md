---
title: "Choosing: control, work and the way out"
version: 1
---

There is no best model, and the belief that there is, usually "serverless is the future" or "real
engineers run their own machines", is the thing to leave behind. **Each step up the line removes work
and removes control, and it removes them together, row by row.** The choice is which rows you need to
hold. Three questions decide it.

## Which rows do you need to control?

Walk up the stack and ask, for each row, whether anything about your system needs it to be yours.

A program that needs a specific operating system, a kernel setting, a system package no platform
installs, or a process that runs for days needs the operating system row, and that means IaaS. An
ordinary web application in a supported language needs nothing below its own code, and a platform will
run it. A job that is the same for every business, such as email, a calendar, a helpdesk or a standard
shop, needs no row below the data, and a finished product does it.

**If you cannot name a reason to hold a row, somebody else can run it**, and they have probably done it
more times than you have.

## What can you take with you?

Leaving a provider is rare, but its cost is decided on the day you choose the model, not the day you
leave.

On IaaS, a machine running Ubuntu, PostgreSQL and your application runs the same way on any provider
that rents virtual machines, and lesson 3 names several. Moving it is work, but it is the same work
everywhere. On PaaS, an application written to ordinary conventions, one that listens on a port and
reads its settings from environment variables, moves with modest changes; the platform's own build
files, add-ons and services have to be redone for the next one. On SaaS you take what the export gives
you and rebuild everything else by hand.

Being tied to a provider this way is called **lock-in**. It is not a defect to avoid at any price: a
managed service can save more work than a move would ever cost. It is a price, and it is cheaper to
know it before you sign.

## Where does the cost go?

A platform charges for the jobs it does. Per unit of computing, a platform or a managed database usually
costs more than a virtual machine of the same size, because the patching, the restarts and the backups are
in the price. On the course's sheet a small São Paulo machine with a disk and an address came to 18.95
dollars a month. That figure has no hours of anybody's time in it, and the time is where the rest of
the IaaS cost is.

**The cost moves from people to the bill.** For three developers with no one who wants to patch
servers, the platform's higher bill is cheaper than the hours; for a team with somebody whose job is
running machines, and a load that barely changes, virtual machines may cost less in total. Lesson 10 is
about reading the bill; the hours are for you to count.

## A short table

| if this is true of the system | lean towards |
|---|---|
| the job is one every business has: email, documents, a standard shop | SaaS |
| you wrote the application and nobody wants to run servers | PaaS, or functions (lesson 8) |
| it needs its own operating system, system packages or long processes | IaaS |
| it must move between providers with the least rework | IaaS, with software you could run anywhere |
| its data has to stay in Brazil | any model, from a provider with a region there (lesson 9) |

The last row is there because it is a different question. The model says who runs each row; the
**region** says where the rows run, and the two are chosen separately.

Most companies end up with all three at once, one per system, and that is the right outcome rather
than an inconsistency. Draw the line for each system, write down which rows are yours, and make sure
each of them has a name next to it.
