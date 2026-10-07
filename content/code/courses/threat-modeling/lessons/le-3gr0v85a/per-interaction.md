---
title: STRIDE per interaction
version: 1
---

**STRIDE per interaction** applies the letters to a flow together with the two elements at its
ends, and only to flows that cross a trust boundary. It is the variant behind Microsoft's free
Threat Modeling Tool, and it suits the way threats actually happen: across a line, between a
sender and a receiver that trust each other differently.

For each crossing, the questions come in a fixed order, from the sender's side to the receiver's:

| | about | asks |
|---|---|---|
| **S** | the source | is the sender who it claims to be? |
| **T, I** | the flow | can the data be changed or read on the way? |
| **D** | the flow and the receiver | can the receiver be flooded, or the flow cut? |
| **E** | the receiver | can the receiver be made to do something the sender may not ask for? |
| **R** | both | if the sender later denies it, is there a record? |

### Flow 7, interaction by interaction

The payment webhook goes from the gateway (vendors' zone) to the portal (Vereda's cloud), and it
changes a booking from unpaid to paid.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l03-webhook-letters\" aria-label=\"STRIDE per interaction on the payment webhook. At the source, the gateway: S, is it really the gateway? On the flow: T and I, can it be changed or read on the way, and D, can it be sent too often? At the receiver, the portal: E, does an anonymous request get to mark a booking paid? And R on both ends: is the original kept?\"><defs><marker id=\"l03-webhook-letters-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"35.0\" y=\"75.0\" width=\"150.0\" height=\"50.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Payment gateway</text><circle cx=\"600.0\" cy=\"100.0\" r=\"52\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal</text><path d=\"M185.0 100.0 L548.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-webhook-letters-tm-ah-paper-dim)\"></path><text x=\"366.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">payment webhook</text><path d=\"M290.0 30.0 L290.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"296.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">vendors | Vereda</text><text x=\"110.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">S</text><text x=\"110.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">is it the gateway?</text><text x=\"366.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">T  I  D</text><text x=\"366.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">changed, read, flooded?</text><text x=\"600.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">E</text><text x=\"600.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">more than anonymous may do?</text><text x=\"366.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">R at both ends: is the original webhook kept?</text></svg>", "caption": "S and E describe the same flaw from two ends: the portal does not ask who sent the request, and then lets it do what only the gateway should."}
```

- S, the source: is the request from the gateway? The portal does not check. **This is T01**,
  and it is the threat lesson 1 started from. The gateway signs each call; the fix is verifying
  the signature.
- T, the flow: could the amount or the booking id be changed on the way? It travels over HTTPS
  from the gateway, so on the way, no. Once anybody can send the request, the question is moot:
  they write whatever they like.
- I, the flow: the webhook carries a booking id and a status, nothing worth reading.
- D: a flood of fake webhooks could load the portal; the same answer as for any public address.
- E, the receiver: marking a booking paid is more than an anonymous request should be able to
  do. It is S and E describing the same flaw from two ends.
- R: if the gateway and the portal disagree about whether a session was paid, does Vereda keep
  the original webhook? Nobody knows, which is itself worth writing down.

Six questions, one serious threat, two "check this", and three answered. That ratio is normal. The
value of working the letters in order is that **the one serious threat could not hide in a
category nobody asked about.**

### Which variant to use

Per element for a first pass over a whole system, because it is quick and covers everything. Per
interaction on the flows that cross the boundaries you care about most, because that is where
the serious threats concentrate. Most real models use both, in that order.
