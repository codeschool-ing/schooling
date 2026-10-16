---
title: An indicator, counted from what customers see
version: 1
---

Lesson 10's alarms ask whether something is wrong right now. A **service level objective** asks a
different question: over a month, **was the service as reliable as we promised, and how much room is
left?** It begins with an indicator, and the common mistake is to pick one that is easy to measure
rather than one customers feel. CPU at 40% is easy; nobody has ever left a shop because of it.

A **service level indicator** is a ratio of events:

> SLI = good events / valid events

For the shop's API, two of them cover what customers feel:

| SLI | a valid event | a good event |
|---|---|---|
| availability | a request to the API, health checks excluded | a request answered without a 5xx |
| latency | the same | a request answered in under 300 ms |

Three choices hide in those two lines, and each changes the number:

- **what counts as valid**: health checks, internal callers and bots are traffic, and not customers;
  counting them inflates both the numerator and the denominator with easy successes;
- **where it is measured**: at the load balancer, a request the API never received because the task was
  dead is a 502 and counts; measured in the API's own code, it is invisible;
- **what counts as good**: a 4xx is the customer's mistake and usually good for the service; a 429 the
  service sent because it was overloaded is arguably bad.

**Measure at the edge closest to the customer**, in counts, and keep the definitions in a document the
team agreed to, because an SLI that changes definition when it looks bad measures nothing.

## Counts, not averages

Both indicators are counts of requests, which is why the shop publishes `Requests` and `Errors` as
sums per minute. A latency SLI is counted the same way, requests under the threshold over all requests,
and not as an average latency: lesson 8 showed what an average hides. On a load balancer, the request
counts and the 5xx counts already exist as metrics, free.
