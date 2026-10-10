---
title: Assinar e verificar
version: 1
---

O terceiro pedaço de um JWT é calculado, não escolhido. No HS256 ele é o **HMAC-SHA256** do texto
`header.payload`, exatamente como aparece no token, com o ponto entre os dois, feito com a chave do
servidor e escrito em base64url. Verificar é calcular de novo e comparar. Mude um byte do cabeçalho
ou do payload e os dois deixam de bater, e uma assinatura que bata com um conteúdo novo precisa da
chave.

Então uma assinatura responde duas perguntas de uma vez: isto foi alterado desde que foi assinado, e
foi assinado por alguém que tem a chave. Ela não responde se o token ainda deve ser aceito. Esse é o
trabalho das claims, na próxima seção.

## Fazendo à mão

O PyJWT faz a conta dentro do `jwt.decode`. Não há nada de especial nela, e o módulo `hmac` do Python
a faz em poucas linhas. Salve isto como `hs256.py`:

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

Ele lê a chave do `jwt.key`, então rode-o em `~/shelf`. Passe o token de acesso:

```
ana@api:~/shelf$ python3 hs256.py "$(jq -r .access_token login.json)"
in the token: 6htCZVCQFrI9WiAkcaMaskVDcb9mPSuA6V_RF0cmR2M
recomputed:   6htCZVCQFrI9WiAkcaMaskVDcb9mPSuA6V_RF0cmR2M
they match
```

**A assinatura não é segredo.** Ela viaja no token para qualquer um ver, e vê-la não ajuda: o HMAC é
feito de modo que nenhuma quantidade de assinaturas revele a chave. O que precisa ficar em segredo
são os 32 bytes do `jwt.key`.

## Mudando um caractere

O payload começa com os nove bytes `{"sub":"1`, que o base64 escreve como `eyJzdWIiOiIx`. Com um `2`
no lugar do `1` eles viram `eyJzdWIiOiIy`: uma letra de diferença. O `sed` faz a troca, e o token
agora diz ser do usuário 2, bruno:

```
ana@api:~/shelf$ jq -r .access_token login.json | sed 's/\.eyJzdWIiOiIx/.eyJzdWIiOiIy/' > edited.txt
ana@api:~/shelf$ cut -d. -f2 edited.txt | sed 's/$/=/' | basenc --base64url -d; echo
{"sub":"2","iss":"shelf","aud":"shelf-api","iat":1791606667,"nbf":1791606667,"exp":1791606967,"jti":"1902a1acaa43b316"}
```

A assinatura ficou como estava, já que fazer uma nova exige a chave. Ela não bate mais:

```
ana@api:~/shelf$ python3 hs256.py "$(cat edited.txt)"
in the token: 6htCZVCQFrI9WiAkcaMaskVDcb9mPSuA6V_RF0cmR2M
recomputed:   SgS9eJ4tv8huF_u0HbO8xxyrc2EXxCHdgSJtyHIcyYY
they differ
```

E a API recusa o token. O corpo diz qual verificação falhou, e **o código de status é o mesmo 401 que
um token ausente recebe**, porque a única resposta útil do cliente a qualquer um dos dois é entrar de
novo.

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

A comparação no fim do `hs256.py` usa `hmac.compare_digest` em vez de `==`. Uma comparação comum de
strings para na primeira diferença, então o tempo que leva revela quantos caracteres iniciais
estavam certos. O `compare_digest` leva o mesmo tempo seja qual for a entrada, e as verificações de
senha e de CSRF do `sessions.py` também o usam.

## Uma chave, ou duas

O HS256 é **simétrico**: a chave que assina é a chave que verifica. Isso é simples quando um programa
só faz as duas coisas, como o `tokens.py`. Deixa de ser simples quando dez serviços verificam tokens,
porque cada um deles passa a ter uma chave que também **emite** tokens, e um vazamento de qualquer um
deixa quem o leu entrar como qualquer pessoa em todos.

Os algoritmos assimétricos, `RS256` com RSA e `ES256` com curvas elípticas, separam as duas tarefas.
Uma chave privada assina e fica com o emissor; uma chave pública verifica e pode ser dada a todos os
serviços, ou publicada. Um serviço que verifica deixa de conseguir emitir. A aula 9 encontra esse
arranjo no OpenID Connect, em que um provedor de identidade publica as chaves públicas que conferem
os tokens dele.
