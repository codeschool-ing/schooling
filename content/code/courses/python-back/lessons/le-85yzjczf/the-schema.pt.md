---
title: O esquema que o FastAPI escreve a partir do seu código
version: 1
---

A aula 1 reparou que o endpoint hello publicava `/openapi.json` sem ninguém escrevê-lo. Esse documento
é uma descrição **OpenAPI** da API: um formato padrão, JSON ou YAML, que lista todo caminho, método,
parâmetro e corpo, com o formato de cada requisição e resposta. O FastAPI o monta a partir das rotas,
das anotações de tipo e dos modelos Pydantic, então ele é exatamente tão atual quanto o código.

Esta aula muda o `app/main.py` e acrescenta o `app/dependencies.py`; os dois estão na seção sobre
dependências, e com eles salvos o esquema começa assim:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | head -c 300; echo
{"openapi":"3.1.0","info":{"title":"agenda API","description":"Community events with a limited number of seats.","version":"0.2.0"},"paths":{"/events":{"get":{"tags":["events"],"summary":"List Events","description":"Events in date order, optionally only those at one venue.","operationId":"list_event
```

O `title`, a `description` e a `version` são os argumentos do `FastAPI(...)`. Todo caminho, com os
métodos:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; d = json.load(sys.stdin); [print(m.upper().ljust(5), p) for p, ops in d["paths"].items() for m in ops]'
GET   /events
POST  /events
GET   /events/{slug}
POST  /events/{slug}/registrations
GET   /events/{slug}/registrations
```

E todo formato que a API manda ou aceita, sob `components`:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; print(list(json.load(sys.stdin)["components"]["schemas"]))'
['EventIn', 'EventOut', 'HTTPValidationError', 'RegistrationIn', 'RegistrationOut', 'RegistrationPublic', 'ValidationError']
```

Cinco são modelos desta API. **`HTTPValidationError` e `ValidationError` são do FastAPI**: o corpo do
422 da aula 7, documentado para toda rota que valida algo, para um cliente saber o formato do erro
antes de receber um. Um modelo, inteiro:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; print(json.dumps(json.load(sys.stdin)["components"]["schemas"]["RegistrationIn"], indent=2))'
{
  "properties": {
    "name": {
      "type": "string",
      "maxLength": 100,
      "minLength": 1,
      "title": "Name"
    },
    "email": {
      "type": "string",
      "format": "email",
      "title": "Email"
    }
  },
  "type": "object",
  "required": [
    "name",
    "email"
  ],
  "title": "RegistrationIn"
}
```

As restrições de `Field` da aula 7 viraram palavras-chave do **JSON Schema**, `minLength` e
`maxLength`, e o `EmailStr` virou `"format": "email"`. O JSON Schema é um padrão próprio, e existem
validadores dele em toda linguagem, o que torna o documento útil fora do Python.

## Para que serve um esquema

| quem | o que faz com ele |
|---|---|
| pessoas | o leem por uma página de documentação, a próxima seção |
| outras equipes | **geram um cliente** em TypeScript, Kotlin ou Go em vez de escrever um à mão |
| testes e gateways | conferem que requisições e respostas batem com ele |
| você | **o revisa num pull request**: mudar o esquema é mudar o contrato |

A última linha é a que as equipes esquecem. Um campo renomeado num modelo é uma diferença de uma linha
no Python e uma quebra para todo cliente, e comparar o `/openapi.json` de antes e de depois é como isso
é percebido. O DRF do Django não escreve esse documento sozinho; bibliotecas como o
`drf-spectacular` o geram a partir dos serializers.
