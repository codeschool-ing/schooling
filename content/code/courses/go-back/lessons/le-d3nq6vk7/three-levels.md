---
title: Three distances from the code
version: 1
---

`go-concurrency` taught the tools: `go test` and subtests in lesson 25, tables in 26, `httptest` in 28,
coverage in 30, and the race detector back in 16. This lesson points them at a service, and the question
it keeps asking is **how far from the code a test should stand.** boxoffice can be tested at three
distances, and each catches something the others cannot:

| distance | what runs | what it catches | what it costs |
|---|---|---|---|
| **one handler** | the handler function, a request built in memory and an `httptest.ResponseRecorder` | wrong statuses, wrong bodies, validation that lets a bad value through | microseconds; nothing to set up |
| **the whole router** | `routes(…)` with its middleware, served by `httptest.Server` on a real port | a route not registered, middleware in the wrong order, a missing header, a token in the log | milliseconds; still nothing outside the process |
| **a real database** | `pgStore` against PostgreSQL | SQL that does not do what it says, a transaction that is not one, a trigger that never fires | a database server, and a few hundred milliseconds |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Three nested boxes and one outside them. Innermost, a handler such as getEvent, with memStore, tested by events_test.go through a ResponseRecorder. Around it the router: requestID, logRequests, recoverPanics, cors and the mux, tested by routes_test.go. Around that an httptest.Server on 127.0.0.1. Apart from them, pgStore with a real PostgreSQL, tested by pgstore_test.go.\"><defs><marker id=\"gb-l15-distances-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"430\" height=\"220\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">httptest.Server · 127.0.0.1</text><rect x=\"35\" y=\"48\" width=\"390\" height=\"172\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"50\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">routes(…)</text><text x=\"50\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">requestID · logRequests · recoverPanics · cors · mux</text><rect x=\"60\" y=\"100\" width=\"340\" height=\"100\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">getEvent(store)</text><rect x=\"75\" y=\"138\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ResponseRecorder</text><rect x=\"245\" y=\"138\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">memStore</text><rect x=\"515\" y=\"95\" width=\"170\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pgStore</text><text x=\"600\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"600\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pgstore_test.go</text><text x=\"410\" y=\"66\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">routes_test.go</text><text x=\"385\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">events_test.go</text></svg>", "caption": "Each distance adds what the one inside it cannot see, and costs a little more to run."}
```

The first two use `memStore`, the in-memory store boxoffice has had since lesson 1, behind the `Store`
interface of lesson 6. That interface was written so PostgreSQL could replace memory, and it pays a second
time here: every handler test runs against memory, with no database and no cleanup, in a few milliseconds.

**Most tests belong at the first two distances**, because they are fast enough to run on every save. The
third is for what only a database can show. Section 07's test sells seats from thirty goroutines and checks
that exactly ten succeed; no in-memory fake can tell you whether the `UPDATE` of lesson 8 is safe under
concurrency, because the fake is not the thing being trusted.

## Where the tests live

A test file sits beside the code it tests, in the same package. boxoffice is `package main`, and its tests
are `package main` too, so they can call `getEvent`, `load` and `newMemStore` directly, the unexported
names included. Five files arrive in this lesson:

| file | section | distance |
|---|---|---|
| `events_test.go` | 03 | one handler |
| `routes_test.go` | 04 | the whole router |
| `config_test.go` | 05 | one function |
| `concurrency_test.go` | 06 | the whole router, fifty requests at once |
| `pgstore_test.go` | 07 | a real database |

**A test that only repeats the code proves nothing.** Each test here states something boxoffice promises,
a 404 for an event that is not there, a 401 without a token, ten seats sold out of ten, in terms a person
reading it could check against the lessons that made the promise. One of them finds a defect that every
earlier lesson missed, and another finds one in a test.
