---
title: What a service mesh does
version: 1
---

Every signal in this course was produced by the shop's own code: a counter in `web.py`, a span opened
by hand, a log line with a trace id. **A service mesh produces a set of signals the code never
mentions**, because it sits where the code cannot: in the network path between services.

The mechanism is a proxy beside every service. Each request leaves through the caller's proxy and
arrives through the callee's, and the two proxies can do anything a proxy can:

| | what the proxy does | what that replaces in the code |
|---|---|---|
| telemetry | counts and times every request, by source and destination | `web.py`'s counter and histogram, for HTTP |
| retries and timeouts | retries a failed call, gives up after a deadline | retry loops and timeouts in every client |
| encryption and identity | mutual TLS between proxies, with a certificate per workload | TLS configuration per service |
| traffic control | sends 5% to a new version, mirrors traffic, fails over | load-balancer rules |

A mesh has two halves. The **data plane** is the proxies, which carry every request. The **control
plane** configures them: it hands each proxy its routes, its certificates and its policies. In Istio
the proxies are Envoy and the control plane is `istiod`; in Linkerd the proxy is a small one written
in Rust for the purpose.

What a mesh cannot do is equally important. **It sees requests, not meaning.** It knows that
`orders` called `payments` and got a 503 in 400 ms. It does not know which product was bought, which
customer it was, or that the 503 was a card network refusing. Spans from inside the code, lesson 2's
attributes and lesson 8's log fields still carry everything the business cares about. A mesh adds a
uniform layer of network signals under them; it does not replace them.

It also cannot trace by itself. The proxies record spans, but joining them into one trace needs the
`traceparent` header from lesson 4 to be passed from an incoming request to the outgoing one, and
only the application knows which outgoing call belongs to which incoming request.
