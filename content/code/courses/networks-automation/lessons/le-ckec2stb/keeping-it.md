---
title: What to do with a stream
version: 1
---

A subscription produces values forever, and a script that prints them is a demonstration, not a
system. **In production a collector subscribes and writes every value into a time-series
database**, and dashboards and alerts read from there. `gnmic` itself can run as that collector,
with outputs for Prometheus, InfluxDB and Kafka, and Telegraf has a gNMI input that does the same.
None of those run in the lab; what they all have to get right is the same few things this
lesson's scripts already touched.

- **The timestamp comes from the device.** `rate.py` divided by the time between two samples as
  `edge1` measured it. A collector that uses its own arrival time turns every network hiccup into
  a spike in the graph.
- **Counters are cumulative, and they restart.** A counter goes back to zero when the device
  reboots or the interface is recreated, and an old 32-bit counter wraps after about 4.3 billion.
  A rate computed across the reset is negative; a collector must detect it and skip that interval
  rather than draw it.
- **Wait for `sync-response`** before trusting the current state. Before it, the collector has
  only part of the picture.
- **A subscription dies with its connection.** gRPC runs over one long-lived TCP connection, and
  when the device reboots or a firewall times the connection out, the stream just stops. The
  collector has to notice the silence and subscribe again, and an ON_CHANGE stream that has
  quietly stopped looks exactly like a network where nothing is changing.

**Sample what you can graph; subscribe on change to what you alert on.** Counters every ten or
thirty seconds are plenty for capacity graphs. Oper-status, routing adjacencies and anything else
a person should be woken for belongs in an ON_CHANGE subscription, where the message arrives
when the event does.
