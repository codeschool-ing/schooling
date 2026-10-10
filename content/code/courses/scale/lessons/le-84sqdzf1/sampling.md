---
title: Sampling, and which traces to keep
version: 1
---

A trace per request is affordable at the box office's few hundred requests a second in a lab. At a
hundred thousand, it is a second system bigger than the first: the spans have to be sent, processed
and stored, and nearly all of them describe requests that were fast and fine. **Sampling** keeps
some traces and drops the rest.

## Head sampling

The simplest decision is made at the start of the trace, by the first service: keep this trace or
not, with a probability. Every later service reads the decision in the `traceparent` flags of
section 08 and follows it, so a trace is either kept whole or dropped whole.

OpenTelemetry's SDKs read the sampler from standard variables, which `compose.yaml` passes to the box
office. First with the default, every trace kept, after restarting Jaeger to empty it, and two
hundred reads:

```
ana@lab:~/tickets$ docker compose restart jaeger
 Container tickets-jaeger-1 Restarting 
 Container tickets-jaeger-1 Started 
ana@lab:~/tickets$ for i in $(seq 200); do curl -s localhost:8080/events/1 >/dev/null; done
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py --count 'GET /events/{id}'
200 traces of GET /events/{id}
```

**200 traces for 200 reads.** Then the box office restarted with `parentbased_traceidratio` at 0.1:
keep a trace if its id falls in the lowest tenth of the possible ids, unless a parent already
decided:

```
ana@lab:~/tickets$ SAMPLER=parentbased_traceidratio SAMPLER_ARG=0.1 docker compose up -d app
 Container tickets-db-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ docker compose restart jaeger
 Container tickets-jaeger-1 Restarting 
 Container tickets-jaeger-1 Started 
ana@lab:~/tickets$ for i in $(seq 200); do curl -s localhost:8080/events/1 >/dev/null; done
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py --count 'GET /events/{id}'
22 traces of GET /events/{id}
```

**22 traces for 200 reads**, about a tenth, as asked. The decision is made from the trace id, which
is random, so the count varies around 20 from run to run; and because it is made from the id rather
than from a coin, every service that applies the same ratio to the same id makes the same decision.

## What head sampling cannot do

It decides before anything has happened, so it keeps a tenth of the slow requests and a tenth of the
failed ones, the traces anybody actually wants. With a 1% ratio, the one failing request in ten
thousand is almost never traced.

**Tail sampling** decides at the end, once the whole trace has arrived: keep every trace with an
error, every trace slower than 250 ms, and 1% of the rest. It runs in the Collector, in the
`tail_sampling` processor of the Collector's contrib distribution, and it has a real cost: the
Collector must hold every span of every recent trace in memory until it decides, and all the spans of
a trace must reach the **same** Collector, which needs a load-balancing layer of Collectors routing
by trace id.

The usual arrangement is both: a generous head sample, or none, in the services, and tail sampling in
a Collector tier that keeps what is interesting. Whatever the policy, **metrics are never sampled**:
the counters of lesson 7 count every request, so a sampled trace is a detail of a number that is
still exact.
