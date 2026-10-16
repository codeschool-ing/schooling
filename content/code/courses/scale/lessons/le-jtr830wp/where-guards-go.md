---
title: Where each guard goes
version: 1
---

The box office has all of its guards in its own code, which is the clearest way to see them. In a
larger system each one usually has a better place, and the general rule is that **the earlier a
request is refused, the cheaper the refusal**.

- **At the edge**: rate limits by address or by account, and admission control. nginx's `limit_req`
  and `limit_conn`, an API gateway, a CDN's bot rules. A request refused there never reached a
  service.
- **In each service**: load shedding, because only the service knows what it is short of, whether
  that is CPU, connections or memory.
- **Around each call to another service**: the timeout and the breaker, because they are about the
  callee's health and the caller is where it shows. Libraries do this for most languages, like
  resilience4j for Java and Polly for .NET, and a service mesh such as Envoy can do it outside the
  code, with connection limits and *outlier detection*, which ejects a misbehaving copy from the
  pool.

## What the buyer sees

A `429` or a `503` is a status for programs. For a person, every guard needs a sentence: *you are
buying too fast, wait a second*, *we are very busy, try again in a moment*, *payments are not
working right now, your seat is not reserved*. Ticketing has a well-known answer for the biggest
on-sales: a **virtual waiting room**, which is load shedding with manners. Instead of refusing the
buyers over capacity, the edge gives each a place in a line and lets them in at the rate the box
office can serve, so the refusal becomes a wait the buyer can see.

Lesson 10 is the caller's side of all this: how to try again without making things worse. Lesson 11
is what to answer, other than an error, when a dependency is down.
