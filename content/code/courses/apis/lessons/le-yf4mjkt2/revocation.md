---
title: Taking a token back
version: 1
---

A session ends the moment its row is deleted. A signed token has no row. Once issued, it is accepted
by every server holding the key until its `exp`, whatever happens in the meantime: the user logs out,
changes the password, is fired, or reports the laptop stolen. **The server cannot recall a token,
because recalling needs a record and the token was designed to need none.**

So "logging out of a JWT" usually means the client throws its copy away, the same housekeeping the
section on logout set aside for cookies. Any other copy keeps working. Three tools narrow the gap, and
each one gives back part of the statelessness that was the reason for choosing a token.

## A short life

The first tool is arithmetic. `tokens.py` gives an access token **five minutes**, so a stolen one is
useful for five minutes at most. Five minutes is also how often the client has to come back for a new
one, and it should not ask the user for a password each time.

## A refresh token, used once

That is what the second token in the login answer is for. The **refresh token** lives for fourteen
days and does one thing: at `POST /refresh` it buys a new pair. It is a random string, like a session
id, and the server keeps it in a table by its hash, like a session. It goes to one endpoint only,
which is why it can live longer than the access token that goes everywhere.

`tokens.py` **rotates** it: every refresh token works once and is replaced by the new one in the
answer. Spend the one from the login:

```
ana@api:~/shelf$ jq '{refresh_token}' login.json | curl -s localhost:8000/refresh -H 'Content-Type: application/json' -d @- | tee second.json | jq .
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiaXNzIjoic2hlbGYiLCJhdWQiOiJzaGVsZi1hcGkiLCJpYXQiOjE3OTE2MDY2NjksIm5iZiI6MTc5MTYwNjY2OSwiZXhwIjoxNzkxNjA2OTY5LCJqdGkiOiIzNjJkYmI2MjdiM2I5MWU2In0.07uZ_cEskfcWYjwqHJBat_kDH4a6leS2oNqU29MmOf4",
  "token_type": "Bearer",
  "expires_in": 300,
  "refresh_token": "e7P8enUOEKeBJ6Y1fzbT-Ww-KbAc_fr5m4va6VF7Wjw"
}
```

Now suppose somebody had copied that first refresh token. Rotation makes a copy show itself: the
owner and the copier both hold it, and whichever presents it second is presenting a token already
spent. The server cannot tell which of the two is legitimate, so it ends the whole sign-in, every
token descended from that login:

```
ana@api:~/shelf$ jq '{refresh_token}' login.json | curl -s localhost:8000/refresh -H 'Content-Type: application/json' -d @-
{"error": "refresh token used twice: this sign-in is revoked"}
```

The new refresh token, which the honest client held, died with the rest:

```
ana@api:~/shelf$ jq '{refresh_token}' second.json | curl -s localhost:8000/refresh -H 'Content-Type: application/json' -d @-
{"error": "unknown or expired refresh token"}
```

**And the access token issued a moment ago still works.** Nothing about it was stored, so there was
nothing to delete:

```
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(jq -r .access_token second.json)"
{"name": "ana", "exp": 1791606969, "jti": "362dbb627b3b91e6"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"A timeline in minutes from 0 to 15. Access token A1 is valid from 0 to 5. At 5 the client uses refresh token R1 and receives A2, valid from 5 to 10, and R2. At 7 someone presents R1 again: reuse is detected and the whole family, R2 included, is deleted, so no new access token can be had. A2 is still accepted until 10, because nothing about it is stored to delete.\"><defs><marker id=\"l08-refresh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"140\" y1=\"250\" x2=\"680\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"140\" y1=\"246\" x2=\"140\" y2=\"254\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"140\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0 min</text><line x1=\"320\" y1=\"246\" x2=\"320\" y2=\"254\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"320\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 min</text><line x1=\"500\" y1=\"246\" x2=\"500\" y2=\"254\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"500\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10 min</text><line x1=\"680\" y1=\"246\" x2=\"680\" y2=\"254\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"680\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">15 min</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">access tokens</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refresh tokens</text><rect x=\"140\" y=\"56\" width=\"180\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A1</text><rect x=\"320\" y=\"56\" width=\"72\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"356.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A2</text><rect x=\"392\" y=\"56\" width=\"108\" height=\"28\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"446.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A2 still accepted</text><rect x=\"140\" y=\"126\" width=\"180\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R1</text><rect x=\"320\" y=\"126\" width=\"72\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"356.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R2</text><rect x=\"392\" y=\"126\" width=\"288\" height=\"28\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"536.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">family deleted: no refresh works</text><line x1=\"320\" y1=\"154\" x2=\"320\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-refresh-ah)\"></line><text x=\"320\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R1 used: A2 + R2</text><line x1=\"392\" y1=\"228\" x2=\"392\" y2=\"158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l08-refresh-ah)\"></line><text x=\"398\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">R1 presented again</text><text x=\"506\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">A2 expires: the damage ends here</text><line x1=\"500\" y1=\"46\" x2=\"500\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line></svg>", "caption": "Rotation with reuse detection, drawn over fifteen minutes. Reusing R1 kills every refresh token of that sign-in at once; the access token already issued stays good until its exp."}
```

## A denylist, checked every time

To end an access token before its `exp`, the server must remember that it ended. `tokens.py` keeps a
table of revoked `jti` values, and `verify` reads it on every request. Log in again and log out:

```
ana@api:~/shelf$ curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-horse"}' > login.json
ana@api:~/shelf$ curl -si -X POST localhost:8000/logout -H "Authorization: Bearer $(jq -r .access_token login.json)"
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:09 GMT
Content-Length: 0

ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(jq -r .access_token login.json)"
{"error": "token revoked"}
```

The table holds one row per revoked token, and only until that token would have expired anyway. After
its `exp` the signature check refuses it without help, so `logout` deletes rows whose time has passed:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT jti, exp FROM revoked'
333d78c320d234d6|1791606969
```

**Look at what this has done to "stateless".** `tokens.py` now keeps a refresh table and a denylist,
and checks the second on every request: a lookup per request against shared storage, which is
exactly the cost the token was supposed to remove. The lookup is smaller, because only the revoked
tokens are listed rather than every live one, and it can be cached. It is still a lookup. A JWT that
can be revoked at once is a session that also carries its claims.
