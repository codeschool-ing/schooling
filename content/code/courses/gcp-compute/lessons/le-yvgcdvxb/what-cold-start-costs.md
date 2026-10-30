---
title: What a cold start actually costs
version: 1
---

A cold start is the wait of a request that arrives when no instance is free to take it. **It is the
sum of three things, and only one of them is yours to shorten much: what your program does before
it listens.** The other two, getting the image to the machine and starting the container, are Cloud
Run's, and Google has spent years making them small.

## The three parts

**The image.** Cloud Run fetches the image from Artifact Registry. Google's documentation says it
streams images so that a container can start before the whole image has arrived, which is why image
size matters less than intuition says, though a smaller image still helps. Lesson 21 is about the
registry.

**The container.** The runtime starts, a sandbox around the container is set up, the process starts.
This part is the platform's and short.

**Your program, until it listens.** Imports, configuration, connections, caches warmed, a model
loaded. This is the part that varies from a few milliseconds to a minute, and **it is entirely
yours**.

## Measuring it at home

This laptop cannot measure Cloud Run's first two parts, and nothing here pretends to. What it can
measure is the last part, and a container start, which is the same order of magnitude. From `~/gcp`,
start the orders service and wait until `/health` answers, all inside one `time`:

```
ana@laptop:~/gcp$ time (docker run -d --name orders-cold -p 8080:8080 orders:1 > /dev/null; until curl -sf localhost:8080/health > /dev/null; do sleep 0.02; done)

real	0m0.537s
user	0m0.063s
sys	0m0.050s
ana@laptop:~/gcp$ time curl -s localhost:8080/health
{"status": "ok"}
real	0m0.007s
user	0m0.005s
sys	0m0.000s
```

**On this laptop, from `docker run` to the first answer took about half a second**, and the next
request, to a warm instance, a few milliseconds. Almost all of the half second is the container and
Python starting; the orders service itself does nothing before it listens.

Now the part that does vary. A program's imports are part of its start, and a large library costs
real time. Compare importing Google's Pub/Sub client, which lesson 17 uses, with importing what the
orders service needs:

```
ana@laptop:~/gcp$ python3 -X importtime -c 'import google.cloud.pubsub_v1' 2>&1 | tail -1
import time:       311 |     300167 | google.cloud.pubsub_v1
ana@laptop:~/gcp$ time python3 -c 'import google.cloud.pubsub_v1'

real	0m0.376s
user	0m0.322s
sys	0m0.048s
ana@laptop:~/gcp$ time python3 -c 'import json, http.server'

real	0m0.053s
user	0m0.032s
sys	0m0.021s
```

`-X importtime` reports every module Python loads and how long each took, in microseconds; the last
line is the total for the package asked for, 300,167 microseconds. **Starting Python and importing
the Pub/Sub client took 0.38 seconds on this laptop; starting Python and importing what the orders
service needs took 0.05.** A service
that imports a dozen libraries of that size at start-up has added seconds to every cold start before
it has done anything, and on Cloud Run each instance pays it once.

## Shortening your part

The changes that matter are the ones in your program, in order of how much they usually buy:

1. **Do less before listening.** Load what the first request needs, and defer the rest to first use;
   open a database connection when it is first wanted rather than at import.
2. **Import less.** A dependency used by one rare endpoint can be imported inside that endpoint.
3. **Keep the image to what runs.** A slim base and no build tools in the final image, which the
   `docker` course's multi-stage builds cover.

Section 05 covers the two settings that hide a cold start rather than shorten it: a warm minimum
instance and a faster CPU at start-up.
