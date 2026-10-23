---
title: What 1.22 closed, and what it left open
version: 1
---

This lesson takes a side, and it should say which before it argues. **For a new HTTP API in Go,
start with the standard library, add small libraries for specific needs, and adopt a framework when
you can name what it does that you would otherwise have to build.** The rest of this lesson is the
evidence for it, taken from what lessons 1 to 4 measured. It is a judgement, not a
law, and section 06 is about where it is wrong.

## The gap that made the frameworks

Lesson 4 section 02 said why Go grew routers: until 1.22 the standard mux could not route by method
or capture part of a path. Here is what was missing then, and where each need stands now:

| need | before Go 1.22 | now, in the standard library |
|---|---|---|
| route by method | an `if` in every handler | `GET /events`, with a 405 and an `Allow` header written for you |
| a value from the path | cut the path by hand | `{id}` and `r.PathValue("id")` |
| the rest of a path | the subtree pattern and `TrimPrefix` | `{path...}` |
| an exact path, not its subtree | impossible for `/` | `{$}` |
| which route wins | the longest pattern | the most specific, and a panic when two cannot be ranked |
| middleware | the `func(http.Handler) http.Handler` shape | the same shape; it never needed a framework |
| route groups | a mux inside a mux | the same, as boxoffice does for `/admin/` |

**The first five rows are the reason most projects reached for a router, and all five are closed.**
The last two never needed one: a middleware chain and a mounted sub-mux were always plain Go.

## What is still not there

Some things a framework gives are still absent from `net/http`, and they are real:

- **Decoding and validating a body in one call.** Lesson 3 wrote `decodeJSON` and a `validate` method
  per request type; Gin's `ShouldBindJSON` and its tags do both.
- **A central place where errors become responses.** Echo's returned errors do this; boxoffice has
  `fail` and `writeProblem`, called by hand in each handler.
- **The mux's own 404 and 405 in your format.** Lesson 3 section 05 showed that a catch-all costs the
  405, and that `ServeMux` has no setting for it.
- **A catalogue of ready middleware**: rate limiting, compression, request ids, timeouts, all
  installed with one line.
- **Generating an API description** (OpenAPI) from the routes and types.

Each of those is a few dozen lines, a small library, or a real reason to use a framework. **The
question this lesson asks is not "does the framework have more" — it always does — but whether what
it has is worth what it costs.** The next two sections put a number on each side.
