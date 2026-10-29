---
title: locals, e um id para cada requisição
version: 1
---

**`event.locals` é um objeto que pertence a uma requisição**, em que um hook pode escrever e que toda
função load de servidor, action e endpoint daquela requisição pode ler. As aplicações costumam pôr ali o
usuário logado: um hook lê o cookie de sessão uma vez, e tudo o que vem depois sabe quem está pedindo. O
planner não tem usuários, mas tem um uso para o mesmo mecanismo desde já: **um id curto para cada
requisição**, impresso na linha do log, para que, quando algo der errado, a linha do log e a página que
a pessoa viu possam ser ligadas uma à outra. Substitua o `src/hooks.server.js`:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers.\nimport { sequence } from '@sveltejs/kit/hooks';\nimport { building } from '$app/env';"},
 {"code": "async function log({ event, resolve }) {\n\tevent.locals.id = crypto.randomUUID().slice(0, 8);\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.locals.id} ${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n}\n\nasync function headers({ event, resolve }) {\n\tconst response = await resolve(event);\n\tresponse.headers.set('X-Content-Type-Options', 'nosniff');\n\tresponse.headers.set('Referrer-Policy', 'same-origin');\n\tresponse.headers.set('X-Frame-Options', 'DENY');\n\treturn response;\n}\n\nexport const handle = sequence(log, headers);", "note": "Definido antes do `resolve`, então tudo o que atende a requisição pode ler `event.locals.id`. Oito caracteres hexadecimais bastam para distinguir as requisições de um dia."}
]}
```

`crypto` é a Web Crypto API, que o Node tem como global, como os navegadores. Faça o build, reinicie e
peça uma página duas vezes:

```
ana@dev:~/planner$ curl -s -o /dev/null http://localhost:3000/ && curl -s -o /dev/null http://localhost:3000/courses/piano
```

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
5ac1a69f GET / 200 36 ms
25d2780e GET /courses/piano 404 3 ms
```

Cada linha agora começa com o id da sua requisição. A próxima seção põe o mesmo id na página que a
pessoa vê quando algo falha.

`locals` é do servidor, como o arquivo de hooks. Ele nunca chega ao navegador a não ser que uma função
load devolva algo dele, o que faz dele o lugar certo para coisas que o navegador não pode ver, e o lugar
errado para qualquer coisa de que uma página precise: isso vai no que uma função load devolve.
