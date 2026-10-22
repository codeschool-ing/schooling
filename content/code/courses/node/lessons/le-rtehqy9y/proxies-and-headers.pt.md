---
title: Quem está perguntando, e o que dizer a ele
version: 1
---

**O `req.ip` é o endereço de onde a requisição veio, e atrás de um proxy esse é o endereço do
proxy.** Em produção um serviço Node costuma ficar atrás de um — Nginx, um balanceador de carga, o
roteador de uma plataforma — e toda requisição chega dele. O proxy diz quem era o cliente de verdade
num cabeçalho, o `X-Forwarded-For`, e o Express só o lê quando mandam confiar no proxy que o escreveu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dentro de uma máquina, um proxy escuta no endereço público e repassa cada requisição ao Node em 127.0.0.1, acrescentando o X-Forwarded-For com o endereço de onde a requisição veio de fato. Fora da máquina, um cliente em 203.0.113.9. O Node confia no cabeçalho só porque o proxy, no loopback, é a única coisa que o alcança.\"><rect x=\"20\" y=\"80\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um cliente</text><text x=\"95\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">203.0.113.9</text><rect x=\"230\" y=\"20\" width=\"470\" height=\"210\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"246\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma máquina</text><rect x=\"260\" y=\"80\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"340\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o proxy</text><text x=\"340\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">endereço público, :443</text><rect x=\"500\" y=\"80\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Node, 127.0.0.1:3000</text><text x=\"590\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">trust proxy: \"loopback\"</text><line x1=\"170\" y1=\"115\" x2=\"258\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"258.0,115.0 250.6,118.1 250.6,111.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"420\" y1=\"115\" x2=\"498\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"498.0,115.0 490.6,118.1 490.6,111.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"459\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">X-Forwarded-For:</text><text x=\"459\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">203.0.113.9</text><text x=\"590\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">req.ip = 203.0.113.9</text><text x=\"214\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">internet</text></svg>", "caption": "O cabeçalho é aceito porque só o proxy alcança o endereço de loopback. Uma confiança que vá além deixa qualquer cliente escrever o seu.", "same": ["internet"]}
```

```javascript
// demo/ip.js
import express from "express";

const app = express();
if (process.argv[2]) app.set("trust proxy", process.argv[2]);
app.get("/ip", (req, res) => res.json({ ip: req.ip, ips: req.ips }));
app.listen(3000, "127.0.0.1");
```

Pergunte com um cabeçalho forjado, primeiro sem confiança definida:

```
ana@dev:~/server/links$ curl -s -H 'X-Forwarded-For: 203.0.113.9' http://127.0.0.1:3000/ip
{"ip":"127.0.0.1","ips":[]}
```

e de novo com o servidor reiniciado como `node demo/ip.js loopback`:

```
ana@dev:~/server/links$ curl -s -H 'X-Forwarded-For: 203.0.113.9' http://127.0.0.1:3000/ip
{"ip":"203.0.113.9","ips":["203.0.113.9"]}
```

**Sem confiança, o cabeçalho é ignorado e o `req.ip` é o endereço do socket**, que é a verdade. Com
`loopback`, o Express acredita num `X-Forwarded-For` que chega de `127.0.0.1`, e o endereço forjado
virou o `req.ip`. Essa é a configuração certa quando a única coisa que alcança o serviço no loopback
é o proxy na mesma máquina, e a errada em qualquer outro caso. **O `trust proxy` como `true` acredita
no cabeçalho vindo de qualquer um**, então todo cliente pode escolher o endereço que os logs, os
limites de taxa e a trilha de auditoria registram. Confie exatamente nos proxies que você roda, por
endereço ou por contagem, e em mais nada. Os endereços aqui são de `203.0.113.0/24`, uma faixa
reservada para documentação que não pertence a ninguém.

## O que a resposta conta ao mundo

A aula 6 notou o `X-Powered-By: Express`. Duas linhas o tiram e acrescentam o cabeçalho que mais
importa para uma API:

- **`app.disable("x-powered-by")`**, para que uma varredura atrás de uma versão vulnerável de
  framework não aprenda nada com uma resposta;
- **`X-Content-Type-Options: nosniff`**, que diz a um navegador para acreditar no `Content-Type` e
  nunca adivinhar, para que um corpo JSON não possa ser tratado como script ou página.

Um site que serve páginas a navegadores precisa de mais deles — `Content-Security-Policy`,
`Strict-Transport-Security` e outros — e o pacote **`helmet`** define um grupo sensato numa linha; para
uma API que responde JSON esses dois são o essencial. A aplicação links com os dois, e com a confiança
de que um proxy na mesma máquina precisa:

```schooling-example
{"language": "javascript", "file": "src/app.js", "parts": [
 {"code": "// src/app.js: the application, built and not started.\nimport express from \"express\";\nimport { links } from \"./links.js\";\nimport * as store from \"./store.js\";\n\nexport function createApp() {\n  const app = express();\n  app.disable(\"x-powered-by\");\n  app.set(\"trust proxy\", \"loopback\");\n  app.use((req, res, next) => {\n    res.set(\"x-content-type-options\", \"nosniff\");\n    next();\n  });", "note": "**As três linhas que esta aula acrescenta**, antes de qualquer outra coisa: nada de nome de framework, confiança só num proxy desta máquina, e `nosniff` em toda resposta."},
 {"code": "  app.use((req, res, next) => {\n    res.on(\"finish\", () => console.log(`${req.ip} ${req.method} ${req.originalUrl} ${res.statusCode}`));\n    next();\n  });\n  app.use(express.json({ limit: \"1kb\" }));\n  app.use(\"/links\", links);", "note": "A linha de log agora diz quem perguntou, e é por isso que a configuração de confiança precisa estar certa."},
 {"code": "  app.get(\"/:code\", async (req, res, next) => {\n    const link = await store.visit(req.params.code);\n    if (!link) return next();\n    res.redirect(302, link.url);\n  });\n\n  app.use((req, res) => res.status(404).json({ error: `nothing at ${req.path}` }));\n  app.use((err, req, res, next) => {\n    const status = err.status ?? 500;\n    if (status >= 500) console.error(`${req.method} ${req.originalUrl}:`, err);\n    res.status(status).json({ error: status >= 500 ? \"internal error\" : err.message });\n  });\n\n  return app;\n}", "note": "O resto é o da aula 6, sem mudança."}
]}
```

```
ana@dev:~/server/links$ npm test 2>&1 | grep -E "^(✔|✖|ℹ (tests|pass|fail))"
✔ a code has the right length (0.699116ms)
✔ a code uses only the alphabet (5.934597ms)
✔ isCode refuses what makeCode would never make (0.229715ms)
✔ a new link answers 201 with its location (39.311932ms)
✔ following a link redirects and counts the visit (9.100847ms)
✔ a url that is not a web address is refused (2.763037ms)
✔ deleting needs the admin key (5.822677ms)
ℹ tests 7
ℹ pass 7
ℹ fail 0
```

O `grep` guarda só as linhas que relatam um resultado, sem as linhas de log entre elas. Os sete
testes da aula 6 continuam passando com as conferências novas no lugar. **Era para isso que eles
serviam**: as rotas mudaram por baixo deles, e as promessas a que eles prendem o serviço não mudaram.
