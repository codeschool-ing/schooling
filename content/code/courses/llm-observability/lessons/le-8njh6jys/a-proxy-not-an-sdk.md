---
title: A proxy, not an SDK
version: 2
---

Every tool so far was fed from inside the application: spans written by the assistant, or by a library
loaded into it. **Helicone** starts from the other side. It is a gateway: the application sends its
model requests to Helicone instead of the provider, Helicone forwards them, and it records each request
and reply as they pass. The integration is a change of base URL and a header with Helicone's key, and
nothing else in the program changes.

That is its whole appeal, and its whole limit:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The assistant's four steps, embed, search, generate and check citations, inside the application. Spans written in the application see all four. A gateway sits outside, between the application and the provider, and sees only the two calls that cross it: the embedding request and the model request.\"><rect x=\"10\" y=\"10\" width=\"430\" height=\"230\" rx=\"6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">inside the application: what spans can see</text><rect x=\"40\" y=\"50\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">embed</text><rect x=\"40\" y=\"100\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">search</text><rect x=\"40\" y=\"150\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">generate</text><rect x=\"40\" y=\"200\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check_citations</text><rect x=\"300\" y=\"95\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">index.json</text><path d=\"M210 115 L300 115\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"470\" y=\"40\" width=\"90\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"515\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">gateway</text><rect x=\"610\" y=\"40\" width=\"100\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">provider</text><path d=\"M210 65 L470 65\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M210 165 L470 165\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M560 65 L610 65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M560 165 L610 165\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"515\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a gateway sees only these</text></svg>", "caption": "A gateway is on the wire to the provider. It sees every model call, from any program, and nothing that happens between them."}
```

**What a gateway gets for free.** Every model call from every program that uses the key, in any
language, including the ones nobody remembered to instrument. Lesson 3's worst gap, calls nobody
traced, closes, because there is no way to reach the provider except through it. The tokens, the cost,
the latency and the status come straight from the provider's own reply, so they are right by
construction.

**What it cannot see.** Anything that is not a model call: the search, the floor, the chunks kept, the
citation check. Lesson 5 found the cause of the order refusals in the search span's top score; a
gateway would have shown a fall in model calls and nothing about why. It also cannot see which calls
belong together, unless the application tells it with a header on every request.

So a gateway takes **headers** where an SDK takes attributes: the user, the session and the feature
travel with each request, because the gateway has no other way to learn them. The next section shows
what one sees without them.

## What a gateway can do that a tracer cannot

Because it stands in the path of every request, a gateway can **act** on them as well as record
them. It can answer a repeated request from a cache without calling the provider, refuse a user over
a rate limit, retry on another provider when the first fails, and keep the provider keys so that
applications never hold them. Those are lesson 3's budgets and lesson 4's retries, moved out of the
application into infrastructure. That is a real gain for a company with many applications and one
bill, and a real cost: one more service on the critical path of every answer, adding its own latency
and its own outages, and holding every prompt and reply in its logs.