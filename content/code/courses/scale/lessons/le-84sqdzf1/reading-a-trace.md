---
title: Reading a trace
version: 1
---

Jaeger has a web page for traces at `http://localhost:16686` on the lab, and the same data through
an API. To read traces in the terminal, as the rest of this course does, this short program asks the
API for the latest trace of an operation and prints it as a tree. Save it as `trace.py`:

```schooling-example
{"language": "python", "file": "trace.py", "parts": [{"code": "# trace.py\n\"\"\"Print the latest trace of one operation as a tree, from Jaeger's API.\nWith --count, print how many traces of it Jaeger holds from the last hour instead.\"\"\"\nimport json\nimport sys\nimport urllib.parse\nimport urllib.request\nfrom datetime import datetime, timedelta, timezone", "note": "A small reader for Jaeger's query API, so a trace can be read in the terminal. The Jaeger page on port 16686 shows the same traces in a browser."}, {"code": "\ncount = \"--count\" in sys.argv\nargs = [a for a in sys.argv[1:] if a != \"--count\"]\noperation = args[0] if args else \"POST /events/{id}/tickets\"\nnow = datetime.now(timezone.utc)\nquery = urllib.parse.urlencode({\n    \"query.service_name\": \"tickets\",\n    \"query.operation_name\": operation,\n    \"query.start_time_min\": (now - timedelta(hours=1)).isoformat(),\n    \"query.start_time_max\": now.isoformat(),\n    \"query.search_depth\": 1000 if count else 1,\n})\nwith urllib.request.urlopen(f\"http://localhost:16686/api/v3/traces?{query}\") as answer:\n    found = json.load(answer)[\"result\"][\"resourceSpans\"]\n", "note": "It asks for the traces of one operation of `tickets` in the last hour: the latest one, or up to a thousand with `--count`."}, {"code": "spans = []\nfor group in found:\n    service = next(a[\"value\"][\"stringValue\"] for a in group[\"resource\"][\"attributes\"]\n                   if a[\"key\"] == \"service.name\")\n    for scope in group[\"scopeSpans\"]:\n        for span in scope[\"spans\"]:\n            spans.append({**span, \"service\": service})\n", "note": "The answer is OTLP's own JSON: spans grouped by the service that produced them. This flattens them into one list, each span labelled with its service."}, {"code": "if count:\n    print(len({s[\"traceId\"] for s in spans}), \"traces of\", operation)\n    sys.exit()\n"}, {"code": "ids = {s[\"spanId\"] for s in spans}\nchildren = {}\nfor span in spans:\n    parent = span.get(\"parentSpanId\") if span.get(\"parentSpanId\") in ids else None\n    children.setdefault(parent, []).append(span)\nstart = min(int(s[\"startTimeUnixNano\"]) for s in spans)\nprint(f\"trace {spans[0]['traceId']}\")", "note": "Each span names its parent by id; a span whose parent is not in the trace is a root. That is the whole of what makes a trace a tree."}, {"code": "\n\ndef show(span, depth):\n    begin = (int(span[\"startTimeUnixNano\"]) - start) / 1e6\n    took = (int(span[\"endTimeUnixNano\"]) - int(span[\"startTimeUnixNano\"])) / 1e6\n    print(f\"{'  ' * depth}{span['name']:<{30 - 2 * depth}} {span['service']:<9}\"\n          f\" at {begin:5.1f} ms  took {took:5.1f} ms\")\n    for child in sorted(children.get(span[\"spanId\"], []), key=lambda s: int(s[\"startTimeUnixNano\"])):\n        show(child, depth + 1)\n\n\nfor root in children.get(None, []):\n    show(root, 0)", "note": "Each span is printed indented under its parent, with when it started relative to the trace and how long it took."}]}
```

One sale, then a pause, because the SDK sends its batches every five seconds and the Collector
waits up to one more, then the trace:

```
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/1/tickets; echo
{"event": 1, "seat": 1, "code": "cb5ad8d5b5fd9bea"}
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py
trace 50257c23c4e03af564a04c50844cf11d
POST /events/{id}/tickets      tickets   at   0.0 ms  took  68.6 ms
  charge                       tickets   at   0.1 ms  took  38.3 ms
    POST /charges              payments  at  14.7 ms  took  23.2 ms
  UPDATE events                tickets   at  54.4 ms  took   4.0 ms
  sign                         tickets   at  58.5 ms  took   5.2 ms
  INSERT tickets               tickets   at  63.9 ms  took   2.9 ms
```

Read it from the top. The request took **68.6 ms** in total. **Charging took 38.3 ms of it**, and
inside the charge, payments' own span took 23.2 ms, **starting 14.7 ms after the charge began**. Then
the `UPDATE` took 4.0 ms, the signing 5.2 ms and the `INSERT` 2.9 ms. Two services, one tree, one
trace id, and the time of each step.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The first sale's trace drawn as a timeline from 0 to 70 milliseconds. The request bar spans 68.6 ms. The charge bar starts at once and lasts 38.3 ms; inside it, payments' own bar starts at 14.7 ms and lasts 23.2 ms. After the charge come three short bars: the update, 4.0 ms, the signing, 5.2 ms, and the insert, 2.9 ms.\"><text x=\"20\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /events/{id}/tickets</text><rect x=\"230.0\" y=\"20\" width=\"452.75999999999993\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">charge</text><rect x=\"230.66\" y=\"52\" width=\"252.77999999999997\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">POST /charges</text><rect x=\"327.02\" y=\"84\" width=\"153.11999999999998\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UPDATE events</text><rect x=\"589.04\" y=\"116\" width=\"26.4\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sign</text><rect x=\"616.0999999999999\" y=\"148\" width=\"34.32\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT tickets</text><rect x=\"651.74\" y=\"180\" width=\"19.139999999999997\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M230.0 212 L230.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"230.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M296.0 212 L296.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"296.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M362.0 212 L362.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"362.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><path d=\"M428.0 212 L428.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"428.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><path d=\"M494.0 212 L494.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"494.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><path d=\"M560.0 212 L560.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"560.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><path d=\"M626.0 212 L626.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"626.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60</text><path d=\"M692.0 212 L692.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"692.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">70</text><path d=\"M230 212 L692.0 212\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"220\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ms</text></svg>", "caption": "The first sale: more than half of it is the charge, and part of the charge is the gap before payments answers."}
```

**The gaps are as informative as the spans.** The 14.6 ms between the box office starting the charge
and payments starting to answer is time spent on neither side's work: opening a TCP connection,
Python's HTTP client getting ready, the request crossing the network. This was the first sale since
the box office started, and the first query on each database connection is slower too, which is why
the `UPDATE` took 4 ms here. Section 08's trace, a minute later, shows the same gap at 1.8 ms.

A read is a smaller tree:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 999999, "host": "dd4bf75a071b"}
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py 'GET /events/{id}'
trace 2add1a888db764a7e5c1661b5065ee66
GET /events/{id}               tickets   at   0.0 ms  took  14.5 ms
  SELECT events                tickets   at   0.1 ms  took  13.9 ms
```

Nearly all of its 14.5 ms is the query on the replica. Lesson 7's histogram said reads were fast at
the 95th percentile; this trace says which part of one read was slow, which is the question a
histogram cannot answer.

## What the Collector saw

The `debug` exporter writes one line per batch it forwards:

```
ana@lab:~/tickets$ docker compose logs collector --no-log-prefix | grep 'Traces' | tail -2
2026-10-10T06:22:12.317Z	info	Traces	{"resource": {"service.instance.id": "1806cab2-143b-4e55-a339-a0ca5bab6217", "service.name": "otelcol", "service.version": "0.162.0"}, "otelcol.component.id": "debug", "otelcol.component.kind": "exporter", "otelcol.signal": "traces", "resource spans": 1, "spans": 6}
2026-10-10T06:22:17.319Z	info	Traces	{"resource": {"service.instance.id": "1806cab2-143b-4e55-a339-a0ca5bab6217", "service.name": "otelcol", "service.version": "0.162.0"}, "otelcol.component.id": "debug", "otelcol.component.kind": "exporter", "otelcol.signal": "traces", "resource spans": 1, "spans": 3}
```

Each line is one batch: `resource spans` is how many services it came from, here one each time,
and `spans` how many spans it held, **6 and then 3**. Those numbers do not match the trees above, and
they are not meant to. A batch holds whatever spans reached the Collector in its second, from
whichever service sent them: payments' spans and the box office's travel separately, and every
Prometheus scrape of `/metrics` is a request too, with a span of its own. **The Collector forwards
spans, not traces**, and Jaeger assembles the trees by their ids. That is what lets the spans of one
trace arrive from different services, at different moments, through different Collectors.
