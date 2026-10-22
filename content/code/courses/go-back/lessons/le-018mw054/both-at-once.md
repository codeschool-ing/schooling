---
title: One service, both doors
version: 1
---

boxoffice already serves both styles, and the way it does is worth naming as a pattern: **two thin
adapters over one core.**

- The **store** is the core: lesson 6's `Store` interface and the `pgStore` behind it. It knows events,
  sales and tickets, and nothing about HTTP or gRPC.
- The **HTTP handlers** of lessons 1 to 3 translate HTTP requests into store calls and store errors into
  statuses and problem details.
- The **gRPC methods** of lesson 10 translate gRPC requests into the same store calls and the same errors
  into gRPC codes, through `toStatus`.

Neither adapter contains a business rule. **A sale is the same `Sell`, whichever door it came through**, which
is why lesson 10 section 07 saw an HTTP purchase reach a gRPC watcher half a second later. A rule added to
the store, say a limit of ten tickets per e-mail per event, applies to both at once.

## Who uses which

The split follows the callers, not the features:

| caller | door | why |
|---|---|---|
| the public ticket site, in a browser | HTTP, `:8080` | browsers speak HTTP and JSON; the CORS of lesson 2 is for them |
| staff tools and scripts | HTTP, `/admin/` | `curl` and a token are all they need |
| the scanners at the door | gRPC, `:9090` | a stream per door, a generated client, a deadline on every scan |
| the box office's live screen | gRPC, `:9090` | server streaming of availability |

## What it costs

Two ports, two sets of middleware or interceptors, two places to put authentication and logging, two
formats of error. **Every concern that cuts across requests is now written twice**, once per door, and
lesson 12's logging and lesson 17's metrics will have to cover both. That cost is real and it is the reason
not to add a second protocol before a caller needs it. boxoffice added it because the scanners and the
screen are programs the venue owns, built against a contract it controls, with streams that REST would
have to imitate.

An alternative some teams prefer is a single protocol and a translation in front: write the service in
gRPC and generate the REST face with grpc-gateway, or write it with Connect and serve both from one
handler. It moves the duplication from your code into generated code, which is a good trade when the API is
large.
