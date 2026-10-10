---
title: The claims, and the checks an API must make
version: 1
---

A valid signature says the token is the one the server issued. It says nothing about whether it
should still be accepted, here, now, by this API. **That is decided by the claims, and only if the
server checks them.** A library verifies what it is told to verify, and a missing argument is a check
that silently does not happen.

The JWT standard names seven claims, and `tokens.py` puts in all of them:

| claim | means | in `tokens.py` | if nobody checks it |
|---|---|---|---|
| `sub` | subject: who the token is about | the user's id, as a string | the server cannot tell whose request it is |
| `exp` | expiry, in seconds since 1970 | 300 seconds after issue | a token copied once works for ever |
| `iat` | issued at | the moment of the login | there is no telling how old a token is |
| `nbf` | not valid before | the same moment | a token minted for later works today |
| `iss` | issuer: who made the token | `shelf` | a token another system signed with a shared key passes |
| `aud` | audience: who it is meant for | `shelf-api` | a token for one API is accepted by another |
| `jti` | the token's own id | 16 random hex digits | one token cannot be told from another, so it cannot be revoked alone |

The times are plain numbers. `date` turns the access token's `exp` into a clock time:

```
ana@api:~/shelf$ date -d @$(jq -r .access_token login.json | cut -d. -f2 | sed 's/$/=/' | basenc --base64url -d | jq .exp)
Sat Oct 10 01:36:07 -03 2026
```

## Leeway

Two machines never agree on the time to the second. A token issued by one server and checked by
another whose clock runs a little fast would be rejected moments before it should be, so `verify`
passes `leeway=30`: thirty seconds of grace on `exp` and `nbf`. `tokens.py` can be imported, so
`tokens.issue` will make a token as if the login had happened some seconds ago. One issued 310
seconds ago expired 10 seconds ago, inside the grace:

```
ana@api:~/shelf$ python3 -c 'import tokens, time; print(tokens.issue(1, now=time.time() - 310))' > late.txt
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(cat late.txt)"
{"name": "ana", "exp": 1791606658, "jti": "09a2d6adea537e80"}
```

One issued 600 seconds ago expired 300 seconds ago, and is refused:

```
ana@api:~/shelf$ python3 -c 'import tokens, time; print(tokens.issue(1, now=time.time() - 600))' > old.txt
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(cat old.txt)"
{"error": "Signature has expired"}
```

PyJWT calls it an expired signature; the signature is fine, and it is the token that has expired. A
leeway of seconds absorbs clock drift. A leeway of hours turns a five-minute token into a long one.

## The audience

Another service that holds the same key, an admin API say, should refuse a token made for the
shop. That is what `aud` is for: checked against `shelf-admin`, ana's token fails, although its
signature is perfect.

```
ana@api:~/shelf$ python3 -c 'import json, jwt, tokens; t = json.load(open("login.json"))["access_token"]; jwt.decode(t, tokens.KEY, algorithms=["HS256"], audience="shelf-admin")' 2>&1 | tail -1
jwt.exceptions.InvalidAudienceError: Audience doesn't match
```

**PyJWT checks `exp`, `nbf` and `iat` only when the token contains them, and `iss` only when the
caller names an issuer.** A token with no `exp` at all would never expire. That is why `verify` lists
all seven in `options={"require": [...]}`: a token missing one is refused rather than waved through.

## The algorithm is the server's choice

The header says `"alg": "HS256"`, and the header is written by whoever made the token. If a server
read the algorithm from the header and used whatever it said, the token would be choosing how it gets
checked. The standard includes one value, `none`, that means no signature at all, and PyJWT will
produce such a token:

```
ana@api:~/shelf$ python3 -c 'import jwt; print(jwt.encode({"sub": "1", "iss": "shelf", "aud": "shelf-api"}, None, algorithm="none"))' > none.txt
ana@api:~/shelf$ cat none.txt
eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiIxIiwiaXNzIjoic2hlbGYiLCJhdWQiOiJzaGVsZi1hcGkifQ.
```

The third piece is empty. Sent to the API, it is refused before any claim is read, because `verify`
passes `algorithms=["HS256"]` and `none` is not on the list:

```
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(cat none.txt)"
{"error": "The specified alg value is not allowed"}
```

PyJWT 2.7 goes further and will not decode at all unless the caller says which algorithms it
accepts:

```
ana@api:~/shelf$ python3 -c 'import jwt; jwt.decode(open("none.txt").read().strip())' 2>&1 | tail -1
jwt.exceptions.DecodeError: It is required that you pass in a value for the "algorithms" argument when calling decode().
```

**Pin the algorithm, in one place, to the one your keys are for.** The same rule covers the subtler
mistake of a server that accepts both `HS256` and `RS256` and lets the header pick, so that a public
key, which is not a secret, ends up used as an HMAC key. A server that names exactly one algorithm
has neither problem.
