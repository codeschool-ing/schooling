---
title: CORS mistakes, and what CORS is not
version: 1
---

**Every common CORS mistake comes from treating the headers as an obstacle to get past rather than
as a statement about who may read.** A page fails with a red message, somebody searches for it, and
the first answer that makes the message go away is the one that ships. Four of those answers are
worth recognising, because each one makes the error disappear and each one is wrong.

## Reflecting whatever origin arrives

The quickest fix copies the request's `Origin` into `Access-Control-Allow-Origin`, whatever it says.
Every page now works, including every page on every other site. With a public API that is only `*`
spelt the long way; with credentials, it lets any site a user visits read that user's data through
their browser. `secure.py` checks the origin against its set before it names it, so an origin it has
never heard of gets nothing back:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/1 -H 'Origin: https://other.example' | grep -iE '^(HTTP|access-control|vary)'
HTTP/1.1 200 OK
Vary: Origin
```

The check has to compare **whole strings**. A test such as "the origin ends in `shelf.example`"
accepts `https://notshelf.example`, a domain anybody can register, and a regular expression with an
unescaped dot or no anchors has the same hole. A set of exact origins, like `ORIGINS`, has none.

## `*` with credentials

When a page asks for cookies or HTTP authentication to be sent (`credentials: "include"` in
`fetch`), the server has to answer `Access-Control-Allow-Credentials: true`. And **browsers refuse `*` in that
case**: the specification requires a credentialed response to name one origin exactly.
The refusal is deliberate. A wildcard on an API that recognises its users would let every site on the
internet read every user's data, so the browser will not accept it. The way out that people find next
is the first mistake, reflecting the origin. The right one is the list.

## The `null` origin

A browser sends `Origin: null` from places that have no proper origin: a page opened from a
`file://` address, a sandboxed `iframe`, some redirects. Allowing `null` because it showed up while
testing a local file allows every one of those, and anybody can put a sandboxed `iframe` on any page
they publish. `secure.py` treats `null` as one more origin that is not on its list:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/1 -H 'Origin: null' | grep -iE '^(HTTP|access-control|vary)'
HTTP/1.1 200 OK
Vary: Origin
```

## Forgetting `Vary: Origin`

When the answer depends on `Origin`, a cache between the browser and the server has to know, or it
stores the answer made for one page and hands it to another. Page A gets an answer naming page A,
the cache keeps it, and page B is refused for no reason it can find; or, with the order reversed, the
answer that said nothing reaches page A. `Vary: Origin` tells every cache to keep one copy per origin.
`secure.py` sends it on **every** answer, the ones with no `Access-Control-Allow-Origin` included, as
both transcripts above show, because "this origin may not read" depends on `Origin` just as much.
The `servers-cache` course is about those caches.

## CORS is not access control

The mistake under all four is believing that CORS protects the API. Here is curl, claiming to be a
page from an origin `secure.py` has never trusted, changing the stock:

```
ana@api:~/shelf$ curl -s -X PATCH localhost:8000/v1/books/1 -H 'Origin: https://other.example' -H 'Content-Type: application/json' -d '{"stock": 0}'
{"id": 1, "title": "Dom Casmurro", "stock": 0}
```

And with no `Origin` at all, which is what every program that is not a browser sends:

```
ana@api:~/shelf$ curl -s -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"stock": 12}'
{"id": 1, "title": "Dom Casmurro", "stock": 12}
```

**Both worked, because CORS only tells a browser what to show a page; it never stops a request from
being answered.** A client that is not a browser ignores the headers, and a client that wants to
misbehave is not a browser. What decides whether a request may change the stock is authentication
and authorisation, lessons 7 to 11, checked on the server for every request whatever its `Origin`.
CORS decides something narrower: whether the browser of a person who is signed in will let one page
read your API on that person's behalf.
