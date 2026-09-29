---
title: Cold starts
version: 1
---

Scaling to zero has a price, and one request pays it. **When no copy of the function is ready, the
platform has to make one before it can answer, and the request that arrived waits while it does.**
That wait is a cold start.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two timelines starting when a request arrives. A cold invocation first creates an execution environment, then loads the code, then runs the module-level initialisation, and only then runs the handler and responds. A warm invocation reuses an environment that is already initialised, so it runs the handler straight away. The widths are not measurements.\"><defs><marker id=\"sl-cold-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">Cold</text><rect x=\"110\" y=\"52\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"170.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new environment</text><rect x=\"230\" y=\"52\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"285.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">load your code</text><rect x=\"340\" y=\"52\" width=\"150\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">init: module-level code</text><rect x=\"490\" y=\"52\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">handler</text><path d=\"M600 70 L630 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-cold-ah)\"></path><text x=\"636\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">response</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">Warm</text><rect x=\"110\" y=\"132\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"165\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">handler</text><path d=\"M220 150 L250 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-cold-ah)\"></path><text x=\"256\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">response</text><path d=\"M110 34 L110 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"110\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">request arrives</text><path d=\"M110 100 L338 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"224\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the platform's part</text><path d=\"M342 100 L598 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">yours: what you put outside the handler</text><text x=\"20\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The widths say which phases happen, not how long they take: nothing here was timed.</text></svg>", "caption": "A cold start is the first three boxes. A warm call skips them, which is why the first request after a quiet spell is the slow one."}
```

Phase by phase, on Lambda:

1. A request arrives and no execution environment is free: none exists yet, or every one is busy
   with another request.
2. The platform creates a new execution environment, a small isolated virtual machine with the
   runtime you chose, and puts your code in it.
3. The runtime starts and runs your module-level code, the init. In this lesson's handler that is
   `import json` and two assignments; in a real function it is often large imports and the clients
   for a database and other services.
4. Only now is the handler called with the event, and the response goes back.

After the response the environment is not thrown away. **It is frozen and kept, and the next
request that reaches it skips straight to step 4: a warm start.** How long an idle environment is
kept is not a number AWS publishes, and a design should not depend on it. A function called every
few seconds lives almost entirely on warm starts. A function called a few times an hour can meet a
cold start on most of its calls.

**That is why the first request after a quiet period is the slow one**, and why a load test that
sends steady traffic can look better than a real day with bursts in it. A burst is also where cold
starts cluster: fifty requests arriving together at a function with five warm environments means
some forty-five new ones created at once, each paying the first three steps.

This lesson quotes no durations. None were measured here, and they depend on the runtime, on the
size of the code and on what the init does. What can be said without a stopwatch is which part is
whose: **step 2 belongs to the platform, and step 3 is mostly the code you put at module level.**

## Keep the work out of the handler, and the init small

Two rules pull in opposite directions, and both are right.

**Anything reused between calls goes outside the handler**: the database client, the configuration
read, the model loaded from a file. Created there, it is paid once per environment and reused by
every warm call after it. Created inside the handler, it is paid on every call, warm or cold.

**The init should still do only what every call needs.** Importing a large library that one rare
path uses makes every cold start pay for it, including the ones that never take that path. Import
it inside the branch that needs it.

Providers sell ways around the cold start itself. On Lambda, provisioned concurrency keeps a number
of environments initialised in advance and is charged for the time it is configured, used or not,
which gives back part of what scaling to zero saved. SnapStart restores an environment from a
snapshot taken after the init, for the runtimes that support it. **Neither removes the trade; each
moves it.** Cloudflare Workers make a different trade, three sections on.
