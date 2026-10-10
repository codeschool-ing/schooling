---
title: "OpenID Connect: who signed in"
version: 1
---

**OAuth answers "may this app do this?" and never "who is this?"** The wrong idea that follows is a
common one: an app receives an access token, calls an API that
returns a user id, and treats the person as signed in. The access token was never meant for the
app. Its audience is the API, and the app cannot tell whether a token handed to it was issued to it
or to some other app that happened to obtain one for the same person. An app that signs people in
with whatever access token it is given will sign in anybody who brings one.

**OpenID Connect is a layer on OAuth 2.0 that adds the answer.** It was published by the OpenID
Foundation in 2014, and it is what a "Sign in with…" button speaks today. The client asks for the
scope `openid`, the flow is the same code flow, and the token response gains an **ID token**: a JWT
made out to the client, saying who signed in, where and when.

| | access token | ID token |
|---|---|---|
| made out to (`aud`) | the API: `shelf-api` | the client: `shelf-web` |
| read by | the API | the client, which checks it and then signs the person in |
| says | what the bearer may do (`scope`) | who signed in (`sub`), for which sign-in (`nonce`) |
| sent to an API | yes, as `Authorization: Bearer` | never |
| format | anything the authorization server likes; often a JWT, sometimes opaque | always a JWT |

## Finding the keys

A client must check the ID token's signature, so it needs the authorization server's public key,
and OpenID Connect publishes it in two steps. **Discovery** is a document at a fixed address under
the issuer, `/.well-known/openid-configuration`, listing every endpoint and what the server
supports:

```
ana@api:~/shelf$ curl -s localhost:8000/.well-known/openid-configuration | jq .
{
  "issuer": "http://localhost:8000",
  "authorization_endpoint": "http://localhost:8000/authorize",
  "token_endpoint": "http://localhost:8000/token",
  "userinfo_endpoint": "http://localhost:8000/userinfo",
  "jwks_uri": "http://localhost:8000/jwks.json",
  "response_types_supported": [
    "code"
  ],
  "grant_types_supported": [
    "authorization_code",
    "refresh_token",
    "client_credentials"
  ],
  "code_challenge_methods_supported": [
    "S256"
  ],
  "scopes_supported": [
    "books:read",
    "email",
    "openid",
    "profile"
  ],
  "subject_types_supported": [
    "public"
  ],
  "id_token_signing_alg_values_supported": [
    "RS256"
  ],
  "token_endpoint_auth_methods_supported": [
    "client_secret_basic"
  ]
}
```

The `jwks_uri` in it points to the **JWKS**, the JSON Web Key Set: the public keys, each with the
`kid` a token names in its header. A server rotating keys lists two for a while, and the `kid`
says which one signed a given token. Yours has one, and its `kid` is the id the server printed when
it started:

```
ana@api:~/shelf$ curl -s localhost:8000/jwks.json | jq .
{
  "keys": [
    {
      "kty": "RSA",
      "key_ops": [
        "verify"
      ],
      "n": "zdwZvA21Q7Xr9uy9dU-fpxvAjdlmJN0_m1w2UtCvV0k3AmUniz7TeIMdVtiBcDtlKS8eLZgZcb9CUVQaeA_cPEWbUnuJrhRfVVJvyoA5ut5Lrmf0YMDfiQZ_-VsVssZLII_T-vwW5E0N03g2qKEEx7Qmi07vSuI4mLl1g5T457G5aSFNZFfjzsQdZhMLsksskkcdoYAYMWq6ssP1k_NWdkBTvKg7wJFLEUB3sDGBuC32Nsc_ZvL_cTzsi3Dvz0upJXi7YfKdlwnPbsqYnKqUDAp4LRXQ7Cte3tEJbATcom0OKYcEMrkjw4ijLrFI6g-5vY4ZX2oTYzcsiJhR-iEYOw",
      "e": "AQAB",
      "kid": "420dabcd",
      "use": "sig",
      "alg": "RS256"
    }
  ]
}
```

## Checking an ID token

`check_token.py` does what a client must do before it believes an ID token. It reads the discovery
document, fetches the key the token's `kid` names, and lets PyJWT check the rest:

```python
# shelf/check_token.py
"""Check a token from idp.py the way its receiver must, and print its claims.

    python3 check_token.py TOKEN AUDIENCE [NONCE]
"""
import json
import sys
import urllib.request

import jwt

ISSUER = "http://localhost:8000"

token, audience = sys.argv[1], sys.argv[2]
with urllib.request.urlopen(ISSUER + "/.well-known/openid-configuration") as r:
    config = json.load(r)
try:
    key = jwt.PyJWKClient(config["jwks_uri"]).get_signing_key_from_jwt(token)
    claims = jwt.decode(token, key.key, algorithms=["RS256"], audience=audience,
                        issuer=ISSUER, options={"require": ["iss", "aud", "exp", "sub"]})
    if len(sys.argv) > 3 and claims.get("nonce") != sys.argv[3]:
        raise jwt.InvalidTokenError("the nonce is not the one this client sent")
except jwt.PyJWTError as e:
    sys.exit(f"refused: {e}")
print(json.dumps(claims, indent=2))
```

The six checks, and what each one stops:

| check | in `check_token.py` | what it stops |
|---|---|---|
| the signature, by the key the `kid` names | `get_signing_key_from_jwt`, then `jwt.decode` | a token anybody wrote |
| the algorithm is the one expected | `algorithms=["RS256"]` | a token claiming `none`, or an algorithm the key was not made for |
| `iss` is exactly this issuer | `issuer=ISSUER` | a token from another authorization server |
| `aud` is this client | `audience=audience` | a token made out to somebody else |
| `exp` has not passed | `jwt.decode`, always | a token kept and used later |
| `nonce` is the one this client sent | the last `if` | an ID token from an earlier sign-in, replayed into this one |

Save it as `~/shelf/check_token.py` and give it the ID token from the flow, the client's own name,
and the nonce the client made. **The token lasts 300 seconds**: if PyJWT says the signature has
expired, run the flow again.

```
ana@api:~/shelf$ python3 check_token.py "$IDT" shelf-web "$NONCE"
{
  "iss": "http://localhost:8000",
  "iat": 1791606661,
  "exp": 1791606961,
  "aud": "shelf-web",
  "sub": "u-81f3a2",
  "nonce": "a8bf7ebd4136e3bc"
}
```

The same token with a different nonce is what a replayed ID token looks like, and it is refused:

```
ana@api:~/shelf$ python3 check_token.py "$IDT" shelf-web 0123456789abcdef
refused: the nonce is not the one this client sent
```

## The confusion, refused

Give the access token to the same check, as a client that confuses the two would:

```
ana@api:~/shelf$ python3 check_token.py "$AT" shelf-web
refused: Audience doesn't match
```

**The audience is the whole difference.** Checked as what it is, a token for the API, it passes,
and its claims show a scope where the ID token had a nonce:

```
ana@api:~/shelf$ python3 check_token.py "$AT" shelf-api
{
  "iss": "http://localhost:8000",
  "iat": 1791606661,
  "exp": 1791606961,
  "aud": "shelf-api",
  "sub": "u-81f3a2",
  "client_id": "shelf-web",
  "scope": "books:read openid profile",
  "jti": "dfdea3d2aac4fe7a"
}
```

The confusion runs the other way too, and the API refuses it for the same reason. An ID token is
made out to the client, so an API that checks the audience will not accept it as an access token:

```
ana@api:~/shelf$ curl -s localhost:8000/userinfo -H "Authorization: Bearer $IDT"
{"error": "invalid_token", "error_description": "Audience doesn't match"}
```

`/userinfo` is the third piece OpenID Connect adds: an endpoint on the authorization server that
takes an access token with `openid` in its scope and returns what the scope allows about the
person, as you saw in the section on scopes. The ID token says who signed in; `/userinfo` says more
about them when the client needs it.
