---
title: Códigos de status
version: 1
---

**O código de status é a parte da resposta que um programa lê primeiro, e muitas vezes a única.** Um
cliente escrito contra a sua API decide por ele: repetir, mostrar um erro, pedir login, seguir em frente.
Um código errado é, portanto, um defeito no contrato mesmo quando o corpo explica tudo perfeitamente,
porque o código de ninguém lê o corpo para decidir.

O primeiro dígito é a classe, e só a classe já diz a um cliente quase tudo de que ele precisa:

| classe | significado | o que o cliente deve fazer |
|---|---|---|
| `2xx` | deu certo | seguir em frente |
| `3xx` | está em outro lugar | seguir o `Location` |
| `4xx` | **a requisição está errada** | corrigir a requisição; enviá-la de novo sem mudar vai falhar de novo |
| `5xx` | **o servidor falhou** | a requisição pode estar certa; tentar mais tarde pode funcionar |

A linha entre 4xx e 5xx é a que mais importa, e a que mais se traça errado. Um servidor que responde 500
a um corpo malformado manda todo cliente repetir uma requisição que nunca vai dar certo; um que responde
400 quando o banco caiu manda parar de enviar uma requisição que estava certa.

## Os códigos que o shelf usa

Sete falhas, cada uma com o código que o shelf escolheu. A primeira é um corpo que não diz ser JSON: o
`-d` do curl envia um formulário, a não ser que alguém diga o contrário. As duas seguintes são corpos
que dizem ser JSON e não são, ou são JSON mas não um objeto:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -d 'title=Quincas Borba'
{"error": "send the book as application/json"}
415
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"title": '
{"error": "the body is not valid JSON"}
400
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '["Quincas Borba"]'
{"error": "the body must be a JSON object"}
400
```

**415 Unsupported Media Type** é sobre o rótulo, **400 Bad Request** é sobre os bytes. As quatro
seguintes são requisições bem formadas que mesmo assim não podem ser aceitas: um campo que a API não
tem, um preço enviado como texto, um estoque negativo e um autor que não existe. As duas últimas foram
pegas pelo banco, pelo `CHECK` e pela chave estrangeira do `db.py`, e o `rest.py` transformou a
reclamação do banco no mesmo código que as próprias verificações dele dão:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"colour": "red"}'
{"error": "unknown fields: colour"}
422
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"price_cents": "39.90"}'
{"error": "wrong type for: price_cents"}
422
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"stock": -1}'
{"error": "rejected: CHECK constraint failed: stock >= 0"}
422
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"author_id": 99}'
{"error": "rejected: FOREIGN KEY constraint failed"}
422
```

**422 Unprocessable Content** diz "entendi você, e o conteúdo quebra uma regra". Algumas APIs respondem
400 para tudo isso, e é uma escolha defensável se for feita em todo lugar; o que não se defende é a
mistura, em que o mesmo erro recebe 400 de um endpoint e 422 de outro.

Junto com o que as seções anteriores mostraram, essa é a lista inteira de que o shelf precisa:

| código | nome | no shelf |
|---|---|---|
| 200 | OK | uma leitura, ou uma substituição ou mudança que deu certo |
| 201 | Created | um livro novo, com o `Location` dele |
| 204 | No Content | uma remoção que deu certo |
| 400 | Bad Request | o corpo não é JSON, ou não é um objeto |
| 404 | Not Found | não existe esse endereço, ou esse livro |
| 405 | Method Not Allowed | o endereço existe e não aceita aquele método; `Allow` lista os que aceita |
| 409 | Conflict | a requisição choca com algo que existe: um segundo livro com o mesmo ISBN |
| 415 | Unsupported Media Type | o corpo não está rotulado como `application/json` |
| 422 | Unprocessable Content | o JSON está certo e o conteúdo dele quebra uma regra |

Mais três pertencem a aulas futuras e vale reconhecê-los agora. **401 Unauthorized** quer dizer "não sei
quem você é" e **403 Forbidden** quer dizer "sei quem você é, e não"; as aulas 7 e 11 tratam da
diferença. **429 Too Many Requests** é a aula 12.

## Um código que você não escolheu

O shelf não define o método `OPTIONS`, então a biblioteca do Python respondeu por ele:

```
ana@api:~/shelf$ curl -si -X OPTIONS localhost:8000/v1/books
HTTP/1.1 501 Unsupported method ('OPTIONS')
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:53 GMT
Connection: close
Content-Type: text/html;charset=utf-8
Content-Length: 360

<!DOCTYPE HTML>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Error response</title>
    </head>
    <body>
        <h1>Error response</h1>
        <p>Error code: 501</p>
        <p>Message: Unsupported method ('OPTIONS').</p>
        <p>Error code explanation: 501 - Server does not support this operation.</p>
    </body>
</html>
```

Há três coisas erradas aí, e nenhuma é culpa do Python. **501 Not Implemented** existe para um método
que o servidor nem reconhece, enquanto `OPTIONS` é um método padrão que este endereço simplesmente não
aceita, e para isso existe o 405. O corpo é uma página HTML numa API em que todas as outras respostas
são JSON. E o cabeçalho `Server` entrega a versão exata do Python a quem perguntar, assunto a que a aula
13 volta. **Todo código que a sua API envia faz parte do contrato dela, inclusive os que uma biblioteca
envia em seu nome.** A aula 13 também volta ao `OPTIONS`, porque os navegadores o enviam antes de uma
requisição entre origens e esperam uma resposta de verdade.
