---
title: Descrever a API para as páginas valerem a leitura
version: 1
---

Um esquema gerado do código é preciso, e por padrão também é seco: um resumo derivado do nome da
função, `List Events`, e nada sobre o porquê. As rotas do `app/main.py` desta aula levam um pouco mais,
e cada peça cai num lugar específico:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; op = json.load(sys.stdin)["paths"]["/events/{slug}/registrations"]["post"]; print(op["tags"], op["summary"]); print(sorted(op["responses"])); print(op["responses"]["409"])'
['registrations'] Register for an event
['201', '409', '422']
{'description': 'The event is full, or the address is already registered'}
```

As **`tags`** agrupam operações na página de documentação, o **`summary`** troca o título derivado do
nome da função, e o **`responses`** documenta o 409, que o FastAPI não teria como achar lendo o código:
ele só vê o `status_code=201` e o 422 que a validação pode produzir. A lista de eventos mostra a
docstring e os parâmetros, incluindo os dois que vieram de uma dependência:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; op = json.load(sys.stdin)["paths"]["/events"]["get"]; print(op["summary"], "|", op["description"]); [print(p["name"], p["in"], p["schema"]) for p in op["parameters"]]'
List Events | Events in date order, optionally only those at one venue.
venue query {'anyOf': [{'type': 'string'}, {'type': 'null'}], 'title': 'Venue'}
limit query {'type': 'integer', 'maximum': 100, 'minimum': 1, 'default': 20, 'title': 'Limit'}
offset query {'type': 'integer', 'minimum': 0, 'default': 0, 'title': 'Offset'}
```

O `venue` é opcional, o `limit` tem faixa e padrão, o `offset` tem mínimo, tudo das assinaturas. **Uma
docstring é documentação que mora onde o código muda**, e esse é o melhor argumento para escrever uma
em toda rota.

## O que não pôr nela

Descrições são publicadas. Nomes de host internos, os nomes das tabelas do banco, o motivo de negócio
de um campo existir, uma nota sobre um bug: nada disso pertence a um documento que todo cliente e
qualquer pessoa com a URL podem ler. Descreva o contrato, o que mandar e o que volta, e deixe a
implementação nos comentários.
