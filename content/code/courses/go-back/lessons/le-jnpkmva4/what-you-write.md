---
title: What writing it yourself actually cost
version: 1
---

The fair way to weigh a framework is against the code you write instead of it, and boxoffice has
that code. Lessons 1 to 3 wrote every piece of plumbing a framework would have provided, and it can be
counted:

```
ana@vm:~/boxoffice$ wc -l middleware.go recover.go cors.go auth.go json.go decode.go problem.go
  58 middleware.go
  25 recover.go
  30 cors.go
  41 auth.go
  25 json.go
  48 decode.go
  42 problem.go
 269 total
ana@vm:~/boxoffice$ wc -l store.go events.go admin.go routes.go main.go
  81 store.go
 107 events.go
  65 admin.go
  18 routes.go
  34 main.go
 305 total
```

The first command counts the plumbing, the files that would exist in any HTTP service and say
nothing about tickets: the middleware chain and the status recorder, panic recovery, CORS, token
authentication, writing JSON, reading JSON, and the problem format with the error translation. **269
lines, comments and blank lines included.** The second counts what boxoffice is about, the store, the
handlers and the routes: 305.

## What the 269 lines are

| file | lines | what a framework offers instead |
|---|---|---|
| `middleware.go` | 58 | a logger middleware, and its own chain |
| `recover.go` | 25 | a recovery middleware |
| `cors.go` | 30 | a CORS middleware with a configuration struct |
| `auth.go` | 41 | a basic or bearer auth middleware, or nothing, because authentication is usually yours anyway |
| `json.go` | 25 | `c.JSON` |
| `decode.go` | 48 | `c.Bind` or `ShouldBindJSON`, with less strictness by default |
| `problem.go` | 42 | a central error handler, in its own format |

**Every one of those lines is code you read, understand and change in the same editor as the rest of
the service.** When the decoder refuses a body, the sentence it uses is in `decode.go`, and changing it
is a one-line diff; in lesson 4, changing Echo's `Bad Request` or Gin's validator message meant
learning where each framework keeps its hooks. When lesson 15 tests a handler, it tests these lines too,
with the same tools.

## What they did not cost

The 269 lines brought **no new module**: `go.mod` in boxoffice still lists nothing but the module
itself, and the binary carries nothing that boxoffice does not call. They did not cost a learning
curve, because they use exactly the types lessons 1 to 3 taught: `http.Handler`, `ResponseWriter`,
`encoding/json`, `context`. And they will not cost an upgrade: **the Go 1 compatibility promise means
that code written against `net/http` in 2012 still compiles**, and nothing in these files depends on a
release later than 1.22.

What they did cost is the writing, once, and the duty to get it right. `decode.go` took the most care
in lesson 3 because the obvious one-line version is wrong in four ways, and a framework's version has
had those mistakes found by thousands of users. **That is the strongest argument a framework has, and
it is a good one** for code that is hard to get right. For a 25-line `writeJSON`, it is not much of an
argument.
