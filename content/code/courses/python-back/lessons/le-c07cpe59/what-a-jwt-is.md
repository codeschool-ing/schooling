---
title: What a JWT is
version: 1
---

This is the token ana received, cut at its dots and decoded:

```
ana@vm:~/agenda-api$ tr '.' '\n' < token.txt
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
eyJzdWIiOiJhbmEiLCJleHAiOjE3OTI3MTM5MzV9
q9DrKbWnRSehD40b0wJQ1ZMkKes5LpDArCmiqO0RGpM
ana@vm:~/agenda-api$ cut -d. -f1 token.txt | base64 -d; echo
{"alg":"HS256","typ":"JWT"}
ana@vm:~/agenda-api$ cut -d. -f2 token.txt | base64 -d; echo
{"sub":"ana","exp":1792713935}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"The token from token.txt in its three parts. The header decodes to alg HS256, typ JWT. The payload decodes to sub ana and an exp timestamp. The signature is an HMAC-SHA256 of the first two parts, made with SECRET_KEY.\"> <text x=\"20\" y=\"42\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">header</text> <rect x=\"110\" y=\"20\" width=\"330\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"41\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9</text> <text x=\"460\" y=\"41\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{\"alg\":\"HS256\",\"typ\":\"JWT\"}</text> <text x=\"20\" y=\"104\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">payload</text> <rect x=\"110\" y=\"82\" width=\"330\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"103\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eyJzdWIiOiJhbmEiLCJleHAiOjE3OTI3MTM5MzV9</text> <text x=\"460\" y=\"103\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{\"sub\":\"ana\",\"exp\":1792713935}</text> <text x=\"20\" y=\"166\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">signature</text> <rect x=\"110\" y=\"144\" width=\"330\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"275\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">q9DrKbWnRSehD40b0wJQ1ZMkKes5LpDArCmiqO0RGpM</text> <text x=\"460\" y=\"165\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HMAC-SHA256(header.payload, SECRET_KEY)</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The first two are base64, which anyone can read. Only the third needs the key.</text> </svg>", "caption": "The token ana received, cut at its dots. Changing a letter of the payload makes the signature wrong, which is what the forged token found."}
```

**A JWT is three base64 strings joined by dots.** The header says how it is signed. The payload is
the **claims**: `sub`, the subject, here a username, and `exp`, the moment it stops being valid, in
seconds since 1970. `base64 -d` read both with no key at all: **a JWT is signed, not encrypted**,
so nothing secret goes in the payload.

The third part is the **signature**: an HMAC of the first two, computed with a key only the server
knows. Change one character of the header or the payload, and the signature no longer matches;
compute a new signature, and you need the key. So the server can trust `sub` without asking the
database whether this token was ever issued.

## Tokens that should fail

`bad_tokens.py` makes two: ana's token with `ana` changed to `bruno` in the payload, the signature
left alone, and a token signed with the right key that expired a minute ago.

```python
# bad_tokens.py
import base64
import json
import time

import jwt

from app.security import ALGORITHM, SECRET_KEY

header, payload, signature = open("token.txt").read().strip().split(".")
claims = json.loads(base64.urlsafe_b64decode(payload + "=="))
claims["sub"] = "bruno"
forged = base64.urlsafe_b64encode(json.dumps(claims).encode()).decode().rstrip("=")
open("forged.txt", "w").write(f"{header}.{forged}.{signature}")

expired = jwt.encode({"sub": "ana", "exp": int(time.time()) - 60}, SECRET_KEY, algorithm=ALGORITHM)
open("expired.txt", "w").write(expired)
```

```
ana@vm:~/agenda-api$ uv run python bad_tokens.py
ana@vm:~/agenda-api$ uv run python -c "import jwt; print(jwt.decode(open('forged.txt').read(), options={'verify_signature': False}))"
{'sub': 'bruno', 'exp': 1792713935}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat forged.txt)"; echo
{"detail":"Could not validate the token"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat expired.txt)"; echo
{"detail":"Could not validate the token"}
```

PyJWT reads the forged payload when told not to check, and **the API refuses both**, with one
message that does not say which check failed.

## What it costs

That is also its limit. **Nothing is stored, so there is nothing to delete**: a JWT stays valid until
its `exp`, even after a logout, a password change or a dismissal. The usual answers are a short life,
minutes rather than days, with a second, longer-lived refresh token kept on the server to get new
ones; or a list of revoked tokens, which is a table checked on every request again. And the signing
key is now the one secret that, leaked, lets anybody be anybody: lesson 15 takes it out of the code.
