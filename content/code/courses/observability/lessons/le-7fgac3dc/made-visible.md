---
title: Nothing is visible that was not made visible
version: 1
---

A common picture of observability is a product: something you install, point at production, and
then look at. **No product can show you a number your code never produced.** A dashboard draws what
it was sent, a log search finds the lines somebody wrote, and a trace exists only where every
service on the path agreed to carry it. Before any of that, somebody decided what the system would
say about itself.

That is why this course starts with instrumenting, and only then reaches the tools that store and
draw what the instrumentation produces. Reading a dashboard is the easy half. Making sure the
dashboard has something true to draw is the half that needs a running service, and it is the half
that decides whether the other one is worth anything.

**Monitoring and observability answer different questions.** Monitoring watches for conditions
somebody already knew to worry about: is the service up, is the disk full, are errors above two per
cent. Observability is being able to ask a question nobody planned for, from the outside, and get
an answer: *why are checkouts paid with one card brand slower since Tuesday?* The first needs a
list of checks. The second needs signals rich enough that the question can be put to them after the
fact.

Three kinds of signal carry almost all of it, and the field calls them the **three pillars**:

| signal | what one of them is | what it answers well |
|---|---|---|
| metric | a number, sampled over time, with a few labels | how much, how often, is it getting worse |
| log | one event, written when it happened, with fields | what exactly happened, in words and values |
| trace | one request's path through every service it touched | where the time went, and which call failed |

"Pillar" suggests three separate structures. **They are three views of the same events**, and the
rest of this lesson takes one slow checkout and looks at it through each. OpenTelemetry, the
standard this course instruments with, defines all three and has been adding a fourth, profiles,
which this course does not cover.
