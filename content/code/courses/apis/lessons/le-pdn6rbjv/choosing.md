---
title: REST or GraphQL
version: 1
---

**Neither replaces the other.** They divide the same work differently: REST fixes the shape of each
answer on the server and lets HTTP do a great deal for free, and GraphQL hands the shape to the
client and makes the server defend itself. The shop now has both, over the same database, and every
row of this table is something you saw one of them do:

| | REST, `rest.py` | GraphQL, `graph.py` |
|---|---|---|
| addresses | one per resource | one, `/graphql` |
| who decides an answer's shape | the server, per endpoint | the client, per query |
| a page that needs three resources | three requests, or a new endpoint | one request |
| HTTP caches | work as designed on `GET` | need `GET` and persisted queries |
| the status code | carries the outcome | 200 for anything that ran; read `errors` |
| work one request can cause | fixed by the endpoint | chosen by the client, so it needs limits |
| the contract | written beside the code, lesson 6 | the schema, which the server can describe |
| changing it | a new version in the path | one schema that grows, with `@deprecated` |

## Where each one fits

**GraphQL earns its cost when one team serves many screens it also writes.** A web app, an Android
app and an iPhone app each want a different slice of the same data, and each changes every few
weeks. A GraphQL layer in front of the services, often called a **backend for frontend**, lets each
screen ask for exactly its slice without a new endpoint. Because every client is yours, persisted
queries can also turn the open language into a fixed list. That is the case GraphQL was built for.

**REST is the safer default for an API strangers call.** A public API is used by programs you will
never see, written in languages you did not pick, often with nothing but `curl`. They benefit from
addresses they can bookmark, status codes they can branch on, answers any HTTP cache understands,
and a cost per request you decided in advance. GitHub publishes both a REST and a GraphQL API,
which is a fair summary of the trade: the same data, for two kinds of client.

Between services inside one system, where neither the screen nor the stranger is the client, there
is a third answer, and lesson 4 is about it.
