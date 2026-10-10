---
title: Procedures rather than resources
version: 1
---

**In REST a request names a thing; in a remote procedure call it names an action.** Lesson 1's
`GET /v1/books/1` says "this book" and lets the method say what to do with it. A remote procedure
call says `Reserve`, hands over the arguments, and waits for a return value, as if the function were
in the same program. A library on each side turns the call into a message, sends it, and turns the
reply back into a value.

That idea is older than the web, and the wrong picture of it is older still: **that a remote call
is an ordinary function call that happens to be far away.** It is not, and the systems that tried
to make it look like one, CORBA and Java RMI among them, are remembered for it. A local call cannot
lose the network halfway, cannot take forty seconds because another machine is busy, and cannot
succeed on the other side while the answer is lost on the way back. A remote call can do all three,
and code that pretends otherwise has no plan for the day it does.

**gRPC is the remote procedure call most companies run today**, and it is built around that
difference rather than against it. Google published it in 2015 as the open version of the system it
used between its own services. Every call carries a deadline, ends with a status from a fixed list,
and is described in advance in a contract that both sides are generated from. The contract is
written in **Protocol Buffers**, Google's format for describing and encoding messages, and that is
the next two sections.

## Three ways to ask for one book

Lesson 1 listed four styles in a table. Here are three of them asking for the same book, and what
actually crosses the wire each time:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The same question asked three ways. REST sends GET /v1/books/1 with no body and gets JSON back. GraphQL sends POST /graphql with a query naming the fields it wants and gets JSON back. gRPC sends POST /shelf.stock.v1.Stock/GetStock with a binary Protocol Buffers message and gets a binary message back, then a grpc-status trailer.\"><defs><marker id=\"l04-three-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"60\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">style</text><text x=\"300\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what goes, and what comes back</text><text x=\"605\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what it is</text><rect x=\"14\" y=\"48\" width=\"92\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">REST</text><rect x=\"120\" y=\"34\" width=\"360\" height=\"86\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /v1/books/1</text><line x1=\"132\" y1=\"64\" x2=\"466\" y2=\"64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l04-three-ah)\"></line><text x=\"132\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(no body)</text><line x1=\"466\" y1=\"94\" x2=\"132\" y2=\"94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-three-ah)\"></line><text x=\"132\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">{&quot;id&quot;: 1, &quot;title&quot;: &quot;Dom Casmurro&quot;, …}</text><rect x=\"494\" y=\"34\" width=\"212\" height=\"86\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"506\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">names a resource</text><text x=\"506\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">JSON</text><text x=\"506\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTTP/1.1 or HTTP/2</text><rect x=\"14\" y=\"146\" width=\"92\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">GraphQL</text><rect x=\"120\" y=\"132\" width=\"360\" height=\"86\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST /graphql</text><line x1=\"132\" y1=\"162\" x2=\"466\" y2=\"162\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l04-three-ah)\"></line><text x=\"132\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">{&quot;query&quot;: &quot;{ book(id: 1) { title } }&quot;}</text><line x1=\"466\" y1=\"192\" x2=\"132\" y2=\"192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-three-ah)\"></line><text x=\"132\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">{&quot;data&quot;: {&quot;book&quot;: {&quot;title&quot;: …}}}</text><rect x=\"494\" y=\"132\" width=\"212\" height=\"86\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"506\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">names the fields it wants</text><text x=\"506\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">JSON</text><text x=\"506\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTTP, one address</text><rect x=\"14\" y=\"244\" width=\"92\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">gRPC</text><rect x=\"120\" y=\"230\" width=\"360\" height=\"86\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST /shelf.stock.v1.Stock/GetStock</text><line x1=\"132\" y1=\"260\" x2=\"466\" y2=\"260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l04-three-ah)\"></line><text x=\"132\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00 00 00 00 0f 0a 0d 39 37 …</text><line x1=\"466\" y1=\"290\" x2=\"132\" y2=\"290\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-three-ah)\"></line><text x=\"132\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00 00 00 00 21 0a 0d 39 37 …  grpc-status: 0</text><rect x=\"494\" y=\"230\" width=\"212\" height=\"86\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"506\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">names a procedure</text><text x=\"506\" y=\"273\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Protocol Buffers</text><text x=\"506\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTTP/2 only</text></svg>", "caption": "One book asked for three ways. REST names the thing, GraphQL names the fields, gRPC names a procedure; only gRPC sends bytes that mean nothing without the schema."}
```

Three differences decide most of what follows in this lesson:

| | REST | GraphQL | gRPC |
|---|---|---|---|
| **the request names** | a resource, by its address | the fields the client wants | a procedure on a service |
| **the contract** | optional; lesson 6 writes one | a schema, required | a `.proto` file, required |
| **what travels** | JSON, readable by eye | JSON, readable by eye | binary, readable with the schema |
| **underneath** | HTTP/1.1 or HTTP/2 | HTTP, usually one address | HTTP/2, and nothing else |

The last two rows are the costs, and the section on choosing comes back to them. The first two are
the point: **a gRPC client cannot send a request the contract does not describe**, because it never
builds a request at all. It calls a generated function, and the function only exists if the
contract says so.

The bookshop gets a new program for this lesson rather than a rewrite of the old one. Its
warehouse needs to answer how many copies of a book are on the shelf, to hold copies for an order,
to tell the tills when a level changes, and to take in deliveries. **shelf's REST API stays where
lesson 1 left it**, and the warehouse is a second service beside it, which is how gRPC usually
arrives in a company: between two of its own programs, not in front of its customers.
