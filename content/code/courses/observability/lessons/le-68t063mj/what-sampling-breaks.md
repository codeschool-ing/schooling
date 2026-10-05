---
title: What sampling breaks
version: 1
---

Every join lesson 1 described assumes the trace is there. Sampling removes most of them, and the
joins fail quietly, with an empty answer that looks like a broken tool.

**An exemplar names a trace that may not exist.** The exemplars `orders` attaches to its histogram
are chosen by the histogram, the most recent request in each bucket, with no idea what the Collector
will keep. Four of them, from the last two minutes, opened in Jaeger:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/0a8b800ccc00dbc576a69bdcd97dd588 | jq -r 'if .data then "\(.data[0].spans | length) spans" else .errors[0].msg end'
trace not found
ana@obs:~/shop$ curl -s localhost:16686/api/traces/f1f82b5b65b25d8c97e5618fff901f70 | jq -r 'if .data then "\(.data[0].spans | length) spans" else .errors[0].msg end'
trace not found
ana@obs:~/shop$ curl -s localhost:16686/api/traces/77729df5a3c72f5bf3988b63edda48de | jq -r 'if .data then "\(.data[0].spans | length) spans" else .errors[0].msg end'
trace not found
ana@obs:~/shop$ curl -s localhost:16686/api/traces/953fe3b1cd4be851296dc0b06e6cd6ee | jq -r 'if .data then "\(.data[0].spans | length) spans" else .errors[0].msg end'
trace not found
```

Four exemplars, four traces that do not exist. With 12% of traces kept, that is the common outcome.
Under head sampling there is a fix, because the decision is known while the request runs: attach an
exemplar only when the span is sampled. The lab's `web.py` checks only that a span exists, and
adding `ctx.trace_flags.sampled` to that test would make every exemplar point at a kept trace.
OpenTelemetry's own metrics SDK does it by default, with the exemplar filter `trace_based`. Under
tail sampling nothing at measuring time knows the answer, and an exemplar is a guess.

**A log line names a trace that may not exist.** The head-sampling section showed it: every line
carries a trace id, and nine in ten of them lead nowhere. Lines of a failed request are the ones
somebody follows, which is one more reason to keep errors at the tail.

**A search sees only what was kept.** A search for slow checkouts under head sampling finds one in
ten of them, and its result looks complete. Under tail sampling it finds all of them, but a search
for *checkouts of the product `kettle`* finds 5% of the ordinary ones.

**Counting from traces is wrong under any sampling.** The span metrics of the previous section are
the counts; the traces are examples of what the counts describe.

A sampled store is a set of examples chosen by rules, and the rules belong in the documentation of
the system. Anybody reading a trace, or failing to find one, needs to know which requests could have
been dropped.