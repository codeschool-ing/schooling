---
title: Choreography
version: 1
---

The other way to run a saga has no orchestrator. Each service listens for the events that concern it,
does its step, and publishes what happened; the next service reacts to that. **The plan exists only as
the sum of the reactions**: stock reacts to `OrderPlaced`, payments to `StockReserved`, shipping to
`PaymentCharged`, and the compensations are reactions too, payments to `ShippingFailed` and stock to
`PaymentFailed` and `PaymentRefunded`. Look at the `listen(...)` line at the bottom of each service: that
is the whole choreography.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Choreography. Events pass between three services with no orchestrator. OrderPlaced reaches stock, which publishes StockReserved. Payments reacts and publishes PaymentCharged. Shipping reacts and publishes ShippingFailed for an unserved city. Payments reacts by refunding and publishes PaymentRefunded; stock reacts by releasing and publishes StockReleased.\"><defs><marker id=\"l14-choreography-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-choreography-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"26\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stock</text><path d=\"M110 56 L110 250\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"290\" y=\"26\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">payments</text><path d=\"M360 56 L360 250\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"540\" y=\"26\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shipping</text><path d=\"M610 56 L610 250\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"30\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OrderPlaced →</text><path d=\"M113 96 L357 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-choreography-ah-phosphor)\"></path><text x=\"235.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">StockReserved</text><path d=\"M363 132 L607 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-choreography-ah-phosphor)\"></path><text x=\"485.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">PaymentCharged</text><path d=\"M607 168 L363 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-choreography-ah-amber)\"></path><text x=\"485.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">ShippingFailed</text><path d=\"M357 204 L113 204\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-choreography-ah-amber)\"></path><text x=\"235.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">PaymentRefunded</text><text x=\"120\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">StockReleased</text></svg>", "caption": "In a choreography each service reacts to the events before it. The checkout's plan exists only as the sum of those reactions."}
```

Place three orders the choreographed way: one that works, one to a city without deliveries, and one with
a declined card. `place.py` only publishes `OrderPlaced` and exits:

```
ana@vm:~/lab/saga$ $R place.py o-6; $R place.py o-7 --city Noronha; $R place.py o-8 --card 4000-0002
07:34:18.600 checkout: OrderPlaced o-6
07:34:19.755 checkout: OrderPlaced o-7
07:34:20.781 checkout: OrderPlaced o-8
```

Nothing on the screen says how they ended. The only way to find out is to put the services' logs
together, in time order:

```
ana@vm:~/lab/saga$ docker compose logs --no-log-prefix stock payments shipping | sort
07:34:18.611 stock: StockReserved o-6
07:34:18.625 payments: PaymentCharged o-6
07:34:18.641 shipping: ShippingScheduled o-6
07:34:19.775 stock: StockReserved o-7
07:34:19.783 payments: PaymentCharged o-7
07:34:19.795 shipping: ShippingFailed o-7
07:34:19.807 payments: PaymentRefunded o-7
07:34:19.820 stock: StockReleased o-7
07:34:20.789 stock: StockReserved o-8
07:34:20.797 payments: PaymentFailed o-8
07:34:20.806 stock: StockReleased o-8
```

o-6 went all the way through. o-7 was charged, failed at shipping, was refunded, and its stock released.
o-8's card was declined and its stock released. The same outcomes as the orchestrated saga, with no
component that knew the plan.

That is the strength and the weakness in one. **Adding a step is adding a listener**: a loyalty service
that gives points on `ShippingScheduled` needs no change anywhere else. And **nobody knows the state of
an order**: to answer "what happened to o-7?" you just did what support would have to do, collect logs
from three services and read them in order. Lesson 5's correlation id, carried in every event, is what
makes that possible at all; a choreography without one is a set of logs nobody can join.
