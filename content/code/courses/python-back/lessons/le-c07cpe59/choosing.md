---
title: Choosing between them
version: 1
---

The three answer the same question with different trade-offs:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Three rows. A session: the request carries the cookie sessionid, and the server checks it against a row in django_session; logout deletes the row. A DRF token: the request carries Authorization Token, checked against a row in authtoken_token; drf_create_token -r replaces it. A JWT: the request carries Authorization Bearer, and the server checks nothing stored, only the signature with SECRET_KEY; it ends at exp and not before.\"> <defs><marker id=\"tr-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"130\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the request carries</text> <text x=\"430\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the server checks it against</text> <text x=\"20\" y=\"58\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">session</text> <rect x=\"110\" y=\"34\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"205\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Cookie: sessionid=…</text> <rect x=\"330\" y=\"34\" width=\"370\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"515\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a row in django_session</text> <text x=\"515\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">logout deletes the row</text> <path d=\"M300 52 L326 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tr-a)\"></path> <text x=\"20\" y=\"120\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">DRF token</text> <rect x=\"110\" y=\"96\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"205\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization: Token …</text> <rect x=\"330\" y=\"96\" width=\"370\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"515\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a row in authtoken_token</text> <text x=\"515\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">drf_create_token -r replaces it</text> <path d=\"M300 114 L326 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tr-a)\"></path> <text x=\"20\" y=\"182\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">JWT</text> <rect x=\"110\" y=\"158\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"205\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization: Bearer …</text> <rect x=\"330\" y=\"158\" width=\"370\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"515\" y=\"174\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing: the signature, checked with SECRET_KEY</text> <text x=\"515\" y=\"188\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">it ends at exp, not before</text> <path d=\"M300 176 L326 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tr-a)\"></path> </svg>", "caption": "Where each kind of credential is checked. The first two can be taken back at once because the server holds a row; the third holds nothing to delete."}
```

| | session | DRF token | JWT |
|---|---|---|---|
| sent as | a cookie, by the browser itself | a header the client adds | a header the client adds |
| checked against | a row | a row | a signature |
| taken back | at once: delete the row | at once: change the key | **not before `exp`** |
| CSRF | **needed**, because cookies are automatic | not needed | not needed, in a header |
| a stolen copy | `HttpOnly` keeps it from scripts | as good as a password | as good as a password until `exp` |
| suits | a site and its own pages | scripts and apps against one server | several services trusting one issuer |

Three rules of thumb follow.

**A browser talking to its own site: sessions.** They are built in, revocable, and `HttpOnly`
cookies are out of reach of any script that gets into a page. The CSRF token is the price, and
Django pays it for you.

**Programs talking to one server: a token from a table.** DRF's, or one you hash yourself. Revoking
one is a write; the lookup per request is one indexed query.

**Several services that should not all share one database: a JWT**, with a short life. The service
that issues tokens holds the key; the others check signatures. If every request is going to look the
user up anyway, as `current_user` does here, the JWT bought little over a token in a table.

**Where a browser keeps a JWT is its own problem.** `localStorage` is readable by any script that runs
on the page, so one injected script takes the token with it; a cookie marked `HttpOnly` protects it
from scripts and brings CSRF back. Most single-page applications on one domain are better served by a
session cookie, and the JWT is a choice for the space between servers.
