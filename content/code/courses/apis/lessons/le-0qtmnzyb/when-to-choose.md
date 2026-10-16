---
title: When gRPC, and when not
version: 1
---

**gRPC fits between programs you own on both ends, and fits badly where the caller is somebody
else's.** Inside a company, one team publishes a `.proto`, every other team generates from it, and
the compiler holds them all to it. At the edge, the caller may be a browser, a partner with nothing
but `curl`, or a script written in an afternoon, and every one of them is easier to serve with
lesson 1's JSON.

The wrong idea is that gRPC is a faster REST and replaces it. Thirty-three bytes against eighty-five
is real, and for most APIs it is not what decides: a request that spends its time waiting for a
database will not notice whether the answer was 33 bytes or 85. What decides is
who is on the other end.

## Where it earns its place

**Between your own services.** Both sides are generated from one file, a change that breaks the
contract breaks the build rather than production, and a deadline passes from one service to the
next without anybody writing code for it.

**Where data has to flow, not be fetched.** A level that changes, a delivery sent in pieces, a
conversation in both directions: the four kinds of call give each its own shape, on one connection,
where REST would poll or need a second technology beside it.

**Where many languages meet.** The track's four languages all have gRPC, and a `.proto` is the same
contract in each of them.

## Where it does not

**A public API.** Its users want to read a response with their eyes, try it with `curl`, and call it
from a browser. All three are lesson 1 for free and a project with gRPC.

**Anything a browser calls directly**, for the reason in the previous section: it needs gRPC-Web and
a proxy, or a JSON gateway, which is a REST API with extra steps.

**Responses a cache could serve.** Every gRPC call is a `POST`, and HTTP caches do not keep the
answers to `POST`. A catalogue that thousands of people read and few people change is what lesson 1's
`GET` and its caching were made for.

| situation | choose | because |
|---|---|---|
| the warehouse answering the tills | gRPC | both ends are yours, and stock changes while a till watches |
| the bookshop's catalogue for partners | REST | strangers, `curl`, browsers and caches |
| the nightly sales export for the accountant | REST | one download of JSON that anyone can open, and nothing to stream |
| ten internal services in four languages | gRPC | one contract, generated everywhere, deadlines passed along |

**The common answer in practice is both**: REST or GraphQL at the edge, where the callers are
other people's, and gRPC behind it, where the callers are yours. shelf is already shaped that way,
with `rest.py` on port 8000 for the shop's customers and the warehouse on 50051 for its tills.
