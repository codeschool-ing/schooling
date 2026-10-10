---
title: Bearer tokens
version: 1
---

**A token swaps the password for something worth less.** The client sends the password once, to
`/v1/login`, and gets back a long random string. From then on it sends the string, in
`Authorization: Bearer`, and the password stays where it was typed.

```
ana@api:~/shelf$ curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{"username": "ana", "password": "river-lamp-42"}' | tee login.json
{"token": "6RE9jDMi2jfinx2GFkaNYn_3dxh7_0SClOQxCPsN0pk", "expires_in": 3600}
ana@api:~/shelf$ curl -s -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/whoami
{"kind": "person", "name": "ana"}
```

`tee` prints the answer and keeps a copy in `login.json`, so the next commands can read the token with
`jq` instead of you pasting it. That file is a lab convenience: it holds a live credential, and a real
client keeps a token in memory or in the operating system's credential store.

**Bearer means whoever bears it.** The server does not ask who is holding the string, only whether
the string is one it issued. That makes a token exactly as sensitive as a password while it lasts,
and the rest of this section is about making it last less and be worth less when it leaks.

## What the server keeps

The token is 43 characters of base64 drawn from 32 random bytes by `secrets.token_urlsafe`. The
server does not keep it. It keeps its SHA-256:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM tokens'
d2e53762560e0308cc7fd0f5958bb6eaaf4723fe24fcb3a481058986b0ac26ff|1|1791609966
ana@api:~/shelf$ jq -j .token login.json | sha256sum
d2e53762560e0308cc7fd0f5958bb6eaaf4723fe24fcb3a481058986b0ac26ff  -
```

The first column of the row is the hash of the token in `login.json`, character for character. A
leaked copy of `shelf.db` gives an attacker that hash, and the hash is no use as a token: `keys.py`
hashes whatever it is sent, so sending the hash makes it look up the hash of the hash, which is in no
row.

Why SHA-256 here when the password needed scrypt? **A password is a guess away from being found; a
random token is not.** People choose passwords from a small set of likely words, and a slow hash is
what makes trying them expensive. A token is 256 random bits that nobody chose, and no list of likely
tokens exists to try, so a fast hash loses nothing. Lesson 10 makes the same distinction from the
password's side.

## Expiry and revocation

The second column is who the token belongs to and the third is when it stops working, in seconds
since 1970. Read as a date:

```
ana@api:~/shelf$ sqlite3 shelf.db "SELECT datetime(expires, 'unixepoch', 'localtime') FROM tokens"
2026-10-10 02:26:06
```

One hour after the login, because `TOKEN_SECONDS` is 3600. **An expiry bounds the damage of a token
nobody knew had leaked**: it stops working by itself. Revocation is the other half, for the token
somebody does know about, and it is deleting a row. `/v1/logout` deletes the row of the token it is
sent:

```
ana@api:~/shelf$ curl -si -X POST -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/logout
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:06 GMT
Content-Length: 0

ana@api:~/shelf$ curl -si -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/whoami
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:06 GMT
Content-Type: application/json
Content-Length: 38
WWW-Authenticate: Basic realm="shelf"
WWW-Authenticate: Bearer realm="shelf", error="invalid_token"

{"error": "invalid or expired token"}
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT count(*) FROM tokens'
0
```

The same token, a second later, is refused, and the table is empty. Note the second `WWW-Authenticate`:
`error="invalid_token"` tells the client that a token came and was not accepted, which is different
from no token at all. It does not say whether the token expired, was revoked or never existed, and the
client does not need to know: it logs in again.

Rather than wait an hour to watch a token expire, log in again and move its expiry into the past:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{"username": "ana", "password": "river-lamp-42"}' -o login.json
ana@api:~/shelf$ sqlite3 shelf.db "UPDATE tokens SET expires = strftime('%s', 'now') - 1"
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/whoami
{"error": "invalid or expired token"}
401
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT count(*) FROM tokens'
0
```

`keys.py` treated the expired token like one that never existed, and deleted its row on the way.
Revoking every session of a user is the same move with a wider `WHERE`: `DELETE FROM tokens WHERE
user_id = 1` logs ana out everywhere, which is what a server does when she changes her password.

## Opaque and self-contained

This token is **opaque**: it means nothing by itself, and the server has to look it up on every
request to learn whose it is. That lookup is what makes revocation instant, and it is also a database
read per request. The other family of tokens is **self-contained**: the token carries the user and
the expiry inside it, signed by the server, so checking it needs no lookup, and revoking it before it
expires needs something extra. JWT is the common format, and lesson 8 weighs the two against each
other.
