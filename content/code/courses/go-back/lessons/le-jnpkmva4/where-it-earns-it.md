---
title: Where a framework earns its place
version: 1
---

An argument that never concedes anything is not worth reading. **There are situations where a
framework is the right call**, and they share a feature: the framework does something the team would
otherwise do many times, badly or differently each time.

## Many routes, many people, one way

boxoffice has six routes and one author. A service with eighty routes and twelve developers is a
different problem. **What it needs most is that every handler looks the same**: decodes the same way,
validates the same way, fails the same way. Hand-written helpers can deliver that, if somebody writes
them early and everybody uses them; a framework delivers it on the first day, documented, and a new
developer who has used Gin elsewhere is productive in it at once. **Consistency across a large team is
the strongest argument for a framework**, and it gets stronger with the size of the team.

## Rules that are better as data

Lesson 3's `validate` methods are code, which is easy to read and to test. For a request with thirty
fields, each with a length, a format and a range, thirty `if` statements are tedious and easy to get
subtly wrong, and `binding:"required,email,max=100"` is shorter and harder to get wrong. **Validation
by tags is a real gain at that scale.** It is also the one part of Gin you can have without Gin: the
library underneath, `go-playground/validator`, works on any struct in any handler.

## A description of the API, generated

Clients of a public API want an OpenAPI document, the machine-readable description that tools turn
into documentation and client code. Writing one by hand and keeping it in step with the code is a
chore that drifts. Some Go frameworks are built around generating it from the routes and the types,
and **if the API is a product, that alone can decide the choice.**

## Speed, measured

Fiber's case is speed, and it is a real case for a service whose time goes into HTTP handling itself:
a proxy, a cache in front of something fast, a service answering from memory at very high rates. **For
an API whose requests wait on a database, as boxoffice's will from lesson 6, the time spent in the
HTTP layer is a small share of each request**, and halving it is not noticed. Choosing Fiber for speed
is right when a profile of the real service says the HTTP layer is where the time goes, and not before.

## The team already has one

The most common good reason is the least technical. **If the services around yours are written in
Echo, write yours in Echo.** A team's shared knowledge, shared middleware and shared habits are worth
more than any difference in this lesson, and a lone service in a different style costs everyone who
has to work on it once a year.
