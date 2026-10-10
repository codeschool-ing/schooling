---
title: Forms that prove where they came from
version: 1
---

A browser sends a site's cookies with every request to that site, including requests another site
started. That is cross-site request forgery, CSRF: a page somewhere else submits a form to
`account.py`, the browser attaches the customer's session cookie, and **without a further check the
service cannot tell a cancellation the customer chose from one another page made in their name.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-csrf\" aria-label=\"Three actors left to right: another site, the customer's browser, and account.py. Along the top, the customer's own page carries the CSRF token in its form, and the cancellation with the token is accepted with 303. Along the bottom, another site makes the browser post the same form; the browser may attach the session cookie, but the other site cannot read the token, so the request arrives without it and is refused with 403.\"><defs><marker id=\"l20-csrf-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-csrf-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l20-csrf-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"90.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">another site</text><path d=\"M90.0 54.0 L90.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"290.0\" y=\"20.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the browser</text><path d=\"M360.0 54.0 L360.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"560.0\" y=\"20.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"630.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">account.py</text><path d=\"M630.0 54.0 L630.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M630.0 90.0 L360.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-csrf-nf-ah-paper-dim)\"></path><text x=\"495.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">page with the token in its form</text><path d=\"M360.0 125.0 L630.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-csrf-nf-ah-phosphor)\"></path><text x=\"495.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cookie + token</text><text x=\"495.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">303</text><path d=\"M90.0 175.0 L360.0 175.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l20-csrf-nf-ah-amber)\"></path><text x=\"225.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a form posted from elsewhere</text><path d=\"M360.0 205.0 L630.0 205.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l20-csrf-nf-ah-amber)\"></path><text x=\"495.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cookie, no token</text><text x=\"495.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">403 stale form</text></svg>", "caption": "The cookie travels with any form the browser sends. The token travels only with the forms the service drew."}
```

`account.py` has two layers, and lesson 17 showed the first: `SameSite=Lax` on the cookie, which
tells the browser to leave it off a form posted from another site. The second is a **CSRF token**: a
random value created with the session, written into every form the service draws, and compared on
every state-changing request. Another site can make the browser send a form; it cannot read the page
that holds the token, so it cannot fill the field in.

The probe is the form sent without its token, then the same form with it:

```
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar -w '%{http_code}\n' -X POST localhost:8001/account/cancel -d 'booking=1'
{"error": "stale form"}
403
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar localhost:8001/account | grep -o 'name="csrf" value="[^"]*"' | head -1 | cut -d'"' -f4 > ~/ana.csrf
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar -o /dev/null -w '%{http_code}\n' -X POST localhost:8001/account/cancel -d "booking=1&csrf=$(cat ~/ana.csrf)"
303
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/ana.token)"
{"error": "no such booking"}
404
```

Without the token, `403` and `stale form`; with it, `303` back to the page, and booking 1 is gone.
Both answers matter: **a defence that refused every form would pass the first check**, and the
second proves the refusal is the token check and not a broken route.

Two details a tester asks about, and `account.py` answers. The comparison uses
`hmac.compare_digest`, so the time it takes does not depend on how many characters matched. And the
token belongs to the session: the test in "The vector tests" sends one customer's token with another
customer's cookie and expects a refusal, because a token any session accepts is a token an attacker
could fetch for themselves.

The JSON routes take the session from an `Authorization` header instead of the cookie, and a browser
never adds that header on its own. That is why they need no CSRF token, and why moving them to
cookie sessions would make them need one.
