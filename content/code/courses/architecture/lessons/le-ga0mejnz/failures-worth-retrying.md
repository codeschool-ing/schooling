---
title: Which failures are worth a second try
version: 1
---

Most failures between services are **transient**: a connection dropped by a load balancer that was
being replaced, a service that answered `503` while it restarted, a database that refused a connection
during a failover lasting a few seconds. Trying again a moment later usually works, and a retry is the
cheapest way to hide them from the person waiting.

Some failures are **permanent** for that request: the request is malformed, the order does not exist, the
customer is not allowed to see it. Trying again gets the same answer, and every attempt costs the
service something. The status code says which is which, and it is the first thing a retry policy reads:

| answer | retry? | why |
| --- | --- | --- |
| connection refused or reset, DNS failure | yes | the other side was not there for a moment |
| timeout | yes, if the operation is idempotent | the request may have been done; see below |
| `503 Service Unavailable` | yes | the service says so itself, sometimes with `Retry-After` |
| `429 Too Many Requests` | yes, after the `Retry-After` it gives | it asked you to slow down; lesson 12 is about saying it |
| `500 Internal Server Error` | maybe, once | it might be a bug that fails every time |
| `400`, `401`, `403`, `404`, `409`, `422` | no | the same request will get the same answer |

## A timeout is not a failure, it is an unknown

The row that needs care is the timeout. When a call times out, **the caller does not know whether it
happened**: the request may never have arrived, may be still running, or may have finished a millisecond
after the caller stopped listening. Retrying a read is harmless. Retrying "charge this card" can charge it
twice.

Lesson 7 is the answer, and it applies to every retry, not only to messages: **an operation that will be
retried has to be idempotent**, either by nature ("set the stock to 12") or with an idempotency key the
caller sends again with each attempt, so the service can recognise a repeat. A retry policy on a call
that is not idempotent is a duplicate-charge policy that has not happened yet.

And after the last retry fails, the caller still has to do something: show an error the person can act
on, use a fallback such as a cached value, or put the work on a queue to be done later. "Retry" is never
the whole plan; it is the first line of one.
