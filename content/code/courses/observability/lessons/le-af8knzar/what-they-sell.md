---
title: What an APM product sells
version: 1
---

APM stands for *application performance monitoring*, and the name is older than the products that
carry it. **What these products sell today is the stack this course has built, run by somebody
else**: an agent or SDK that collects, an intake that receives, a store for each signal, and one
interface over all of them.

The lab's version of that stack is about twenty containers on one machine. To run it in production a
team also needs what the lab skips: storage sized for weeks of data, upgrades for six projects that
release on their own schedules, backups, high availability for the parts that alert, and access
control. **That work is the first thing a hosted product replaces**, and for a small team it is often
the deciding one.

The second is what is hard to build at all. The products add things the open-source pieces either
lack or leave to you to assemble:

| | what it is | the open-source nearest |
|---|---|---|
| real user monitoring | timings and errors measured in the customer's browser or app | the OpenTelemetry JavaScript SDK, plus somewhere to send it |
| synthetic checks | scripted visits from many countries, on a schedule | the blackbox exporter, from one place |
| continuous profiling | which functions spend the CPU, all the time, in production | Pyroscope, now part of Grafana |
| session replay | a reconstruction of what the user saw before an error | nothing common |
| anomaly detection | a baseline learnt per series, and an alert when it breaks | recording rules written by hand |

The third is that **the joins come built**. Lesson 7 configured a data source per signal and lesson
11 needed one more setting for exemplars; a hosted product has every signal in one store, with the trace
id joining logs to traces by default.

What it does not sell is a different idea. The same three signals, the same trace id, the same
cardinality bill: everything lesson 1 to lesson 12 said still applies, and the products are judged
on how well they do those things and at what price.
