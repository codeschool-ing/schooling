---
title: Validando o que um cliente manda
version: 1
---

**Tudo numa requisição veio de alguém que você não controla, e uma rota confere antes de usar.** A
aula 5 conferia uma coisa num link novo, que a `url` fosse um endereço web. Uma requisição pode estar
errada de mais jeitos que esse, e a resposta é mais útil quando diz todos de uma vez.

Três regras dão forma à conferência a seguir:

- **uma lista do que é permitido, não do que é proibido.** O corpo pode ter `url` e mais nada. Um
  campo que o serviço não conhece é recusado, em vez de ignorado, para que um cliente que escreva
  `ur1` descubra na hora em vez de ficar sem entender por que o link não tem URL;
- **tipos antes de valores.** O `typeof url !== "string"` vem primeiro, porque qualquer outro teste
  num número ou num objeto daria bobagem;
- **um limite em tudo que tem tamanho.** Uma URL de dois megabytes não é um endereço de que alguém
  precise, e 2048 caracteres é uma escolha comum de limite, longa o bastante para qualquer endereço
  que uma pessoa queira encurtar.

As rotas, com esta conferência, com a conferência de parâmetro desta aula e com o limite na lista:

```schooling-example
{"language": "javascript", "file": "src/links.js", "parts": [
 {"code": "// src/links.js: the routes under /links.\nimport express from \"express\";\nimport { requireKey } from \"./admin.js\";\nimport { isCode } from \"./code.js\";\nimport * as store from \"./store.js\";\n\nexport const links = express.Router();\n\nfunction isWebAddress(text) {\n  try {\n    const url = new URL(text);\n    return url.protocol === \"http:\" || url.protocol === \"https:\";\n  } catch {\n    return false;\n  }\n}", "note": "As rotas importam o `isCode` agora, para a conferência de parâmetro."},
 {"code": "function problemsWith(body) {\n  if (typeof body !== \"object\" || body === null || Array.isArray(body)) return [\"send a JSON object\"];\n  const problems = [];\n  for (const key of Object.keys(body)) {\n    if (key !== \"url\") problems.push(`unknown field ${JSON.stringify(key)}`);\n  }\n  if (typeof body.url !== \"string\") problems.push(\"url is required, as a string\");\n  else if (body.url.length > 2048) problems.push(\"url may be at most 2048 characters\");\n  else if (!isWebAddress(body.url)) problems.push(\"url must be an http or https address\");\n  return problems;\n}", "note": "**Todos os problemas, não o primeiro.** A função devolve uma lista, e uma lista vazia quer dizer que o corpo é aceitável."},
 {"code": "function limitFrom(query, fallback = 20, most = 100) {\n  if (query.limit === undefined) return fallback;\n  const n = Number(query.limit);\n  if (!Number.isInteger(n) || n < 1 || n > most) return null;\n  return n;\n}", "note": "O limite da seção sobre a query string."},
 {"code": "links.param(\"code\", (req, res, next, code) => {\n  if (!isCode(code)) return res.status(400).json({ error: `${JSON.stringify(code)} is not a link code` });\n  next();\n});", "note": "A conferência de parâmetro da primeira seção desta aula, para toda rota abaixo que cite `:code`."},
 {"code": "links\n  .route(\"/\")\n  .get(requireKey, async (req, res) => {\n    const limit = limitFrom(req.query);\n    if (limit === null) return res.status(400).json({ error: \"limit must be a whole number from 1 to 100\" });\n    res.set(\"cache-control\", \"no-store\").json((await store.all()).slice(0, limit));\n  })\n  .post(async (req, res) => {\n    const problems = problemsWith(req.body);\n    if (problems.length) return res.status(400).json({ error: \"the link was not created\", problems });\n    const link = await store.add(req.body.url);\n    res.status(201).location(`/links/${link.code}`).json(link);\n  })\n  .all((req, res) => res.set(\"allow\", \"GET, POST\").status(405).json({ error: \"method not allowed\" }));", "note": "**A lista nunca vai para cache** (`no-store`): ela é a visão do administrador, e uma cópia deixada num proxy ou num navegador sobreviveria à chave que a buscou. Criar responde 400 com a lista inteira de problemas."},
 {"code": "links\n  .route(\"/:code\")\n  .get(async (req, res) => {\n    const link = await store.find(req.params.code);\n    if (!link) return res.status(404).json({ error: `no link ${req.params.code}` });\n    res.json(link);\n  })\n  .delete(requireKey, async (req, res) => {\n    if (!(await store.remove(req.params.code))) return res.status(404).json({ error: `no link ${req.params.code}` });\n    res.status(204).end();\n  })\n  .all((req, res) => res.set(\"allow\", \"GET, DELETE\").status(405).json({ error: \"method not allowed\" }));", "note": "Um link, como na aula 6."}
]}
```

Com o `server.js` rodando:

```
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"ur1": "https://example.com/"}' http://127.0.0.1:3000/links
{"error":"the link was not created","problems":["unknown field \"ur1\"","url is required, as a string"]}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": 42, "note": "hi"}' http://127.0.0.1:3000/links
{"error":"the link was not created","problems":["unknown field \"note\"","url is required, as a string"]}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '["https://example.com/"]' http://127.0.0.1:3000/links
{"error":"the link was not created","problems":["send a JSON object"]}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "ftp://example.com/file"}' http://127.0.0.1:3000/links
{"error":"the link was not created","problems":["url must be an http or https address"]}
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/links
201
```

**Cada resposta diz o que corrigir, com o nome do campo.** Um cliente com três erros fica sabendo dos
três numa requisição só, e nada chegou ao store até não haver nenhum.

Escrita à mão, são umas vinte linhas para um corpo com um campo. Um serviço com muitos corpos usa uma
biblioteca de esquemas — Zod, Ajv e Joi são as comuns — que descreve o formato uma vez e produz a mesma
lista de problemas a partir dele. As regras acima são as mesmas com qualquer uma: lista do permitido,
tipos primeiro, um limite em todo tamanho.
