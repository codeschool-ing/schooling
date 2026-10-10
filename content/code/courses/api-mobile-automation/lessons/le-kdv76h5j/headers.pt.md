---
title: Os cabeçalhos que valem a leitura
version: 1
---

**Cabeçalhos são os metadados de uma mensagem: o que é o corpo, por quanto tempo continua valendo,
quem está pedindo.** Uma resposta traz um punhado deles e a maioria é rotina. Quem testa lê os que
mudam como o corpo é entendido, porque um cabeçalho errado torna inútil um corpo certo.

Nomes de cabeçalho não diferenciam maiúsculas: `Content-Type`, `content-type` e `CONTENT-TYPE` são o
mesmo cabeçalho. O boxoffice os escreve em minúsculas, que é o que o Node faz e o que o HTTP/2 exige,
e as requisições do próprio curl os escrevem com inicial maiúscula. Um teste que compara nomes de
cabeçalho letra por letra é um teste com um defeito próprio.

## Os que quem testa lê

| cabeçalho | em | diz | o que conferir |
|---|---|---|---|
| `content-type` | ambos | o que é o corpo: `application/json`, `application/problem+json` | que bate com o corpo, nos erros também |
| `location` | resposta | onde mora algo novo | que está lá num `201`, e que um GET nele funciona |
| `allow` | resposta | os métodos que um endereço aceita | que está lá num `405`, e é verdade |
| `www-authenticate` | resposta | como se autenticar, e por que falhou | que está lá num `401` (lição 3) |
| `cache-control` | resposta | por quanto tempo uma cópia pode ser reaproveitada | que respostas privadas não vão para cache |
| `etag` | resposta | uma impressão digital desta versão da coisa | que muda quando a coisa muda |
| `authorization` | requisição | as credenciais do cliente | que nunca aparece num log (lição 3) |

Volte ao pedido da seção 08 e três deles já estão lá: `location` no `201`, `allow` no `405` e
`content-type` em toda resposta, inclusive nos erros, que dizem `application/problem+json`. Esse
rótulo nomeia um formato padrão para erros, e a lição 2 o testa.

## Uma impressão digital, e a resposta que poupa um download

O `etag` de um espetáculo é uma impressão digital do estado atual dele. Um cliente que guarda uma
cópia devolve a impressão digital em `if-none-match`, que pergunta *"mudou desde isto?"*:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/shows/sh-101 | grep -i etag
etag: "287e9ace94be5cc6"
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/shows/sh-101 -H 'if-none-match: "287e9ace94be5cc6"'
HTTP/1.1 304 Not Modified
etag: "287e9ace94be5cc6"
Date: Sat, 10 Oct 2026 07:13:50 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

`304 Not Modified`, sem corpo: a cópia que o cliente tem continua valendo, então nada é mandado de
novo. Num celular com sinal fraco essa é a diferença entre um app que atualiza na hora e um que fica
esperando, e a lição 22 mede isso. Para quem testa ela abre duas perguntas, e as duas já pegaram
defeitos reais: **a impressão digital muda quando a coisa muda**, e o servidor continua respondendo
`304` depois de quando deveria ter parado? Vender um lugar muda `seats_left`, então precisa mudar o
`etag` daquele espetáculo. O exercício no fim desta lição pergunta como você conferiria.

## O que o servidor viu

O segundo terminal guardou uma linha para cada requisição que esta lição mandou. Aqui está tudo,
desde o começo:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
boxoffice listening on http://localhost:8080
GET /health 200
GET /v1/shows 200
GET /v1/shows/sh-103 200
GET /v1/shows/sh-103 200
DELETE /v1/shows/sh-103 405
HEAD /v1/shows/sh-103 405
POST /oauth/token 200
POST /oauth/token 200
GET /v1/shows 200
GET /v1/shows/sh-999 404
GET /v1/orders 401
PUT /v1/shows 405
POST /v1/orders 201
POST /v1/orders 409
POST /v1/orders 422
POST /v1/orders 400
POST /v1/orders 415
GET /v1/shows/sh-101 200
GET /v1/shows/sh-101 200
GET /v1/shows/sh-101 304
```

Esse é o lado do servidor de cada troca acima, e um log assim é o primeiro lugar para olhar quando um
teste falha e a resposta sozinha não diz por quê.
