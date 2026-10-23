---
title: Requisições condicionais e cabeçalhos de cache
version: 1
---

**Um cliente que já tem uma cópia de uma resposta pode perguntar "isto mudou?" em vez de pedir de
novo**, e um servidor que consegue responder "não" com um 304 manda uma linha de status e nenhum
corpo. O Express torna metade disso automática: o `res.json` e o `res.send` calculam um `ETag`, uma
impressão digital do corpo, e respondem 304 sozinhos quando o cliente manda essa impressão de volta no
`If-None-Match`.

Com o `server.js` rodando e um link nele:

```
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/links/vb3qxu | grep -i etag
ETag: W/"5e-KLu1io51n87g/2gy6Oj3o56wm4s"
ana@dev:~/server/links$ curl -si -H 'If-None-Match: W/"5e-KLu1io51n87g/2gy6Oj3o56wm4s"' http://127.0.0.1:3000/links/vb3qxu | head -1
HTTP/1.1 304 Not Modified
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/vb3qxu
302
ana@dev:~/server/links$ curl -si -H 'If-None-Match: W/"5e-KLu1io51n87g/2gy6Oj3o56wm4s"' http://127.0.0.1:3000/links/vb3qxu | grep -iE '^HTTP|^etag'
HTTP/1.1 200 OK
ETag: W/"5e-GCroJt7mlVyGKv5hLdbPiIy8v04"
```

**A segunda requisição mandou a impressão digital e recebeu 304 sem corpo**: o link não tinha mudado.
A quarta veio depois da terceira, uma visita, que muda o `visits`, então a impressão não batia mais e
o link inteiro voltou com uma nova. O `W/` na frente quer dizer um ETag *fraco*: dois corpos com o
mesmo sentido podem dividir um, que é tudo de que uma API JSON precisa.

O ETag é calculado a partir do corpo depois de a rota montá-lo, então um 304 economiza a rede e não o
trabalho. Uma rota cara de calcular precisa de um cache na frente, que o `servers-cache` monta.

## Dizendo por quanto tempo uma cópia pode ser guardada

O `ETag` responde "isto mudou?". **O `Cache-Control` responde "você pode guardar isto, e por quanto
tempo?"**, e o servidor o define por rota:

| `Cache-Control` | significa |
|---|---|
| `no-store` | não guarde cópia em lugar nenhum: a lista do administrador, qualquer coisa pessoal |
| `no-cache` | guarde, e pergunte com `If-None-Match` antes de cada uso |
| `max-age=3600` | use a cópia por uma hora sem perguntar |
| `private` | um navegador pode guardar; um proxy compartilhado não |

A lista do administrador diz `no-store` desde a seção sobre validação, e uma requisição mostra:

```
ana@dev:~/server/links$ curl -si -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links | grep -iE '^(cache-control|etag)'
cache-control: no-store
ETag: W/"60-t+j0ML9EqfCyDHsGPRTgvFk0j+I"
```

O redirecionamento de um link curto não diz nada sobre cache, então um navegador o trata pelos
padrões dele, que para um 302 é perguntar toda vez; a seção sobre os auxiliares da resposta escolheu o
302 exatamente por isso.
