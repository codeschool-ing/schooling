---
title: "Client credentials: a machine on its own behalf"
version: 1
---

Every night a job copies the shop's stock levels to the warehouse. **No person is involved, so
there is nobody to send to a sign-in page and nobody to consent.** The job is a client acting for
itself, and OAuth has a grant for exactly that: **client credentials**. The client authenticates at
`/token` and receives a token in its own name. There is no browser and no code.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Client credentials: three parties instead of four. A warehouse job, registered as the client shelf-web, posts grant_type=client_credentials with its id and secret to /token and receives an access token only, then calls the stock list with it. There is no browser, no person and no code.\"><defs><marker id=\"l09-cc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"170\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">warehouse job</text><text x=\"105.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">client: shelf-web</text><rect x=\"275\" y=\"14\" width=\"170\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">authorization server</text><text x=\"360.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/token</text><rect x=\"530\" y=\"100\" width=\"170\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resource server</text><text x=\"615.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/books/stock</text><line x1=\"120\" y1=\"98\" x2=\"273\" y2=\"44\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-cc-ah)\"></line><text x=\"108\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">grant_type=client_credentials</text><text x=\"108\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1 · id and secret, HTTP Basic</text><line x1=\"330\" y1=\"68\" x2=\"165\" y2=\"98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-cc-ah)\"></line><text x=\"300\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2 · an access token, nothing else</text><line x1=\"192\" y1=\"130\" x2=\"528\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-cc-ah)\"></line><text x=\"360.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 · Authorization: Bearer …</text><rect x=\"20\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"84.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no browser</text><rect x=\"158\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"222.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no person</text><rect x=\"296\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no code</text><rect x=\"434\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"498.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no refresh token</text><rect x=\"572\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"636.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no ID token</text></svg>", "caption": "Client credentials. The client is acting for itself, so everything in the code flow that existed for a person is absent."}
```

`idp.py`'s client is allowed `books:read` on its own, and nothing else. `del(.access_token)` leaves
the long token out of the print, and `machine.json` keeps all of it:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=client_credentials -d scope=books:read | tee machine.json | jq 'del(.access_token)'
{
  "token_type": "Bearer",
  "expires_in": 300,
  "scope": "books:read"
}
ana@api:~/shelf$ MT=$(jq -r .access_token machine.json)
```

Two tokens are missing, and both absences are deliberate. **No refresh token**, because the client
can repeat this request whenever its token expires; a refresh token would be a second long-lived
credential protecting nothing. **No ID token**, because nobody signed in.

The token opens the stock list like a person's would:

```
ana@api:~/shelf$ curl -s localhost:8000/books/stock -H "Authorization: Bearer $MT" | jq -c '.[0]'
{"id":1,"title":"Dom Casmurro","stock":12}
```

Its claims say whose it is. `sub`, the subject, is the client itself, where a person's token
carried Ana's id; `check_token.py`, from the OpenID Connect section, reads the
token:

```
ana@api:~/shelf$ python3 check_token.py "$MT" shelf-api
{
  "iss": "http://localhost:8000",
  "iat": 1791606663,
  "exp": 1791606963,
  "aud": "shelf-api",
  "sub": "shelf-web",
  "client_id": "shelf-web",
  "scope": "books:read",
  "jti": "9f4af73e03383ad9"
}
```

An API that needs a person refuses it, and the authorization server will not issue `openid` to a
machine at all:

```
ana@api:~/shelf$ curl -s localhost:8000/userinfo -H "Authorization: Bearer $MT"
{"error": "insufficient_scope", "error_description": "this needs the scope openid"}
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=client_credentials -d scope=openid
{"error": "invalid_scope", "error_description": "a machine may ask for books:read only"}
```

## The secret is now the whole credential

**In the code flow a stolen client secret was not enough on its own; here it is everything.**
Whoever holds `shelf-web:lab-only-secret` can mint tokens for as long as the secret is valid. So a
machine client's secret lives where secrets belong: in a secret manager or the platform's
environment, never in the repository, and rotated on a schedule. Better still, many authorization servers let a client prove itself with a private key instead of a
shared secret. The client signs a short JWT (`private_key_jwt`) or presents a TLS client
certificate (RFC 8705), and then there is no secret on the server side to steal.

Give each machine client the smallest scope that does its job, one client per job, so a leaked
credential opens one door. And **never use client credentials to act for a person**: a token whose
`sub` is the client says the client did it, and every log after that is wrong about who.
