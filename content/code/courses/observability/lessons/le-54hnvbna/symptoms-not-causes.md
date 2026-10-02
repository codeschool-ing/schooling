---
title: Page on symptoms, not on causes
version: 1
---

Lesson 5 ended with an alert called `PaymentsFailing`: more than 2% of charges failing for two
minutes, severity `page`. It works, and it is the kind of alert this lesson replaces. **It pages on a
cause**, one of many things that can go wrong, rather than on what the customer feels.

The difference matters in both directions:

- **A cause can fire with no harm.** If `orders` retried a failed charge, payments could fail 3% of
  first attempts while every checkout succeeded, and `PaymentsFailing` would page somebody for
  nothing.
- **Harm can happen with no cause alerting.** If the database is slow, or the storefront throws on a
  new release, or the queue fills, `PaymentsFailing` says nothing, and a cause alert would have to
  exist for every one of them. The list never ends, and the one missing from it is the one that
  happens.

A **symptom** is what the customer sees, and the shop's is already measured: lesson 15's SLI, the
share of checkouts that did not fail on our side. One alert on it covers every cause at once, the
known ones and the ones nobody has thought of, because it does not care why checkouts failed.

That leaves the causes with a different job. Payments failing, a disk filling, a target that stopped
answering a scrape: these are **tickets**, signals for somebody to look at during working hours, and
the right place to start an investigation once the symptom has paged. Two severities are enough for
most teams:

| severity | means | reaches |
|---|---|---|
| page | customers are hurt now, or will be before morning | a person, immediately, at any hour |
| ticket | something needs attention, and can wait for working hours | a queue that is read every day |

The test for a page is a question about the person receiving it: **is there something they must do
now, that cannot wait until morning?** If the answer is *look at it, probably*, it is a ticket.
