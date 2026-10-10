---
title: "OpenID Connect: quem entrou"
version: 1
---

**O OAuth responde "este app pode fazer isto?" e nunca "quem é esta pessoa?"** A ideia errada que
vem daí é comum: um app recebe um access token,
chama uma API que devolve um id de usuário e trata a pessoa como autenticada. O access token nunca
foi feito para o app. A audiência dele é a API, e o app não tem como saber se um token entregue a
ele foi emitido para ele ou para outro app qualquer que obteve um para a mesma pessoa. Um app que
autentica pessoas com qualquer access token que receba vai autenticar qualquer um que traga um.

**O OpenID Connect é uma camada sobre o OAuth 2.0 que acrescenta a resposta.** Foi publicado pela
OpenID Foundation em 2014, e é o que um botão "Entrar com…" fala hoje. O cliente pede o escopo
`openid`, o fluxo é o mesmo fluxo de código, e a resposta de token ganha um **ID token**: um JWT
emitido para o cliente, dizendo quem entrou, onde e quando.

| | access token | ID token |
|---|---|---|
| emitido para (`aud`) | a API: `shelf-api` | o cliente: `shelf-web` |
| lido por | a API | o cliente, que o confere e então autentica a pessoa |
| diz | o que o portador pode fazer (`scope`) | quem entrou (`sub`), em qual entrada (`nonce`) |
| enviado a uma API | sim, como `Authorization: Bearer` | nunca |
| formato | o que o servidor de autorização quiser; muitas vezes um JWT, às vezes opaco | sempre um JWT |

## Achando as chaves

Um cliente precisa conferir a assinatura do ID token, então precisa da chave pública do servidor de
autorização, e o OpenID Connect a publica em dois passos. O **discovery** é um documento num
endereço fixo abaixo do emissor, `/.well-known/openid-configuration`, que lista todo endpoint e o
que o servidor suporta:

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

O `jwks_uri` nele aponta para o **JWKS**, o JSON Web Key Set: as chaves públicas, cada uma com o
`kid` que um token cita no cabeçalho. Um servidor que troca de chave lista duas por um tempo, e o
`kid` diz qual assinou um dado token. O seu tem uma, e o `kid` dela é o id que o servidor imprimiu
ao iniciar:

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

## Conferindo um ID token

O `check_token.py` faz o que um cliente precisa fazer antes de acreditar num ID token. Ele lê o
documento de discovery, busca a chave que o `kid` do token cita e deixa o PyJWT conferir o resto:

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

As seis conferências, e o que cada uma impede:

| conferência | no `check_token.py` | o que impede |
|---|---|---|
| a assinatura, com a chave que o `kid` cita | `get_signing_key_from_jwt`, depois `jwt.decode` | um token que qualquer um escreveu |
| o algoritmo é o esperado | `algorithms=["RS256"]` | um token que diz `none`, ou um algoritmo para o qual a chave não foi feita |
| `iss` é exatamente este emissor | `issuer=ISSUER` | um token de outro servidor de autorização |
| `aud` é este cliente | `audience=audience` | um token emitido para outro |
| `exp` não passou | `jwt.decode`, sempre | um token guardado e usado depois |
| `nonce` é o que este cliente enviou | o último `if` | um ID token de uma entrada anterior, reaproveitado nesta |

Salve-o como `~/shelf/check_token.py` e passe a ele o ID token do fluxo, o nome do próprio cliente e
o nonce que o cliente gerou. **O token dura 300 segundos**: se o PyJWT disser que a assinatura
expirou, rode o fluxo de novo.

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

O mesmo token com outro nonce é a cara de um ID token reaproveitado, e é recusado:

```
ana@api:~/shelf$ python3 check_token.py "$IDT" shelf-web 0123456789abcdef
refused: the nonce is not the one this client sent
```

## A confusão, recusada

Passe o access token para a mesma conferência, como faria um cliente que confunde os dois:

```
ana@api:~/shelf$ python3 check_token.py "$AT" shelf-web
refused: Audience doesn't match
```

**A audiência é toda a diferença.** Conferido como o que ele é, um token para a API, ele passa, e as
claims dele mostram um escopo onde o ID token tinha um nonce:

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

A confusão também vai no outro sentido, e a API a recusa pelo mesmo motivo. Um ID token é emitido
para o cliente, então uma API que confere a audiência não o aceita como access token:

```
ana@api:~/shelf$ curl -s localhost:8000/userinfo -H "Authorization: Bearer $IDT"
{"error": "invalid_token", "error_description": "Audience doesn't match"}
```

O `/userinfo` é a terceira peça que o OpenID Connect acrescenta: um endpoint no servidor de
autorização que recebe um access token com `openid` no escopo e devolve o que o escopo permite
sobre a pessoa, como você viu na seção sobre escopos. O ID token diz quem entrou; o `/userinfo` diz
mais sobre ela quando o cliente precisa.
