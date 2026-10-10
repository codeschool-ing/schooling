---
title: The bill for a second service
version: 1
---

The cost of a service is mostly paid outside its code. **Each one needs everything the monolith
needed once, again**, and the work that was done once for the whole system is now done per
service, forever.

Even at rest, each service is a process with a runtime in it. Here are the two containers of the
lab, doing nothing:

```
ana@vm:~/lab/split$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
NAME            MEM USAGE / LIMIT
split-shop-1    18.27MiB / 15.72GiB
split-stock-1   10.85MiB / 15.72GiB
```

Two small Python programs, and each one holds its own interpreter in memory.
The number per container is small here and it is per service: on the JVM, a service that does
almost nothing commonly starts at a few hundred megabytes, and ten of them are a machine.

Memory is the cheap part. The list that grows with every service is this one:

| per service | what it is |
| --- | --- |
| a pipeline | build, test and publish an image on every commit |
| a deployment | its own configuration, its own number of copies, its own rollout and rollback |
| health checks | a way for the platform to know it is up and ready, lesson 19 |
| logs that can be joined | a request id in every line, as `X-Request-Id` here, and somewhere to search all of them together |
| metrics and alerts | its own error rate, latency and saturation, with somebody paged when they go wrong |
| an API contract | versioned, documented, and tested against its callers, because it can no longer change in step with them |
| secrets and identity | its own credentials, and a way for the services to know who is calling, which `apis` covers |
| an owner | a team that answers for it at three in the morning |

**Multiply the table by the number of services** before deciding on a number. Quitanda with two
services pays it twice. Split by every noun, catalogue, stock, orders, payments and delivery, it
pays it five times, for a shop that one team of six could run as one program.

## Where the cost goes down

The per-service cost falls with platform work: a shared pipeline template, a deployment platform
that every service uses the same way, logging and metrics collected without each team building
them. Companies with hundreds of services keep a platform team for exactly that. **That platform is
itself a cost**, and it is one reason microservices suit large organisations better than small
ones. Lesson 3 looks at two products of that platform work, serverless functions and the service
mesh, which take some of the list off each team.

Stop the lesson's services now:

```sh
docker compose down -v
```
