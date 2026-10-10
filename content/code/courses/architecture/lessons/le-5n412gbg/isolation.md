---
title: What other orders see
version: 1
---

A database transaction is **isolated**: until it commits, nobody else sees its changes. A saga is not.
Each of its steps commits, so between the first step and the last, every other customer and every other
saga sees a checkout that is half done. Chris Richardson's catalogue of saga patterns calls a saga
**ACD**: atomic in the sense that it completes or is compensated, consistent, durable, and **not
isolated**.

The stock service's reservation is the lab's answer, and it is a **semantic lock**: the units leave
what can be sold the moment they are reserved, before anybody knows whether the order will complete. It
is what stops two sagas from both selling the last bag. It also has a cost, and the lab can show it.
Order o-4 reserves the last two bags and then waits five seconds before charging a card that will be
declined; two seconds in, o-5 asks for one bag:

```
ana@vm:~/lab/saga$ $R saga.py o-4 --units 2 --card 4000-0002 --pause 5 & sleep 2; $R saga.py o-5; wait
o-4: saga started
  stock reserve: ok {'reserved': 2}
o-5: saga started
  stock reserve: failed {'error': 'only 0 coffee left'}
o-5: compensating
o-5: failed, everything undone
  payments charge: failed {'error': 'card declined'}
o-4: compensating
  stock release: ok {'released': 'o-4'}
o-4: failed, everything undone
ana@vm:~/lab/saga$ curl -s localhost:8001; echo
{"shelf": {"coffee": 2}, "reservations": {"o-1": {"sku": "coffee", "units": 1, "status": "sold"}, "o-2": {"sku": "coffee", "units": 1, "status": "released"}, "o-3": {"sku": "coffee", "units": 1, "status": "released"}, "o-4": {"sku": "coffee", "units": 2, "status": "released"}}}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two orders over time. Order o-4 reserves the last two bags of coffee and then waits five seconds before charging the card. During those seconds order o-5 asks for one bag and is refused, because none is free. Then o-4&#x27;s card is declined and the two bags are released, back on the shelf, after o-5 has gone.\"><defs><marker id=\"l14-lock-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">o-4</text><text x=\"30\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">o-5</text><path d=\"M70 92 L690 92\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l14-lock-ah-wire)\"></path><path d=\"M70 182 L690 182\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l14-lock-ah-wire)\"></path><rect x=\"100\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reserve 2</text><rect x=\"230\" y=\"40\" width=\"220\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">holding the last 2 bags</text><rect x=\"460\" y=\"40\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"515\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">declined</text><rect x=\"580\" y=\"40\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">release 2</text><rect x=\"280\" y=\"130\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refused: 0 left</text><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o-5 was refused for coffee that was never sold</text></svg>", "caption": "A reservation is a lock other sagas can see. It prevents overselling, and it can refuse a customer for stock that ends up unsold."}
```

**o-5 was refused for coffee that was never sold.** o-4 held the two bags while its card was being
tried, the card was declined, the bags went back on the shelf, and by then o-5's customer had been told
"only 0 left". Without the reservation, the opposite would have happened: o-5 would have taken a bag
that o-4 had counted on, and if o-4's card had been accepted, two customers would have been sold the same
coffee.

Neither outcome is free, and choosing between them is a business decision dressed as a technical one:

| countermeasure | what other sagas see | the cost |
| --- | --- | --- |
| **semantic lock** (reserve first) | the units as taken, as the lab did | a customer refused for stock that ends up free |
| **reread the value** before the pivot | nothing until the end; the saga checks again before committing | the check can fail late, after the card was charged |
| **commutative updates** | changes that can apply in any order, such as "add 2 to stock" | only some operations can be written that way |
| **pessimistic view** | the riskiest step last, the one most likely to fail first | fewer, shorter windows; not always possible |

Quitanda's shop, like most, reserves: a refused customer can be told to try again in a minute, and an
oversold one needs an apology and a refund. **Holding a reservation for as little time as possible** is
what keeps its cost small: reserve at checkout, not when the item enters the basket, and release it on
a timer if the saga stalls.
