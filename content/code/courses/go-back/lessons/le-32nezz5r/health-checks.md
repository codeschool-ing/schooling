---
title: What the platform asks
version: 1
---

Once boxoffice runs somewhere other than your terminal, something else decides when to start it, when to
send it requests, when to restart it and when to stop it: Docker, Kubernetes, a cloud platform, systemd.
That something cannot read the log the way you do. **It asks the process questions, over HTTP, and acts on
the answers**, and the answers have to be designed as carefully as any other endpoint, because a wrong one
gets acted on automatically.

There are two questions, and mixing them up is the classic mistake:

| question | the platform's word | what a "no" makes it do | what must decide the answer |
|---|---|---|---|
| **Is this process working at all?** | liveness | kill it and start another | only the process itself: can it still answer? |
| **Should this process be sent requests now?** | readiness | stop sending it traffic, and wait | whether what it needs right now is there: the database, a warm cache, not shutting down |

**A liveness check that tests the database is a trap.** When the database goes down, every copy of
boxoffice fails its liveness check at the same moment, and the platform restarts all of them. They come
back, the database is still down, and they are restarted again, in a loop that adds load to a system that
is already in trouble and fixes nothing: a restarted boxoffice cannot reach a database that is down any
better than the old one. Liveness should fail only for what a restart cures, a deadlock or a process that
has stopped answering, and the cheapest honest test of that is answering at all.

Readiness is where dependencies belong. A process whose database is gone should stop receiving requests
it cannot serve, so the load balancer sends them to a copy that can, or nowhere; and it should start
receiving them again by itself when the database returns. **Readiness is also how a process leaves
gracefully**: section 06 has boxoffice report "not ready" the moment it starts shutting down.

A third check, startup, exists in Kubernetes for processes that take minutes to start, so liveness does
not kill them during it. boxoffice starts in milliseconds and does not need one.

## A port of their own

Health checks and metrics are for the machinery around the service, not for its customers. boxoffice
serves them on a third listener, `-ops`, `localhost:9100` by default: one more line in lesson 14's
configuration. **That port is never published to the internet**: metrics describe the inside of the
service in detail, and the platform reaches the port from inside the network.

Lesson 13 left one more thing to watch for, and section 03 runs into it.
