---
title: Refresh tokens, and rotation
version: 1
---

**An access token is checked by the API with a public key and no conversation.** That is what
makes it fast, and it is also why nobody can call one back: an API that never asks the
authorization server cannot hear that a token was withdrawn. The damage a stolen access token can
do is bounded by one thing, its lifetime, so it is kept short. Those from `idp.py` last 300
seconds.

A person should not sign in every five minutes, and the **refresh token** is the answer. It is long
lived, it goes only to the authorization server and never to an API, and it buys a new access token
without the person. `jq 'del(.access_token)'` prints the answer without the long access token:

```
ana@api:~/shelf$ echo $RT
IMn9szUzfVNK0MgY32rQLBFvNzf179TwXPC2i73FdAQ
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=refresh_token -d refresh_token=$RT | tee tokens2.json | jq 'del(.access_token)'
{
  "token_type": "Bearer",
  "expires_in": 300,
  "scope": "books:read openid profile",
  "refresh_token": "QxCmj-nVw11uQP41CGKzG3wedisK3gsVFBN6RN_y9Ds"
}
```

The answer carries a new access token, and **a new refresh token, different from the one that was
sent.** That is **rotation**: every refresh token works once, and using it replaces it. Keep the
new one:

```
ana@api:~/shelf$ RT2=$(jq -r .refresh_token tokens2.json)
```

## Why rotation catches a theft

Suppose a copy of a refresh token leaks. Without rotation, the thief and the app use the same token
side by side for weeks and neither notices. With rotation, the first of the two to use it gets a
new one, and when the other presents the old one, **the authorization server sees a refresh token
come back that was already spent.** It cannot tell which of the two holders is the real app, so it
ends the whole grant and both lose:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=refresh_token -d refresh_token=$RT
{"error": "invalid_grant", "error_description": "refresh token used twice; grant revoked"}
```

Including the replacement, which was issued correctly a moment ago:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=refresh_token -d refresh_token=$RT2
{"error": "invalid_grant", "error_description": "unknown or revoked refresh token"}
```

The real app's next refresh fails, the person signs in again, and the thief's copy is dead. A real
authorization server also writes the event somewhere a person will look, because a reused refresh
token is evidence of a theft, and `idp.py` only refuses.

**What rotation does not do is reach the access token already issued.** The grant is revoked and
the first access token still opens the stock list, because the API checked a signature and a time
and asked nobody:

```
ana@api:~/shelf$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8000/books/stock -H "Authorization: Bearer $AT"
200
```

That is the reason for the short lifetime, stated with a number: whoever holds that token has at
most what is left of its 300 seconds. If more than five minutes have passed since you made it, your
answer is `401` instead, which is the same point arriving from the other side.

## Where a refresh token is kept

It is the most valuable thing a client holds, so where it lives matters more than where the access
token does:

| client | where the refresh token lives |
|---|---|
| a web app with a server | on the server, in the user's session; the browser only ever holds a session cookie |
| a phone app | the operating system's protected store: Keychain on iOS, Keystore on Android |
| a single-page app | ideally nowhere in the browser: a small server of the app's own (a "backend for frontend") holds the tokens and the browser gets a cookie. If the browser must hold it, rotation is mandatory, and the authorization server limits its life |
