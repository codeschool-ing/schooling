---
title: O servidor é seu
version: 1
---

**Em desenvolvimento o dev server encaminhava `/api` para a API; em produção ninguém faz isso,
porque o `proxy.conf.json` é do `ng serve`.** O servidor de produção recebe um pedido de
`/api/planner`, não acha arquivo com esse nome, e renderiza a aplicação nesse endereço. A aplicação
também não tem rota ali:

```
ana@dev:~/planner$ curl -s -i http://localhost:4000/api/planner | head -1
HTTP/1.1 404 Not Found
```

Um `404`, do `NotFound`, em HTML, onde o planner esperava JSON. O servidor de produção precisa fazer
o que o proxy fazia, e o `src/server.ts` é o lugar. É código Express comum, do projeto, e o `ng add`
deixou nele um comentário dizendo onde uma API entra: antes da linha que renderiza todo o resto. A API
do planner já existe, na porta 3000, então o servidor encaminha para ela:

```schooling-example
{"language": "typescript", "file": "src/server.ts", "parts": [
 {"code": "// src/server.ts\nimport {\n  AngularNodeAppEngine,\n  createNodeRequestHandler,\n  isMainModule,\n  writeResponseToNodeResponse,\n} from '@angular/ssr/node';\nimport express from 'express';\nimport { join } from 'node:path';\n\nconst browserDistFolder = join(import.meta.dirname, '../browser');"},
 {"code": "const plannerApi = process.env['PLANNER_API'] ?? 'http://localhost:3000';\n\nconst app = express();\nconst angularApp = new AngularNodeAppEngine();", "note": "Onde a API está, a partir de uma variável de ambiente, com o endereço da aula 12 quando não há nenhuma."},
 {"code": "app.use('/api', express.text({ type: 'application/json' }), async (req, res) => {\n  try {", "note": "Toda requisição sob `/api`, primeiro. O `express.text` lê um corpo JSON como texto, que é tudo de que um encaminhamento precisa: quem confere é a API."},
 {"code": "    const answer = await fetch(plannerApi + req.originalUrl, {\n      method: req.method,\n      headers: {\n        'content-type': 'application/json',\n        'x-requested-by': req.get('x-requested-by') ?? '-',\n      },\n      body: typeof req.body === 'string' ? req.body : undefined,\n    });\n    res.status(answer.status).type('application/json').send(await answer.text());", "note": "O `originalUrl` ainda tem o `/api`, então a API vê o endereço que o navegador pediu."},
 {"code": "  } catch (error) {\n    console.error(`The planner's API at ${plannerApi} did not answer:`, error);\n    res.status(502).json({ error: 'the planner API did not answer' });\n  }\n});", "note": "Uma API que não responde é um `502`, dito em JSON, e dito neste terminal. Um encaminhamento que falhasse em silêncio deixaria todo mundo sem saber qual dos dois servidores caiu."},
 {"code": "app.use(\n  express.static(browserDistFolder, {\n    maxAge: '1y',\n    index: false,\n    redirect: false,\n  }),\n);\n\napp.use((req, res, next) => {\n  angularApp\n    .handle(req)\n    .then((response) => (response ? writeResponseToNodeResponse(response, res) : next()))\n    .catch(next);\n});\n\nif (isMainModule(import.meta.url) || process.env['pm_id']) {\n  const port = process.env['PORT'] || 4000;\n  app.listen(port, (error) => {\n    if (error) {\n      throw error;\n    }\n\n    console.log(`Node Express server listening on http://localhost:${port}`);\n  });\n}\n\nexport const reqHandler = createNodeRequestHandler(app);", "note": "O resto é o que o `ng add` escreveu, sem os comentários."}
]}
```

Só os cabeçalhos que a API lê são repassados. Um encaminhamento que copiasse todos também copiaria os
cookies e qualquer outra coisa que o navegador mandou para um servidor que não tem uso para eles; a
API fica sabendo do que precisa e de mais nada.

Faça o build, e reinicie o servidor, desta vez com o script que o `ng add` escreveu no `package.json`,
`npm run serve:ssr:planner`, que roda a mesma linha. O planner funciona na porta 4000 como funcionava
na 4200, marcação incluída:

```
ana@dev:~/planner$ look http://localhost:4000/courses/javascript --today 2026-10-23 --network --text app-course-sessions --do 'check Sat 24 Oct, 50 minutes'
-- check Sat 24 Oct, 50 minutes
net  PATCH /api/sessions/5  200
Hide sessions that are done
Tue 13 Oct, 45 minutes
Tue 20 Oct, 1 hour
Sat 24 Oct, 50 minutes
```

A página chegou renderizada, então o navegador não pediu nada até a caixa ser marcada; o `PATCH` foi
para o servidor de produção e, por ele, para a API. Desmarque, com o mesmo comando, para o planner
ficar como estava.

## Quando a API cai

Pare a API com Ctrl-C no terminal dela, e abra a semana:

```
ana@dev:~/planner$ look http://localhost:4000/ --today 2026-10-23 --no-js --text app-week
This week

19 October to 25 October 2026

The week could not be loaded: Http failure response for http://localhost:4000/api/planner: 502 Bad Gateway
```

O servidor renderizou a página com o erro que a aula 12 escreveu para esse caso, e o terminal dele
diz qual servidor falhou:

```
ana@dev:~/planner$ npm run serve:ssr:planner

> planner@0.0.0 serve:ssr:planner
> node dist/planner/server/server.mjs

Node Express server listening on http://localhost:4000
The planner's API at http://localhost:3000 did not answer: TypeError: fetch failed
    at node:internal/deps/undici/undici:14902:13
    at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    at async file:///home/ana/planner/dist/planner/server/server.mjs:60:3140 {
  [cause]: Error: connect ECONNREFUSED 127.0.0.1:3000
      at TCPConnectWrap.afterConnect [as oncomplete] (node:net:1637:16) {
    errno: -111,
    code: 'ECONNREFUSED',
    syscall: 'connect',
    address: '127.0.0.1',
    port: 3000
  }
}
```

Inicie a API de novo, e faça o commit:

```
ana@dev:~/planner$ git add -A && git commit -q -m "SSR: the planner is rendered on the server"
```

O `dist/` está no `.gitignore` que o CLI escreveu na aula 2, então o build não vai no commit: um build
é feito a partir de um commit, nunca guardado nele.
