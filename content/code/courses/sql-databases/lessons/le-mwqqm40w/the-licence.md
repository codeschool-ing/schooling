---
title: The licence, which decides more than the engine does
version: 1
---

This section is second rather than last because it explains most of what is otherwise puzzling
about an Oracle system. Anything in this lesson that reads like a strange engineering choice is
usually a reasonable answer to a question about money.

## You are licensed per core, and the core is counted with a factor

The metric that matters for a server is **Processor**. It is not a count of sockets and not a
count of machines. You take the physical cores in the machine, multiply by a **core factor** that
Oracle publishes per processor family — 0.5 for ordinary x86 chips, other values elsewhere — and
round up. Two sockets of sixteen cores is thirty-two cores, times 0.5, is sixteen processor
licences.

For a small population of known users there is a second metric, **Named User Plus**, with a
published minimum per processor. It is the right answer for an internal system with forty users
and the wrong one for anything a customer can reach.

Two consequences fall straight out of the arithmetic, and they are the ones that shape systems:

**A faster server costs more.** Not in hardware — in licence. Doubling the cores to halve a report
doubles the licence. The usual response is to tune the query, which is a good response, and it is
being made for a reason that is not engineering.

**A second server costs the same again.** A standby, a reporting replica, a test environment that
somebody wants to be production-sized — each is another licence unless it qualifies for one of the
narrow exceptions Oracle publishes. This is why a corporate Oracle system often has **no reporting
replica**, and why reports run against the same instance the application uses, at night, which is
the condition lesson 10's advice was written for.

## The features are priced separately, and one of them is the tuning tool

This is the part that catches developers, because these are not exotic add-ons. They are things
that are simply *in* PostgreSQL:

| option | what it does | what it is in PostgreSQL |
|---|---|---|
| Partitioning | splits a large table by range or list | built in |
| Diagnostics Pack | AWR and ASH: the performance history and the session sampler | `pg_stat_statements`, built in |
| Tuning Pack | the advisors that recommend indexes and rewrites | no equivalent, and no charge for not having one |
| Advanced Compression | compresses table data | built in |
| Real Application Clusters | several machines opening one database | no equivalent |
| Active Data Guard | a standby you may read from | a streaming replica, built in |
| In-Memory | a column store in memory | no equivalent |
| Advanced Security | transparent encryption at rest, redaction | encryption built in, redaction not |

**The Diagnostics Pack row is the one to remember.** The Automatic Workload Repository is how you
find out which query is slow on Oracle: it is that engine's answer to the first section of lesson
10. On an unlicensed system, querying its views is a licence violation rather than a technical
error. The views are present and will answer; the contract says you may not ask.

So *"has anybody looked at the AWR report"* is a question with three possible answers in a large
organisation, and only one of them is about the report. Either the pack is licensed and somebody
should look, or it is not and the question is a compliance incident, or nobody is certain which.
The third is the most common, and it is why the DBA is the person to ask rather than the person
to work around.

## The audit

Oracle audits its customers, and the contract gives it the right to. An audit that finds an
unlicensed option in use — including one that got switched on by a default, or by a tool, or by
somebody trying it once — produces a bill for the licences plus back support. That is the
mechanism, and it is why the culture around an Oracle installation is more careful than the one
around a PostgreSQL installation, and why a developer asking to enable something is asked why
rather than told yes.

**None of that is a reason to be timid, and it is a reason to ask.** The people who run the system
know which options are licensed. They are answering that question anyway.

## What it costs, and how to find out

Oracle publishes a price list, and the structure is stable even though the numbers move: a
perpetual licence fee per processor for the edition, a percentage of that fee per year for
support, and a separate per-processor fee for each option. Enterprise Edition's per-processor
licence has been in the tens of thousands of dollars for many years, with annual support around a
fifth of it, and each significant option adds a substantial fraction on top.

**Look it up rather than trusting a number in a lesson** — including this one. What is worth
carrying is the shape: the licence is per core, the support is annual and recurring, the options
are extra, and a second environment is a second bill.

## Why this is in a course about SQL

Because it answers questions that otherwise look like bad engineering, and a developer who cannot
read those answers will spend a year proposing things that are already understood:

- **why the business logic is in the database.** The licence is paid; the application servers are
  cheap. The next section is about what that looks like.
- **why there is no reporting replica**, and why reports run at night on the production instance.
- **why the test environment is smaller**, and why a plan that is fine there is not evidence.
- **why nobody has run the tuning advisor.** It may be an option nobody bought.
- **why migrating off is a project with a budget**, discussed in the last section, rather than a
  weekend.

Every one of those is a technical-sounding sentence whose real subject is a contract.
