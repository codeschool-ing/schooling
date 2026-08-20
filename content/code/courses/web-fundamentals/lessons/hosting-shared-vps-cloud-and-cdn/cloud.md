---
title: Cloud: paying for what you use
---

The cloud — AWS, Azure, Google Cloud and the like — sells **resources on demand**: you create ten servers in a minute and destroy them in another, paying for the time they existed. It is the same idea as a VPS taken to the extreme of elasticity, with a catalogue of ready-made services around it (managed database, queue, storage, authentication).

The real advantage is following demand that varies: a shop that triples its traffic on Black Friday adds capacity that day and gives it back the following week. A shop with steady traffic gains nothing from it — and probably pays more than it would on a VPS.

The two costs that surprise newcomers: **outbound data transfer** is usually billed and vanishes from the initial estimate, and complexity climbs fast. A badly sized cloud architecture is more expensive and more fragile than one well-tended machine.
