---
title: Browsers, and APIs for strangers
version: 1
---

## A browser cannot call boxoffice's gRPC port

gRPC needs two things from HTTP/2 that a web page cannot control: it must send its own framing and read
**trailers**, the headers that arrive after the body and carry `grpc-status`. Browsers speak HTTP/2, and
`fetch` gives a page no access to trailers or to the framing. **So a web page cannot be a gRPC client of
boxoffice as it is**, whatever library it loads.

There are ways around it, and each adds something between the page and the service:

- **gRPC-Web**, a variant of the protocol that a browser can speak, with a proxy such as Envoy translating
  it to real gRPC in front of the server;
- **Connect**, a protocol and set of libraries that serve gRPC, gRPC-Web and a plain JSON-over-HTTP form
  from the same handlers, so a browser can call with ordinary `fetch`;
- **grpc-gateway**, which generates a REST and JSON front for a gRPC service from annotations in the
  `.proto`.

None of them was run for this course. All of them work, and **all of them are a second protocol to operate
so that a browser can reach the first**. For a service whose main caller is a web page, that is usually the
moment to ask why it is gRPC at all.

## APIs for people you will never meet

A public API, one that partners and strangers write programs against, has callers in every language, on
every platform, with every tool. **What they all share is HTTP and JSON.** A developer evaluating your API
pastes a `curl` line from the documentation into a terminal; with gRPC they install a tool, fetch your
`.proto`, and learn a protocol first. Every hour that costs is an hour some of them will not spend.

Some public APIs are offered in gRPC, usually beside a REST form, by companies whose customers are other
infrastructure teams. **For the general case, a public API is REST and JSON**, with an OpenAPI description so
that clients can still be generated, which keeps the main advantage of a contract without its toolchain.

## Caching

One more property of the web that gRPC gives up: **an HTTP `GET` can be cached** by the browser, by a CDN, by
any proxy on the way, under rules the `servers-cache` course covers. Every gRPC call is an HTTP/2 `POST`,
and no cache in between will store it. A public catalogue of events read by thousands is exactly the answer
a CDN should serve, and it can only do that over REST.
