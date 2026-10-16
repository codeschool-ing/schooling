---
title: Metrics, logs and traces
version: 1
---

Every measurement in this course so far came from **outside** the box office: `load.py` timing its
own requests, `docker stats` reading a container's processor, `pg_stat_activity` asked by hand at
the right moment. That works in a lab, where you start the load and know when to look. **In
production the load starts itself, at three in the morning**, and the question is what happened
twenty minutes ago. A system has to record what it does, continuously, in a form that can be asked
later. That is what **observability** means in practice: being able to answer a question about the
system's behaviour from the data it already emits, without shipping new code to find out.

Three kinds of data, called **signals**, do most of the work, and each answers a different question:

- **Metrics** are numbers, counted or measured and summed over time: requests per second, the
  95th percentile of latency, connections in use. They are cheap, because a counter is one number
  however many requests it counts, and they answer **"how much, and is it normal?"**
- **Logs** are records of individual events, with their details: this request, this status, this
  error message. They answer **"what exactly happened to this one?"**, and they cost in proportion
  to the traffic.
- **Traces** follow one request through every service it touches, with the time spent in each.
  They answer **"where did the time go?"** in a system of several services. Lesson 8 builds them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"One sale seen three ways. As a metric, it is one more increment of a counter and one more count in a latency bucket, added to thousands of others. As a log, it is one line with its route, status and duration. As a trace, it is a bar for the whole request with nested bars for the database update, the signing and the insert, showing where its time went.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">metric</text><text x=\"140\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests_total{route=&quot;/events/{id}/tickets&quot;,status=&quot;201&quot;}  13250 → 13251</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">log</text><text x=\"140\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{&quot;level&quot;: &quot;info&quot;, &quot;route&quot;: &quot;/events/{id}/tickets&quot;, &quot;status&quot;: 201, &quot;ms&quot;: 43.2}</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">trace</text><rect x=\"140\" y=\"138\" width=\"520\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /events/{id}/tickets  43 ms</text><rect x=\"150\" y=\"170\" width=\"40\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">UPDATE</text><rect x=\"195\" y=\"170\" width=\"380\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"385.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">sign()</text><rect x=\"580\" y=\"170\" width=\"40\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">INSERT</text><text x=\"400\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">how much · what exactly · where the time went</text></svg>", "caption": "The same sale as a number among many, as a record, and as a timeline."}
```

They are used together, in that order. A metric says that something is wrong and roughly where:
sales got slow at 03:10. A trace says which part of the sale got slow. A log says what that part
was doing: which query, which error, which input. **A system with only logs answers everything
slowly; a system with only metrics answers nothing in detail.**

This lesson gives the box office its metrics and its logs, collects the metrics with Prometheus,
and asks them the questions earlier lessons answered by hand.
