---
title: The trace that crosses a queue
version: 1
---

Lesson 4 carried the context through RabbitMQ and saw one message wait 22.8 seconds. One trace
shows that a message can wait. **Several, read across an outage, show how a backlog behaves.**

The mailer is stopped for thirty seconds while customers keep buying, then started again:

```
ana@obs:~/shop$ docker compose stop mailer 2>&1 | tail -1
 Container shop-mailer-1 Stopped 
ana@obs:~/shop$ docker compose start mailer 2>&1 | tail -1
 Container shop-mailer-1 Started 
```

Twenty seconds later, five of the confirmations the mailer sent in the last minute are picked at
even steps through its log. Each trace is asked one question: how long between the `UPDATE`, after
which `orders` publishes, and the mailer taking the message?

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/30062f0fab08e70ae9b00866cb0d05e4 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 11 ms
ana@obs:~/shop$ curl -s localhost:16686/api/traces/dc40e8a055aedfb7a12beeca85635427 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 7 ms
ana@obs:~/shop$ curl -s localhost:16686/api/traces/9499029b112afb087b7a231792a939d9 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 26666 ms
ana@obs:~/shop$ curl -s localhost:16686/api/traces/ed14b89a82ff9cdd4577a49b3c05ff89 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 20294 ms
ana@obs:~/shop$ curl -s localhost:16686/api/traces/70dc732d7302edaed283a9a2292e9a54 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 13716 ms
```

The first two were published before the stop and waited milliseconds, which is the queue doing its
job unnoticed. **The other three were published while the mailer was down**, and their waits fall in
steps. The oldest message waited longest, and each later one less, because they were all taken in a
burst once the mailer came back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"How long five confirmations waited in the queue, in the order they were published. 11 ms, 7 ms, 26666 ms, 20294 ms, 13716 ms. The first two were published before the mailer stopped; the last three during the stop, and the oldest of those waited longest.\"><defs><marker id=\"dq-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M110 230 L680 230\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"102\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"102\" y=\"173.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 s</text><text x=\"102\" y=\"116.66666666666667\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20 s</text><text x=\"102\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30 s</text><rect x=\"140\" y=\"228\" width=\"60\" height=\"2\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11 ms</text><rect x=\"250\" y=\"228\" width=\"60\" height=\"2\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7 ms</text><rect x=\"360\" y=\"78.89266666666666\" width=\"60\" height=\"151.10733333333334\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"68.89266666666666\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26666 ms</text><rect x=\"470\" y=\"115.00066666666666\" width=\"60\" height=\"114.99933333333334\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"105.00066666666666\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20294 ms</text><rect x=\"580\" y=\"152.276\" width=\"60\" height=\"77.724\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"142.276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">13716 ms</text><text x=\"250\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">before the stop</text><text x=\"470\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">published while the mailer was down</text><text x=\"400\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">time in the queue, by order of publication</text></svg>", "caption": "A backlog drains oldest first. A message's wait is the time from its publication to the moment the mailer, back again, reached it."}
```

Two things about reading this in a trace store:

- **The trace's length is not what anybody waited.** A trace store measures a trace from its first
  span's start to its last span's end, so these checkouts list as twenty-odd seconds long. The
  customer waited about 430 ms, the root span's duration. Search on the root span when the question
  is about the customer, and on the trace when it is about the order.
- **The wait has no span of its own.** It is the gap between a span in one service and a span in
  another, measured on two machines' clocks. In the lab both clocks are the same host's; between
  real hosts a few milliseconds of clock skew can make a short wait look negative, which is noise,
  while a wait of seconds is a finding.

The queue's own metrics, its depth and its consumers, say the same thing from the other side: lesson
5 queried RabbitMQ's. The metric says that a backlog formed. The traces say which orders were in it
and how late each confirmation went out.