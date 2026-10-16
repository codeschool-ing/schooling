---
title: What it is for, and what it is not
version: 1
---

A number belongs in an operational tool when three things are true: **somebody acts on one customer
at a time, the action depends on the number, and the number is computed from data the tool does not
have.** Lantern's examples:

| who | where they work | what they would see | what they would do differently |
|---|---|---|---|
| the person who calls office customers | the CRM | each office's lifetime value and whether it is still ordering | call the large office that went quiet first |
| support | the help desk | the customer's segment and value beside the ticket | answer a long-standing customer's complaint today, not next week |
| marketing | the e-mail tool | a list of customers whose health is *at risk* | send a win-back offer to them and not to everybody |

Each of those works without reverse ETL — by somebody exporting a spreadsheet — and each is better
with it, because the number on the record is today's and nobody has to remember to export it.

## What it is not

- **It is not a way to change the source.** The CRM receives a copy of a computed field. If the
  customer's address is wrong, the fix is in the shop's system, and the next load and the next sync
  carry it; writing it into the CRM by hand is overwritten at the next sync.
- **It is not real time.** A sync that runs every hour means the CRM is up to an hour behind. For a
  lead score that is fine; for "this customer just paid", the event should go straight from the
  system where it happened.
- **It is not a dashboard.** Sending forty fields to the CRM because they exist gives the salesperson
  forty fields to ignore. Send the few that change an action, which is the same rule as lesson 6's
  three tiles.
