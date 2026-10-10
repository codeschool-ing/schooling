---
title: The ambassador
version: 1
---

The sidecar stood in front of a service and handled what came **in**. The **ambassador** is the same idea
on the other side: it stands beside a service and handles what goes **out**, to a dependency the
service would rather not deal with directly.

The monolith's checkout calls a payment gateway that needs an API key and is busy every other request.
The monolith's code does neither: it calls `http://localhost:9000/charge` and nothing else. The
ambassador, in the monolith's network namespace, adds the key, forwards to the gateway, and retries a
`503` up to twice. Three checkouts, and the ambassador's log:

```
ana@vm:~/lab/strangler$ for i in 1 2 3; do curl -s -X POST localhost:8080/checkout; done
monolith: checkout done, gateway said charged
monolith: checkout done, gateway said charged
monolith: checkout done, gateway said charged
ana@vm:~/lab/strangler$ docker compose logs ambassador
ambassador-1  | ambassador: POST /charge -> 200 in 40 ms, 1 attempt(s)
ambassador-1  | ambassador: POST /charge -> 200 in 6 ms, 2 attempt(s)
ambassador-1  | ambassador: POST /charge -> 200 in 6 ms, 2 attempt(s)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A box for the monolith&#x27;s network namespace contains the monolith and the ambassador. The monolith calls localhost:9000; the ambassador adds the API key, forwards the call to the external payment gateway, and retries when the gateway answers 503.\"><defs><marker id=\"l15-ambassador-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"460\" height=\"160\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"260\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">one network namespace: the monolith's</text><rect x=\"60\" y=\"95\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">monolith</text><rect x=\"300\" y=\"95\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ambassador</text><text x=\"380\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:9000</text><path d=\"M222 120 L298 120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-ambassador-ah-amber)\"></path><text x=\"260\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost</text><rect x=\"560\" y=\"95\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">gateway</text><path d=\"M462 120 L558 120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-ambassador-ah-amber)\"></path><text x=\"525\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">+ key, retries</text></svg>", "caption": "An ambassador sits on the caller's side: the application makes a plain local call, and the ambassador does what talking to the outside requires."}
```

All three checkouts succeeded, and the log shows why: two of them were refused once by the gateway and
went through on the ambassador's second attempt. The monolith saw none of it. The key lives in the
ambassador's configuration rather than in the monolith's, so it can be rotated without a release of the
monolith, and the retry policy can be changed the same way.

It is the same `proxy.py` as the sidecar, with different environment variables. **What distinguishes the
two patterns is position**: a sidecar is beside the service that is called, an ambassador beside the one
that calls. Typical ambassador work is anything about reaching a particular outside system: its
credentials, its retry and rate rules from lessons 11 and 12, a circuit breaker around it, a connection
pool to a database cluster that needs a smart client, or the translation to a protocol the application
does not speak.
