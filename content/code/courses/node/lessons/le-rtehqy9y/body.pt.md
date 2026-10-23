---
title: O corpo, e o que o express.json decide
version: 1
---

**O `express.json()` tem quatro opções, e cada uma é uma decisão sobre o que o serviço aceita.** Os
padrões são razoáveis para um servidor genérico e errados para a maioria dos específicos:

| opção | padrão | o que ela decide |
|---|---|---|
| `limit` | `"100kb"` | o maior corpo lido antes de responder 413 |
| `strict` | `true` | só objetos e arrays no topo; um `"texto"` ou um `42` soltos são recusados |
| `type` | `"application/json"` | qual `content-type` faz ele ler o corpo |
| `inflate` | `true` | se um corpo comprimido com gzip é descomprimido |

O serviço links recebe um objeto pequeno, então definiu `limit: "1kb"` na aula 6. Vale ver o
`strict`, porque o erro que ele lança é um que o serviço precisa responder bem:

```javascript
// demo/body.js
import express from "express";

const app = express();
app.use(express.json({ limit: "1kb" }));
app.post("/links", (req, res) => res.json({ body: req.body ?? "nothing" }));
app.use((err, req, res, next) => res.status(err.status ?? 500).json({ error: err.type ?? "internal" }));
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '"https://example.com/"' http://127.0.0.1:3000/links
{"error":"entity.parse.failed"}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/links
{"body":{"url":"https://example.com/"}}
ana@dev:~/server/links$ curl -s -X POST http://127.0.0.1:3000/links
{"body":"nothing"}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/", }' http://127.0.0.1:3000/links
{"error":"entity.parse.failed"}
```

**O `err.type` diz o que deu errado numa palavra que um programa consegue testar**:
`entity.parse.failed` para JSON recusado ou malformado, `entity.too.large` para um corpo acima do
limite. O handler manda a palavra e não a mensagem, que num erro de leitura cita de volta ao cliente o
próprio corpo dele.

A terceira requisição não mandou corpo nenhum, e o `req.body` ficou `undefined`: o Express 5 o deixa
sem valor quando nada foi lido, onde o Express 4 punha um objeto vazio. **Uma rota lê `req.body?.url`,
com o ponto de interrogação**, ou lança um `TypeError` na primeira requisição que esquecer o corpo,
que foi a escolha da aula 6 e o motivo dela.
