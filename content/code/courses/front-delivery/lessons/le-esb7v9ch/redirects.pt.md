---
title: Redirecionamentos, e qual código usar
version: 1
---

**Um redirecionamento é uma resposta com status na casa dos 300 e um cabeçalho `Location`, e o status diz
ao navegador, e a todo buscador e cache, por quanto tempo acreditar nele.** Escolher o código é escolher
essa duração e o que acontece com o método da requisição, e os quatro em uso têm significados exatos:

| código | nome | quer dizer | método no caminho |
|---|---|---|---|
| 301 | Moved Permanently | este endereço sumiu de vez; use o novo daqui em diante | pode transformar um `POST` em `GET` |
| 302 | Found | vá lá desta vez; me pergunte de novo da próxima | pode transformar um `POST` em `GET` |
| 307 | Temporary Redirect | como o 302 | mantido exatamente |
| 308 | Permanent Redirect | como o 301 | mantido exatamente |

**Um redirecionamento permanente é lembrado.** Navegadores guardam um 301 ou um 308 sem precisar que
alguém peça, então um redirecionamento permanente mandado por engano continua levando as pessoas ao lugar
errado depois que você o remove, até cada visitante limpar o cache. Use 302 enquanto não tiver certeza e
301 quando a decisão estiver tomada. Para um site estático de páginas, a questão do método quase nunca
aparece, e 301 é o padrão dos arquivos de regras; o Cloudflare Pages é a exceção e usa 302 por padrão,
então escreva o código em toda regra.

## Um endereço renomeado

As páginas de curso do planner já moraram em `/courses/<id>`, no plural, e links para elas ainda estão
por aí. Uma regra manda todo endereço antigo para o novo, mantendo a parte que cita o curso. O arquivo vai
em `public/`, para o Vite copiá-lo para `dist/`, onde a Netlify, o Cloudflare Pages e agora o `host.mjs` o
procuram:

```
# public/_redirects
/courses/* /course/:splat 301
```

Construa, inicie o host em outro terminal com `node host.mjs`, como na aula 1, e peça um endereço antigo:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ curl -sI http://127.0.0.1:8080/courses/git
HTTP/1.1 301 Moved Permanently
location: /course/git
Date: Fri, 23 Oct 2026 23:04:20 GMT
Connection: keep-alive
Keep-Alive: timeout=5

ana@dev:~/planner$ curl -sL -o /dev/null -w '%{http_code} %{url_effective}\n' http://127.0.0.1:8080/courses/git
404 http://127.0.0.1:8080/course/git
```

A resposta não traz página, só o status e para onde ir: `/course/git`, com o `git` tirado do que o `*`
casou. Um navegador o segue sem quem lê perceber, e a barra de endereço mostra o novo. O `curl -L` também
o segue, e chega em `/course/git`, que ainda é um 404 neste host: esse endereço é o problema da próxima
seção.

## O que um redirecionamento não resolve

Um redirecionamento manda o navegador para outro endereço, então muda o que a barra de endereço diz. Isso
está certo para uma página que mudou de lugar e errado para o problema da próxima seção: um endereço que
está correto, que o app sabe desenhar, e para o qual o host não tem arquivo. Mandar `/course/git` para `/`
quebraria todo link profundo que o app faz. Isso precisa de uma reescrita, que serve outro arquivo **no
mesmo endereço**.
