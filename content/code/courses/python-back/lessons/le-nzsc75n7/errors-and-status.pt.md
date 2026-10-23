---
title: Os erros que você levanta, e os códigos de status que eles levam
version: 1
---

A validação responde sozinha. Toda outra recusa é levantada pelo seu código, com `HTTPException`, e o
código sobre o qual um cliente age é o status. Criar um evento, e depois criá-lo de novo:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"slug\": \"pycon-watch\", \"title\": \"PyCon talks, watched together\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"Public Library, lab 2\", \"capacity\": 15}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events
{"slug":"pycon-watch","title":"PyCon talks, watched together","starts_at":"2026-12-03T19:00:00-03:00","venue":"Public Library, lab 2","capacity":15,"description":"","taken":0}
201
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"slug\": \"pycon-watch\", \"title\": \"Again\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"x\", \"capacity\": 15}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events
{"detail":"pycon-watch already exists"}
409
```

**201, depois 409** com a mensagem que a rota escreveu. O `status.HTTP_409_CONFLICT` e as outras
constantes de `fastapi.status` são os números com nome, o que deixa uma rota legível sem uma tabela de
códigos ao lado.

## Um método que ninguém declarou

```
ana@vm:~/agenda-api$ curl -si -X DELETE http://127.0.0.1:8001/events/pycon-watch | grep -iE "^(HTTP|allow)"
HTTP/1.1 405 Method Not Allowed
allow: GET
```

Não há rota `DELETE` para um evento, e o FastAPI respondeu **405 com um cabeçalho `allow`** listando os
métodos que o caminho tem, como o `require_GET` do Django fez na aula 2.

## Os códigos que esta API usa

| código | quando | quem levanta |
|---|---|---|
| 200 | uma leitura | o padrão |
| 201 | algo foi criado | `status_code=` na rota |
| 404 | o evento não existe | `find_event` |
| 405 | o método não tem rota | o FastAPI |
| 409 | a requisição está certa e o estado a recusa | a rota, com `HTTPException` |
| 422 | os dados não cabem no modelo | o Pydantic, antes de a rota rodar |

**Não responda 200 com `{"error": …}` no corpo.** É o erro que APIs mais cometem, e ele obriga todo
cliente a ler toda resposta para descobrir se ela falhou. A linha de status existe para que um cliente,
um proxy e uma linha de log consigam distinguir sucesso de falha sem ler um byte do corpo.
