---
title: O 422 e o formato de um erro de validação
version: 1
---

Um corpo que falha na validação recebe um **422 Unprocessable Content**, onde o DRF respondia 400. Os
dois são defensáveis: 400 diz que a requisição estava ruim, 422 diz que era JSON bem formado cujo
conteúdo não pôde ser processado. O que importa mais é que o corpo tem sempre o mesmo formato, e assim
um cliente trata todos eles com um pedaço de código só:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"\", \"email\": \"not-an-address\"}" http://127.0.0.1:8001/events/testing-dojo/registrations | python3 -m json.tool
{
    "detail": [
        {
            "type": "string_too_short",
            "loc": [
                "body",
                "name"
            ],
            "msg": "String should have at least 1 character",
            "input": "",
            "ctx": {
                "min_length": 1
            }
        },
        {
            "type": "value_error",
            "loc": [
                "body",
                "email"
            ],
            "msg": "value is not a valid email address: An email address must have an @-sign.",
            "input": "not-an-address",
            "ctx": {
                "reason": "An email address must have an @-sign."
            }
        }
    ]
}
```

Todo erro da lista tem as mesmas chaves:

| chave | o que guarda |
|---|---|
| `type` | um código estável, `string_too_short`, `value_error`, para um programa testar |
| `loc` | onde: `"body"`, `"query"` ou `"path"`, depois o campo |
| `msg` | uma frase para uma pessoa |
| `input` | o valor que foi recusado |
| `ctx` | os números da própria regra, como `min_length` |

## JSON quebrado, regras quebradas

JSON quebrado também é 422, com a posição onde o parser desistiu:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\"" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/testing-dojo/registrations
{"detail":[{"type":"json_invalid","loc":["body",16],"msg":"JSON decode error","input":{},"ctx":{"error":"Expecting ',' delimiter"}}]}
422
```

E criar um evento com dois campos ruins lista os dois, aqui reduzidos ao tipo e à mensagem:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"slug\": \"Bad Slug\", \"title\": \"x\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"x\", \"capacity\": 0}" http://127.0.0.1:8001/events | python3 -m json.tool | grep -E "\"(type|msg)\""
            "type": "string_pattern_mismatch",
            "msg": "String should match pattern '^[a-z0-9-]+$'",
            "type": "greater_than_equal",
            "msg": "Input should be greater than or equal to 1",
```

## Quando 422 é a resposta errada

Erros de validação são sobre o **formato** dos dados. Uma requisição cujos dados estão certos mas cujo
efeito o estado atual recusa, um slug que já existe, um evento cheio, não é 422: é o 409 da próxima
seção. Manter os dois separados deixa um cliente distinguir "corrija sua entrada" de "o mundo mudou",
que pedem telas diferentes.
