---
title: O serviço links em Express
version: 1
---

**O mesmo serviço da aula 5, na organização da aula 3, em cinco arquivos pequenos.** Cada seção desta
aula é uma peça dele. Substitua o `server.js` de uma rota só da aula 4, e acrescente o resto ao lado
do `src/code.js`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Os cinco arquivos do serviço links e quem importa quem. O server.js importa o app.js e o põe para escutar. O app.js monta a aplicação e pendura o roteador do links.js. O links.js tem as rotas e importa o admin.js, para a chave, e o store.js, para os links. O store.js importa o code.js, que faz os códigos.\"><rect x=\"20\" y=\"90\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">server.js</text><text x=\"90\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escuta</text><rect x=\"180\" y=\"90\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/app.js</text><text x=\"250\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">monta o app</text><rect x=\"350\" y=\"90\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/links.js</text><text x=\"420\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as rotas</text><rect x=\"540\" y=\"30\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/admin.js</text><text x=\"610\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a chave</text><rect x=\"540\" y=\"150\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/store.js</text><text x=\"610\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os links</text><line x1=\"160\" y1=\"113\" x2=\"178\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"178.0,113.0 170.6,116.1 170.6,109.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"320\" y1=\"113\" x2=\"348\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"348.0,113.0 340.6,116.1 340.6,109.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"490\" y1=\"105\" x2=\"538\" y2=\"60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,60.0 534.8,67.3 530.5,62.8\" fill=\"var(--paper-dim)\"></polygon><line x1=\"490\" y1=\"121\" x2=\"538\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,168.0 530.6,165.1 534.9,160.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"175\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/code.js</text><text x=\"450\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">faz os códigos</text><line x1=\"540\" y1=\"186\" x2=\"522\" y2=\"192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"522.0,192.0 528.0,186.7 530.0,192.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma seta: importa</text></svg>", "caption": "Um trabalho por arquivo: as regras do serviço ficam no links.js, e o encanamento em volta."}
```

## O armazenamento

```javascript
// src/store.js: where the links live. In memory for now; lesson 8 gives it a file.
import { makeCode } from "./code.js";

const links = new Map(); // code -> { code, url, visits, created }

export async function add(url) {
  let code;
  do code = makeCode();
  while (links.has(code));
  const link = { code, url, visits: 0, created: new Date().toISOString() };
  links.set(code, link);
  return link;
}

export async function find(code) {
  return links.get(code);
}

export async function all() {
  return [...links.values()];
}

export async function remove(code) {
  return links.delete(code);
}

export async function visit(code) {
  const link = links.get(code);
  if (link) link.visits++;
  return link;
}
```

**Toda função é `async`, embora nada aqui espere.** A aula 8 guarda os links num arquivo, e escrever
um arquivo é assíncrono; se as funções devolvessem valores simples agora, toda rota mudaria lá.
Escritas assim, só este arquivo muda.

## A chave de administração

```javascript
// src/admin.js: a shared key for whoever runs the service.
import { timingSafeEqual } from "node:crypto";

const ADMIN_KEY = "change-me-in-lesson-9"; // lesson 9 moves it to the environment

export function requireKey(req, res, next) {
  const given = Buffer.from(req.get("x-admin-key") ?? "");
  const wanted = Buffer.from(ADMIN_KEY);
  if (given.length !== wanted.length || !timingSafeEqual(given, wanted)) {
    return res.status(401).json({ error: "this needs the admin key" });
  }
  next();
}
```

## As rotas

```schooling-example
{"language": "javascript", "file": "src/links.js", "parts": [
 {"code": "// src/links.js: the routes under /links.\nimport express from \"express\";\nimport { requireKey } from \"./admin.js\";\nimport * as store from \"./store.js\";\n\nexport const links = express.Router();\n\nfunction isWebAddress(text) {\n  try {\n    const url = new URL(text);\n    return url.protocol === \"http:\" || url.protocol === \"https:\";\n  } catch {\n    return false;\n  }\n}", "note": "O roteador de tudo sob `/links`, e a conferência da aula 5 de que só endereços web são guardados."},
 {"code": "links\n  .route(\"/\")\n  .get(requireKey, async (req, res) => res.json(await store.all()))\n  .post(async (req, res) => {\n    const url = req.body?.url;\n    if (!isWebAddress(url)) return res.status(400).json({ error: \"url must be an http or https address\" });\n    const link = await store.add(url);\n    res.status(201).location(`/links/${link.code}`).json(link);\n  })\n  .all((req, res) => res.set(\"allow\", \"GET, POST\").status(405).json({ error: \"method not allowed\" }));", "note": "**Qualquer um pode criar um link; só o administrador pode listá-los.** O 201 leva o endereço do link novo no `location`."},
 {"code": "links\n  .route(\"/:code\")\n  .get(async (req, res) => {\n    const link = await store.find(req.params.code);\n    if (!link) return res.status(404).json({ error: `no link ${req.params.code}` });\n    res.json(link);\n  })\n  .delete(requireKey, async (req, res) => {\n    if (!(await store.remove(req.params.code))) return res.status(404).json({ error: `no link ${req.params.code}` });\n    res.status(204).end();\n  })\n  .all((req, res) => res.set(\"allow\", \"GET, DELETE\").status(405).json({ error: \"method not allowed\" }));", "note": "Um link: qualquer um pode lê-lo, só o administrador pode apagá-lo, e o 405 diz quais métodos existem."}
]}
```

## A aplicação

```schooling-example
{"language": "javascript", "file": "src/app.js", "parts": [
 {"code": "// src/app.js: the application, built and not started.\nimport express from \"express\";\nimport { links } from \"./links.js\";\nimport * as store from \"./store.js\";\n\nexport function createApp() {\n  const app = express();", "note": "**O `createApp` monta a aplicação e a devolve sem escutar**, o motivo da aula 3 para dois arquivos. Um teste o chama; o `server.js` o chama e escuta."},
 {"code": "  app.use((req, res, next) => {\n    res.on(\"finish\", () => console.log(`${req.method} ${req.originalUrl} ${res.statusCode}`));\n    next();\n  });\n  app.use(express.json({ limit: \"1kb\" }));\n  app.use(\"/links\", links);", "note": "A corrente, de cima para baixo: uma linha de log para cada requisição, o parser de corpo JSON, o roteador."},
 {"code": "  app.get(\"/:code\", async (req, res, next) => {\n    const link = await store.visit(req.params.code);\n    if (!link) return next();\n    res.redirect(302, link.url);\n  });", "note": "**O próprio link curto.** Um código que não existe chama `next()`, e cai no 404 abaixo."},
 {"code": "  app.use((req, res) => res.status(404).json({ error: `nothing at ${req.path}` }));\n  app.use((err, req, res, next) => {\n    const status = err.status ?? 500;\n    if (status >= 500) console.error(`${req.method} ${req.originalUrl}:`, err);\n    res.status(status).json({ error: status >= 500 ? \"internal error\" : err.message });\n  });\n\n  return app;\n}", "note": "O 404 para o que não casou com nada, e depois o handler de erros, por último."}
]}
```

```javascript
// server.js
import { createApp } from "./src/app.js";

createApp().listen(3000, "127.0.0.1", () => console.log("links on http://127.0.0.1:3000"));
```

As 110 linhas da aula 5 são cerca de 100 aqui, em cinco arquivos, e a diferença não é a contagem.
**Cada arquivo tem um trabalho só**, o `src/links.js` é só as regras do serviço, e nenhum encanamento
é nosso para errar.

## Usando

```
ana@dev:~/server/links$ curl -si -H 'content-type: application/json' -d '{"url": "https://expressjs.com/"}' http://127.0.0.1:3000/links
HTTP/1.1 201 Created
X-Powered-By: Express
Location: /links/wuhuch
Content-Type: application/json; charset=utf-8
Content-Length: 96
ETag: W/"60-awXfUEWKuqqp75g5Jpz5AyPjMAY"
Date: Fri, 16 Oct 2026 23:20:05 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"code":"wuhuch","url":"https://expressjs.com/","visits":0,"created":"2026-10-16T23:20:05.813Z"}
```

```
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/wuhuch | head -3
HTTP/1.1 302 Found
X-Powered-By: Express
Location: https://expressjs.com/
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/wuhuch
{"code":"wuhuch","url":"https://expressjs.com/","visits":1,"created":"2026-10-16T23:20:05.813Z"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links
{"error":"this needs the admin key"}
ana@dev:~/server/links$ curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links
[{"code":"wuhuch","url":"https://expressjs.com/","visits":1,"created":"2026-10-16T23:20:05.813Z"}]
ana@dev:~/server/links$ curl -s -X DELETE -H 'x-admin-key: change-me-in-lesson-9' -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/links/wuhuch
204
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/nothing/here
{"error":"nothing at /nothing/here"}
```

## Testando

O teste inicia a aplicação numa porta que o sistema escolhe, faz perguntas a ela com `fetch`, e a
fecha quando o arquivo termina:

```schooling-example
{"language": "javascript", "file": "test/links.test.js", "parts": [
 {"code": "import { test, before, after } from \"node:test\";\nimport assert from \"node:assert/strict\";\nimport { createApp } from \"../src/app.js\";\n\nlet server, base;\nbefore(async () => {\n  server = createApp().listen(0, \"127.0.0.1\");\n  await new Promise((resolve) => server.once(\"listening\", resolve));\n  base = `http://127.0.0.1:${server.address().port}`;\n});\nafter(() => server.close());\n\nconst post = (path, body) =>\n  fetch(base + path, { method: \"POST\", headers: { \"content-type\": \"application/json\" }, body: JSON.stringify(body) });", "note": "**O `before` e o `after` rodam uma vez em volta dos testes do arquivo.** A porta 0 dá uma porta livre, e o `server.close()` no `after` deixa o processo de teste terminar, a regra da aula 2 sobre o que mantém um processo vivo."},
 {"code": "test(\"a new link answers 201 with its location\", async () => {\n  const res = await post(\"/links\", { url: \"https://example.com/\" });\n  assert.equal(res.status, 201);\n  const link = await res.json();\n  assert.equal(res.headers.get(\"location\"), `/links/${link.code}`);\n});\n\ntest(\"following a link redirects and counts the visit\", async () => {\n  const link = await (await post(\"/links\", { url: \"https://example.com/a\" })).json();\n  const res = await fetch(`${base}/${link.code}`, { redirect: \"manual\" });\n  assert.equal(res.status, 302);\n  assert.equal(res.headers.get(\"location\"), \"https://example.com/a\");\n  const seen = await (await fetch(`${base}/links/${link.code}`)).json();\n  assert.equal(seen.visits, 1);\n});\n\ntest(\"a url that is not a web address is refused\", async () => {\n  const res = await post(\"/links\", { url: \"javascript:alert(1)\" });\n  assert.equal(res.status, 400);\n});", "note": "O que o serviço promete a um cliente: um 201 com location, um redirecionamento que é contado, uma recusa de tudo o que não for endereço web."},
 {"code": "test(\"deleting needs the admin key\", async () => {\n  const link = await (await post(\"/links\", { url: \"https://example.com/b\" })).json();\n  const res = await fetch(`${base}/links/${link.code}`, { method: \"DELETE\" });\n  assert.equal(res.status, 401);\n});", "note": "E o que ele promete a quem o roda: nada é apagado sem a chave."}
]}
```

```
ana@dev:~/server/links$ npm test

> links@0.1.0 test
> node --test --test-reporter=spec

✔ a code has the right length (0.996466ms)
✔ a code uses only the alphabet (5.434548ms)
✔ isCode refuses what makeCode would never make (0.188832ms)
POST /links 201
✔ a new link answers 201 with its location (62.900467ms)
POST /links 201
GET /wxvhgq 302
GET /links/wxvhgq 200
✔ following a link redirects and counts the visit (8.646862ms)
POST /links 400
✔ a url that is not a web address is refused (2.711347ms)
POST /links 201
DELETE /links/pqw9uc 401
✔ deleting needs the admin key (5.480915ms)
ℹ tests 7
ℹ suites 0
ℹ pass 7
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 236.864328
```

Sete testes: os três da aula 4, e estes quatro. As linhas entre eles são o log da própria aplicação,
uma por requisição que os testes fizeram. O `redirect: "manual"` impede o `fetch` de seguir o 302 até
o `example.com`, então o teste vê o próprio redirecionamento e nunca sai do computador.
