---
title: Choosing between them
version: 1
---

The two products overlap in what they do and differ in where they run and what they ask of you. The
questions that decide it are mostly not about features.

| | Langfuse | LangSmith |
|---|---|---|
| licence | open source (MIT), with some enterprise features under a separate licence | proprietary; the SDK is open source |
| where it runs | your machines, or Langfuse's cloud in the EU or the US | LangChain's cloud in the US or the EU; on your machines for enterprise customers |
| how spans arrive | OpenTelemetry (OTLP) or its own SDK, which is built on OpenTelemetry | its own SDK; OpenTelemetry ingestion as well |
| tied to a framework | no | no, though it is closest to LangChain and LangGraph |
| what running it costs you | six containers to operate, back up and upgrade | a bill per trace, and a contract about data |

**Where the data may go comes first.** Every trace carries what customers typed, redacted or not, and
lesson 2 showed redaction is never complete. For a shop in Brazil under the LGPD, sending that to
another company's servers abroad is an international transfer that needs a legal basis and a contract,
and some organisations' answer is simply no. If it is no, the choice is made: a self-hosted tool. If it
is yes, the hosted services save a great deal of operating work.

**Then who will run it.** Six containers, two databases and a queue are a small production system of
their own. They need backups, upgrades, disk, and somebody who knows them when the worker falls
behind. A team without that capacity is better served by a hosted service with a good contract than by
a self-hosted one nobody maintains.

**And keep the instrumentation portable.** The assistant in this lesson sent the same spans to a file
and to Langfuse with two environment variables, because it writes OpenTelemetry and its convention, and
the tool-specific names are added in a eleven-line adapter at the edge. That arrangement makes the
choice reversible. An application that calls one vendor's SDK in every function has made a decision
it will pay to undo.

`observability` lesson 13 asks the same questions of commercial APM products, and reaches the same
order: data first, operation second, features third. Lesson 7 applies it to two more tools, one built
on a different idea altogether.
