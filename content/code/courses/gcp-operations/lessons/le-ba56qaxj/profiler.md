---
title: Cloud Profiler, and where the CPU goes
version: 1
---

**A profiler answers a question neither metrics nor traces can: inside the process, which functions use the
CPU and the memory.** A trace says the API spent 2.3 seconds in itself; a profile says those seconds were
spent in a JSON encoder serialising the same product list on every request. Cloud Profiler collects profiles
from running services continuously, a few seconds at a time from each instance, with an overhead Google states
as small enough for production, and draws them as a flame graph. **Nothing in this section was run**: it needs
the Profiler agent talking to Google, and has no emulator.

## How it is turned on

Profiler is an agent in the process, a library imported at start-up:

```python
import googlecloudprofiler

googlecloudprofiler.start(service="shop-api", service_version="a1b2c3d")
```

The service account the process runs as needs `roles/cloudprofiler.agent`. The agent supports Go, Java,
Node.js and Python, each with the profile types its runtime can measure: CPU time and wall time, heap and
allocated memory, threads and contention, not all of them in every language.

## Reading a flame graph

Each bar is a function; its width is the share of the measured resource spent in it and in what it called;
a bar sits on top of its caller. **Read it by width, not by height.** A tall, narrow tower is a deep call
stack that costs little. A wide bar near the top is a single function that costs a lot by itself, and is
where to look first.

Profiler compares, too: two time ranges, or two versions from `service_version`, side by side. A release
that made the API 30% slower shows up as one bar that grew, which is much faster to find than by reading the
diff.

## Which of the three to reach for

| the question | the tool |
|---|---|
| which error is new, and how often does it happen? | Error Reporting |
| where did this one slow request spend its time? | Cloud Trace |
| what does the process spend its CPU on, overall? | Cloud Profiler |
| is it worse than usual right now? | a metric and an alert (lessons 8, 10, 14) |

The first three investigate; the fourth notices. None of them replaces the others, and the order an incident
uses them in (notice, then find the request, then find the function) is the order of lesson 15.
