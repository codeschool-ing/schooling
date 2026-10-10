---
title: Methods, and the first defect
version: 1
---

**The method is the verb of a request: what the client wants done to the thing at that address.**
The same path can mean different things under different methods. `GET /v1/orders/ord-1001` reads an
order and `DELETE /v1/orders/ord-1001` cancels it, so a tester never checks an address without
checking which methods it answers.

| method | what it asks | changes anything? | safe to repeat? | boxoffice uses it for |
|---|---|---|---|---|
| `GET` | send me this | no | yes | the shows, one show, an order |
| `HEAD` | send me only the headers a GET would send | no | yes | (see below) |
| `POST` | here is something new; you choose where it goes | yes | **no** | a token, a new order |
| `PUT` | store this, whole, at this address | yes | yes | — |
| `PATCH` | change part of what is at this address | yes | it depends | — |
| `DELETE` | remove what is at this address | yes | yes | cancelling an order |

Two words in that table carry most of the course. A **safe** method changes nothing on the server,
so a client, a cache or a test may send it as often as it likes. An **idempotent** method may change
something, but sending it twice leaves the server as sending it once does: cancelling a cancelled
order changes nothing more. `POST` is neither, which is why pressing *Buy* twice on a slow
connection can buy two tickets, and why lesson 13 spends a whole lesson on it.

## Asking with the wrong verb

A tester asks with the wrong verb on purpose, because an API that does something with a method it
does not support has a defect. curl's `-X` chooses the method, and `-i` adds the status line and the
headers to the output:

```
ana@laptop:~/boxoffice$ curl -i -X DELETE localhost:8080/v1/shows/sh-103
HTTP/1.1 405 Method Not Allowed
content-type: application/problem+json
allow: GET
Date: Sat, 10 Oct 2026 07:13:50 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"type":"about:blank","title":"Method Not Allowed","status":405,"detail":"DELETE is not allowed here"}
```

That is the right refusal. `405 Method Not Allowed` says the address exists and the method is not
accepted there, and the `allow` header lists what is, which the standard requires with a 405. A
`404` here would be wrong, because the show exists, and a `200` would be alarming.

## The first defect

`HEAD` asks for the headers a `GET` would return, without the body. A client uses it to find out
whether something changed, or how big it is, without downloading it. curl sends one with `-I`:

```
ana@laptop:~/boxoffice$ curl -I localhost:8080/v1/shows/sh-103
HTTP/1.1 405 Method Not Allowed
content-type: application/problem+json
allow: GET
Date: Sat, 10 Oct 2026 07:13:50 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

boxoffice refuses it, and the refusal contradicts itself: the `allow` header says `GET` is fine,
and the standard is explicit that **every general-purpose server must support `GET` and `HEAD`**
(RFC 9110, section 9.1). This is a defect, and a typical one: nothing on any screen will ever show
it, nobody wrote a case for it, and it was found by asking the API a question nobody else asks.

If you took `manual-testing`, this is the moment to write it up the way that course taught: what
you sent, what came back, what the standard says should have come back, and the evidence, which is
the transcript above. The fix is a few lines in boxoffice, and the course leaves it unfixed so you
can watch the tests of later lessons catch it.
