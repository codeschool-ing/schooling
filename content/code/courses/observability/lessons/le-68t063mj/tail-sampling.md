---
title: Deciding at the tail
version: 1
---

**Tail sampling decides after the trace has ended**, so it can decide on what happened. The services
go back to recording every trace, and the Collector holds each one until it is complete, then keeps
it if any of its policies says so. The lab's sampling configuration, `otel/collector-sampling.yaml`,
has three:

```
ana@obs:~/shop$ sed -n '/^  tail_sampling:/,/^  memory_limiter:/p' otel/collector-sampling.yaml
  tail_sampling:
    decision_wait: 10s
    num_traces: 20000
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow
        type: latency
        latency: {threshold_ms: 1000}
      - name: a-few-of-the-rest
        type: probabilistic
        probabilistic: {sampling_percentage: 5}
  memory_limiter:
```

- **`errors`**: any span with an error status keeps the whole trace.
- **`slow`**: a trace longer than one second is kept.
- **`a-few-of-the-rest`**: 5% of everything, so that there are ordinary traces to compare the
  slow ones with. Without a baseline, every trace in the store is a problem and nobody can say what
  normal looks like.

`decision_wait` is how long the Collector waits after a trace's first span before deciding. To give
the policies something to find, payments is told to add 1500 ms to every twenty-fifth charge and to
fail every fortieth. After two minutes, the Collector's own metrics say what each policy kept:

```
ana@obs:~/shop$ ./promq 'sum by (policy) (increase(otelcol_processor_tail_sampling_count_traces_sampled{decision="sampled"}[2m]))'
policy=a-few-of-the-rest  34.285714285714285
policy=errors  13.714285714285714
policy=slow  21.71428571428571
```

```
ana@obs:~/shop$ ./promq 'sum by (decision) (increase(otelcol_processor_tail_sampling_global_count_traces_sampled[2m]))'
decision=not_sampled  475.4285714285714
decision=sampled  65.14285714285714
```

About 540 checkouts in two minutes, and 65 kept, 12%. `errors` kept 14, which is every fortieth
charge; `slow` kept 22, every twenty-fifth; `a-few-of-the-rest` kept 34, near its 5%. The three add up
to more than 65 because a trace can satisfy two policies at once, and the counts are fractional
because `increase` extrapolates to the edges of its window, as lesson 5 showed.

And what that does to the volume:

```
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'
  39.86666666666666
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_exporter_sent_spans{exporter="zipkin"}[1m]))'
  4.933333333333334
```

Forty spans a second arrive and five leave. **The traces in the store are now the ones worth
opening**. A search in Jaeger for errors finds every error of the last two minutes, and a search for
slow checkouts finds every slow one, not one in ten.

The policies are evaluated together and any one of them is enough. The processor has more types than
these three: on an attribute's value, on a span count, on the rate per second, and combinations of
them. A policy on an attribute is how a team keeps every trace of one important customer, or of one
new release, for a week.
