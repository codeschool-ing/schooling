---
title: Three questions with different consequences
version: 1
---

"Is the service healthy?" sounds like one question. **It is three, asked by different machines, and
each answer triggers a different action**, which is why a single `/health` that answers all three
ends up answering none of them well.

| question | asked by | if the answer is no |
|---|---|---|
| **liveness**: is the process stuck beyond recovery? | Kubernetes | the container is killed and started again |
| **readiness**: can it serve a request right now? | Kubernetes, load balancers | traffic stops going to it until it says yes |
| **startup**: has it finished starting? | Kubernetes | the other two probes wait |

The consequences decide what each probe may check. **A restart fixes only what is wrong inside the
process**: a deadlock, a leak that has eaten the memory, a thread pool that is stuck. So liveness
should check that the process can answer at all, and nothing outside it. A restart cannot bring a
database back, and the worst demonstration in this lesson is a liveness probe that tries.

**Readiness is about traffic**, and it may look further: a service that cannot reach its database
cannot take an order, and sending it orders only produces errors. Taking it out of rotation lets
the load balancer send the request to a copy that can.

There is a fourth asker with no restart button and no traffic to move: **the probe from outside**.
The blackbox exporter of lesson 5 asks the storefront's `/health` every fifteen seconds, and a
synthetic check from another country does the same for a hosted product. It decides nothing by
itself; it is a measurement, and it is only as good as the question it asks.
