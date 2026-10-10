---
title: The token bucket
version: 1
---

**A token bucket gives each client a bucket that holds up to a fixed number of tokens and refills
at a fixed rate.** Every request takes a token, and a request that finds the bucket empty is refused. Two numbers describe it, and they say two different things:

| number | in `limits.py`'s free tier | what it decides |
|---|---|---|
| **capacity** | 10 tokens | the largest burst a client can send at once, after being quiet |
| **refill rate** | 1 token a second | the pace a client can keep up forever |

The split matters because a real client is bursty: a page loads and asks for six things at once, then
nothing for a minute. A fixed window of one request per second would refuse five of the six, while
a bucket of ten refilled at one a second accepts all six and still holds any client to one a
second on average.

## Nothing ticks

The wrong picture is a timer somewhere dropping a token into every client's bucket once a second.
With a million clients that is a million timers. Nothing ticks: the bucket stores **how many tokens
it had and when it last looked**, and when a request arrives it adds what the elapsed time is worth,
up to the capacity. A client that was quiet for an hour gets ten tokens back, not 3,600, because
the bucket was full after ten seconds.

The same arithmetic answers the question a refused client asks. With 0.2 tokens in the bucket and
a request that costs one, the missing 0.8 tokens at one a second arrive in 0.8 seconds, and
`Retry-After` carries whole seconds, so it says `1`.

Twenty-four requests, four a second, against a fresh bucket of the free tier. The run and the
program that sent it are in the section "A burst against it"; drawn, with the tokens the server
reported after each request:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Twenty-four requests, four a second, against a bucket of ten refilled at one a second. The tokens left fall from 9 to 0 over the first three seconds while every request is accepted; after that one request in four is accepted, one a second. 15 of the 24 were accepted.\"><line x1=\"80\" y1=\"200\" x2=\"660\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"80\" y1=\"70\" x2=\"660\" y2=\"70\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"660\" y=\"61\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">capacity 10</text><text x=\"72\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"135\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"72\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"20\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tokens</text><text x=\"20\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">left</text><rect x=\"84.0\" y=\"83\" width=\"12\" height=\"117\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"85.0\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"107.8\" y=\"96\" width=\"12\" height=\"104\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"108.8\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"131.5\" y=\"109\" width=\"12\" height=\"91\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"132.5\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"155.2\" y=\"122\" width=\"12\" height=\"78\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"156.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"179.0\" y=\"135\" width=\"12\" height=\"65\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"180.0\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"202.8\" y=\"135\" width=\"12\" height=\"65\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"203.8\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"226.5\" y=\"148\" width=\"12\" height=\"52\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"227.5\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"250.2\" y=\"161\" width=\"12\" height=\"39\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"251.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"274.0\" y=\"174\" width=\"12\" height=\"26\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"275.0\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"297.8\" y=\"174\" width=\"12\" height=\"26\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"298.8\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"321.5\" y=\"187\" width=\"12\" height=\"13\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"322.5\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"347.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"370.9\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"394.7\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"418.4\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"442.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"465.9\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"489.7\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"513.5\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"537.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"561.0\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"584.7\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"608.4\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"632.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"185\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 s</text><text x=\"280\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 s</text><text x=\"375\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 s</text><text x=\"470\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 s</text><text x=\"565\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5 s</text><text x=\"660\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6 s</text><text x=\"223.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the saved-up burst</text><text x=\"517.5\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">then one a second: the refill rate</text><rect x=\"90\" y=\"240\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"108\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">accepted</text><rect x=\"200\" y=\"240\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"218\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refused</text></svg>", "caption": "Capacity paid for the burst; the refill rate decided the rest. 15 of 24 accepted."}
```

The first requests are paid for out of the ten tokens saved up, while the refill adds a quarter of a
token between each pair, which is why the count falls by less than one per request. Once the
bucket is empty, the client sending four a second gets one of them through each second, which is
the refill rate. **Capacity paid for the burst; the rate decided everything after it.**

A request does not have to cost one token. `limits.py` charges a search five, which is how a
single limit can cover endpoints of very different cost; the section on quotas and costs measures
it.

## The leaky bucket, its mirror

The **leaky bucket** is the same picture turned over. Requests go into the bucket, and it drains
at a fixed rate; a request that arrives when the bucket is full is refused. Used only to decide
accept or refuse, it is the token bucket counted from the other end, and accepts the same requests.

The other way to use it is as a **queue**: accepted requests wait in the bucket and are passed on
at the drain rate, so a burst comes out the other side evenly spaced, slower but not refused. That
smooths what reaches the application at the price of delay, and it is what a proxy in front of the
API usually does. Nginx describes its own request limiting as a leaky bucket, and `servers-cache`,
the next course, configures it.

| | token bucket | leaky bucket as a queue |
|---|---|---|
| a burst within capacity | passes through at once | waits, and leaves at the drain rate |
| what a client sees over the limit | `429` | delay first, then `429` once the queue is full |
| state per client | tokens and a time | a queue of waiting requests |
