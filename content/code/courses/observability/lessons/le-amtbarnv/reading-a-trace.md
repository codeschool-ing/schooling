---
title: Reading one trace
version: 2
---

A trace view looks like a timeline, and the habit it invites is reading the longest bar. **The
longest bar is nearly always the root**, because a parent lasts at least as long as the children it
waits for, so it tells you nothing about where the time went. The question to ask of each span is
how much of its duration was its own: its **self time**, the part not spent inside a child span.

Jaeger's interface does not print self time, so it is computed here with a small `jq` program over
the trace as Jaeger's API returns it. Save it as `~/shop/selftime.jq`:

```
# One line per span of a Jaeger trace: service, name, duration, and self time,
# the part of the duration not spent inside a child span.
.data[0] as $t
| ($t.spans | map({key: .spanID, value: .}) | from_entries) as $span
| ($t.spans | map({key: .spanID, value: 0}) | from_entries) as $zero
| (reduce ($t.spans[] | select(.references | length > 0)) as $c ($zero;
     $span[$c.references[0].spanID] as $p
     | (([$c.startTime + $c.duration, $p.startTime + $p.duration] | min)
        - ([$c.startTime, $p.startTime] | max)) as $inside
     | .[$p.spanID] += ([$inside, 0] | max))) as $waited
| $t.spans | sort_by(.startTime) | .[]
| [$t.processes[.processID].serviceName, .operationName,
   "\(.duration / 1000 | floor) ms", "self \((.duration - $waited[.spanID]) / 1000 | floor) ms"]
| @tsv
```

It builds a table of every span by id, then walks each child and adds to its parent **the part of
the child that falls inside the parent's own interval**. A child that starts after its parent has
ended, like a message taken off a queue, adds nothing. What remains of each duration is self time.

The shop runs with payments slowed by 400 ms, and five simulated customers a second are buying. To
set that up, start the lab again from nothing and save this override first. It switches on a
feature of Prometheus that the last section of this lesson is about, and Prometheus needs it from
the start, before the traffic it will read:

`~/shop/compose.override.yaml`

```yaml
services:
  prometheus:
    command: [--config.file=/etc/prometheus/prometheus.yml, --web.enable-lifecycle,
              --storage.tsdb.path=/prometheus, --enable-feature=exemplar-storage]
```

Then slow payments, start Prometheus again with the override, and set the customers going for
twenty-five minutes. A minute and a half later, pick one of their checkouts from the storefront's
log by its last line, with lesson 3's `last_trace`:

```sh
echo '{"latency_ms": 400}' > faults/payments.json
docker compose up -d prometheus
docker compose run -d --rm loadgen python -m loadgen.load 5 1500
sleep 90
TRACE=$(last_trace)
```

`$TRACE` goes where the transcripts of this lesson have that checkout's id:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/2317d16ea481cf7a0350d6d965f983e9 | jq -r -f selftime.jq
storefront	POST /checkout	439 ms	self 3 ms
orders	POST /orders	436 ms	self 25 ms
orders	INSERT	1 ms	self 1 ms
orders	POST	404 ms	self 3 ms
payments	POST /charge	401 ms	self 0 ms
payments	wait for the card network	400 ms	self 400 ms
orders	UPDATE	1 ms	self 1 ms
mailer	orders.placed process	20 ms	self 0 ms
mailer	send confirmation	20 ms	self 20 ms
```

Read the third column top to bottom and every span looks guilty: the storefront took 439 ms, orders
436, the call to payments 404. **The fourth column says that almost none of them did anything.** The
storefront spent 3 ms of its own, and payments' `POST /charge` spent none. All 400 ms are inside one
span, `wait for the card network`, which the payments code opens by hand around the call it cannot
see into. That is the whole answer, and it is one line out of nine.

Two lines are worth a second look:

- **`POST /orders` has 25 ms of self time** that no child accounts for. The code says what it is:
  after the `UPDATE`, `orders` opens a new RabbitMQ connection for every message it publishes, and
  nothing instruments `pika`, as lesson 4 said. Self time is where uninstrumented work shows up, as
  a gap that belongs to nobody below.
- **The mailer's two spans are in the trace but not in its duration.** They began after the
  checkout had answered, because the message waited in a queue, and the overlap rule in the program
  above gives them nothing to subtract from their parent. They belong to what the order caused, not
  to what the customer waited for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 344\" role=\"img\" aria-label=\"The checkout's nine spans as two bars each. The outline is the span's duration; the filled part is its self time, the time not spent inside a child. storefront POST /checkout: 439 ms, self 3 ms. orders POST /orders: 436 ms, self 25 ms. orders INSERT: 1 ms, self 1 ms. orders POST: 404 ms, self 3 ms. payments POST /charge: 401 ms, self 0 ms. payments wait for the card network: 400 ms, self 400 ms. orders UPDATE: 1 ms, self 1 ms. mailer orders.placed process: 20 ms, self 0 ms. mailer send confirmation: 20 ms, self 20 ms. Only the span wait for the card network is filled almost end to end.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"300\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">duration</text><text x=\"380\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">self time</text><text x=\"16\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">storefront</text><text x=\"96\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /checkout</text><rect x=\"300\" y=\"52\" width=\"340.0\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"52\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"59\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 / 439 ms</text><text x=\"16\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orders</text><text x=\"96\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /orders</text><rect x=\"300\" y=\"78\" width=\"337.6765375854214\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"78\" width=\"19.362186788154897\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"85\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25 / 436 ms</text><text x=\"16\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orders</text><text x=\"96\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">INSERT</text><rect x=\"300\" y=\"104\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"104\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"111\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 / 1 ms</text><text x=\"16\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orders</text><text x=\"96\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST</text><rect x=\"300\" y=\"130\" width=\"312.89293849658316\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"130\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"137\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 / 404 ms</text><text x=\"16\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payments</text><text x=\"96\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /charge</text><rect x=\"300\" y=\"156\" width=\"310.56947608200454\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"163\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 / 401 ms</text><text x=\"16\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payments</text><text x=\"96\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">wait for the card network</text><rect x=\"300\" y=\"182\" width=\"309.79498861047836\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"182\" width=\"309.79498861047836\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"189\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400 / 400 ms</text><text x=\"16\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orders</text><text x=\"96\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UPDATE</text><rect x=\"300\" y=\"208\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"208\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 / 1 ms</text><text x=\"16\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">mailer</text><text x=\"96\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders.placed process</text><rect x=\"300\" y=\"234\" width=\"15.489749430523919\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"241\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 / 20 ms</text><text x=\"16\" y=\"267\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">mailer</text><text x=\"96\" y=\"267\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send confirmation</text><rect x=\"300\" y=\"260\" width=\"15.489749430523919\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"260\" width=\"15.489749430523919\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"267\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20 / 20 ms</text></svg>", "caption": "Every bar but one is almost empty: the spans above the wait lasted as long as it did, and did nearly nothing themselves. The mailer's bars are drawn at full length though they ran after the checkout answered."}
```
