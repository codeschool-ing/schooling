---
title: Where the framework gets in the way
version: 1
---

The costs in section 04 are paid by everyone who uses a framework, the day they start. Some costs only
arrive later, at a particular moment, and they are worth knowing by name, because each one looks like
a bug in your code when it happens.

## When its default is not your decision

Lesson 4 section 07 laid out six questions and how each framework answered them, and most of the
differences were defaults: **Gin answering 404 to a wrong method, Echo hiding the reason for a 400,
Beego sending an HTML page to a JSON client, Gin trusting `X-Forwarded-For` from anyone.** Each is a
reasonable choice for somebody. None of them was yours, and you find out about each one the day a
client or an auditor does.

The standard library has defaults too; lesson 1 section 08 spent a section on the one that matters
most, the missing timeouts. The difference is the size of the surface. **`net/http` makes a handful of
choices and the documentation of one package lists them**; a framework makes hundreds, spread over its
binding, its routing, its error handling, its logging and every middleware it ships.

## When its handler is not an `http.Handler`

Lesson 2's four middlewares wrap any `http.Handler`. They work unchanged around Gin's engine, Echo's
and Beego's, and around a chi router, because all of those are `http.Handler`s at the top. **They do
not work inside a Gin route**, between the router and one handler, because there a handler is a
`gin.HandlerFunc` and a middleware has Gin's shape; and they do not work anywhere in Fiber, which is not
`net/http` at all. The Go ecosystem is full of middleware written in the standard shape, for tracing,
metrics, authentication and rate limiting, and each framework that leaves that shape needs its own
version of each, or an adaptor.

The same goes for tests. **`httptest`, which lesson 15 uses, drives any `http.Handler`** with a fake
request and a recorder, and needs nothing else. Fiber needs its own `app.Test`.

## When its context outlives the request

A framework's context carries the request and the response, and frameworks reuse those objects to go
faster. Gin's documentation says that a handler which starts a goroutine must give it a copy of the
context, `c.Copy()`, and never the original, because the original is recycled for another request as
soon as the handler returns. Fiber says the same about every string read from its `Ctx`, as lesson 4
section 05 showed. **A program that breaks this rule works in every test and fails under load**, with a
value from one customer's request showing up in another's, which is the worst kind of bug to find.

`net/http` gives a handler an ordinary `*http.Request`, and `r.Context()` is an ordinary
`context.Context` that `go-concurrency` lesson 12 taught. Nothing is recycled behind your back.

## When it hides the HTTP

`c.JSON(422, value)` is shorter than lesson 3's `writeJSON`, and it hides the order of status, headers
and body that lesson 1 section 07 was about. That is fine until a header has to be set after a
middleware has already written, or a response must be streamed, as lesson 13 does, and then the
framework's helper has to be bypassed and the HTTP understood anyway. **A framework does not remove the
need to know HTTP; it postpones the day you find out you need to.**
