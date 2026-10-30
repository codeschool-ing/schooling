---
title: Five kinds of window
version: 1
---

**This section is taught from Microsoft's documentation and was not run.** The course's program of
the last section implements tumbling windows only; the other four are shown in the service's own
query language, as Microsoft documents them.

**A window turns an endless stream into finite groups that an aggregate can finish.** `COUNT(*)`
over a stream never ends, because the stream never does; `COUNT(*)` over the events between 20:00
and 20:01 is a number. Stream Analytics has five ways of cutting the time line, and each answers a
different question. All five are written in `GROUP BY`, and `System.Timestamp()` in the `SELECT` is
the time the window ends.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four ways of cutting the same eight events on a time line into windows. Tumbling: one-minute windows back to back, each event in exactly one. Hopping: two-minute windows starting every minute, overlapping, so each event falls in two. Sliding: a window exists only where an event enters or leaves it, ending at each event. Session: one window per burst of events, closed after a gap with no events, giving three sessions.\" data-fig=\"l23-windows\"><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tumbling</text><line x1=\"130\" y1=\"76\" x2=\"700\" y2=\"76\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"158.5\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"206.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.5\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"377.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"405.5\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"548.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"586.0\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hopping</text><line x1=\"130\" y1=\"136\" x2=\"700\" y2=\"136\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"158.5\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"206.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.5\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"377.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"405.5\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"548.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"586.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sliding</text><line x1=\"130\" y1=\"206\" x2=\"700\" y2=\"206\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"158.5\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"206.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.5\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"377.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"405.5\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"548.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"586.0\" cy=\"206\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">session</text><line x1=\"130\" y1=\"266\" x2=\"700\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"158.5\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"206.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.5\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"377.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"405.5\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"548.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"586.0\" cy=\"266\" r=\"3.5\" fill=\"var(--amber)\"></circle><rect x=\"132\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"227\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"322\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"417\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"607\" y=\"44\" width=\"91\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"132\" y=\"102\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"227\" y=\"116\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"322\" y=\"102\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"417\" y=\"116\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"102\" width=\"186\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"130\" y=\"172\" width=\"28.5\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"181\" width=\"76.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"139.5\" y=\"190\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"282.0\" y=\"172\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"310.5\" y=\"181\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"453.0\" y=\"190\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"472.0\" y=\"172\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"491.0\" y=\"181\" width=\"95.0\" height=\"8\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><rect x=\"152.5\" y=\"236\" width=\"88.0\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"371.0\" y=\"236\" width=\"40.5\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"542.0\" y=\"236\" width=\"50.0\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"130\" y1=\"280\" x2=\"130\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"130\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"225\" y1=\"280\" x2=\"225\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"225\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><line x1=\"320\" y1=\"280\" x2=\"320\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"320\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><line x1=\"415\" y1=\"280\" x2=\"415\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"415\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><line x1=\"510\" y1=\"280\" x2=\"510\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"510\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><line x1=\"605\" y1=\"280\" x2=\"605\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"605\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"700\" y1=\"280\" x2=\"700\" y2=\"286\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"700\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"700\" y=\"276\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">event time, minutes</text></svg>", "caption": "The same eight events, cut four ways: back to back, overlapping, wherever an event changes the window, and one window per burst."}
```

**Tumbling: fixed, back to back, never overlapping.** Every event belongs to exactly one window. It
is the window of a report by minute or by hour, and of the job in this lesson:

```sql
GROUP BY TumblingWindow(minute, 1)
```

**Hopping: fixed size, starting at a fixed step, overlapping when the step is shorter than the
size.** "Checkouts in the last five minutes, updated every minute" is a hopping window of five
minutes with a hop of one, and every event is counted in five windows. A hopping window whose hop
equals its size is a tumbling window.

```sql
GROUP BY HoppingWindow(minute, 5, 1)
```

**Sliding: a window that exists wherever events change it.** The service produces a row only when
an event enters or leaves the window, so a quiet hour produces nothing and a burst produces a row
per event. It answers "did more than ten checkouts of one customer fall within any ten minutes",
the kind of question the fraud check asks, which a tumbling window misses when the ten straddle a
boundary.

```sql
GROUP BY customer, SlidingWindow(minute, 10)
HAVING COUNT(*) > 10
```

**Session: a window per burst of activity.** It starts with an event and stays open while events
keep arriving within a timeout of each other, closing after the timeout passes with no event, or at
a maximum duration. Grouped by customer, it is one window per visit to the app, which is what the
analysts mean when they ask how long a visit lasts.

```sql
GROUP BY customer, SessionWindow(minute, 5, 30)
```

The first number is the timeout and the second the longest a session may last.

**Snapshot: events that share exactly the same timestamp.** There is no window function; grouping
by `System.Timestamp()` itself groups the events that carry the same time, and it is mostly used
on the output of another window, to aggregate the rows a previous step produced at one instant.

```sql
GROUP BY System.Timestamp()
```

## What a window costs while it is open

**A window holds state until it closes**: a count is one number per window, but a `COUNT(DISTINCT
customer)` over an hour holds every customer seen in that hour, and a session window grouped by
customer holds one open session per customer currently using the app. The longer and the more
finely grouped the window, the more memory the job needs, and memory is part of what the streaming
units of the last section buy. A hopping window of a day with a hop of a minute keeps 1,440
overlapping windows open at once.
