---
title: Which shape for which force
version: 1
---

Lessons 1 to 3 have now named five shapes. **None of them is the next stage of another**; each is
the answer to a different question, and a real system usually mixes them. Quitanda could reasonably
run as a modular monolith for its shop, one stock service for the warehouse team, and three functions
for the glue around it.

| shape | it answers | it costs |
| --- | --- | --- |
| monolith, modular | one team, boundaries still moving, data that must agree at once | everything deploys and scales together |
| microservices | several teams that must release independently; parts with very different load or needs | the network, partial failure, no transactions across services, the per-service bill |
| SOA with a bus | integrating many existing applications that cannot be changed much | a central team and product in the path of every change |
| serverless functions | event-driven glue, bursty or rare load, scheduled jobs | cold starts, limits on run time, per-request cost at steady load, coupling to one platform |
| a service mesh on top of services | the same network chores repeated in many services and languages | a proxy per service, two hops per call, a control plane to run |

## The limits that decide some cases

Functions carry limits that settle some decisions on their own. AWS Lambda, for example, stops an
invocation after at most 15 minutes, and every platform sets some maximum. A job that runs for an hour
does not fit, whatever the bill would have been. A function keeps nothing between calls that it can
rely on, so a WebSocket connection held open for minutes, lesson 18, belongs somewhere else. And each
platform's triggers, permissions and configuration are its own, so a system built from fifty functions
on one provider is a system that moves to another provider only with a rewrite.

## The question to ask

For each part of the system, before picking a shape: **what force does this part feel?** A team that
needs to release alone, a load pattern, a runtime need, an integration with something that cannot
change. The force picks the shape. When no force is named, the cheapest shape that works is the
monolith from lesson 1, and lesson 4's twelve factors apply to it as much as to anything else.
