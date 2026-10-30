---
title: A metric, its aggregation and its dimensions
version: 1
---

**A metric is a series of numbers over time, and a chart of it always shows an aggregation, never the
raw values.** App Service's `HttpResponseTime` is recorded per minute as a count, a sum, a minimum and a
maximum of the requests in that minute. Ask for the average over an hour and Azure Monitor computes it
from those; ask for the maximum and you get the slowest minute's slowest request. The same metric, read
two ways, tells two different stories, and the chart's title is where it says which.

The trap is the average. An average response time of 180 ms over a minute is equally true of a minute
where every request took 180 ms and a minute where most took 60 ms and a few took four seconds. The
customers in the second minute were not served at 180 ms; some of them gave up. Platform metrics
generally offer average, minimum, maximum, sum and count, and not percentiles. That is the strongest
reason the shop measures latency from its request logs as well, where lesson 10 can compute the 95th
percentile directly.

**A dimension splits a metric.** `Http5xx` on an App Service plan can be split by instance; a storage
account's `Transactions` by API name and by response type. Splitting turns one line into several, which is
how you find that the errors all come from one instance. Not every metric has dimensions, and a metric's
documentation lists which it has.

What this lab cannot show is a metric itself: metrics come from running resources, and there are none
here. So the rest of the monitoring lessons work from **logs** loaded into the Kusto emulator, which is
where the questions that matter during an incident are answered anyway. When a metric is the right tool,
for a cheap alert on CPU, say, the lesson says so and teaches it from the documentation.
