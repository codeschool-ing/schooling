---
title: Códigos de status, lidos como quem testa os lê
version: 1
---

**Um código de status são três dígitos, e só o primeiro já diz quem deve agir.** Existem dezenas de
códigos e ninguém decora todos. O que quem testa precisa é do primeiro dígito, de uma dúzia de
códigos que aparecem toda semana e do hábito de perguntar se o código que um servidor escolheu era o
certo.

| classe | significa | quem deve agir |
|---|---|---|
| `2xx` | funcionou | ninguém |
| `3xx` | procure em outro lugar, ou use o que você tem | o cliente, seguindo um redirecionamento ou o próprio cache |
| `4xx` | a requisição está errada | o cliente: mandar a mesma requisição de novo vai falhar de novo |
| `5xx` | o servidor falhou | o servidor; a mesma requisição pode funcionar mais tarde |

A linha entre `4xx` e `5xx` é a que mais importa. Um `4xx` culpa a requisição e um `5xx` culpa o
servidor, então **um servidor que responde `500` a uma requisição malformada tem dois defeitos**:
quebrou com uma entrada ruim e disse ao cliente para tentar de novo quando tentar de novo não pode
ajudar.

## Fazendo o boxoffice dizer cada um

O curl sabe imprimir só o código, que é a cara de uma verificação rápida. `-o /dev/null` joga o corpo
fora e `-w '%{http_code}\n'` escreve o código de status e uma quebra de linha:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/shows
200
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/shows/sh-999
404
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/orders
401
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT localhost:8080/v1/shows
405
```

`200` para a lista, `404` para um espetáculo que não existe, `401` para pedidos sem token, e `405`
para um método que a lista não aceita. Pedidos exigem um token, uma chave que diz qual programa está
pedindo. A lição 3 explica tokens; por ora, esta linha pede um ao boxoffice e o guarda numa variável
chamada `TOKEN`:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

Com ele, um pedido de três lugares da sessão pequena é aceito:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":3}'
HTTP/1.1 201 Created
content-type: application/json
location: ]8;;http://localhost:8080/v1/orders/ord-1001\/v1/orders/ord-1001
]8;;\Date: Sat, 10 Oct 2026 07:13:50 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"id":"ord-1001","show_id":"sh-103","seats":3,"total_cents":19500,"status":"confirmed","payment":"ch-local-ord-1001"}
```

`201 Created` em vez de `200`, porque agora existe algo novo, e o cabeçalho `location` diz onde ele
mora. A mesma requisição de novo encontra um lugar sobrando, e depois vêm as requisições com erros,
uma por linha:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}'
{"type":"about:blank","title":"Conflict","status":409,"detail":"only 1 seat left"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":0}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103"'
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body is not valid JSON"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -d 'show_id=sh-103&seats=2'
{"type":"about:blank","title":"Unsupported Media Type","status":415,"detail":"send the order as application/json"}
```

Quatro requisições, quatro códigos diferentes, e cada um é uma afirmação que um teste pode conferir:

| código | está aqui porque | o cliente deveria |
|---|---|---|
| `409 Conflict` | a requisição está boa, mas o estado do servidor a impede: 1 lugar sobrando, 2 pedidos | pedir menos, ou escolher outra sessão |
| `422 Unprocessable Content` | o JSON é válido e o conteúdo fere uma regra: 0 lugares | corrigir o valor |
| `400 Bad Request` | o corpo nem é JSON; falta o `}` do fim | corrigir a sintaxe |
| `415 Unsupported Media Type` | o corpo é um formulário, não JSON | mandar JSON, rotulado como JSON |

O boxoffice dá ao `422` o título *Unprocessable Entity*, o nome que o Node usa; a RFC 9110 o rebatizou
de *Unprocessable Content* em 2022. O número é o que um cliente lê, e ele não mudou.

Essas distinções não são preciosismo. Um cliente que recebe `409` pode dizer ao usuário *"só resta 1
lugar"*; um que recebe `400` para a mesma situação não tem nada útil a dizer. **Escolher o código
certo faz parte do contrato da API**, e a lição 2 diz o que é um contrato.

## Os códigos que aparecem toda semana

| código | significado | onde você vai encontrá-lo |
|---|---|---|
| `200` OK | aqui está o que você pediu | a maioria dos GETs |
| `201` Created | existe algo novo, em `location` | um POST que criou |
| `204` No Content | feito, e nada a devolver | um DELETE |
| `304` Not Modified | o que você já tem continua valendo | seção 09 |
| `400` Bad Request | não dá para ler a requisição | JSON malformado |
| `401` Unauthorized | quem é você? nenhuma credencial válida | lição 3 |
| `403` Forbidden | sei quem você é, e você não pode | lição 3 |
| `404` Not Found | nada naquele endereço | um id errado |
| `405` Method Not Allowed | esse verbo não é aceito aqui | seção 07 |
| `409` Conflict | o estado do servidor impede | esgotado |
| `422` Unprocessable Content | legível, e fere uma regra | 0 lugares |
| `429` Too Many Requests | vá mais devagar | lição 13 |
| `500` Internal Server Error | o servidor quebrou | nunca de propósito |
| `502` / `504` | um servidor atrás deste falhou ou não respondeu | lição 13 |
| `503` Service Unavailable | agora não, tente depois | lição 13 |

O `401` se chama *Unauthorized* e significa *não autenticado*: o servidor não sabe quem você é. O
`403` significa que ele sabe, e a resposta é não. Os nomes são um acidente histórico com que todo
mundo convive, e a lição 3 testa a diferença.
