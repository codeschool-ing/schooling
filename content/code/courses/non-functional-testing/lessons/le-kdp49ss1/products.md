---
title: Five products and what each is for
version: 1
---

The lesson's title names five products, and job adverts name them the same way, as if they were
five brands of one thing. They are not. Each one started from one of the three signals, or from a
way of looking at them, and grew outwards from there; today their catalogues overlap so much that
the starting point is the best way to remember what each is for.

| product | started as | the question it answers best | runs where |
|---|---|---|---|
| **New Relic** | APM, application performance monitoring: an agent inside your application that times every transaction | which endpoint got slow, and which call inside it | a hosted service |
| **Datadog** | infrastructure metrics: an agent on every host, collecting processors, disks, containers | which machine, container or queue is in trouble | a hosted service |
| **Grafana** | dashboards: graphs drawn over data stored somewhere else, Prometheus most often | what do the numbers look like, side by side, over time | your own server, or Grafana Labs' hosted one |
| **Kibana** | the search screen of Elasticsearch: logs indexed so that any field can be filtered | which log lines match, and what they have in common | your own server, or Elastic's hosted one |
| **Sentry** | error tracking: every exception, with its stack trace, grouped with the others like it | which error is new since the last release, and how many users it hit | a hosted service, or your own server |

**APM** is the oldest of the categories and the one that most resembles what you have done in this
course. An APM agent is a library loaded into the application. It wraps each incoming request and
each outgoing call — the database, an HTTP client, a queue — so it can report a trace for a sample
of requests and RED metrics for all of them without you writing a line. New Relic, Datadog,
Dynatrace and Elastic all sell one.

**Grafana stores nothing by itself.** It draws what a data source answers: Prometheus, Loki for
logs, Tempo for traces, a SQL database, Elasticsearch. That is why it sits beside Prometheus in so
many teams: Prometheus collects and answers queries, Grafana draws the answers. The company behind
it, Grafana Labs, also owns k6, which is why the banner of every k6 run in this course says
*Grafana*.

**Sentry is the one a developer opens first**, because it answers in the language of code: this
exception, in this file, at this line, introduced in this release, seen by this many users.
Metrics say that errors went up. Sentry says which error it was.

## What this lesson runs instead

All five are services you sign up for or servers you install and feed, and none of them runs in
the machine this course is recorded on. **Nothing in this lesson shows a screenshot of any of
them**, and nothing quotes their output, because none of it was run here. Their screens change
every few months; what each one is for changes far more slowly.

What the lesson does run is the open-source core that two of them are built around:

- **Prometheus** for metrics, the system Grafana draws most often, installed from Ubuntu's archive.
  Its query language, PromQL, is the one lesson 24 writes its alert in, and Grafana's own hosted metrics
  service speaks it too.
- **`jq` over a file of JSON lines** for logs. It is Kibana's job at the size of one machine: filter
  by a field, count, find one request by its id. Kibana does the same over billions of lines from
  hundreds of machines, with an index that makes it fast.

Error tracking and tracing you will see in miniature: the error field boxoffice writes into its log
when a request crashes, and the `Server-Timing` header it already sends.

## Lock-in, and OpenTelemetry

Every one of these products began with its own agent, its own wire format and its own query
language: New Relic has NRQL, Datadog its own query syntax, Prometheus PromQL, Kibana KQL and
Lucene. **The instrumentation is the expensive part to change**, because it lives inside every
service the company runs, and the dashboards and alerts written in one vendor's language do not
move to another's. A team that instrumented everything with one vendor's agent in 2018 pays that
vendor's price in 2028, or re-instruments every service.

**OpenTelemetry** is the industry's answer: an open standard, under the Cloud Native Computing
Foundation, for producing all three signals. It defines the libraries an application uses to emit
metrics, logs and traces, a wire protocol called OTLP, and a *collector*, a program that receives
that data and forwards it to whichever back end you choose. Instrument with OpenTelemetry once, and
changing vendor means changing where the collector sends things rather than touching the
application. All five products above publish ways to take in OpenTelemetry data, though how
complete each one is varies, and changes faster than this course does.

It does not remove the lock-in of the query language. **An alert written in PromQL is still an
alert written in PromQL**, and lesson 24's rules would need rewriting for a product that does not
speak it.
