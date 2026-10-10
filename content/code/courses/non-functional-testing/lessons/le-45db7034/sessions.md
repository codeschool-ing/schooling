---
title: Sessions that end
version: 1
---

A session token is a password with a lifetime: whoever holds it is, as far as the service can
tell, the customer who signed in. **So the questions a tester asks about a token are the questions
about a password, plus one: when does it stop working?** A token that works for ever is a password
that can never be changed, and one that leaked into a log last year still opens the account today.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l17-session\" aria-label=\"A session drawn as a bar along time. It starts at sign-in, when a random token is issued, and every request in between is accepted. It ends in one of two ways: at logout, when its row is deleted, or at expiry, 1800 seconds after sign-in. After the end, the same token is answered with 401. Below the bar, the database row holds the SHA-256 of the token, not the token, so a copy of the database opens nothing.\"><defs><marker id=\"l17-session-nf-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">a token is a password with an end</text><path d=\"M40.0 120.0 L690.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l17-session-nf-ah-wire)\"></path><rect x=\"80.0\" y=\"98.0\" width=\"480.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M130.0 104.0 L130.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M190.0 104.0 L190.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M250.0 104.0 L250.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M310.0 104.0 L310.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M370.0 104.0 L370.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"250.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every request accepted</text><text x=\"80.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sign-in</text><path d=\"M430.0 92.0 L430.0 148.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"430.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">logout</text><text x=\"430.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">row deleted</text><path d=\"M560.0 92.0 L560.0 148.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"560.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">expiry</text><text x=\"560.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1800 s after sign-in</text><text x=\"626.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">401</text><rect x=\"80.0\" y=\"192.0\" width=\"330.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"245.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the database keeps sha256(token), not the token</text></svg>", "caption": "Whichever comes first ends the session: logout or expiry. Either way the token stops opening anything."}
```

`account.py` ends a session three ways. **Logout** deletes its row. **Expiry** is a time written
into the row when the session starts, `SESSION_SECONDS` after sign-in, 1800 seconds unless the
environment says otherwise, and `who` ignores any row past it. And a **copy of the database** opens
nothing, because the row holds the token's SHA-256 rather than the token, which "Passwords and
sign-in" shows.

## Logout, and a token in the address

`ana` still holds the token from the previous section. Put it in the address instead of the header,
the way some services accept it; then log out, and try the header again:

```
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' "localhost:8001/bookings/1?token=$(cat ~/ana.token)"
{"error": "sign in first"}
401
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/logout -H "Authorization: Bearer $(cat ~/ana.token)"
{"ok": true}
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/ana.token)"
{"error": "sign in first"}
401
```

The token in the address is ignored, so the request is anonymous and gets a `401`. That is the
behaviour to require, not a missing feature. **An address is written down in more places than
anybody can list**: the browser's history, the server's access log, every proxy on the way, the
`Referer` header sent to the next site, the screenshot pasted into a ticket. A token in a header
or a cookie goes to the one server it is meant for.

After logout the same header that worked a minute ago gets `401`. **That is the test lesson 16
already runs**, `test_logout_ends_the_session`, and it is worth having because the easy way to
build logout is to forget the token in the browser and leave it valid on the server, which looks
identical to the person clicking the button.

## Expiry, with a short clock

Thirty minutes is too long to wait for, so the lifetime is an environment variable. Stop the
service with `Ctrl+C` in its terminal and start it again with sessions of two seconds:

```sh
env ACCOUNT_SESSION_SECONDS=2 python3 account.py
```

Then, in the other terminal, sign `bia` in again, use the token at once, wait three seconds, and
use it again:

```
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/login -d '{"name": "bia", "password": "correct horse battery"}' | jq -r .token > ~/bia.token
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/bia.token)"
{"error": "no such booking"}
404
ana@nft:~/boxoffice$ sleep 3
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/bia.token)"
{"error": "sign in first"}
401
```

The first answer is the owner check, refusing her `ana`'s booking, which proves the session was
alive. Three seconds later the same request is anonymous. Stop the service again and start it with
plain `python3 account.py` before going on: two-second sessions are a test setting, not a
configuration anybody should ship.

## The cookie's three flags

The HTML page of `account.py` is reached with a cookie rather than a header, because a browser
sends a cookie on its own. Sign in and look at what the service asks the browser to keep:

```
ana@nft:~/boxoffice$ curl -si -X POST localhost:8001/login -d '{"name": "bia", "password": "correct horse battery"}' | grep -i -e '^HTTP' -e '^set-cookie'
HTTP/1.1 200 OK
Set-Cookie: session=0X8_t7CJ5D8WAd1DjRxrsgJtdUOTEz1v2u03XvsvkCw; HttpOnly; SameSite=Lax; Path=/; Max-Age=1800
```

- **`HttpOnly`** keeps the cookie away from JavaScript on the page. If text from outside ever did
  get run as a script, it still could not read the session and send it somewhere.
- **`SameSite=Lax`** tells the browser not to send the cookie with a form posted from another site.
  Lesson 20 tests the second layer behind it, the CSRF token.
- **`Max-Age=1800`** lets the browser forget the cookie when the server forgets the session.

The flag that is absent is **`Secure`**, which tells the browser to send the cookie only over
HTTPS. It is absent because this service speaks plain HTTP to `127.0.0.1`, and a browser would
refuse to send a `Secure` cookie there. In a real deployment, behind HTTPS, it belongs on every
session cookie, and a test plan says so in a row of its own.
