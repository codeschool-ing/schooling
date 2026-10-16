---
title: One slow dependency
version: 1
---

Make the stock service take five seconds per answer, and run the same load:

```
ana@vm:~/lab/bulkheads$ curl -s -X POST localhost:8001/slow/5
every answer now takes 5.0 s
ana@vm:~/lab/bulkheads$ $L mixed
catalogue  timeout: 193, 200: 7     median  3004 ms, slowest  3012 ms
stock      timeout: 200             median  3004 ms, slowest  3047 ms
```

The stock page timed out, which is unsurprising: its dependency takes five seconds and the load waits
three. **The catalogue timed out too**, 193 of its 200 requests, and the catalogue does not call the
stock service at all. Its median went from 3 milliseconds to the full three-second timeout.

Follow the threads. Twenty stock requests arrive every second, and each holds one of the eight threads
for five seconds. Within half a second all eight are waiting on the stock service, and every request
after that, catalogue or stock, waits in the pool's queue for a thread that will not be free for
seconds. The catalogue was not broken; it was **starved**. From outside, the shop is down.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The shop&#x27;s eight threads, drawn as eight slots, at two moments. Healthy: a few slots are briefly busy with stock requests and catalogue requests, and most are free. With the stock service slow: all eight slots are held by stock requests waiting for an answer, and a catalogue request waits outside with nowhere to run.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">healthy: most threads free</text><rect x=\"40\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"80\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"120\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"160\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"200\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"280\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">stock slow: every thread waiting on it</text><rect x=\"40\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"80\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"120\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"160\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"200\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"240\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"280\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"420\" y=\"160\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"480\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">catalogue</text><text x=\"560\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waits</text><rect x=\"420\" y=\"60\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stock request</text><rect x=\"420\" y=\"84\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">catalogue request</text></svg>", "caption": "A slow dependency does not fail the requests that call it; it holds the threads they run on, and everything else needs those threads too."}
```

A timeout on the call to the stock service would shorten the hold from five seconds to one, which helps
and does not solve it: twenty a second, each holding a thread for one second, is still more than eight
threads. A circuit breaker would open after enough failures, which also helps, after those failures.
What is missing is a rule that says **the stock service may not take all the threads**.

Put the stock service back before going on:

```sh
curl -s -X POST localhost:8001/slow/0.02
```
