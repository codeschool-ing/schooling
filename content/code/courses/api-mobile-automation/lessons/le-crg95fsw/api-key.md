---
title: An API key, and the three requests that test one
version: 1
---

**An API key is a fixed secret that a program sends with every request to say which program it
is.** It is the simplest credential there is: no login, no expiry, one string agreed in advance.
boxoffice protects one address with a key, the theatre's sales report at `/v1/reports/sales`, and
expects it in a header called `X-Api-Key`.

The belief worth dropping is that a key says *who* is asking. It says *which program*, or which
copy of a configuration file. Every person and every script that holds the string is the same
caller to the server, so a key cannot tell the box-office manager from a script somebody copied it
into last year. That is why keys suit a report a few internal programs read, and why boxoffice
does not use one for orders, where it matters which client placed which order.

## Three requests

A key is tested with at least three requests: none, a wrong one, the right one. Without a key
first, with `-i` to see the headers:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/reports/sales
HTTP/1.1 401 Unauthorized
content-type: application/problem+json
Date: Sat, 10 Oct 2026 19:43:07 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"type":"about:blank","title":"Unauthorized","status":401,"detail":"send the staff key in X-Api-Key"}
```

A `401` and a problem body that says what to send, which is right. One header is missing, though.
**A `401` must carry a `www-authenticate` header saying how to authenticate** (RFC 9110, §15.5.2), and this one has none. The orders do send it, as section 05 shows, so the report is the
odd one out. It is a small defect and a real one: a client library that reads the header to decide
what credentials to send has nothing to read. Write it up.

Then a wrong key and the right one:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/reports/sales -H 'X-Api-Key: guess'
{"type":"about:blank","title":"Unauthorized","status":401,"detail":"send the staff key in X-Api-Key"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/reports/sales -H 'X-Api-Key: lab-only-staff-key'
{"orders":0,"seats":0,"revenue_cents":0}
```

The wrong key gets the same answer as no key, word for word. **That sameness is correct**: a server
that said *"key not recognised"* to one and *"key missing"* to the other would tell a stranger
which guesses came close to being a key. The right key gets the report, with nothing sold yet.

## Why a header, and not the address

Some APIs accept the key in the query string, `?key=…`, because it is easy to paste into a
browser. boxoffice does not, and asking that way is refused:

```
ana@laptop:~/boxoffice$ curl -s 'localhost:8080/v1/reports/sales?key=lab-only-staff-key'
{"type":"about:blank","title":"Unauthorized","status":401,"detail":"send the staff key in X-Api-Key"}
```

The refusal is not the interesting part. Look at the second terminal, where boxoffice logs every
request it answers:

```
GET /v1/reports/sales?key=lab-only-staff-key 401
```

**The key is in the log, in plain text.** boxoffice's log writes the method, the address and the
status, which is what nearly every web server, proxy and load balancer logs by default; an address
also lands in browser history and in the `Referer` header sent to other sites. A header is not
logged unless somebody chooses to log it. So the test a tester adds is not only "the key works in
the header", but **"the key does not work in the address"**, because an API that accepted it there
would invite every client to leak it.
