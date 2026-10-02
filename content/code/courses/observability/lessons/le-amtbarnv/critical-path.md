---
title: The critical path
version: 1
---

Self time tells you who did the work. It does not yet tell you **what to make faster**, and the
two differ as soon as anything runs in parallel.

The **critical path** is the chain of spans that ends the request: start at the root's end, find the
child that finished last, step into it, and repeat. Shortening a span on that chain shortens the
request; shortening a span off it shortens nothing, because the request was waiting for something
else at the time.

In the shop every call is made one after another, so the critical path of a checkout is all of it,
and the lesson is arithmetic. Of the 439 ms, the card network is 400. Making the `INSERT` ten times
faster saves under a millisecond, and removing the connection `orders` opens per message saves
perhaps twenty. **The only change a customer could notice is in payments**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A request of 300 ms whose handler calls two services at the same time. The call for prices takes 280 ms and the call for stock takes 120 ms. The critical path runs through the request and the prices call. Stock has 160 ms of slack: making it faster changes nothing.\"><defs><marker id=\"cp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"200\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"680.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300 ms</text><path d=\"M200 40 L200 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M680.0 40 L680.0 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET /product</text><rect x=\"200\" y=\"62\" width=\"480.0\" height=\"16\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">prices</text><rect x=\"216.0\" y=\"102\" width=\"448.0\" height=\"16\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">stock</text><rect x=\"216.0\" y=\"142\" width=\"192.0\" height=\"16\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M408.0 150 L664.0 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"536.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">slack: 160 ms</text><text x=\"440.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">critical path: the request, then prices</text></svg>", "caption": "Two children in parallel. The request ends when the slower one does, so the faster one's 160 ms of slack is time nobody waits for."}
```

Where calls do run in parallel, the picture changes. A page that asks for prices and stock at the
same time waits for the slower of the two, and the faster one has **slack**: it could take longer
and nobody would notice. Two traps follow from that:

- **Optimising the span with the most self time can do nothing.** If it is off the critical path,
  its time was already hidden behind a longer sibling.
- **Making a call parallel moves the critical path rather than removing it.** The new path runs
  through whichever sibling is now slowest, and that is the span to read next.

Asynchronous work is the far end of this. The mailer is off the checkout's critical path entirely,
but it is the whole critical path of a different question, *when did the customer get the e-mail?*
**A trace answers whichever question you ask of it**, and the span you read first depends on which
one that is.
