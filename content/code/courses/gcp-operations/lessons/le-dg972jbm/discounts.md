---
title: Four ways to pay less for the same machine
version: 1
---

**Compute Engine has one price list and four ways to pay less than it, and they cannot be combined on the same
usage.** Two are automatic, two need a decision; one gives up nothing, the others give up flexibility, capacity
guarantees or the ability to stop paying. All four are read here from Compute Engine's pricing page, on 30 October
2026; none can be practised without an account, and the arithmetic of choosing between them, which can, is the
next section.

| discount | what you give up | how much |
|---|---|---|
| **sustained use (SUD)** | nothing: it is automatic | up to 30% net for a resource used the whole month, on the machine types that receive it |
| **resource-based commitment** | a fixed amount of vCPU and memory, in one region, paid for 1 or 3 years whether used or not | up to 37% for 1 year; 55% for 3 years (70% for memory-optimised types) |
| **Compute flexible commitment** (spend-based) | a fixed hourly spend, paid for 1 or 3 years, usable across machine families and regions | 28% for 1 year, 46% for 3 years, on the committed spend |
| **Spot VMs** | the machine: Google can stop it at any time with 30 seconds' warning | up to 91% off the on-demand price, varying up to once a day |

Three things the table cannot say, which decide most choices:

- **A commitment is paid whether or not anything runs.** It is a contract for the term, and it cannot be cancelled.
  A commitment to eight machines when four are running pays for eight.
- **The discounts do not stack.** A resource covered by a commitment receives no sustained use discount, so the
  SUD a team was already getting is subtracted from what a commitment saves them.
- **Spot is for work that can be interrupted**: batch jobs, test runners, the CI of lesson 1 on private pools. An
  API that serves customers is not that, whatever the discount.

## Where the shop's money goes

The shop's API runs on Cloud Run, which is billed per request and per second of instance time, not by the machine.
Compute flexible commitments cover Cloud Run as well as Compute Engine, which is why the spend-based kind is the one
that matters for the shop; the resource-based kind covers Compute Engine machines, which the shop has only for its
batch work. The next section's fleet is that batch work, and the reasoning is the same for either kind: commit to
what is always running, never to the peak.
