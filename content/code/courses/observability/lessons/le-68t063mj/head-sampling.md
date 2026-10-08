---
title: Deciding at the head
version: 2
---

**Head sampling decides when the trace begins**, in the service that starts it, and every service
after it does what it was told. The SDK makes the decision with a *sampler*, and the usual one keeps
a fixed fraction. A script in the sandbox starts eight checkouts under a sampler that keeps half. Save it as
`~/shop/scratch/flags.py`:

```python
"""Eight checkouts under a sampler that keeps half of all traces."""
from opentelemetry import propagate, trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.sampling import ParentBased, TraceIdRatioBased

trace.set_tracer_provider(TracerProvider(sampler=ParentBased(TraceIdRatioBased(0.5))))
tracer = trace.get_tracer("flags")

for _ in range(8):
    with tracer.start_as_current_span("POST /checkout") as span:
        headers = {}
        propagate.inject(headers)
        print(headers["traceparent"], "recorded" if span.is_recording() else "dropped")
```

And run it:

```
ana@obs:~/shop$ docker compose run --rm sandbox python flags.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-6e3ae4e8d198 Creating 
 Container shop-sandbox-run-6e3ae4e8d198 Created 
00-54199263ed3ad5ffbb58df35a67aa053-c9195a44cfd2c2a8-02 dropped
00-c6db9fe128d3a99ac5f915234528b71e-61d22abfc6cb43b2-02 dropped
00-36c6ffd2ee255dd7693caacddcc25651-202a72d84f6fa68e-03 recorded
00-edaa875d1f8177f50f0b20753f99a1d4-44b919efcfb39b7b-03 recorded
00-8a5d4e4a91fd6fda14ff1770afdd2bd8-8523f6532382cf90-03 recorded
00-67f0d72edf5f168ebf2a7aedfefadfda-679245edb0a4c2cb-02 dropped
00-0c891ce3f92c9efedafd8bc245e6d78e-1ceb2015333608e9-02 dropped
00-78389170ad267c7309c8b6b3e668f664-29b99cefc9378fe5-03 recorded
```

Every line is a `traceparent`, the header lesson 4 took apart, and the answer is in its last field.
**`03` says the trace is being recorded**, `02` that it is not. The `2` in both is the flag lesson 4
mentioned, saying the trace id's bits are random, which is the property this sampler relies on.
`TraceIdRatioBased` does not roll a die: it reads the trace id as a number and keeps the trace if
that number falls below the fraction. Two services given the same id and the same fraction reach the
same answer without talking to each other.

The shop needs no code for this. The SDK reads its sampler from the environment, so the storefront,
where every checkout's trace begins, is given one in an override, keeping one trace in ten. Save the lines the `cat` below prints as
`~/shop/compose.override.yaml`, recreate the storefront with them, and give the change a minute and
a quarter to show in the numbers:

```sh
docker compose up -d storefront
sleep 75
```

Then:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  storefront:
    environment:
      OTEL_TRACES_SAMPLER: parentbased_traceidratio
      OTEL_TRACES_SAMPLER_ARG: "0.1"
```

`parentbased_traceidratio` is two rules: **if a parent arrived, do what it says; if this is the
root, keep the given fraction.** The other services keep their default, `parentbased_always_on`,
which follows a parent and keeps everything when there is none. So the storefront decides and
everybody else obeys. A minute later, what reaches the Collector:

```
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'
  4.9111111111111105
```

4.9 spans a second instead of 35.5, nearer a seventh than a tenth: one in ten is a probability rather
than a quota, and a minute holds only about 270 checkouts.

And for the last ten checkouts in the storefront's log, what Jaeger holds:

```
ana@obs:~/shop$ for t in $(docker compose logs --no-log-prefix --since 40s --until 15s storefront | grep "checkout finished" | jq -r .trace_id | tail -10); do printf "%s  " $t; curl -s localhost:16686/api/traces/$t | jq -r 'if .data then (.data[0] as $d | ($d.spans | map(.spanID)) as $ids | $d.spans | "\(length) spans, top: " + (map(select(.references == [] or (.references[0].spanID | IN($ids[]) | not))) | map($d.processes[.processID].serviceName + " " + .operationName) | join(", "))) else .errors[0].msg end'; done
f014826b4c5845d99dd84557c0137401  trace not found
e58969d1ab8e7bd1bbfdca4dae9da118  trace not found
a8a985b1dcd8de687aa9cdba4f0e5c6b  trace not found
809b434e8e1a4c1a745633af675e53a4  trace not found
a94508d611d901b89f5786e32cdf1549  trace not found
89f7d213f373cbf7b8d4cf76b074bd28  trace not found
3c7a870b82e3afe23825fe0310dc4260  trace not found
c93cc02fad1a827cee4603a967989fec  trace not found
cea0990a2b7b980d4e2464447e909c9d  trace not found
7d199f333e9aa3e8317b43b2c5ae6009  trace not found
```

None of the ten was kept. At one in ten that happens about one time in three, and the next section
shows kept traces whole. Every checkout still wrote its log line, with its trace id, whatever the
decision. A trace id in a log is no promise that the trace was kept: remember that the next time a
click from a log line to Jaeger finds nothing.

Head sampling is cheap in the way that matters most: **a dropped trace costs almost nothing from its
first span on**. The SDKs do not export it, the network does not carry it and the store never sees
it. Its weakness is that it decides blind. The slow checkout and the failed one are dropped exactly
as often as the fast one, at the same one in ten.
