---
title: "What is gone: the implicit and password grants"
version: 1
---

RFC 6749 defined four grants in 2012. Two are the ones this lesson has run, the authorization code
and client credentials. **The other two are still in older documentation, older libraries and
many answers on the internet, and both are now refused.** RFC 9700, the OAuth security
recommendations of 2025, says the implicit grant should not be used and the password grant must
not be; the OAuth 2.1 draft leaves both out of the protocol.

| grant | how it worked | why it went | instead |
|---|---|---|---|
| implicit, `response_type=token` | `/authorize` sent the access token straight back in the redirect, in the part of the address after `#` | the token travels in the front channel: it can end up in the history and in logs, nothing binds it to the client, and there is no refresh token | the code flow with PKCE, which works for a browser app too |
| resource owner password credentials, `grant_type=password` | the client collected the user's password and sent it to `/token` | it is the password-sharing problem from the first section with an OAuth label on it: the app sees the password, and no second factor or consent screen can sit in between | the code flow, so the password is typed only into the authorization server |

**The implicit grant was a workaround for browsers that is no longer needed.** It existed because,
when it was designed, JavaScript in a page could not count on being allowed to call `/token` on
another origin. CORS made that call ordinary, PKCE made it safe for a client with no secret, and
the reason was gone.

`idp.py` refuses both, each in its own way. The implicit request goes back to the callback with an
error, because the client and its address are fine and only the response type is not. `grep`
keeps the one header that matters:

```
ana@api:~/shelf$ curl -si "${AUTH/response_type=code/response_type=token}&scope=openid&code_challenge=$CHALLENGE" | grep Location
Location: http://127.0.0.1:9000/callback?error=unsupported_response_type
```

The password grant is not a grant this server knows:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=password -d username=ana -d password=her-password
{"error": "unsupported_grant_type", "error_description": "password is not offered here"}
```

The OAuth 2.1 draft changes two more things the code flow used to leave optional, and `idp.py`
already enforces both: **PKCE on every code request**, and exact matching of `redirect_uri`, which
turned away the port 9999 address when you ran the flow by hand. A request with no challenge does
not get a code:

```
ana@api:~/shelf$ curl -si "$AUTH&scope=openid" | grep Location
Location: http://127.0.0.1:9000/callback?error=invalid_request&error_description=PKCE+with+S256+is+required
```

A library or a tutorial that offers either grant is telling you its age. Leave both off in any
authorization server you configure, and expect a review to ask why if they are on.
