---
title: Requisições simples, e o preflight
version: 1
---

**Algumas requisições entre origens são mandadas como estão, e o resto é anunciado antes, com uma
requisição que o navegador manda por conta própria: o preflight.** A linha divisória é o que um
formulário HTML simples já conseguia mandar antes de o CORS existir, porque um servidor feito naquela
época tinha de lidar com isso de qualquer jeito.

Uma requisição é **simples** quando o método é `GET`, `HEAD` ou `POST`, os cabeçalhos são só os que um
navegador define mais alguns inofensivos, e o `Content-Type`, se houver, é um que um formulário manda:
`application/x-www-form-urlencoded`, `multipart/form-data` ou `text/plain`. Todo o resto passa por
**preflight**: um `PUT` ou um `DELETE`, um cabeçalho próprio como o `Authorization`, ou, o caso que o
planner encontra primeiro, um `POST` com `Content-Type: application/json`.

Para essas, o navegador manda antes um `OPTIONS` ao mesmo endereço, com dois cabeçalhos dizendo o que vem
aí: `Access-Control-Request-Method: POST` e `Access-Control-Request-Headers: content-type`. Só se a
resposta permitir os dois ele manda a requisição de verdade. Eis o login, da página, na porta da própria
API:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ 'fetch("http://localhost:3000/api/login", { method: "POST", headers: { "content-type": "application/json" }, body: "{}" }).then((r) => r.status, (e) => String(e))'
request:  POST http://localhost:3000/api/login
console:  Access to fetch at 'http://localhost:3000/api/login' from origin 'http://localhost:5173' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource.
console:  Failed to load resource: net::ERR_FAILED
result:   TypeError: Failed to fetch
```

O console diz o nome: **`Response to preflight request doesn't pass access control check`.** A linha de
requisição é o `POST` que a página pediu; o `OPTIONS` antes dele é do próprio navegador e o Playwright não
o lista. A resposta dele recusou, então o `POST` em si nunca saiu do navegador.

O `curl` consegue mandar o mesmo preflight, para ver o que o servidor diz:

```
ana@dev:~/planner$ curl -s -i -X OPTIONS -H 'Origin: http://localhost:5173' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: content-type' http://localhost:3000/api/login
HTTP/1.1 404 Not Found
content-type: application/json
Date: Fri, 23 Oct 2026 23:20:58 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"error":"no such address"}
```

**404, sem cabeçalho de CORS nenhum**, porque o servidor do planner não sabe nada de `OPTIONS`. Restam duas
correções: ensinar o servidor a responder, que é a seção depois da próxima, ou nunca fazer uma pergunta
entre origens, que é a seção depois dessa.
