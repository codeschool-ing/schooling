---
title: Failures that pass
version: 1
---

Lesson 9 ended with the box office answering `502` whenever a charge failed. Many of those
failures were never about the charge. A connection was reset because a copy of payments was being
replaced; a request landed on a copy at the moment it was shedding load; a packet was lost and the
timeout ran out. Tried again a moment later, the same charge would have gone through. These are
**transient failures**, and in a system of many services they are not rare events: they are a
background rate that never reaches zero.

**Retrying** turns a transient failure into a success the buyer never hears about. It is also one
of the easiest ways to make an outage worse, and this lesson is about telling the two apart. A retry
policy answers four questions:

1. **Which failures are worth trying again?** A timeout or a `503` may well succeed next time. A
   `400` will not, and neither will a card that was declined: the answer would be the same.
2. **How many times?** Each attempt costs the caller time and the callee work.
3. **How long to wait between attempts?** Not zero: a service that failed a millisecond ago is
   unlikely to have recovered a millisecond later. Sections 05 and 06.
4. **Is it safe to do the work twice?** A read is. A charge is not, unless the callee can tell that
   the second request is the first one again. Sections 07 and 08.

The last question is the one that matters most and gets asked least. Lesson 9's timeout already
showed the problem: the box office gave up after one second and payments went on to charge the card.
A retry at that moment would have charged it twice.
