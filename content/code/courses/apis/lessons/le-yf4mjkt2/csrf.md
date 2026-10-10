---
title: Cookies and cross-site requests
version: 1
---

**A browser attaches cookies by itself.** Whenever it sends a request to shelf's host, it adds the
cookies it holds for that host, and it does not ask which page started the request. That is what
makes a cookie login convenient, and it is also a hole: a page on any other site can make your
browser send a request to shelf, with a hidden form for example, and your cookie goes along.

The other page cannot read the answer, because the browser's same-origin policy keeps it from the
page's scripts; lesson 13 is about that policy. It does not need to. A request that adds a book to a
wishlist, changes an e-mail address or transfers money has done its work by the time the answer
comes back. This is **cross-site request forgery**, CSRF, and it is the price of the automatic
cookie.

The wrong defence is the obvious one: "that endpoint needs a login, so it is protected". The login is
exactly what the browser supplies on the other page's behalf. A defence has to rest on something the
other page cannot supply, and there are two such things.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"A sequence across three lanes: a page on another site, the browser, and shelf. First the browser signs in to shelf and stores the cookie sid with SameSite=Lax. Later a page on another site submits a form that posts to shelf&#x27;s wishlist. With SameSite=Lax the browser sends that cross-site POST without the cookie and shelf answers 401. If a cookie were attached anyway, the request has no X-CSRF-Token, because the other page cannot read it, and shelf answers 403.\"><defs><marker id=\"l08-csrf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"10\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a page on another site</text><rect x=\"270\" y=\"10\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">your browser</text><rect x=\"510\" y=\"10\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf</text><line x1=\"110\" y1=\"50\" x2=\"110\" y2=\"320\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"350\" y1=\"50\" x2=\"350\" y2=\"320\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"590\" y1=\"50\" x2=\"590\" y2=\"320\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"350\" y1=\"78\" x2=\"588\" y2=\"78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-csrf-ah)\"></line><text x=\"469.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /login</text><line x1=\"590\" y1=\"112\" x2=\"352\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-csrf-ah)\"></line><text x=\"471.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Set-Cookie: sid=…; SameSite=Lax</text><text x=\"470\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 · you sign in, the browser keeps the cookie</text><line x1=\"110\" y1=\"170\" x2=\"348\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-csrf-ah)\"></line><text x=\"229.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a hidden form, submitted</text><text x=\"230\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 · you open another site</text><line x1=\"350\" y1=\"222\" x2=\"588\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-csrf-ah)\"></line><text x=\"469.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /wishlist</text><text x=\"470\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 · the browser decides what goes with it</text><rect x=\"395\" y=\"258\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"465.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no cookie</text><text x=\"465.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Lax, cross-site POST</text><rect x=\"545\" y=\"258\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cookie, no token</text><text x=\"615.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">if it were attached</text><text x=\"465\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">401</text><text x=\"615\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">403</text></svg>", "caption": "Cross-site request forgery, and the two checks that stop it. The other page can make the browser send the request; it can read neither the cookie nor the CSRF token."}
```

## SameSite: the browser decides

`SameSite` tells the browser when a request started by another site may carry the cookie:

| value | the cookie goes with a request another site started | in practice |
|---|---|---|
| `Strict` | never | following a link to shelf from an e-mail arrives logged out |
| `Lax` | only when the user follows a link, a top-level `GET` | a forged `POST`, an image, a frame or a script's request goes without it |
| `None` | always, and only with `Secure` | the old behaviour, for cookies that must work inside other sites |

`sessions.py` sets `Lax`. Chrome and Edge apply `Lax` to a cookie that says nothing, and other
browsers do not, so it is written out. A forged `POST` to `/wishlist` therefore arrives with no
cookie, and the server answers 401 as it would to a stranger. `Lax` still sends the cookie when somebody follows a link, which is one
more reason, after lesson 1's section on methods, that **a `GET` must never change anything**: a
link on another site to `GET /wishlist/add?book=3` would carry the cookie and do the deed.

## A token the other page cannot read

`SameSite` is the browser's check, and it depends on the browser. Older browsers ignore it, and two
sites under one registrable domain, such as `shop.example.com` and `blog.example.com`, count as the
same site for it. So the server also checks something itself: **a secret per session that the page
must send back in a header**. `sessions.py` keeps one in each session row as `csrf` and returns it
from `/me`. shelf's own pages can read that answer; another site's page cannot, and a hidden form
cannot set a header in any case.

Log in again, since the last section logged out, and ask for a book on the wishlist with the cookie
alone:

```
ana@api:~/shelf$ curl -s -c jar.txt localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-horse"}'
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -b jar.txt localhost:8000/wishlist -H 'Content-Type: application/json' -d '{"book_id": 3}'
{"error": "missing or wrong X-CSRF-Token"}
403
```

The session is valid and the request is still refused: **403**, the server knows who you are and
the answer is no. The same request with the token in `X-CSRF-Token`:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -b jar.txt localhost:8000/wishlist -H 'Content-Type: application/json' -H "X-CSRF-Token: $(curl -s -b jar.txt localhost:8000/me | jq -r .csrf)" -d '{"book_id": 3}'
{"book_id": 3}
201
ana@api:~/shelf$ curl -s -b jar.txt localhost:8000/wishlist
[{"id": 3, "title": "A Hora da Estrela"}]
```

curl is not a browser, and nothing above came from another site; what the captures show is the
server's half of the defence, which is the half you write. Two more checks complete it, and both are
short: refuse a state-changing request whose `Origin` header names another site, and accept only `application/json` bodies, which a plain HTML form cannot send.

**A bearer token in an `Authorization` header is not exposed to any of this**, because the browser
never adds one by itself: some code in the page has to. That is a real advantage of bearer tokens,
and it disappears the moment somebody stores the token in a cookie, where it is attached as
automatically as `sid`.
