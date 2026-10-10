---
title: Scopes and consent
version: 1
---

**A scope is easy to mistake for a permission system, and it is something narrower: the list of
things a client asked to do, which a person agreed to, written on the token.** It is an upper limit
on what the token can open. It does not say what the person is allowed to do: a token carrying
`books:read` for somebody the shop has banned still opens nothing, because the API checks its own
rules as well. Lesson 11 is about those rules.

Scope names are strings the authorization server makes up. `books:read` is `idp.py`'s, and the
colon is a habit, not a syntax. Only OpenID Connect defines some: `openid`, `profile`, `email`,
`address` and `phone`. The client asks with `scope` in the `/authorize` address, separated by
spaces, which a URL writes as `+`.

## What consent decides

The consent screen is where the scope is shown to a person: "Shelf Reader wants to see your name
and read your purchases". People press yes without reading it. So **a client should ask for the
smallest set that works and ask for more when a feature needs it**, rather than everything at the
first sign-in; a screen listing nine things trains people to accept any list.

The person may also say yes to less than was asked, and the authorization server may grant less
than the person agreed to. That is why the token response carries `scope`, and **a client reads
it rather than assuming it got what it asked for.**

## Two tokens, two scopes

The token from the last section was granted `openid profile books:read`. `/userinfo` gives it the
name, because of `profile`, and no e-mail address, because nobody asked for `email`:

```
ana@api:~/shelf$ curl -s localhost:8000/userinfo -H "Authorization: Bearer $AT"
{"sub": "u-81f3a2", "name": "Ana Souza"}
```

Now a second sign-in asking for `openid email` and nothing else, with a new PKCE pair. To keep the
lines short these requests leave out `state` and `nonce`; a real client sends a fresh pair with
every one:

```
ana@api:~/shelf$ read VERIFIER CHALLENGE < <(python3 pkce.py)
ana@api:~/shelf$ CODE=$(curl -s -o /dev/null -w '%{redirect_url}' "$AUTH&scope=openid+email&code_challenge=$CHALLENGE" | sed -E 's/.*code=([^&]+).*/\1/')
ana@api:~/shelf$ AT2=$(curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=authorization_code -d code=$CODE -d redirect_uri=http://127.0.0.1:9000/callback -d code_verifier=$VERIFIER | jq -r .access_token)
```

`/userinfo` now has the e-mail address and no name. The stock list says no:

```
ana@api:~/shelf$ curl -s localhost:8000/userinfo -H "Authorization: Bearer $AT2"
{"sub": "u-81f3a2", "email": "ana@shelf.example"}
ana@api:~/shelf$ curl -si localhost:8000/books/stock -H "Authorization: Bearer $AT2"
HTTP/1.1 403 Forbidden
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:02 GMT
Content-Type: application/json
Cache-Control: no-store
Content-Length: 88
WWW-Authenticate: Bearer error="insufficient_scope", scope="books:read"

{"error": "insufficient_scope", "error_description": "this needs the scope books:read"}
```

**403, not 401.** The token is valid; it was never granted `books:read`. RFC 6750 gives this
failure its own error, `insufficient_scope`, and puts the missing scope in `WWW-Authenticate`, so
a client can send the person back to `/authorize` to ask for it.

A scope the client was never registered for is refused at the start, before anybody is asked
anything. The error comes back to the client's callback:

```
ana@api:~/shelf$ curl -si "$AUTH&scope=openid+books:write&code_challenge=$CHALLENGE"
HTTP/1.1 302 Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:02 GMT
Content-Length: 0
Location: http://127.0.0.1:9000/callback?error=invalid_scope
```
