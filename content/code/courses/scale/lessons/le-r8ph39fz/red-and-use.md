---
title: What to measure first
version: 1
---

A program can emit thousands of metrics, and most dashboards fail by showing all of them. Two short
lists, each for a different kind of thing, cover most of what matters.

**For a service that answers requests, RED**, from Tom Wilkie:

- **Rate**: requests per second.
- **Errors**: how many of them fail.
- **Duration**: how long they take, as a distribution, not an average.

These are the box office from its users' side, and they are what `load.py` printed in every lesson:
requests per second, statuses, four points of latency. The difference now is that the box office
will report them itself, for every request from every client, all the time.

**For a resource that work waits for, USE**, from Brendan Gregg:

- **Utilisation**: the share of time it is busy. The processor at 100% of lesson 1.
- **Saturation**: how much work is waiting for it. The queue that made latency double with the
  workers, and the fifteen connections waiting on a lock in lesson 1's hot row.
- **Errors**: how often it fails.

Resources are processors, memory, disks, connection pools, locks. **RED tells you that users are
suffering; USE tells you why.** The bottleneck of lesson 1 is, in these words, a resource whose
utilisation is near 100% and whose saturation keeps growing.

Google's book on site reliability engineering gives a closely related list of four **golden
signals**, latency, traffic, errors and saturation, which is RED with saturation added.

## The box office, against the lists

| | what the box office will report | where in this lesson |
|---|---|---|
| rate | `tickets_requests_total`, a counter per route and status | section 06 |
| errors | the same counter, status 500 | section 08 |
| duration | `tickets_request_seconds`, a histogram per route | section 07 |
| utilisation | `process_cpu_seconds_total`, which the library reports for free | section 06 |
| saturation | `tickets_in_flight`, requests in progress | section 06 |

Five series of numbers, and with them every question asked of the box office in lessons 1 to 6
can be answered after the fact.
