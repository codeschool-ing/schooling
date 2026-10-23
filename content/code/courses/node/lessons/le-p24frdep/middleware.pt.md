---
title: Middleware
version: 1
---

**Um middleware é uma função que vê uma requisição a caminho de uma rota, e decide se a passa
adiante.** Ele tem a assinatura `(req, res, next)`. Pode ler e mudar o `req` e o `res`, responder ele
mesmo à requisição, ou chamar `next()` para entregá-la ao que foi acrescentado depois dele. As rotas
são os últimos middlewares da corrente, e a única diferença é que elas costumam responder.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A aplicação links como uma corrente. Uma requisição entra pela esquerda e passa por um logger, o parser de JSON, o roteador de /links, a rota do link curto e o handler de 404, cada um chamando next() para passá-la adiante. Qualquer um dos quatro últimos pode responder em vez disso. Um erro em qualquer ponto pula por um caminho tracejado até o handler de erros no fim.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">requisição</text><rect x=\"20\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">logger</text><text x=\"70\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">registra no finish</text><line x1=\"120\" y1=\"68\" x2=\"156\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"156.0,68.0 148.6,71.1 148.6,64.9\" fill=\"var(--phosphor)\"></polygon><text x=\"138\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">next()</text><rect x=\"156\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">express.json</text><text x=\"206\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">preenche req.body</text><line x1=\"256\" y1=\"68\" x2=\"292\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"292.0,68.0 284.6,71.1 284.6,64.9\" fill=\"var(--phosphor)\"></polygon><text x=\"274\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">next()</text><rect x=\"292\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"342\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/links</text><text x=\"342\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roteador</text><line x1=\"392\" y1=\"68\" x2=\"428\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"428.0,68.0 420.6,71.1 420.6,64.9\" fill=\"var(--phosphor)\"></polygon><text x=\"410\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">next()</text><line x1=\"342\" y1=\"96\" x2=\"342\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"342.0,140.0 338.9,132.6 345.1,132.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"342\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">res.json(…)</text><rect x=\"428\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"478\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/:code</text><text x=\"478\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">link curto</text><line x1=\"528\" y1=\"68\" x2=\"564\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"564.0,68.0 556.6,71.1 556.6,64.9\" fill=\"var(--phosphor)\"></polygon><text x=\"546\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">next()</text><line x1=\"478\" y1=\"96\" x2=\"478\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"478.0,140.0 474.9,132.6 481.1,132.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"478\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">res.redirect(…)</text><rect x=\"564\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"614\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">404</text><text x=\"614\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada casou</text><line x1=\"614\" y1=\"96\" x2=\"614\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"614.0,140.0 610.9,132.6 617.1,132.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"614\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">res.status(404)</text><rect x=\"560\" y=\"190\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">handler de erros</text><text x=\"630\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">(err, req, res, next)</text><path d=\"M70 96 L70 212 L556 212\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"548\" y1=\"212\" x2=\"557\" y2=\"212\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"557.0,212.0 549.6,215.1 549.6,208.9\" fill=\"var(--amber)\"></polygon><text x=\"300\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um throw, uma promise rejeitada ou next(err), de qualquer ponto</text></svg>", "caption": "Cada função responde ou chama next(). A ordem é a dos app.use, e os erros pulam para o fim."}
```

A ordem das chamadas a `app.use` e `app.get` é a ordem da corrente. Um logger no topo vê toda
requisição, um parser de corpo antes das rotas dá a elas o `req.body`, e o handler de erros no fim
pega o que escorregou.

```schooling-example
{"language": "javascript", "file": "demo/chain.js", "parts": [
 {"code": "import express from \"express\";\n\nconst app = express();\n\napp.use((req, res, next) => {\n  const start = performance.now();\n  res.on(\"finish\", () => {\n    console.log(`${req.method} ${req.originalUrl} ${res.statusCode} ${(performance.now() - start).toFixed(1)} ms`);\n  });\n  next();\n});", "note": "**Um logger.** Ele roda antes de toda rota e chama `next()` na hora. A linha de log espera o `finish`, o evento da própria resposta, para poder imprimir o status que a rota escolheu e quanto tempo levou."},
 {"code": "app.use((req, res, next) => {\n  if (req.path === \"/health\") return res.send(\"ok\\n\");\n  next();\n});", "note": "**Um middleware que responde.** Ele encerra a corrente para um caminho e passa todo o resto adiante. Nada depois dele roda para o `/health`."},
 {"code": "app.use((req, res, next) => {\n  req.requestId = Math.random().toString(36).slice(2, 8);\n  res.set(\"x-request-id\", req.requestId);\n  next();\n});", "note": "**Um middleware que acrescenta à requisição.** Toda rota depois dele consegue ler o `req.requestId`."},
 {"code": "app.get(\"/links\", (req, res) => res.json({ requestId: req.requestId, links: [] }));\napp.get(\"/forgot\", (req, res, next) => {});\n\napp.listen(3000, \"127.0.0.1\");", "note": "Duas rotas. A segunda esquece a única regra que um middleware tem: responder, ou chamar `next()`."}
]}
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/health; curl -s http://127.0.0.1:3000/links
ok

{"requestId":"z5zmod","links":[]}
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/links | grep -i x-request-id
x-request-id: fpdsjh
ana@dev:~/server/links$ curl -s -m 2 http://127.0.0.1:3000/forgot; echo "curl exit code $?"

curl exit code 28
```

O `-m 2` dá ao curl dois segundos e nada mais. **A última requisição nunca recebeu resposta**: a rota
não respondeu nem chamou `next()`, então a requisição ficou parada na corrente sem nada que a
movesse, e o curl desistiu com o código de saída 28. Nada foi registrado para ela também, porque o
`finish` nunca veio. No terminal do servidor:

```
ana@dev:~/server/links$ node demo/chain.js
GET /health 200 2.6 ms
GET /links 200 1.0 ms
GET /links 200 0.5 ms
^C
```

**Uma requisição que trava sem erro em lugar nenhum é quase sempre um middleware que esqueceu o
`next()`**, muitas vezes num ramo de um `if`. É por isso que todo middleware acima ou devolve uma
resposta ou termina em `next()`. O `requestId` aqui é só um exemplo; um de verdade vem do
`crypto.randomUUID()`, e é repassado a todo serviço que este chama, para que uma requisição possa ser
seguida por todos eles.
