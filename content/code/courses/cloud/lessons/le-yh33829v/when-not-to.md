---
title: When a function is the wrong answer
version: 1
---

A function is the right tool when work arrives in bursts, finishes quickly and needs to remember
nothing. **Each case below breaks one of those three conditions**, and each was met in an earlier
section of this lesson.

- Long-running jobs. A one-hour video transcode or a forty-minute batch does not fit the 15-minute
  wall on Lambda, and a heavy computation hits the CPU-time limit on Workers much sooner. Cutting
  the job into steps is possible, and it is an architecture of its own; a container or a machine is
  often the simpler answer.
- Steady, high load. The crossover put it in dollars: at tens of requests a second, all day, every
  day, one or two machines cost less than the function.
- Heavy state. A cache warmed over hours, a large model held in memory, a game server holding a
  room: work whose value is in what the process remembers is work a function is built to forget.
- Strict latency on sparse traffic. When every request has to be fast and requests are few, cold
  starts land on real users. Provisioned concurrency fixes it by paying for idle copies, **at which
  point the function is a machine again with a different bill.**
- Portability. A handler's signature, its event shapes, its triggers and its permissions are one
  vendor's. **The logic inside a function can be kept portable; the wiring around it cannot.** Moving
  one function from Lambda to Workers means rewriting its edges, and a system of two hundred of them
  is a migration project.

None of these is a reason to avoid functions. They are the reasons to choose them for the parts of a
system that have the right shape, and not for the rest. That is how most systems end up: **a few
machines or containers for the steady core, and functions around the edges for what arrives in
bursts.**

::: track data
In a data pipeline the first natural use of a function is the one this lesson drew among its
triggers: **a file lands in a bucket, and a function fires to check it, record it or start the
load.** That fits well: it happens a few times an hour, it is short, and nobody is waiting. The heavy
transformation that follows usually does not fit, because it runs long and holds a lot in memory.
`pipelines-etl`, the next course in this track, continues the pipeline from that first event.
:::

::: track software-architecture
**Going serverless is an architecture decision, not a hosting choice.** The system becomes
event-driven, cut into many small deployables that talk through queues, buckets and gateways rather
than calls inside one process. That buys scaling and deploying each part on its own, and it costs a
system that is harder to see whole, to trace from end to end and to run on one machine. The vendor's
runtime, its event shapes and its limits become a dependency of the design, and they belong in the
decision record like any other dependency.
:::

::: track *
**Serverless is excellent at spiky, event-shaped work and poor at steady, long-running work.** An
API that is quiet most of the day, a file to process when it arrives and a job on a schedule are its
shape. When the work does not have that shape, a machine or a container is the plainer answer.
:::
