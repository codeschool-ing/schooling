---
title: Two styles, compared on what matters
version: 1
---

Lesson 10 built a gRPC service beside an HTTP API, and both answer the same questions from the same store.
That makes the comparison concrete. **Neither style is better in general; each is better at particular
things**, and the mistake teams make is picking one for everything because it was the right choice once.

| | REST with JSON | gRPC with Protocol Buffers |
|---|---|---|
| the contract | optional, an OpenAPI document if somebody writes one | required, the `.proto`, and both sides generated from it |
| what travels | text anyone can read | binary that needs the contract to read |
| size on the wire | larger, section 03 measures it | smaller, section 03 measures it |
| browsers | native: `fetch`, a form, a link | not directly, section 05 |
| tools to poke it | `curl`, a browser, every HTTP library | `grpcurl` and gRPC libraries, section 04 |
| streaming | one direction at a time, with extra machinery, lesson 13 | four kinds of call, built in |
| errors | HTTP status plus a body format you choose | a fixed set of codes, the same in every language |
| caching by proxies and CDNs | built into HTTP, for `GET` | none: every call is a `POST` underneath |
| deadlines | yours to send and honour | sent with every call and propagated |
| generated clients | possible from OpenAPI | always, in every supported language |

**Read the table as a list of questions about your callers**, not as a score. Who calls this service? A
browser, a mobile app, a partner's script, or another service your team owns? How large are the answers,
how often are they sent, and how much does a misunderstanding of the contract cost? The next four sections
take the rows that are most often decided wrongly, with measurements where a measurement exists.
