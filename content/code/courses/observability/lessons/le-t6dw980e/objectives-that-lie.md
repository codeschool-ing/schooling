---
title: Objectives that lie
version: 1
---

An SLO is a number that a team, and often its managers, will trust without looking underneath it.
That makes the ways it can be wrong worth knowing by name:

- **Counting the wrong events.** Probes, retries and a load test inflate the good events; the
  indicators section showed `/ready` doing it. A rise in traffic that is not customers makes a bad
  week look better.
- **Measuring too far inside.** An SLI at `orders` cannot see the storefront failing on its own, and
  an SLI at the storefront cannot see the DNS, the certificate or the CDN in front of it. The closer
  to the customer, the truer; lesson 14's synthetic checkout is the closest a team usually gets.
- **Averaging across what matters differently.** One SLI over every route lets a thousand successful
  product-page views hide fifty failed checkouts. The routes that carry money, or a promise, get
  their own.
- **Too little traffic.** At ten checkouts an hour one failure is a ten per cent error ratio. An
  objective on a quiet service needs a longer window, a synthetic check, or both.
- **An objective nobody missed in a year.** A budget that is never spent is not proof of a reliable
  service; it is usually proof of a loose objective. Tighten it until it means something, or stop
  paying for the reliability nobody needs.

**And the objective is not the goal.** A team that tunes its SLI to look good, by moving the
threshold, excluding a route or relabelling a failure as the customer's fault, has a green dashboard
and the same unhappy customers. The SLO is only useful while it agrees with what customers say; when
the two disagree, it is the SLO that is wrong.
