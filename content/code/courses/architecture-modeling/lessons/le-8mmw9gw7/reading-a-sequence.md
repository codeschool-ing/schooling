---
title: Reading a sequence for waits and failures
version: 1
---

**A sequence diagram is the one picture where you can count how long something takes and see where
it can break**, because every synchronous arrow is a wait and every wait is a place a failure can
land. Reading it that way is a skill on its own, and architecture reviews use it constantly.

## Counting the waits

Take the payment half of the purchase. Each synchronous message holds up everything above it until
the answer comes back, so the passenger waits for the sum of the chain. Carcará's measurements at
the 95th percentile, the time nineteen requests in twenty stay under, were:

| step | p95 |
| --- | --- |
| app to API, over a mobile network | 120 ms |
| API to payment gateway, card charge | 1,400 ms |
| API to booking database, mark as paid | 8 ms |
| API back to the app | 120 ms |

Added up, that is about 1,650 ms, and the table makes the point the diagram already made: **the
gateway is almost all of it**. Shaving the database write would change nothing a passenger could
notice. A diagram with time on it lets you see that before anybody optimises the wrong step.

(Adding percentiles is not exact: the slowest twentieth of one step is not always paired with the
slowest twentieth of another. For a first look at where the time goes, it is close enough, and the
real number comes from a trace.)

## Finding the failures

Now ask, at every synchronous arrow, *what if this never answers?* Three questions per arrow:

1. **Who is waiting, and for how long?** There must be a timeout, and the diagram is where you
   decide where it goes. The app waits for the API; the API waits for the gateway. If the API's
   timeout on the gateway is longer than the app's timeout on the API, the app gives up first and
   the API keeps working on a request nobody is waiting for.
2. **What has already happened?** By the time the gateway is called, the seat is held and the booking
   is written as *pending payment*. A failure here leaves both behind, which is fine only because the
   hold expires after ten minutes on its own.
3. **Could the far side have succeeded anyway?** This is the expensive one. If the call to the
   gateway times out, the card may still have been charged: the answer was lost, not the charge.
   Calling again could charge twice.

## What the third question changed at Carcará

Drawing the payment this way is how Carcará found the double charge before a passenger did. The
fix shows up as two changes to the diagram:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l02-sequence-webhook\" aria-label=\"The payment again, after the fix, with four lifelines: passenger app, ticketing API, booking database and payment gateway. The API sends charge card with key B-4471 to the gateway. The answer is lost: a cross marks it, labelled timeout. The API retries the same charge with the same key, and the gateway answers already charged: approved, without charging again. Later, outside any request, the gateway sends payment approved for B-4471 to the API's webhook, an asynchronous message, and the API marks the booking paid.\"><defs><marker id=\"l02-sequence-webhook-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l02-sequence-webhook-am-open-paper\" viewBox=\"0 0 10 8\" refX=\"9.5\" refY=\"4\" markerWidth=\"9\" markerHeight=\"8\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0.5 L9.5 4 L0 7.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></path></marker></defs><rect x=\"10.0\" y=\"11.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Passenger app</text><path d=\"M80.0 45.0 L80.0 345.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"190.0\" y=\"11.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Ticketing API</text><path d=\"M260.0 45.0 L260.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M260.0 210.0 L260.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M260.0 330.0 L260.0 345.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"370.0\" y=\"11.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Booking DB</text><path d=\"M440.0 45.0 L440.0 345.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"550.0\" y=\"11.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Payment gateway</text><path d=\"M620.0 45.0 L620.0 345.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"255.0\" y=\"72.0\" width=\"10.0\" height=\"138.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><path d=\"M86.0 76.0 L254.0 76.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-fill-paper)\"></path><text x=\"170.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">POST /payments</text><path d=\"M266.0 102.0 L614.0 102.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-fill-paper)\"></path><text x=\"440.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">charge card, key = B-4471</text><path d=\"M614 128 L380 128\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M372.0 121.0 L386.0 135.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M372.0 135.0 L386.0 121.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"400.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">timeout: the answer is lost</text><path d=\"M266.0 164.0 L614.0 164.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-fill-paper)\"></path><text x=\"440.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">charge card, same key = B-4471</text><path d=\"M614.0 192.0 L266.0 192.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l02-sequence-webhook-am-open-paper)\"></path><text x=\"440.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">already charged: approved</text><path d=\"M254.0 206.0 L86.0 206.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l02-sequence-webhook-am-open-paper)\"></path><text x=\"170.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">ticket</text><path d=\"M30.0 240.0 L700.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"36.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">later, outside the request</text><rect x=\"255.0\" y=\"280.0\" width=\"10.0\" height=\"50.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><path d=\"M614.0 284.0 L266.0 284.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-open-paper)\"></path><text x=\"440.0\" y=\"277.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">webhook: payment approved, B-4471</text><path d=\"M266.0 316.0 L434.0 316.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-fill-paper)\"></path><text x=\"350.0\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">mark paid, if not already</text></svg>", "caption": "The key makes the retry safe; the webhook makes the lost answer harmless. Both are visible only on a picture that shows the moment between sent and answered."}
```

- The charge carries an **idempotency key**, the booking id, so that a retry of the same charge is
  recognised by the gateway and not charged again.
- The gateway also tells Carcará the outcome **asynchronously**, by calling a webhook. It appears on
  the diagram as an open-headed arrow from the gateway to the API, outside the original request.
  If the synchronous answer is lost, the webhook still arrives and marks the booking paid.

The `architecture` course, in its lesson on guaranteed delivery, explains idempotency in depth. The
point here is narrower: **a sequence diagram drawn honestly, with its arrowheads right, is where
this class of failure becomes visible**, because it is the only picture that shows the moment
between *sent* and *answered*.
