---
title: CORS for a simple request
version: 1
---

**CORS, Cross-Origin Resource Sharing, is a conversation in two headers.** The browser puts the
page's origin in an `Origin` header on the request. The server answers with
`Access-Control-Allow-Origin`, naming the origin it is willing to be read by. If the two match, the
script gets the response; if the header is missing or names something else, it does not.

The tempting picture is a server that refuses a request from an origin it does not trust. Watch
what `secure.py` actually does. curl sends no `Origin` of its own, so `-H` plays the browser, once
as the page at `localhost:8080`, which is on the list, and once as the same page loaded from
`127.0.0.1:8080`, which is not:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/1 -H 'Origin: http://localhost:8080'
HTTP/1.1 200 OK
Server: shelf
Date: Sat, 10 Oct 2026 04:23:14 GMT
Content-Type: application/json
Content-Length: 48
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Access-Control-Allow-Origin: http://localhost:8080
Vary: Origin

{"id": 1, "title": "Dom Casmurro", "stock": 12}
ana@api:~/shelf$ curl -si localhost:8000/v1/books/1 -H 'Origin: http://127.0.0.1:8080'
HTTP/1.1 200 OK
Server: shelf
Date: Sat, 10 Oct 2026 04:23:14 GMT
Content-Type: application/json
Content-Length: 48
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Vary: Origin

{"id": 1, "title": "Dom Casmurro", "stock": 12}
```

**Both answers are 200 and both carry the book.** The only difference is the one header: the first
answer has `Access-Control-Allow-Origin: http://localhost:8080` and the second has none. The server
does not refuse anything; it states who may read, and the browser does the refusing.

## In a browser

Loaded from the origin on the list, the page's "Read it" button printed this in the console:

```
GET 200 {"id": 1, "title": "Dom Casmurro", "stock": 12}
```

Loaded from `http://127.0.0.1:8080`, the same button printed three lines, the first two of them in
red. This is Chromium's own wording; other browsers word it differently and say the same thing:

```
Access to fetch at 'http://127.0.0.1:8000/v1/books/1' from origin 'http://127.0.0.1:8080' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
Failed to load resource: net::ERR_FAILED
GET failed: TypeError: Failed to fetch
```

The script was told only `TypeError: Failed to fetch`. That is all it ever learns: the browser gives
a page no way to tell a CORS refusal from a server that is down, because the difference would itself
be information about the other origin. The explanation goes to the console, for the developer, and
nowhere the script can read it.

And the server's terminal printed this line for that same click:

```
127.0.0.1 - - [10/Oct/2026 01:23:16] "GET /v1/books/1 HTTP/1.1" 200 -
```

**The request arrived and was answered.** The book was read from the database and sent; the
browser received it and threw it away. That is the cost of a simple request, and it is why lesson 1's
rule matters here: a GET must never change anything, because a page on any origin can make a
browser send one to your API.

## Which requests are simple

The browser sends a request without asking first only when an HTML form could have sent the same
thing, because forms predate CORS and servers already had to cope with them. All three conditions
must hold:

| | a simple request may use |
|---|---|
| method | `GET`, `HEAD` or `POST` |
| headers set by the script | only a short list the specification calls safelisted, such as `Accept`, `Accept-Language` and `Content-Type` |
| `Content-Type` | only `text/plain`, `application/x-www-form-urlencoded` or `multipart/form-data` |

Anything outside it gets a preflight first, which is the next section. A JSON body is outside it,
since `application/json` is not on the list, and so is an `Authorization` header, which means nearly
every call to a real API from a page is preflighted.

## `*`, and when it is right

`Access-Control-Allow-Origin` may also be `*`: any origin may read. For data that is public and needs
no credentials, a catalogue, a timetable, exchange rates, that is the right answer, and an allowlist
would only add a list to maintain. `secure.py` names origins instead because its PATCH changes
something and, after lessons 7 to 9, its requests carry credentials, and the section on mistakes
shows what `*` does then.
