---
title: What the edge costs
version: 1
---

A file of under two kilobytes that answers without a network sounds like the best of the three.
**The edge moves three problems onto the device, and none of them gets easier there.**

**The features.** `edge.py` read them from a CSV. A real device has to compute `recency_days`,
`visits_180d` and the rest itself, from data it holds, with code that is not `features.py`. That is
exactly the second implementation lesson 5 warned about, now running on hardware you cannot reach.
A till knows today's purchase, not a member's last 180 days, so many features cannot be computed on
a device at all, and a model that needs them cannot go there.

**The updates.** Moving the alias changes what the batch job and the service load tonight. A model
on ten thousand phones changes when ten thousand people update an app, so for months several
versions answer at once, and every report has to know which device ran which.

**The evidence.** A batch writes every score to a table and a service can log every request. A
device's answers stay on the device unless it sends them back, and lesson 9's monitoring depends
on those answers and on what happened afterwards.

**So the edge is chosen for a reason the other two cannot meet**: no network, a deadline shorter
than a round trip, or data that must not leave the device. For Ponto Final's lapse model none of
those holds, and the file is a demonstration rather than a plan. For a till that recommends a book
from what is in the basket now, with the shop's connection down, it would be the right answer.
