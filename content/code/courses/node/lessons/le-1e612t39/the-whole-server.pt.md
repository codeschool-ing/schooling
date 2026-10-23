---
title: O serviço links, sem nada instalado
version: 1
---

**Tudo o que esta aula mostrou, junto, é um encurtador de links funcionando num arquivo só.** Ele
guarda os links num `Map`, então eles duram enquanto o processo durar; a aula 8 lhe dá um arquivo.
Salve-o como `~/server/native/server.js`:

```schooling-example
{"language": "javascript", "file": "server.js", "parts": [
 {"code": "// server.js: the links service with nothing but node:http.\nimport http from \"node:http\";\nimport { randomInt } from \"node:crypto\";\n\nconst ALPHABET = \"23456789abcdefghjkmnpqrstuvwxyz\";\nconst links = new Map(); // code -> { code, url, visits, created }\n\nfunction makeCode() {\n  let code;\n  do {\n    code = Array.from({ length: 6 }, () => ALPHABET[randomInt(ALPHABET.length)]).join(\"\");\n  } while (links.has(code));\n  return code;\n}", "note": "O alfabeto do `src/code.js` da aula 4, e o armazenamento: um `Map` de um código para o link dele. Um código novo é sorteado de novo se já estiver em uso, o que com 890 milhões de códigos quase nunca acontece e não custa nada conferir."},
 {"code": "function send(res, status, body, headers = {}) {\n  const text = body === undefined ? \"\" : JSON.stringify(body) + \"\\n\";\n  res.writeHead(status, {\n    ...(text && { \"content-type\": \"application/json; charset=utf-8\" }),\n    \"content-length\": Buffer.byteLength(text),\n    ...headers,\n  });\n  res.end(text);\n}", "note": "**Uma função escreve todas as respostas**, então toda resposta tem os mesmos cabeçalhos: um tipo JSON quando há corpo, um `content-length` contado em bytes, e o que mais a rota acrescentar."},
 {"code": "class HttpError extends Error {\n  constructor(status, message) {\n    super(message);\n    this.status = status;\n  }\n}", "note": "Um erro que carrega o próprio status. Uma rota lança um quando o cliente pediu algo errado, e a borda do servidor o transforma numa resposta."},
 {"code": "async function readJson(req, limit = 1024) {\n  if (!(req.headers[\"content-type\"] || \"\").startsWith(\"application/json\")) {\n    throw new HttpError(415, \"send JSON, with content-type: application/json\");\n  }\n  const chunks = [];\n  let size = 0;\n  for await (const chunk of req) {\n    size += chunk.length;\n    if (size > limit) throw new HttpError(413, `a body may be at most ${limit} bytes`);\n    chunks.push(chunk);\n  }\n  try {\n    return JSON.parse(Buffer.concat(chunks).toString(\"utf8\"));\n  } catch {\n    throw new HttpError(400, \"the body is not valid JSON\");\n  }\n}", "note": "As três conferências da seção sobre ler um corpo, agora lançando erro em vez de devolver."},
 {"code": "function isWebAddress(text) {\n  try {\n    const url = new URL(text);\n    return url.protocol === \"http:\" || url.protocol === \"https:\";\n  } catch {\n    return false;\n  }\n}", "note": "**O serviço redireciona para o que guardou**, então ele só guarda endereços web. Uma URL `javascript:` ou `file:` guardada aqui seria entregue a todo navegador que seguisse o link."},
 {"code": "async function handle(req, res) {\n  const { pathname } = new URL(req.url, \"http://localhost\");\n  const parts = pathname.split(\"/\").filter(Boolean).map(decodeURIComponent);\n\n  if (parts.length === 1 && parts[0] === \"links\") {\n    if (req.method === \"GET\") return send(res, 200, [...links.values()]);\n    if (req.method === \"POST\") {\n      const body = await readJson(req);\n      if (!isWebAddress(body?.url)) throw new HttpError(400, \"url must be an http or https address\");\n      const link = { code: makeCode(), url: body.url, visits: 0, created: new Date().toISOString() };\n      links.set(link.code, link);\n      return send(res, 201, link, { location: `/links/${link.code}` });\n    }\n    return send(res, 405, { error: \"method not allowed\" }, { allow: \"GET, POST\" });\n  }", "note": "As rotas, pelo número de partes do caminho e pelo método. `/links` lista e cria; um link novo responde 201 com um `location` dizendo onde ele passou a morar."},
 {"code": "  if (parts.length === 2 && parts[0] === \"links\") {\n    const link = links.get(parts[1]);\n    if (!link) throw new HttpError(404, `no link ${parts[1]}`);\n    if (req.method === \"GET\") return send(res, 200, link);\n    if (req.method === \"DELETE\") {\n      links.delete(link.code);\n      return send(res, 204);\n    }\n    return send(res, 405, { error: \"method not allowed\" }, { allow: \"GET, DELETE\" });\n  }", "note": "`/links/:code` lê e apaga um link. Um 204 não tem corpo, então o `send` não escreve nem tipo nem texto."},
 {"code": "  if (parts.length === 1 && req.method === \"GET\") {\n    const link = links.get(parts[0]);\n    if (!link) throw new HttpError(404, `no link ${parts[0]}`);\n    link.visits++;\n    return send(res, 302, undefined, { location: link.url });\n  }\n\n  throw new HttpError(404, `nothing at ${pathname}`);\n}", "note": "**O próprio link curto**, `/:code`: conta a visita e responde 302 com o endereço no `location`, que um navegador segue sozinho."},
 {"code": "const server = http.createServer(async (req, res) => {\n  try {\n    await handle(req, res);\n  } catch (err) {\n    if (err instanceof URIError) err = new HttpError(400, \"the path is not valid percent-encoding\");\n    if (!(err instanceof HttpError)) console.error(err);\n    const status = err instanceof HttpError ? err.status : 500;\n    send(res, status, { error: status === 500 ? \"internal error\" : err.message });\n  }\n  console.log(`${req.method} ${req.url} ${res.statusCode}`);\n});\n\nserver.listen(3000, \"127.0.0.1\", () => console.log(\"links on http://127.0.0.1:3000\"));", "note": "A borda. Todo erro vira uma resposta: um `HttpError` diz o próprio status, uma codificação percentual ruim é o 400 do cliente, e qualquer outra coisa vai inteira para o log e é respondida com um 500 curto. Uma linha de log por requisição, depois da resposta."}
]}
```

## Usando

Inicie-o num terminal, e crie um link a partir do outro. O `-i` mostra o status e os cabeçalhos, que
é onde a resposta está:

```
ana@dev:~/server/native$ curl -si -H 'content-type: application/json' -d '{"url": "https://nodejs.org/docs/latest-v22.x/api/"}' http://127.0.0.1:3000/links
HTTP/1.1 201 Created
content-type: application/json; charset=utf-8
content-length: 116
location: /links/tmmzw8
Date: Fri, 16 Oct 2026 23:08:54 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"code":"tmmzw8","url":"https://nodejs.org/docs/latest-v22.x/api/","visits":0,"created":"2026-10-16T23:08:54.326Z"}
```

Agora siga o link, liste os links, e peça coisas que não existem:

```
ana@dev:~/server/native$ curl -si http://127.0.0.1:3000/tmmzw8 | head -3
HTTP/1.1 302 Found
content-length: 0
location: https://nodejs.org/docs/latest-v22.x/api/
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/tmmzw8
{"code":"tmmzw8","url":"https://nodejs.org/docs/latest-v22.x/api/","visits":1,"created":"2026-10-16T23:08:54.326Z"}
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/nope22
{"error":"no link nope22"}
ana@dev:~/server/native$ curl -si -X PUT http://127.0.0.1:3000/links | head -1
HTTP/1.1 405 Method Not Allowed
ana@dev:~/server/native$ curl -s -H 'content-type: application/json' -d '{"url": "javascript:alert(1)"}' http://127.0.0.1:3000/links
{"error":"url must be an http or https address"}
ana@dev:~/server/native$ curl -si -X DELETE http://127.0.0.1:3000/links/tmmzw8 | head -1
HTTP/1.1 204 No Content
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links
[]
```

**A visita foi contada, e cada erro recebeu o próprio status e uma frase.** A URL `javascript:` foi
recusada pelo `isWebAddress`, que é a defesa de que o serviço mais precisa: um encurtador que
guardasse qualquer URL transformaria cada link curto num jeito de entregar a um navegador algo que não
é uma página web.

O terminal do servidor tem uma linha por requisição:

```
ana@dev:~/server/native$ node server.js
links on http://127.0.0.1:3000
POST /links 201
GET /links 200
GET /tmmzw8 302
GET /links/tmmzw8 200
GET /links/nope22 404
PUT /links 405
POST /links 400
DELETE /links/tmmzw8 204
GET /links 200
^C
```

Isso é um serviço completo em cerca de 110 linhas, e é também a lista do que o Express faz por você:
a tabela de rotas, o `send`, o `readJson`, o 404 e o 405, a borda que transforma erros em respostas. A
aula 6 escreve o mesmo serviço de novo, numa fração do código, e cada parte deste arquivo tem uma
contraparte com nome lá.
