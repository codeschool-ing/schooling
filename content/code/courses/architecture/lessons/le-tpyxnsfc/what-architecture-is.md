---
title: What architecture decides
version: 1
---

The common picture is that architecture is a diagram: boxes, arrows, a cloud in the corner, drawn
at the start of a project and framed on a wall. **Architecture is the set of decisions about a
system that are expensive to change once the system exists**, and the diagram is only one way of
writing some of them down.

The test is the cost of reversing a choice. Renaming a variable costs a minute, so it is not an
architectural decision. Choosing one database for the whole system, splitting the code into
services that talk over a network, or deciding that an order is confirmed before the payment
clears all cost weeks to undo, because by then other code, other teams and real data depend on
them. Those are the decisions this course is about.

## What the decisions are for

A decision is never right in general. It is right for a set of **quality attributes**, the
properties a system has to have beyond doing its job, and those pull against each other:

| attribute | the question it asks |
| --- | --- |
| availability | what share of the time does it answer? |
| latency | how long does one request take? |
| throughput | how many requests can it take per second? |
| consistency | does everybody see the same data at the same moment? |
| modifiability | how long does a change take, and how many people must agree to it? |
| operability | how many things have to be watched, deployed and fixed at three in the morning? |
| cost | what does it take to run, in machines and in people? |

Nearly every lesson in this course is a trade between two rows of that table. Splitting a
program into services buys modifiability for separate teams and pays in latency and operability
(lesson 2). Replicating data buys availability and pays in consistency (lessons 8 and 9). A retry
buys availability and can pay in throughput, sometimes all of it (lesson 11).

## The shape of the course

| lessons | subject |
| --- | --- |
| 1 to 4 | the shape of a system: monolith, services, SOA, serverless, a mesh, and the twelve factors |
| 5 to 7 | how services talk: synchronous calls, queues and logs, and what "delivered" means |
| 8 to 10 | the data across them: CAP, eventual consistency, replication and sharding |
| 11 and 12 | staying up when a part fails: retries, circuit breakers, bulkheads, back pressure |
| 13 to 16 | patterns from the cloud design catalogues: CQRS, event sourcing, saga, strangler, sidecar, and the antipatterns |
| 17 to 19 | search, real time, discovery and the gateway |
| 20 | writing the decisions down so that they can be defended |

**One example runs through all of it: Quitanda**, a grocery shop that sells tomatoes, coffee and
cheese for delivery. It starts in this lesson as one program, and each later lesson builds the
part of it that lesson needs, on your own machine, from files the lesson shows you whole.

`scale`, the course after this one in the `backend` track, takes the same patterns to their
limits: measuring load, observing a system across services, and planning capacity. This course
gives them their names and shows each one working.
