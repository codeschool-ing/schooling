---
title: Deciding on purpose
version: 1
---

Lock-in arrives in two ways. **By accident**, one convenient call at a time, until somebody asks
what it would take to leave and nobody can answer. **On purpose**, when a team chooses a service
knowing what it ties them to, writes that down, and gets something worth the price. The difference
is not which services are used. It is whether the choice was written down.

## One line per dependency

The record is short, and it lives beside the code. For each Google service the shop depends on,
four things:

| what we use | why | what leaving takes | when we look again |
|---|---|---|---|
| Cloud Run for orders and web | scale to zero, no cluster to run | rebuild on any container service; the images move as they are | a need Cloud Run cannot meet, such as a protocol other than HTTP |
| Eventarc and Cloud Storage events for photos | thumbnails without a queue to run | a new trigger; the handler reads CloudEvents | the photo volume makes egress the largest line of the bill |
| Pub/Sub, behind the shop's `events` module | ordering and retries we did not build | rewrite one module | a second provider is needed for any reason |
| Cloud Scheduler and a Cloud Run job for the export | cron without a machine | any scheduler that can call a URL | never, probably; it is the cheapest dependency on the list |
| a one-year commitment on Cloud Run | a lower price | the months left on the term | the month before it renews |

The last column is the one that matters. A dependency without a "look again" condition has stopped
being a decision and become a fact about the system nobody remembers choosing.

## Rules of thumb that hold up

- **Prefer the seam when it costs nothing.** A container instead of a source upload, CloudEvents
  instead of a provider-specific payload, a function the Functions Framework can serve locally.
  These are free portability, and declining them is lock-in with no benefit attached.
- **Accept the proprietary service when it saves you building one**, and wrap it in one module of
  your own. Pub/Sub's delivery guarantees are not worth rebuilding to stay portable.
- **Commit only to what you would run anyway.** A committed use discount on the baseline that has
  run for a year is money saved; on capacity you hope to need it is money promised.
- **Keep the data where you can afford to move it**, and price that move once a year with the
  program of the previous section.

## What this course leaves you

Twenty-three lessons of compute come down to one habit: **choose per service, with numbers, and
write the reasons where the next person will find them.** `gcp-operations` takes the shop from
here: watching it run, paying for it, and keeping it up when something breaks. Everything you
decided in this course is what that course will be watching.
