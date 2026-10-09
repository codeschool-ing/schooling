---
title: When it is worth it
version: 1
---

Section 06 showed that cost is rarely the reason for a small team to run its own model. The
reasons that do hold are about **things an API cannot sell you**, and they are worth listing so
that a proposal to self-host can be checked against them.

| reason | what it means | ana's case |
|---|---|---|
| **the data must not leave** | a law, a contract or a customer forbids sending the text to a third party | not today: a business API in a chosen region satisfies her terms |
| **control of time** | the model may not change until you decide (lesson 2 section 06) | partly: a pinned dated identifier gives her most of it |
| **no network** | the model has to work offline, on a device, in a factory, at sea | no |
| **volume** | steady load in the hundreds of thousands of requests a day | no: 400 a day |
| **a model nobody sells** | a fine-tuned model, or an open model no host offers | not yet: lesson 1 section 11 says fine-tuning comes last |
| **latency next to the data** | the model has to sit in the same building as what calls it | no |

Read the table as a filter, not a score. **One row that truly applies can be enough**: a hospital
whose records may not leave the building self-hosts whatever the arithmetic says, and the work in
section 07 is then the price of a requirement rather than a choice.

## Two middle paths

Between "an API from the maker" and "a machine of our own" sit two options that keep some of each:

- **An open model from a host** (lesson 2 section 05). Pay per token, no machine to run, and the
  freedom to move the same weights to another host, or in-house, later. The data does go to the
  host.
- **A dedicated deployment in your own cloud account.** The large clouds rent model endpoints that
  run inside your account and region. The machine is somebody else's work; the data stays in an
  account you control; the bill is per hour.

## What ana writes down

For Lantern Books the decision is short, and she records it in the project so that it can be
revisited when one of its premises moves:

1. **Not self-hosting**, because no row of the table applies.
2. **Revisit** if a contract or a law starts to forbid sending e-mail out, if volume passes a
   hundred thousand a day, or if lesson 5 finds that only a fine-tuned model passes.
3. **Keep the option open**: prefer candidates whose weights are available, all else being equal,
   so that a later move in-house does not mean starting the evaluation again.
