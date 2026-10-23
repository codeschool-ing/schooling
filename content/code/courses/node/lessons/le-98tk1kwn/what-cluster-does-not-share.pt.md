---
title: O que as workers não dividem
version: 1
---

**Cada worker de um cluster é um processo separado, com a própria memória.** Tudo o que um programa
guarda numa variável existe uma vez por worker, e as workers nunca veem as das outras. O serviço links
guarda os links num `Map`, carregado do arquivo na primeira vez que um pedido precisa, e isso basta
para quebrá-lo. Na pasta do links, o lançador da última seção roda o `server.js` quatro vezes, com um
arquivo de dados próprio para que os seus links fiquem em paz:

```
ana@dev:~/server/links$ rm -f demo/cluster.json && DATA_FILE=demo/cluster.json node --env-file=.env ../procs/cluster.js server.js
primary 15317: 4 workers of server.js
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/demo/cluster.json',
  adminKey: '(set, 32 characters)'
}
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/demo/cluster.json',
  adminKey: '(set, 32 characters)'
}
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/demo/cluster.json',
  adminKey: '(set, 32 characters)'
}
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/demo/cluster.json',
  adminKey: '(set, 32 characters)'
}
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 POST /links 201
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 302
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 302
127.0.0.1 POST /links 201
SIGINT: closing; requests already open are finished first
SIGINT: closing; requests already open are finished first
SIGINT: closing; requests already open are finished first
closed
closed
closed
SIGINT: closing; requests already open are finished first
closed
^C
```

Do segundo terminal: oito pedidos para aquecer cada worker, para que cada uma carregue o store vazio;
depois um link novo; oito visitas a ele; e um segundo link.

```
ana@dev:~/server/links$ for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/nothing-here; done; echo
404 404 404 404 404 404 404 404 
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://nodejs.org/"}' http://127.0.0.1:3000/links
{"code":"9g9m9z","url":"https://nodejs.org/","visits":0,"created":"2026-10-22T22:48:38.249Z"}
ana@dev:~/server/links$ for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/9g9m9z; done; echo
404 404 404 302 404 404 404 302 
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/links
{"code":"k4ucg2","url":"https://example.com/","visits":0,"created":"2026-10-22T22:48:38.349Z"}
ana@dev:~/server/links$ cat demo/cluster.json
[
  {
    "code": "k4ucg2",
    "url": "https://example.com/",
    "visits": 0,
    "created": "2026-10-22T22:48:38.349Z"
  }
]
```

**Uma visita em quatro achou o link, e três em quatro responderam 404**: a worker que o criou o tinha
no `Map` dela, e as outras três tinham carregado o store antes de ele existir e nunca mais olharam.
**Depois o arquivo perdeu o primeiro link.** O segundo foi criado em outra worker, cujo `Map` nunca
teve o primeiro, e o save gravou esse `Map` por cima do arquivo. Nada falhou e nada foi para o log: um
link que foi respondido com 201 sumiu, e as visitas que ele tinha sumiram junto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Por que o serviço links quebra num cluster. Quatro workers guardam cada uma o seu Map de links. Um link criado na worker 4 só existe no Map da worker 4, então as outras três respondem 404 para ele. Cada worker grava o seu Map inteiro por cima do mesmo arquivo, então o arquivo guarda o que a última a escrever sabia.\"><rect x=\"20\" y=\"30\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 1</text><text x=\"100\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Map</text><text x=\"100\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(vazio)</text><text x=\"100\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">404</text><line x1=\"100\" y1=\"130\" x2=\"360\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"192\" y=\"30\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 2</text><text x=\"272\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Map</text><text x=\"272\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(vazio)</text><text x=\"272\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">404</text><line x1=\"272\" y1=\"130\" x2=\"360\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"364\" y=\"30\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"444\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 3</text><text x=\"444\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Map</text><text x=\"444\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(vazio)</text><text x=\"444\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">404</text><line x1=\"444\" y1=\"130\" x2=\"360\" y2=\"180\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><rect x=\"536\" y=\"30\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"616\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 4</text><text x=\"616\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Map</text><text x=\"616\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o link novo</text><text x=\"616\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">302</text><line x1=\"616\" y1=\"130\" x2=\"360\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"260\" y=\"182\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">demo/cluster.json</text><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">o que o último save tinha</text></svg>", "caption": "Estado numa variável é estado por worker: as workers discordam, e o arquivo fica com a última palavra.", "same": ["worker 1", "worker 2", "worker 3", "worker 4"]}
```

A mesma falha espera em qualquer coisa guardada na memória:

| guardado na memória de uma worker | o que dá errado num cluster |
|---|---|
| um cache, como o `Map` do store | cada worker tem o seu, e eles discordam |
| um contador, como visitas ou um limite de taxa | cada uma conta um quarto, e o limite fica quatro vezes mais frouxo |
| sessões guardadas na memória | quem entrou numa worker é um estranho para a próxima |
| um arquivo que cada worker regrava | quem escreve por último vence, e toda outra escrita se perde |

**A solução é guardar o estado fora dos processos**: um banco de dados, ou um store como o Redis, a que
todas as workers perguntam. Esse é o assunto dos cursos de banco de dados. Até lá o serviço links roda
como um processo só, o que está certo, e é tão rápido quanto precisa ser.

Um programa ainda pode usar o `cluster` com segurança se não guardar nada entre um pedido e outro. A
pergunta a fazer sobre um serviço antes de rodá-lo num cluster, ou como várias cópias atrás de um
balanceador de carga, é a mesma: **um pedido depende de algo que um pedido anterior deixou na
memória?**
