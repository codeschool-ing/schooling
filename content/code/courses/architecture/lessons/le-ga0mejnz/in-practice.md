---
title: In practice
version: 1
---

Nobody writes their own breaker in production; the lab's is 25 lines so that it could be read. The
libraries that do it, and the places it is configured instead of written:

| where | what it gives you |
| --- | --- |
| Resilience4j (Java), Polly (.NET), Tenacity and Stamina (Python), `cockatiel` (Node.js) | retries with backoff and jitter, circuit breakers, timeouts and bulkheads as decorators around a call |
| the AWS and Google Cloud SDKs | retries on by default, with backoff, jitter and a retry quota, already tuned for their own services |
| gRPC | deadlines carried with every call, retry policies and retry throttling, configured per method |
| Envoy, and service meshes built on it, such as Istio | retries, timeouts and outlier detection (a breaker per instance) in the sidecar, with no code change |

Lesson 3's service mesh is the last row: the sidecar retries for you. That is convenient and it is also
how retries end up at three layers at once, the application's library, the sidecar and the gateway, each
configured by a different person. **Know where your retries are.**

## The deadline that travels

The storm wasted most of its capacity on callers who had left. gRPC's answer is to **send the deadline
with the call**, as the lab's `X-Deadline` header did, and to have every service check it: a request
whose deadline has passed is dropped before any work is done, and a service that calls another passes on
whatever time is left. The lab's service only counted those requests; a service that refused them would
have spent its capacity on callers still waiting.

## A sensible default

For a call from one service to another, before any measurement says otherwise:

1. **A timeout on every call**, from lesson 5, set from the latency the service really has.
2. **Retries only for idempotent operations**, two or three at most, with exponential backoff and full
   jitter, at one layer.
3. **A retry budget**, so retries cannot multiply the load in an outage.
4. **A circuit breaker per dependency**, with a fallback where there is a reasonable one.
5. **Metrics on all of it**: retries, breaker state changes and requests rejected by an open breaker.
   An open breaker that nobody is told about is an outage that looks like a quiet afternoon.

When you are done, stop the lab:

```sh
docker compose down
```
