---
title: Signing and verifying
version: 1
---

The third piece of a JWT is computed, not chosen. For HS256 it is the **HMAC-SHA256** of the text
`header.payload`, exactly as it appears in the token with the dot between them, made with the
server's key and written in base64url. Verifying means computing it again and comparing. Change one
byte of the header or the payload and the two no longer agree, and a matching signature for new
content needs the key.

So a signature answers two questions at once: has this been changed since it was signed, and was it
signed by somebody holding the key. It does not answer whether the token should still be accepted.
That is the claims' job, in the next section.

## Doing it by hand

PyJWT does the computation inside `jwt.decode`. Nothing about it is special, and Python's `hmac`
module does it in a few lines. Save this as `hs256.py`:

```python
# shelf/hs256.py
"""Recompute a token's HS256 signature with nothing but hmac, and compare."""
import base64
import hashlib
import hmac
import sys

header, payload, signature = sys.argv[1].split(".")
with open("jwt.key", "rb") as f:
    key = f.read()
mac = hmac.new(key, f"{header}.{payload}".encode(), hashlib.sha256).digest()
mine = base64.urlsafe_b64encode(mac).rstrip(b"=").decode()
print("in the token:", signature)
print("recomputed:  ", mine)
print("they match" if hmac.compare_digest(mine, signature) else "they differ")
```

It reads the key from `jwt.key`, so run it in `~/shelf`. Give it the access token:

```
ana@api:~/shelf$ python3 hs256.py "$(jq -r .access_token login.json)"
in the token: 6htCZVCQFrI9WiAkcaMaskVDcb9mPSuA6V_RF0cmR2M
recomputed:   6htCZVCQFrI9WiAkcaMaskVDcb9mPSuA6V_RF0cmR2M
they match
```

**The signature is not a secret.** It travels in the token for anyone to see, and seeing it does not
help: HMAC is built so that no amount of signatures reveals the key. What must stay secret is the 32
bytes in `jwt.key`.

## Changing one character

The payload begins with the nine bytes `{"sub":"1`, which base64 writes as `eyJzdWIiOiIx`. With a
`2` in place of the `1` they become `eyJzdWIiOiIy`: one letter apart. `sed` swaps it, and the token
now claims to be user 2, bruno:

```
ana@api:~/shelf$ jq -r .access_token login.json | sed 's/\.eyJzdWIiOiIx/.eyJzdWIiOiIy/' > edited.txt
ana@api:~/shelf$ cut -d. -f2 edited.txt | sed 's/$/=/' | basenc --base64url -d; echo
{"sub":"2","iss":"shelf","aud":"shelf-api","iat":1791606667,"nbf":1791606667,"exp":1791606967,"jti":"1902a1acaa43b316"}
```

The signature was left as it was, since producing a new one needs the key. It no longer matches:

```
ana@api:~/shelf$ python3 hs256.py "$(cat edited.txt)"
in the token: 6htCZVCQFrI9WiAkcaMaskVDcb9mPSuA6V_RF0cmR2M
recomputed:   SgS9eJ4tv8huF_u0HbO8xxyrc2EXxCHdgSJtyHIcyYY
they differ
```

And the API refuses the token. The body names the check that failed, and **the status is the same
401 a missing token gets**, because a client's only useful answer to either is to sign in again.

```
ana@api:~/shelf$ curl -si localhost:8000/me -H "Authorization: Bearer $(cat edited.txt)"
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:08 GMT
Content-Type: application/json
Content-Length: 43
WWW-Authenticate: Bearer error="invalid_token"

{"error": "Signature verification failed"}
```

The comparison at the end of `hs256.py` uses `hmac.compare_digest` rather than `==`. A plain string
comparison stops at the first difference, so the time it takes leaks how many leading characters were
right. `compare_digest` takes the same time whatever the input, and the password and CSRF checks in
`sessions.py` use it too.

## One key, or two

HS256 is **symmetric**: the key that signs is the key that verifies. That is simple when one program
does both, as `tokens.py` does. It stops being simple when ten services verify tokens, because each
of them then holds a key that can also **mint** them, and a leak from any one lets the reader sign in
as anybody everywhere.

The asymmetric algorithms, `RS256` with RSA and `ES256` with elliptic curves, separate the two jobs. A
private key signs and stays with the issuer; a public key verifies and can be given to every service,
or published. A service that verifies can no longer issue. Lesson 9 meets that arrangement in OpenID
Connect, where an identity provider publishes the public keys that check its tokens.
