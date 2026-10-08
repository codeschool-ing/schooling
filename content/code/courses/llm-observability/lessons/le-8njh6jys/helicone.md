---
title: Helicone, and the gateway you already have
version: 2
---

Helicone is open source, and its authors publish one image that runs all of it in a single
container: the gateway and its API, the web screens, PostgreSQL, ClickHouse and MinIO. **This course
does not run it.** The image is a 3.5 GB download and several times that once unpacked, which is
more disk than everything else in the course put together, to see a proxy pass requests along. What
a gateway sees can be shown with far less, because you already have one.

Lesson 4's `flaky.py` stands between the programs and Ollama and passes every request through, and
it writes each one it forwards to `flaky.log`. With nothing told to fail, it is a gateway that only
records. Start it in the background, from `~/obs`, and send one question through it by pointing the
SDK at its port instead of Ollama's:

```sh
python flaky.py &
```

CAPTURE:gateway

PROSE:gateway

## What Helicone adds to that

The same position, with the work done: every request kept with its tokens, cost and latency as the
provider reported them, screens to read them by user and by property, and headers that say what the
gateway cannot work out on its own. A program sends `Helicone-User-Id` for the user,
`Helicone-Session-Id` for calls that belong together, and `Helicone-Property-<Name>` for anything to
filter by, the feature for instance, and changes its base URL to the gateway's. Nothing else in the
program changes.

A gateway has one setting worth looking for before anything else. One that forwarded to any address
named in a header would be an open relay: anybody able to reach it could make it call any machine it
can reach, including the internal services behind it, the attack called **server-side request
forgery**. A gateway worth running forwards only to the providers it has been told about, and a model
server on your own network is one more address that somebody adds to that list on purpose.

## What was not run

Neither the hosted Helicone, where most teams use it, nor the self-hosted image. What the
documentation describes and this course did not verify: the dashboards of requests, cost and latency
by user and property; the cache and rate limits configured by headers; and sessions that group a
chain of calls. Each is a gateway's version of something lessons 3 to 5 built from spans, and the
comparison that matters is the one in the last section, not a list of features.
