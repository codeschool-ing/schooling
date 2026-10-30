---
title: What the move costs, which no price list shows
version: 1
---

The cheapest column in the previous section is a price for running the workload once it is there.
**Getting it there is a second bill, paid in engineering time**, and it is often larger than a
year of the difference. A service that saves 20 USD a month by moving to Functions and needs six
weeks of rework to get there has bought the saving at a price nobody would sign for in writing.

What makes a move expensive is almost never the code that answers a request. It is what the code
quietly assumes about the place it runs. The shop's API is the example throughout, because it
assumes two of these things already.

## Five assumptions that do not travel

**A disk of its own.** A program on a virtual machine writes uploads, caches and reports to its
file system and finds them there tomorrow. A container's file system lasts as long as the container,
and a replica, a function instance or a pod can be replaced at any moment by the platform that
placed it. Moving off the machine means finding every write and sending it somewhere that outlives
the process first: the Azure Files share of lesson 3, mounted as lesson 7 mounted it for the
report, or Blob Storage, or a database.

**Memory that outlives a request.** Sessions kept in the process, an in-memory cache, a counter.
The shop has one: `app.py` keeps its orders in a Python list, `ORDERS`. Two copies of the image show
what that means, each on a port of its own. An order goes to the first, and both are asked for the
list:

```
ana@laptop:~/azure$ docker run -d --name shop-a -p 8081:8080 shop:1.0
c3b13233255e5254a508907791db20e568fef0bc80d7a432c060c994e4ca0ea4
ana@laptop:~/azure$ docker run -d --name shop-b -p 8082:8080 shop:1.0
d5e48f2b82a9240fcaf86eaf421cdb0457f749e8d3aaa330422b810645913d04
ana@laptop:~/azure$ curl -s -X POST localhost:8081/orders -d '{"item": "coffee", "qty": 2}'; echo
{"item": "coffee", "qty": 2, "id": 1}
ana@laptop:~/azure$ curl -s localhost:8081/orders; echo
[{"item": "coffee", "qty": 2, "id": 1}]
ana@laptop:~/azure$ curl -s localhost:8082/orders; echo
[]
ana@laptop:~/azure$ docker restart shop-a
shop-a
ana@laptop:~/azure$ curl -s localhost:8081/orders; echo
[]
```

The long strings are container ids, different on every run. **The second copy has never heard of
the order, and the first forgot it when it restarted.** On one machine that was a bug waiting for a
restart. On two replicas behind Container Apps' ingress, or two instances of an App Service plan,
every other customer would see an empty list, and on Functions there is no process to keep the list
in at all. The orders have to move to a shared store, a database, before the code can move
anywhere with two of anything, and that includes the pair of virtual machines.

**A process that runs for a long time.** A function stops at its timeout. On Flex Consumption the
default is 30 minutes and no maximum is enforced, but lesson 16 read the small print: an execution
gets 60 minutes of grace when its instance is taken away during scale-in. A Container Apps job has
the `replicaTimeout` of lesson 8, a deadline you choose. A virtual machine runs a job for as long as
the job likes, which is the one thing it does that nothing else here does by default.

**A request that waits a long time.** This is the limit that catches people, because it is not the
timeout they set. **An HTTP function has 230 seconds to answer**, in every plan, whatever its
timeout says; Microsoft's Functions documentation gives the reason as the default idle timeout of
Azure Load Balancer, and points to App Service's own FAQ for it, so plan for the same 230 seconds
on a web app. Container Apps' ingress documentation gives a request timeout of 240 seconds. An
endpoint that builds a five-minute file while the browser waits works on neither. It has to become a
job: accept the request, put it on a queue (lesson 20), and let the client collect the result
later. On Functions, Durable Functions (lesson 17) is the way to run work that outlasts a request.

**A connection that stays open.** A pool of 20 database connections per process is 40 for two
machines or two replicas, which the database expects. On Flex Consumption, a Python app takes one
HTTP request per instance at a time, so every request in flight is an instance, each with its own
pool. The shop's evening peak of 80 a second at 100 ms is eight instances; a burst to the app's
default maximum, the 100 instances of lesson 16, is 100 pools, and the database is the first thing
to fall over.

## What each option asks of the code

The same assumptions give a rough cost for each target, before a line of the code is read:

| target | what the code has to become |
| --- | --- |
| two virtual machines | nothing new: the process runs as it does today, and you take on the operating system, its patches and keeping the two alike (lesson 4) |
| Container Apps | a container image that listens on a port, which lesson 7's `shop:1.0` already is; no state in memory or on the local disk; configuration in environment variables |
| App Service | the same image, with its port in the app setting `WEBSITES_PORT` (lesson 18), or the code deployed as files; the same statelessness once the plan has two instances |
| Functions | a function signature: the web server replaced by handlers in `function_app.py` (lesson 15), every HTTP answer inside 230 seconds, one request per instance unless you raise it |
| AKS | the image, plus the manifests that run it: a Deployment, a Service and a route (lessons 11 and 14), on a cluster somebody upgrades |

**Moves towards Functions cost the most**, because a function assumes the least about where it
runs. The shop's `app.py` is a web server with its own routing, and on Functions the server is the
host's: each route becomes a handler with a decorator, and the process around them goes. What that
buys is lesson 15's point. Where the code is mostly input and output, a queue read here and a blob
written there, a binding replaces the client code, and the move deletes more than it writes.

Moves between the other four are cheap in one direction that matters: **the image is the same in
all of them.** The `shop:1.0` that ran in lesson 7 runs unchanged in lessons 8, 11 and 18. Moving
it from Container Apps to AKS is new manifests, not new code; from App Service to Container Apps, a
new resource around the same image. That is worth knowing before the first line is written, and
lesson 22 turns it into a decision about lock-in.
