---
title: As claims, e as verificações que uma API precisa fazer
version: 1
---

Uma assinatura válida diz que o token é o que o servidor emitiu. Não diz nada sobre se ele ainda
deve ser aceito, aqui, agora, por esta API. **Isso é decidido pelas claims, e só se o servidor as
conferir.** Uma biblioteca verifica o que mandam verificar, e um argumento esquecido é uma
verificação que, em silêncio, não acontece.

O padrão JWT dá nome a sete claims, e o `tokens.py` põe todas:

| claim | quer dizer | no `tokens.py` | se ninguém a confere |
|---|---|---|---|
| `sub` | sujeito: de quem é o token | o id do usuário, como string | o servidor não sabe de quem é a requisição |
| `exp` | vencimento, em segundos desde 1970 | 300 segundos depois da emissão | um token copiado uma vez funciona para sempre |
| `iat` | emitido em | o momento do login | não há como saber a idade de um token |
| `nbf` | não vale antes de | o mesmo momento | um token feito para depois funciona hoje |
| `iss` | emissor: quem fez o token | `shelf` | passa um token que outro sistema assinou com uma chave compartilhada |
| `aud` | audiência: para quem ele se destina | `shelf-api` | um token de uma API é aceito por outra |
| `jti` | o id do próprio token | 16 dígitos hexadecimais aleatórios | um token não se distingue de outro, então não dá para revogar só ele |

Os horários são números simples. O `date` transforma o `exp` do token de acesso numa hora de relógio:

```
ana@api:~/shelf$ date -d @$(jq -r .access_token login.json | cut -d. -f2 | sed 's/$/=/' | basenc --base64url -d | jq .exp)
Sat Oct 10 01:36:07 -03 2026
```

## Tolerância

Duas máquinas nunca concordam sobre a hora até o segundo. Um token emitido por um servidor e
conferido por outro cujo relógio está um pouco adiantado seria recusado instantes antes da hora, por
isso o `verify` passa `leeway=30`: trinta segundos de folga no `exp` e no `nbf`. O `tokens.py` pode
ser importado, então o `tokens.issue` faz um token como se o login tivesse acontecido alguns
segundos antes. Um emitido há 310 segundos venceu há 10 segundos, dentro da folga:

```
ana@api:~/shelf$ python3 -c 'import tokens, time; print(tokens.issue(1, now=time.time() - 310))' > late.txt
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(cat late.txt)"
{"name": "ana", "exp": 1791606658, "jti": "09a2d6adea537e80"}
```

Um emitido há 600 segundos venceu há 300 segundos, e é recusado:

```
ana@api:~/shelf$ python3 -c 'import tokens, time; print(tokens.issue(1, now=time.time() - 600))' > old.txt
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(cat old.txt)"
{"error": "Signature has expired"}
```

O PyJWT chama isso de assinatura vencida; a assinatura está ótima, e quem venceu foi o token. Uma
tolerância de segundos absorve a deriva dos relógios. Uma tolerância de horas transforma um token de
cinco minutos num token longo.

## A audiência

Outro serviço que tenha a mesma chave, uma API administrativa digamos, deve recusar um token feito
para a loja. É para isso que serve o `aud`: conferido contra `shelf-admin`, o token de ana falha,
embora a assinatura esteja perfeita.

```
ana@api:~/shelf$ python3 -c 'import json, jwt, tokens; t = json.load(open("login.json"))["access_token"]; jwt.decode(t, tokens.KEY, algorithms=["HS256"], audience="shelf-admin")' 2>&1 | tail -1
jwt.exceptions.InvalidAudienceError: Audience doesn't match
```

**O PyJWT confere `exp`, `nbf` e `iat` só quando o token os contém, e `iss` só quando quem chama
informa um emissor.** Um token sem `exp` nunca venceria. Por isso o `verify` lista as sete em
`options={"require": [...]}`: um token sem alguma delas é recusado em vez de passar.

## O algoritmo é escolha do servidor

O cabeçalho diz `"alg": "HS256"`, e o cabeçalho é escrito por quem fez o token. Se um servidor lesse
o algoritmo do cabeçalho e usasse o que ele dissesse, seria o token escolhendo como vai ser
conferido. O padrão inclui um valor, `none`, que quer dizer nenhuma assinatura, e o PyJWT produz um
token assim:

```
ana@api:~/shelf$ python3 -c 'import jwt; print(jwt.encode({"sub": "1", "iss": "shelf", "aud": "shelf-api"}, None, algorithm="none"))' > none.txt
ana@api:~/shelf$ cat none.txt
eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiIxIiwiaXNzIjoic2hlbGYiLCJhdWQiOiJzaGVsZi1hcGkifQ.
```

O terceiro pedaço está vazio. Mandado à API, ele é recusado antes de qualquer claim ser lida, porque
o `verify` passa `algorithms=["HS256"]` e `none` não está na lista:

```
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(cat none.txt)"
{"error": "The specified alg value is not allowed"}
```

O PyJWT 2.7 vai além e nem decodifica se quem chama não disser quais algoritmos aceita:

```
ana@api:~/shelf$ python3 -c 'import jwt; jwt.decode(open("none.txt").read().strip())' 2>&1 | tail -1
jwt.exceptions.DecodeError: It is required that you pass in a value for the "algorithms" argument when calling decode().
```

**Fixe o algoritmo, num lugar só, naquele para o qual suas chaves existem.** A mesma regra cobre o
erro mais sutil de um servidor que aceita `HS256` e `RS256` e deixa o cabeçalho escolher, de modo que
uma chave pública, que não é segredo, acaba usada como chave de HMAC. Um servidor que nomeia
exatamente um algoritmo não tem nenhum dos dois problemas.
