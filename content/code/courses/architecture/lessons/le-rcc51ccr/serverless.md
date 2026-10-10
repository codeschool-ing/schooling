---
title: Serverless functions
version: 1
---

"Serverless" does not mean there is no server. It means **you never see one**: you hand a platform a
function, the platform runs it when an event arrives, as many copies as the events need, and stops
it when they stop. You pay for the time your code ran, and nothing while it was idle.

The model is usually called **functions as a service**, FaaS. AWS Lambda made it popular in 2014;
Google Cloud Run functions, Azure Functions and Cloudflare Workers are others, and Knative and
OpenFaaS run the same model on your own Kubernetes cluster.

## A function

The unit is a handler: a function that takes an event and returns a result, and keeps nothing in
memory that the next call can rely on. Here is one for Quitanda, quoting the delivery fee for a
basket from its weight. It is in the lesson's directory, `~/lab/faas`:

```sh
mkdir -p ~/lab/faas && cd ~/lab/faas
```

`handler.py`:

```schooling-example
{"language": "python", "file": "handler.py", "parts": [{"code": "def handle(event):\n    grams = event[\"weight_g\"]\n    fee = 790 if grams <= 5000 else 790 + (grams - 5000 + 999) // 1000 * 150\n    return {\"weight_g\": grams, \"fee_cents\": fee}", "note": "A function in the serverless sense: one handler that takes an event and returns an answer, keeping nothing between calls. This one quotes the delivery fee for a basket, from its weight."}]}
```

A basket up to 5 kg pays the base fee of 790 cents, and each started kilogram over that adds 150.
The platform is responsible for everything else: receiving the event, finding a machine, starting
the code, scaling the copies, logging, and stopping them.

## What triggers a function

| event | example for Quitanda |
| --- | --- |
| an HTTP request | the checkout asks for the delivery fee |
| a message on a queue | an order was placed; send the confirmation e-mail |
| a file landing in storage | a supplier uploads the price list; import it |
| a schedule | every night at 02:00, expire unpaid orders |
| a change in a database | a stock count fell below ten; tell the buyer |

Most of those rows are glue between systems, and **glue is where functions fit best**: short pieces
of work, triggered by something else, with nothing to keep in between.

## Scaling to zero

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A chart over one day. Requests arrive in two bursts, one at lunchtime and one in the evening, and none at night. The number of running instances follows the requests: zero overnight, several during each burst, and back to zero after. An always-on server is drawn as a flat line at two instances all day.\"><defs><marker id=\"l3-zero-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M60 220 L690 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-zero-ah-wire)\"></path><path d=\"M60 220 L60 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-zero-ah-wire)\"></path><text x=\"375\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one day, midnight to midnight</text><text x=\"66\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">instances</text><path d=\"M60 220 L250 220 L270 120 L300 80 L330 110 L350 220 L470 220 L490 150 L520 60 L560 70 L590 160 L610 220 L690 220 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></path><path d=\"M60 180 L690 180\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"140\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">always on: 2</text><text x=\"300\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">lunch</text><text x=\"540\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">evening</text><text x=\"150\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zero at night</text></svg>", "caption": "A function platform scales with the events and down to zero between them; you pay for the shaded area, not for the day. An always-on server pays for the flat line whether anybody calls or not."}
```

A function platform runs as many copies as the events need, and none when there are none. For a
workload with long quiet stretches, that is the whole attraction: Quitanda's delivery quotes come in
around lunch and dinner and almost never at four in the morning, and a server sized for dinner sits
mostly idle the rest of the day.

**Scaling to zero has a cost, and it is paid by a person.** When no copy is running and an event
arrives, the platform has to start one before your code can answer it. The next section measures
what that start takes.
