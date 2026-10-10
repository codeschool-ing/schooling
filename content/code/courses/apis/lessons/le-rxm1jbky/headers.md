---
title: CSP and the other headers an API sends
version: 1
---

**Four headers go on every answer `secure.py` gives, and a fifth on every answer over HTTPS.** None of
them changes what a client written in code receives. Each one tells a browser what not to do with the
answer, in case a browser is ever the thing reading it.

| header | what it tells the browser | why an API sends it |
|---|---|---|
| `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'` | load nothing, run nothing, and let no page put this inside a frame | an answer that ends up displayed as a document can do nothing at all |
| `X-Content-Type-Options: nosniff` | trust `Content-Type` and never guess | JSON is never run as a script or drawn as a page |
| `Cache-Control: no-store` | keep no copy, on disk or in any cache on the way | an answer about a person stays out of shared caches and the browser's disk |
| `Referrer-Policy: no-referrer` | send no `Referer` when leaving this document | an address carrying an id or a token is not passed to the next site |
| `Strict-Transport-Security` | HTTPS only, for `max-age` seconds | the previous section |

## Why a JSON API sends a CSP

The usual objection is that a Content Security Policy is for HTML: it limits which scripts, styles
and images a page may load, and an API sends none. That is exactly why the policy costs nothing.
`default-src 'none'` forbids everything, and JSON needs nothing, so no legitimate answer is affected.

**What it protects against is an answer that ends up treated as a page.** Somebody opens the API's
address in a tab. An error message repeats part of the request, `no book 99` here, and one day the
part it repeats is text a stranger chose and sent as a link. A bug elsewhere labels an answer
`text/html`. In each case the browser holds something it might render, and with this policy whatever
it renders can load nothing and run nothing. `frame-ancestors 'none'` adds that no other site may put
the answer inside a frame of its own page, which is how a page dresses up somebody else's content to
get clicks it should not have.

`nosniff` covers the other direction. Without it, some browsers looked at the bytes and decided for
themselves what an answer was, so a JSON answer could be accepted as a script by a page that loaded
it in a `<script>` tag.

## Every answer, errors included

Headers that only some answers carry protect only those answers, and errors are the ones nobody
checks. `secure.py` sends everything through `reply`, and it overrides `send_error`, the method the
library uses when it answers on its own. A method nobody defined, which lesson 1's `rest.py`
answered with an HTML page and Python's version:

```
ana@api:~/shelf$ curl -si -X FOO localhost:8000/v1/books/1
HTTP/1.1 501 Not Implemented
Server: shelf
Date: Sat, 10 Oct 2026 04:23:18 GMT
Content-Type: application/json
Content-Length: 40
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Vary: Origin

{"error": "Unsupported method ('FOO')"}
```

**JSON, the same headers, and a `Server` that names the program without a version.** The version is
not a vulnerability, and removing it fixes nothing that is broken; it stops advertising which known
flaws to try first. Keeping the software up to date is the fix. An ordinary error carries the same
headers:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/99
HTTP/1.1 404 Not Found
Server: shelf
Date: Sat, 10 Oct 2026 04:23:18 GMT
Content-Type: application/json
Content-Length: 24
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Vary: Origin

{"error": "no book 99"}
```

## Two choices worth knowing

`Cache-Control: no-store` on every answer is the safe default and not the only right one. A
catalogue that is the same for everybody is better cached, and lesson 12's limits are easier to keep
when most requests never reach the API. Which answers may be cached, and where, belongs to the
`servers-cache` course. What belongs here is that an answer about a particular person, an order, an
account, anything behind lessons 7 to 11, is `no-store` unless somebody decided otherwise on
purpose.

You will also meet `X-Frame-Options: DENY`, the older header that `frame-ancestors` replaced, and
`X-XSS-Protection`, which switched on a filter that browsers have since removed. The first is
harmless beside a CSP; the second does nothing in a current browser, and a scanner that asks for it
is out of date.
