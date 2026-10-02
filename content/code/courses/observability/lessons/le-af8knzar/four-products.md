---
title: Four products, four histories
version: 1
---

The four in this lesson's title are not four versions of the same thing. **Each began with one
problem and grew towards the others**, and where it began still shows in what it does best and in
what it charges for.

| | began as | collects with | bills mainly by |
|---|---|---|---|
| Datadog | infrastructure metrics for cloud servers, 2010 | the Datadog Agent on each host, plus a tracing library per language | hosts, plus the volume of logs, indexed spans and custom metrics |
| New Relic | application performance for Ruby on Rails, 2008 | an agent per language | data ingested, in gigabytes, plus the number of full users |
| Dynatrace | deep application monitoring for enterprise Java and .NET | OneAgent, installed once per host, which instruments every process it finds | consumption: host memory per hour, data ingested and queries |
| Sentry | an open-source error logger for Django, 2008 | an SDK per language, inside the application | events: errors, spans, replays |

Read the last column as a set of units rather than prices. Prices change every year and differ by
contract, and the price page of each product is the only source worth quoting. **The unit is what
lasts**, and it decides which of your habits becomes expensive.

Three differences matter in practice:

- **Dynatrace instruments without being asked.** OneAgent finds the processes on a host and injects
  its instrumentation into each, so traces appear before anybody writes code. It is the furthest any
  of them goes from lesson 2's spans written by hand, and its causal analysis, which the product calls
  Davis, rests on that complete picture.
- **Datadog is the broadest.** It began with the host and the cloud account, and its integrations,
  hundreds of them, are what most teams adopt it for; APM and logs came later and are billed apart.
- **Sentry is about the error.** It groups exceptions into issues, tracks them across releases and
  says when a fixed one comes back. It added tracing later, and it is the only one of the four whose
  server can be run yourself.

Elastic, Grafana Cloud and Honeycomb sell the same kind of thing and come up in the same evaluations;
the first two are the hosted forms of stores this course has run.
