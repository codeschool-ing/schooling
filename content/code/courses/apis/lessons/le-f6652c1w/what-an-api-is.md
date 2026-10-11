---
title: What an API is
version: 1
---

**An API is a promise one program makes to another.** It says which questions may be asked, how to
ask them, and what shape the answer will have. The page a person reads can change every week; an API
cannot, because on the other side there is somebody else's code that was written against the promise
and will break the day it stops being true.

That is the whole difficulty of the subject, and it is why this course spends as much time on
**contracts** as on code. Lesson 2 is about the shape of what goes back and forth, lesson 6 about
writing the promise down so that a machine can check it, and every lesson on security, from lesson 7
to lesson 13, about who is allowed to ask.

## Four styles, one job

There is more than one way to make the promise. The four this course covers are all in use today,
often inside the same company:

| style | what a request names | what travels | lesson |
|---|---|---|---|
| **REST** | a resource, by its address | JSON over HTTP, mostly | this one |
| **GraphQL** | the fields the client wants | one query, one JSON answer | 3 |
| **gRPC** | a procedure on a service | Protocol Buffers over HTTP/2 | 4 |
| **SOAP** | an operation in a WSDL | an XML envelope | 5 |

REST comes first because the other three are easiest to understand as answers to something REST does
badly, and because most of the APIs you will meet in your first job are REST.

## What REST is, and what it is not

REST is not a protocol and not a library. It is an **architectural style**, described by Roy Fielding
in his doctoral thesis in 2000, and its central idea fits in one sentence: **the server exposes
resources, each with an address, and clients act on them with the small set of methods HTTP already
has.** A book is a resource. Its address is `/v1/books/3`. Reading it is `GET`, changing it is `PUT`
or `PATCH`, removing it is `DELETE`.

The common wrong picture is that REST means "JSON over HTTP". Plenty of APIs send JSON over HTTP and
are not REST at all: one address, `/api`, and every request a `POST` whose body says what to do. That
design works, and it is the shape of the remote procedure calls lesson 4 describes. What it loses is
everything HTTP already knows how to do with a resource: caching a `GET`, retrying a `PUT` safely,
saying "not found" in a way every client in the world understands.

Two more constraints matter in practice. **Each request carries everything needed to answer it**, so
the server keeps no memory of the conversation between requests; that is what lets you run ten copies
of a server behind a load balancer. And **what travels is a representation**, not the thing itself:
the book in the database is a row, and what the client receives is a JSON document built from it. The
two can change independently, and the section on versioning in this lesson depends on that.

## One exchange, taken apart

Everything in this course is built on the same exchange, so it is worth seeing its parts once. A
client sends a **request**: a line naming the method, the path and the protocol version, then headers,
then sometimes a body. The server sends a **response**: a status line, headers, and usually a body.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"A request travels from curl to shelf: the request line GET /v1/books/3 HTTP/1.1, then headers such as Host and Accept, then an optional body. The response comes back: the status line HTTP/1.1 200 OK, headers such as Content-Type and Content-Length, then the JSON body.\"><defs><marker id=\"rr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"110\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><text x=\"75.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the client</text><rect x=\"570\" y=\"105\" width=\"110\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rest.py</text><text x=\"625.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the server</text><rect x=\"170\" y=\"20\" width=\"360\" height=\"105\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">request</text><text x=\"182\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /v1/books/3 HTTP/1.1</text><text x=\"182\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Host: localhost:8000</text><text x=\"182\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Accept: */*</text><text x=\"182\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(a body, for POST, PUT and PATCH)</text><text x=\"518\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">line</text><text x=\"518\" y=\"87\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">headers</text><rect x=\"170\" y=\"145\" width=\"360\" height=\"110\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">response</text><text x=\"182\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HTTP/1.1 200 OK</text><text x=\"182\" y=\"203\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Content-Type: application/json</text><text x=\"182\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Content-Length: 128</text><text x=\"182\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{&quot;id&quot;: 3, &quot;title&quot;: &quot;A Hora da Estrela&quot;, …}</text><text x=\"518\" y=\"183\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">status</text><text x=\"518\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">headers</text><text x=\"518\" y=\"241\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">body</text><line x1=\"130\" y1=\"125\" x2=\"168\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rr-ah)\"></line><line x1=\"532\" y1=\"90\" x2=\"568\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rr-ah)\"></line><line x1=\"568\" y1=\"150\" x2=\"532\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rr-ah)\"></line><line x1=\"168\" y1=\"190\" x2=\"130\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rr-ah)\"></line></svg>", "caption": "One exchange. Everything an API says travels in these three parts, in both directions."}
```

The headers are where most of the interesting work happens, and they keep coming back. `Content-Type`
says what the body is, and `Location` where something new was put. `Authorization` carries a
credential in lesson 7, and `Retry-After` tells a client how long to wait in lesson 12.
