---
title: Proprietary agents and OpenTelemetry
version: 1
---

Every product above started with its own agent, and for years that agent was the product: the
instrumentation was written against the vendor's library, and the data went only to the vendor. **The
lock-in was in the code.** Leaving meant re-instrumenting every service, which is why teams rarely
left.

OpenTelemetry changed where the line sits. All four products now accept OTLP, the protocol the lab's
services speak to the Collector, so a service instrumented as lesson 2 and lesson 3 did can send its
data to any of them. What a vendor still adds is on either side of that protocol:

- **its own distribution of the SDK or the Collector**, with defaults chosen for its intake;
- **instrumentation for what OpenTelemetry covers less well**, such as some runtimes and frameworks;
- **its own agent with extra features**, profiling or automatic injection, that need it.

The rule that keeps the choice open is simple to state: **instrument with OpenTelemetry, and keep
vendor code at the edge**, in the Collector's exporters or in a vendor's distribution that can be
swapped. A vendor's library inside the business code is the expensive kind of dependency, the one
that has to be removed line by line.

Two cautions keep the rule honest. Accepting OTLP is not the same as treating it as a first-class
input: some features of a product may work only with its own agent, and the evaluation should check
which. And semantic conventions, the attribute names lesson 2 followed, are what a vendor's interface
reads to draw its views; data that follows them looks right in every product, and data that does not
looks half-empty in all of them.
