---
title: An SDK, a proxy, or both
version: 2
---

Lessons 6 and 7 have now put four tools in front of the same assistant. The differences between
them that matter are fewer than their feature lists suggest.

| | Langfuse | LangSmith | Helicone | Phoenix |
|---|---|---|---|---|
| how data arrives | OpenTelemetry or its SDK | its SDK (and OpenTelemetry) | as a proxy, on the wire | OpenTelemetry |
| sees the steps between model calls | yes | yes | no | yes |
| sees calls nobody instrumented | no | no | yes, if every call goes through it | no |
| can act on requests: cache, limit, retry | no | no | yes | no |
| where it ran in this course | your machine, six containers | not run; its SDK against a recorder | not run; one image, 3.5 GB to download | your machine, a Python package |
| licence | open source | proprietary service | open source | open source |

**An SDK and a proxy answer different questions**, and a large system often has both: a gateway in
front of the providers, run by the platform team, for keys, limits, caching and a complete count of
model calls; and tracing inside each application, for the questions a gateway cannot see, the ones
about why. The two meet where lesson 1 said everything meets: if the application passes its trace id
to the gateway in a header, a request in the gateway's logs leads to the trace that made it.

For a single assistant like Marginalia's, built by one team, the tracing is the half that cannot be skipped. The failures this course has found so far were in the search, the floor and the customer's message, and a gateway sees none of those. The gateway is the half to add when there are
several applications and one bill.

Whichever is chosen, the order of questions from lesson 6 still decides it: where the data may go,
who will run it, and only then what it does.
