---
title: What it records, and in which names
version: 2
---

From here on, *a checkout is sent* means the `curl` of lesson 1, and the trace a transcript asks
Jaeger for is the one the storefront logged last. Two shell functions save typing either again.
Paste them into the shell in `~/shop` once; they last until that shell closes, and `last_trace`
takes another service and another message when a lesson needs one:

```sh
checkout() { curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json; echo; }
last_trace() { docker compose logs --no-log-prefix "${1:-storefront}" | grep "${2:-checkout finished}" | tail -1 | jq -r .trace_id; }
```

Spans leave each service in batches, a few seconds apart, so wait five seconds or so after a
checkout before asking Jaeger. Then `TRACE=$(last_trace)`, and `$TRACE` goes where a transcript
has an id. A checkout, then the spans `orders` produced for it, with the kind each one was given:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/56414d8c2542c07251f5be873161653b | jq -r '.data[0] as $t | $t.spans | sort_by(.startTime) | .[] | select($t.processes[.processID].serviceName == "orders") | [.operationName, (.tags[] | select(.key == "span.kind") | .value)] | @tsv'
POST /orders	server
INSERT	client
POST	client
UPDATE	client
```

**One `SERVER` span and three `CLIENT` spans.** Flask opened the server span when the request
arrived; psycopg opened one client span per query; `requests` opened one for the call to payments.
That is the shape automatic instrumentation always gives: a span where a request comes in, and a
span wherever the service calls out to something else. The kinds matter to a backend, which pairs a
`CLIENT` span in one service with the `SERVER` span it caused in the next and draws the arrow
between them.

Each span carries what its library could see. The database span:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/56414d8c2542c07251f5be873161653b | jq -c '.data[0].spans[] | select(.operationName == "INSERT") | [.tags[] | select(.key | test("^(db|server|net)")) | {(.key): .value}] | add'
{"db.name":"shop","db.statement":"INSERT INTO orders (sku, qty, total_cents, status, traceparent) VALUES (%s, %s, %s, 'pending', %s) RETURNING id","db.system":"postgresql","db.user":"shop","net.peer.name":"postgres","net.peer.port":5432}
```

**The query is recorded with its placeholders and not its values**: `%s` where the SKU and the
total went. The instrumentation records the statement psycopg was given, and psycopg was given the
values separately, which is also what protects the query from injection. A query built by pasting
values into the string would be recorded with them, card numbers and all, which is one more reason
never to build one that way. And the call to payments:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/56414d8c2542c07251f5be873161653b | jq -c '.data[0].spans[] | select(.operationName == "POST") | [.tags[] | select(.key | test("^(http|url|server)")) | {(.key): .value}] | add'
{"http.method":"POST","http.status_code":200,"http.url":"http://payments:8082/charge"}
```

**These names are not the ones lesson 2 used.** The storefront, instrumented by hand, recorded
`http.request.method` and `http.response.status_code`. Here it is `http.method` and `http.url`, and
the database span says `db.statement` and `net.peer.name`. They are the **older** names of the same
semantic conventions, which OpenTelemetry has since renamed and declared stable. Instrumentation
libraries keep emitting the old ones by default so that the dashboards people already built do not
break overnight. An environment variable, `OTEL_SEMCONV_STABILITY_OPT_IN`, opts a service into
the new names one domain at a time.

So the shop, as it stands, mixes two generations of names, and a query for `http.request.method`
finds the storefront and misses orders. **That is the normal state of a real system** during a
migration that takes years. It is worth checking which names a backend actually holds before
writing a dashboard against them.
