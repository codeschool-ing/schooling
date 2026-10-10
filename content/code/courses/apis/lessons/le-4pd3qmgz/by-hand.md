---
title: The flow, one request at a time
version: 1
---

You are about to play two parts at once. **You are the browser, reading each redirect instead of
following it, and you are the client, keeping the values the flow needs between requests.** The
server in the second terminal is the authorization server and the API. Every command runs in
`~/shelf`, in the terminal where `VERIFIER` and `CHALLENGE` are set from the PKCE section; if you
opened a new one since, run the `read` line from that section again.

## The redirect to /authorize

A real client makes a fresh `state`, and a fresh `nonce` for OpenID Connect, for every sign-in.
Then the parts of the address that never change go in a variable, to keep the commands readable:

```
ana@api:~/shelf$ STATE=$(openssl rand -hex 8); NONCE=$(openssl rand -hex 8)
ana@api:~/shelf$ AUTH='localhost:8000/authorize?response_type=code&client_id=shelf-web&redirect_uri=http://127.0.0.1:9000/callback&code_challenge_method=S256'
```

Now the request a browser would make. `-i` shows the headers, and curl does not follow a redirect
unless asked, so the answer stops at the `Location`:

```
ana@api:~/shelf$ curl -si "$AUTH&scope=openid+profile+books:read&state=$STATE&nonce=$NONCE&code_challenge=$CHALLENGE"
HTTP/1.1 302 Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:01 GMT
Content-Length: 0
Location: http://127.0.0.1:9000/callback?code=27pQ9sZu0wzrzQYmThN7DbGjWZMjV52T&state=512a38221f3037e5
```

That is steps 2, 3 and 4 of the flow's drawing at once, because `idp.py`'s user is always signed
in and has always agreed. **The `Location` is the client's callback, carrying the code and the same
`state` the request sent**; `echo $STATE` prints the one you made. Nothing listens on port 9000. In a
browser the address would load the client's page, which would read the code from it.

You need the code in a variable. The simplest way is to ask again and keep only the code, which
`-w '%{redirect_url}'` prints and `sed` cuts out. The first code is never used and expires on its
own a minute later:

```
ana@api:~/shelf$ CODE=$(curl -s -o /dev/null -w '%{redirect_url}' "$AUTH&scope=openid+profile+books:read&state=$STATE&nonce=$NONCE&code_challenge=$CHALLENGE" | sed -E 's/.*code=([^&]+).*/\1/'); echo $CODE
oIbY0jbm8Xka3l5qbtbpE3tDwg1ZZu3L
```

## The exchange at /token

The code goes to `/token` with the verifier, the same `redirect_uri`, and the client's own
credentials, which `-u` sends as HTTP Basic. `tee` keeps the answer in `tokens.json`, and `jq`
prints it:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=authorization_code -d code=$CODE -d redirect_uri=http://127.0.0.1:9000/callback -d code_verifier=$VERIFIER | tee tokens.json | jq .
{
  "token_type": "Bearer",
  "expires_in": 300,
  "scope": "books:read openid profile",
  "access_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQyMGRhYmNkIiwidHlwIjoiSldUIn0.eyJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwMDAiLCJpYXQiOjE3OTE2MDY2NjEsImV4cCI6MTc5MTYwNjk2MSwiYXVkIjoic2hlbGYtYXBpIiwic3ViIjoidS04MWYzYTIiLCJjbGllbnRfaWQiOiJzaGVsZi13ZWIiLCJzY29wZSI6ImJvb2tzOnJlYWQgb3BlbmlkIHByb2ZpbGUiLCJqdGkiOiJkZmRlYTNkMmFhYzRmZTdhIn0.G_4CM3DIarza-tMoJk5gqNsFNZUGeVtGLFQxa7JAgEmICG8TLQNbO3j_Vmkx4Gs5AK5WY6jIh8ruY19-aiHSELvEePyfPl1EEXf8488u_13L7rxAV5aPqmAYsPKNqkGhdH0Nxsgprze0zaI_hkInAnLarvtCJ8cg4GVmeysI4dzsRNEzcjHQ2PsQBASunG3UT_Y5PSuqGnHlzH5I1ncJATXsqp-s92htcLX7ynGHekr5IUUCs-j8MWmiH-9pXL1n_blRo1sANSw15Sueb1g06iDBHGZJx9gIn8HH_o40KlaUjV6SBxLhmzhQe35x9VaCKZJleGnQyvOxRmVJM2tbYQ",
  "refresh_token": "IMn9szUzfVNK0MgY32rQLBFvNzf179TwXPC2i73FdAQ",
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQyMGRhYmNkIiwidHlwIjoiSldUIn0.eyJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwMDAiLCJpYXQiOjE3OTE2MDY2NjEsImV4cCI6MTc5MTYwNjk2MSwiYXVkIjoic2hlbGYtd2ViIiwic3ViIjoidS04MWYzYTIiLCJub25jZSI6ImE4YmY3ZWJkNDEzNmUzYmMifQ.Q_xikm4l6zjbx6TsXwVdW3rbSmb8cUHeQYVWiH-pLKM5f52vLvWjsHL9CZTxDTuAISGruSm8BrO7TsE2fUEBNrm2OR6vd9qZUBT2qJGrpp5Vt6fJFwIDxj2oK_EkbwN5VBGTxpE2ydfrkKc5pbjsa3ds0Wn7MlFgvqayqnYyK42cNxt7kVic2ohtcTRf-jHKL7NW6Yoh2i1qvQr12ip74NXrQNjJLo348vtGRiZxyz5c-DGAvrPG7TiDN05TKEFxlsSpKcG8DDTJ8sBHyQTB7N95oDCRMgAsAAXyjvS3NhuxqJvZrOp6YUXDi4vPlJcvT2A3ZievhKMYqHwD5QpXnA"
}
```

Three tokens, and each one has a different reader. The **access token** is for the API. The
**refresh token** is for the authorization server alone, and the section on refresh tokens uses it.
The **ID token** is for the client, and says who signed in; the OpenID Connect section reads it.
`scope` says what was granted, and `expires_in` says the access token lasts 300 seconds. The two
long ones are JWTs, three base64url parts joined by dots, which lesson 8 took apart.

Keep the three in variables:

```
ana@api:~/shelf$ AT=$(jq -r .access_token tokens.json); RT=$(jq -r .refresh_token tokens.json); IDT=$(jq -r .id_token tokens.json)
```

## Calling the API

The access token goes in the `Authorization` header, and the API answers:

```
ana@api:~/shelf$ curl -s localhost:8000/books/stock -H "Authorization: Bearer $AT" | jq -c '.[]'
{"id":1,"title":"Dom Casmurro","stock":12}
{"id":2,"title":"Memórias Póstumas de Brás Cubas","stock":7}
{"id":3,"title":"A Hora da Estrela","stock":0}
{"id":4,"title":"Perto do Coração Selvagem","stock":3}
{"id":5,"title":"Ensaio sobre a Cegueira","stock":9}
{"id":6,"title":"Americanah","stock":4}
```

Without it, the same request is refused with **401**, and `WWW-Authenticate` says what kind of
credential the API wants:

```
ana@api:~/shelf$ curl -si localhost:8000/books/stock
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:01 GMT
Content-Type: application/json
Cache-Control: no-store
Content-Length: 72
WWW-Authenticate: Bearer realm="shelf"

{"error": "invalid_token", "error_description": "send an access token"}
```

## What the server refuses

The flow is only as good as its refusals, and four of them are worth seeing. **A code works
once.** The same exchange a second time:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=authorization_code -d code=$CODE -d redirect_uri=http://127.0.0.1:9000/callback -d code_verifier=$VERIFIER
{"error": "invalid_grant", "error_description": "unknown, used or expired code"}
```

**A code is useless without its verifier.** Get a fresh code, then present it with a verifier that
is not the one behind the challenge, as anybody who took the code on its way would have to:

```
ana@api:~/shelf$ CODE=$(curl -s -o /dev/null -w '%{redirect_url}' "$AUTH&scope=openid+profile+books:read&state=$STATE&nonce=$NONCE&code_challenge=$CHALLENGE" | sed -E 's/.*code=([^&]+).*/\1/')
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=authorization_code -d code=$CODE -d redirect_uri=http://127.0.0.1:9000/callback -d code_verifier=not-the-verifier
{"error": "invalid_grant", "error_description": "code_verifier does not match"}
```

The code was taken out of the table before the check, so that one is spent too. A second guess
would need a third code.

**An address nobody registered gets no code at all.** `${AUTH/9000/9999}` is the shell writing
`$AUTH` with the port changed, so the request names a `redirect_uri` that differs from the
registered one by one digit:

```
ana@api:~/shelf$ curl -si "${AUTH/9000/9999}&scope=openid&code_challenge=$CHALLENGE"
HTTP/1.1 400 Bad Request
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:01 GMT
Content-Type: application/json
Cache-Control: no-store
Content-Length: 84

{"error": "invalid_request", "error_description": "unknown client or redirect_uri"}
```

**A 400 and no `Location`.** Every other error in this lesson goes back to the client's callback
with an `error` parameter, because the server knows that address belongs to the client. This one
cannot: the address is the thing in doubt, and redirecting to it would hand whatever is there a
message from the authorization server.
