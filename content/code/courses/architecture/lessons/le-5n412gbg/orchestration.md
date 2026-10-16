---
title: Orchestration
version: 1
---

In an **orchestrated** saga one component holds the plan. `saga.py` is it: a list of steps and
compensations, run in order, calling each service over HTTP. The services do not know they are part of
a checkout; they reserve, charge or schedule when asked.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Orchestration. A box labelled saga.py in the middle calls three services in turn, stock, payments and shipping, with numbered arrows: 1 reserve, 2 charge, 3 schedule, 4 confirm. The services do not talk to each other.\"><defs><marker id=\"l14-orchestration-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"280\" y=\"30\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">saga.py</text><rect x=\"40\" y=\"170\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stock</text><rect x=\"280\" y=\"170\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">payments</text><rect x=\"520\" y=\"170\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shipping</text><path d=\"M300 82 L140 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-orchestration-ah-phosphor)\"></path><text x=\"170\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">1 reserve, 4 confirm</text><path d=\"M360 82 L360 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-orchestration-ah-phosphor)\"></path><text x=\"372\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">2 charge</text><path d=\"M420 82 L580 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-orchestration-ah-phosphor)\"></path><text x=\"560\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">3 schedule</text></svg>", "caption": "An orchestrator holds the plan and calls each service; the services know nothing about the checkout."}
```

A checkout that works:

```
ana@vm:~/lab/saga$ $R saga.py o-1
o-1: saga started
  stock reserve: ok {'reserved': 1}
  payments charge: ok {'charged': 2490}
  shipping schedule: ok {'scheduled': 'Recife'}
  stock confirm: ok {'sold': 'o-1'}
o-1: completed
```

A declined card. The reservation had already been made, so it is released:

```
ana@vm:~/lab/saga$ $R saga.py o-2 --card 4000-0002
o-2: saga started
  stock reserve: ok {'reserved': 1}
  payments charge: failed {'error': 'card declined'}
o-2: compensating
  stock release: ok {'released': 'o-2'}
o-2: failed, everything undone
```

A city shipping does not serve. By then the card had been charged as well, so both earlier steps are
compensated, in reverse order: the refund first, then the release:

```
ana@vm:~/lab/saga$ $R saga.py o-3 --city Noronha
o-3: saga started
  stock reserve: ok {'reserved': 1}
  payments charge: ok {'charged': 2490}
  shipping schedule: failed {'error': 'no deliveries to Noronha'}
o-3: compensating
  payments refund: ok {'refunded': 'o-3'}
  stock release: ok {'released': 'o-3'}
o-3: failed, everything undone
```

And what the stock and payments services hold afterwards:

```
ana@vm:~/lab/saga$ curl -s localhost:8001; echo; curl -s localhost:8002; echo
{"shelf": {"coffee": 2}, "reservations": {"o-1": {"sku": "coffee", "units": 1, "status": "sold"}, "o-2": {"sku": "coffee", "units": 1, "status": "released"}, "o-3": {"sku": "coffee", "units": 1, "status": "released"}}}
{"o-1": {"cents": 2490, "status": "charged"}, "o-3": {"cents": 2490, "status": "refunded"}}
```

Every order left a trace. o-1 is sold and charged. o-2 has a released reservation and no charge. o-3
has a released reservation **and a charge marked refunded**: it was charged, for real, and then refunded.
The shelf has two bags, which is three minus the one sold.

## The orchestrator's own state

`saga.py` keeps the list of completed steps in memory and prints it. If it crashed between the charge
and the schedule, nobody would know that o-3 needed a refund. A real orchestrator **writes each step to
a database before and after making it**, so that after a crash it can read where every saga was and
carry on, forwards or backwards. That record is also the best answer to the question a support person
asks, "what happened to this order?", in one place.

That is most of what saga orchestration products sell. **Temporal** and its ancestor Cadence record
every step of a workflow written as ordinary code and replay it after a crash. **AWS Step Functions**
and **Google Workflows** run a state machine described in JSON or YAML. **Camunda** runs BPMN diagrams.
All of them persist the saga's state so that a crash is a pause, not a lost refund.
