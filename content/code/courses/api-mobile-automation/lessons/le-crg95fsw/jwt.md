---
title: Inside a JWT, and the two ways a server should refuse one
version: 1
---

**A JWT, a JSON Web Token, is three pieces of text joined by dots: a header, a payload of claims,
and a signature over the first two.** boxoffice's tokens are JWTs, and a tester opens them, because
what is inside decides what the token may do and for how long.

The belief to drop is that a token is encrypted. It is **signed**, not encrypted: anybody holding
one can read it, and only the holder of the secret can make a new one that the server will accept.
The dots split it into its three pieces:

```
ana@laptop:~/boxoffice$ echo "$TOKEN" | tr . "\n"
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
eyJzdWIiOiJjaS10ZXN0cyIsInNjb3BlIjoib3JkZXJzOnJlYWQgb3JkZXJzOndyaXRlIiwiaWF0IjoxNzkxNjYxMzg3LCJleHAiOjE3OTE2NjIyODd9
ZYNygARAi8VHK-A59GydT_uT2q6wG8ebDb8D67_sJQU
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 196\" role=\"img\" aria-label=\"A JWT drawn as three boxes joined by dots: the header, holding alg HS256; the payload, holding the claims such as sub ci-tests; and the signature. A bracket under the header and the payload says they are readable by anyone, being base64url and not encryption. A line from that bracket to the signature says the signature is an HMAC-SHA256 of the two with the server’s secret, so changing one character on the left means the signature no longer matches.\"><defs><marker id=\"f03jwt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"350\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one token, three parts joined by dots</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">header</text><text x=\"120\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{\"alg\":\"HS256\"}</text><rect x=\"250\" y=\"40\" width=\"220\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">payload: the claims</text><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{\"sub\":\"ci-tests\",…}</text><rect x=\"500\" y=\"40\" width=\"180\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">signature</text><text x=\"590\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lwdWgGhtfpp9…</text><text x=\"235\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">.</text><text x=\"485\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">.</text><line x1=\"20\" y1=\"112\" x2=\"470\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><line x1=\"20\" y1=\"106\" x2=\"20\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><line x1=\"470\" y1=\"106\" x2=\"470\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><line x1=\"245\" y1=\"112\" x2=\"245\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"245\" y1=\"140\" x2=\"590\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"590\" y1=\"140\" x2=\"590\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03jwt-ah)\"></line><text x=\"236\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">readable by anyone: base64url, not encryption</text><text x=\"420\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">HMAC-SHA256 of the two, with the server’s secret</text><text x=\"350\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">change one character on the left and the signature no longer matches</text></svg>", "caption": "The header and the payload are readable by anyone; the signature covers both, and only the secret can produce it."}
```

## Reading the claims

The first two pieces are JSON written in base64url, an alphabet of letters, digits, `-` and `_` that
travels safely in a header. Node can turn them back into text in one line, which loops over the two
pieces and decodes each:

```
ana@laptop:~/boxoffice$ node -e 'for (const part of process.argv[1].split(".").slice(0, 2)) console.log(Buffer.from(part, "base64url").toString())' "$TOKEN"
{"alg":"HS256","typ":"JWT"}
{"sub":"ci-tests","scope":"orders:read orders:write","iat":1791661387,"exp":1791662287}
```

The header says how the token was signed: `HS256`, an HMAC with SHA-256, which uses one shared
secret both to sign and to check. The payload carries four **claims**:

| claim | means | here |
|---|---|---|
| `sub` | the subject: who the token is about | the client `ci-tests` |
| `scope` | what it may do, separated by spaces | read and write orders |
| `iat` | issued at, in seconds since 1 January 1970 UTC | when the token endpoint answered |
| `exp` | expires at, in the same seconds | `iat` plus the lifetime |

Seconds since 1970 are hard to read, so one more line subtracts them and turns `exp` into a date:

```
ana@laptop:~/boxoffice$ node -e 'const c = JSON.parse(Buffer.from(process.argv[1].split(".")[1], "base64url")); console.log(c.exp - c.iat, new Date(c.exp * 1000).toString())' "$TOKEN"
900 Sat Oct 10 2026 16:58:07 GMT-0300 (Brasilia Standard Time)
```

900 seconds between issue and expiry, the `expires_in` of section 03, and the moment it stops
working in local time. **Two checks a tester makes on every token**: the lifetime is what the API
documents, and the scope is no wider than the client was granted.

## Changing a claim

Since anyone can read a token, anyone can also edit one. The `auditor` client is allowed only to
read; take a token of its own and rewrite its scope so that it claims to write too. First the
auditor's token, the way section 03 fetched the other one:

```
ana@laptop:~/boxoffice$ AUDITOR=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=auditor -d client_secret=auditor-secret | jq -r .access_token)
```

Then a line that decodes the payload, changes `scope`, encodes it again and puts the token back
together **with the original signature**:

```
ana@laptop:~/boxoffice$ FORGED=$(node -e 'const [head, body, sig] = process.argv[1].split("."); const claims = JSON.parse(Buffer.from(body, "base64url")); claims.scope = "orders:read orders:write"; console.log([head, Buffer.from(JSON.stringify(claims)).toString("base64url"), sig].join("."))' "$AUDITOR")
```

Sent to the server as an order:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $FORGED" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":1}' | grep -iE '^HTTP|^www'
HTTP/1.1 401 Unauthorized
www-authenticate: Bearer error="invalid_token", error_description="bad signature"
```

`bad signature`. The signature was made over the original header and payload; boxoffice recomputed
it over the edited ones, they differ, and the token is refused before its claims are even read. This
is the most important test in the lesson: **a server that accepted an edited token would let every
client grant itself any scope**. Its companion is a token whose header says `"alg": "none"` and
whose signature is empty, which a careless library treats as needing no check. `readToken` in
`boxoffice.mjs` never looks at `alg` and always recomputes its own signature, so it would refuse that
one too; against an API whose code you cannot read, you send it and see.

## What a restart does to a token

boxoffice keeps no list of the tokens it has issued. It checks a token by recomputing its signature,
so a token stays valid for as long as the secret and the clock say so. Stop the server in the second
terminal with Ctrl-C and start it again:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Every order is gone and every seat is free again, as lesson 1 said. Then the token fetched before the restart, in
an order:

```
ana@laptop:~/boxoffice$ code localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":1}'
201
```

`201`. **The server that issued the token no longer exists, and the token still works**, because
the secret is the same. The other side of that coin is that a JWT cannot be withdrawn before it
expires without extra machinery, which is why its lifetime should be short.

## Expiry, without waiting fifteen minutes

`TOKEN_TTL` sets the lifetime in seconds. Restart boxoffice with tokens that live five seconds:

```
ana@laptop:~/boxoffice$ TOKEN_TTL=5 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Fetch a token, use it at once, wait six seconds, use it again:

```
ana@laptop:~/boxoffice$ SHORT=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
ana@laptop:~/boxoffice$ code localhost:8080/v1/orders -H "authorization: Bearer $SHORT" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":1}'
201
ana@laptop:~/boxoffice$ sleep 6
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $SHORT" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":1}' | grep -iE '^HTTP|^www'
HTTP/1.1 401 Unauthorized
www-authenticate: Bearer error="invalid_token", error_description="token expired"
```

The same token, a `201` and then a `401`, and the `www-authenticate` header says why: `token
expired`. An expiry test does not need the real lifetime, only a server configured to shorten it,
which is exactly what a setting like `TOKEN_TTL` is for. Restart boxoffice once more with a plain
`node boxoffice.mjs` before going on, and fetch `TOKEN` again: the one you had was issued by a server
whose tokens lived fifteen minutes, and it may have run out by now.
