---
title: The headers worth reading
version: 1
---

**Headers are the metadata of a message: what the body is, how long it stays true, who is asking.**
A response carries a handful of them and most are routine. A tester reads the ones that change how
the body is understood, because a wrong header makes a right body unusable.

Header names are not case-sensitive: `Content-Type`, `content-type` and `CONTENT-TYPE` are the same
header. boxoffice writes them in lower case, which is what Node does and what HTTP/2 requires, and
curl's own requests write them capitalised. A test that compares header names letter for letter is
a test with a defect of its own.

## The ones a tester reads

| header | in | says | what to check |
|---|---|---|---|
| `content-type` | both | what the body is: `application/json`, `application/problem+json` | that it matches the body, on errors too |
| `location` | response | where a new thing lives | that it is there on a `201`, and that a GET to it works |
| `allow` | response | the methods an address accepts | that it is there on a `405`, and true |
| `www-authenticate` | response | how to authenticate, and why it failed | that it is there on a `401` (lesson 3) |
| `cache-control` | response | how long a copy may be reused | that private answers are not cached |
| `etag` | response | a fingerprint of this version of the thing | that it changes when the thing does |
| `authorization` | request | the client's credentials | that it never appears in a log (lesson 3) |

Look back at the order of section 08 and three of these are already there: `location` on the `201`,
`allow` on the `405`, and `content-type` on every answer, including the errors, which say
`application/problem+json`. That label names a standard format for errors, and lesson 2 tests it.

## A fingerprint, and the answer that saves a download

The `etag` of a show is a fingerprint of its current state. A client that keeps a copy sends the
fingerprint back in `if-none-match`, which asks *"has it changed since this?"*:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/shows/sh-101 | grep -i etag
etag: "287e9ace94be5cc6"
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/shows/sh-101 -H 'if-none-match: "287e9ace94be5cc6"'
HTTP/1.1 304 Not Modified
etag: "287e9ace94be5cc6"
Date: Sat, 10 Oct 2026 07:13:50 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

`304 Not Modified`, with no body: the copy the client holds is still current, so nothing is sent
again. On a phone with a weak signal that is the difference between an app that refreshes at once
and one that waits, which lesson 22 measures. For a tester it opens two questions, and both have
caught real defects: **does the fingerprint change when the thing changes**, and does the server
still answer `304` after it should have stopped? Selling a seat changes `seats_left`, so it must
change the `etag` of that show. The drill at the end of this lesson asks how you would check.

## What the server saw

The second terminal has been keeping a line for every request this lesson sent. Here is all of it,
from the start:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
boxoffice listening on http://localhost:8080
GET /health 200
GET /v1/shows 200
GET /v1/shows/sh-103 200
GET /v1/shows/sh-103 200
DELETE /v1/shows/sh-103 405
HEAD /v1/shows/sh-103 405
POST /oauth/token 200
POST /oauth/token 200
GET /v1/shows 200
GET /v1/shows/sh-999 404
GET /v1/orders 401
PUT /v1/shows 405
POST /v1/orders 201
POST /v1/orders 409
POST /v1/orders 422
POST /v1/orders 400
POST /v1/orders 415
GET /v1/shows/sh-101 200
GET /v1/shows/sh-101 200
GET /v1/shows/sh-101 304
```

That is the server's side of every exchange above, and a log like it is the first place to look
when a test fails and the response alone does not say why.
