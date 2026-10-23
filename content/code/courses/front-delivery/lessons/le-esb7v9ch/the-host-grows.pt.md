---
title: O host cresce: regras e HTTPS
version: 1
---

**O resto desta aula precisa de duas coisas do `host.mjs` que um host de verdade tem e ele ainda não: um
arquivo de regras, e HTTPS.** Este é o arquivo inteiro de novo, crescido para umas noventa linhas. As
partes da aula 1 estão iguais; as partes novas leem um arquivo `_redirects` no formato que a Netlify e o
Cloudflare Pages usam, e servem por TLS quando recebem um certificado. Troque o arquivo antigo por ele:

```schooling-example
{"language": "javascript", "file": "host.mjs", "parts": [
 {"code": "// host.mjs\nimport { createServer } from \"node:http\";\nimport { createServer as createSecureServer } from \"node:https\";\nimport { readFile } from \"node:fs/promises\";\nimport { extname, join, normalize } from \"node:path\";\n\nconst root = process.argv[2] ?? \"dist\";\nconst port = Number(process.argv[3] ?? 8080);\nconst types = {\n  \".html\": \"text/html; charset=utf-8\",\n  \".js\": \"text/javascript; charset=utf-8\",\n  \".css\": \"text/css; charset=utf-8\",\n  \".json\": \"application/json\",\n  \".svg\": \"image/svg+xml\",\n};", "note": "Como na aula 1, mais `node:https`, o servidor TLS do próprio Node, que recebe um certificado e uma chave e no resto se comporta como o `node:http`."},
 {"code": "\nasync function load(path) {\n  if (path === \"/_redirects\") return null;\n  const file = join(root, normalize(path));\n  for (const candidate of [file, join(file, \"index.html\")]) {\n    try {\n      return { body: await readFile(candidate), type: types[extname(candidate)] ?? \"application/octet-stream\" };\n    } catch {\n      // not there, or a folder: try the next candidate\n    }\n  }\n  return null;\n}", "note": "Igual, a não ser pela primeira linha: o arquivo de regras é lido pelo host e nunca servido, que é o que a Netlify e a Cloudflare também fazem com ele."},
 {"code": "\nasync function rules() {\n  const text = await readFile(join(root, \"_redirects\"), \"utf8\").catch(() => \"\");\n  return text\n    .split(\"\\n\")\n    .map((line) => line.trim())\n    .filter((line) => line && !line.startsWith(\"#\"))\n    .map((line) => {\n      const [from, to, status = \"301\"] = line.split(/\\s+/);\n      return { from, to, status: Number(status) };\n    });\n}", "note": "Uma regra por linha: de onde, para onde, e um status que vale 301 por padrão. Um arquivo ausente é nenhuma regra, então um site sem ele é servido exatamente como antes. Linhas que começam com `#` são comentários."},
 {"code": "\nfunction target(rule, path) {\n  if (!rule.from.endsWith(\"*\")) return path === rule.from ? rule.to : null;\n  const prefix = rule.from.slice(0, -1);\n  return path.startsWith(prefix) ? rule.to.replace(\":splat\", path.slice(prefix.length)) : null;\n}", "note": "Uma regra bate com um caminho exatamente, ou pelo começo quando termina em `*`, o **splat**. O que o `*` casou substitui `:splat` no destino."},
 {"code": "\nasync function handle(request, response) {\n  const path = new URL(request.url, \"http://host\").pathname;\n  let found = await load(path);\n  for (const rule of found ? [] : await rules()) {\n    const to = target(rule, path);\n    if (to === null) continue;\n    if (rule.status === 200) {\n      found = await load(to);\n      break;\n    }\n    response.writeHead(rule.status, { location: to });\n    response.end();\n    console.log(rule.status, request.method, path, \"->\", to);\n    return;\n  }", "note": "Um arquivo que existe ganha, e as regras só são lidas quando não há nenhum. A primeira regra que bate decide: um 200 é uma **reescrita**, que serve outro arquivo no mesmo endereço; qualquer outro status é um **redirecionamento**, que manda o navegador para outro lugar."},
 {"code": "  if (found) {\n    response.writeHead(200, { \"content-type\": found.type });\n    response.end(found.body);\n  } else {\n    const page = await load(\"/404.html\");\n    response.writeHead(404, { \"content-type\": \"text/html; charset=utf-8\" });\n    response.end(page?.body ?? \"not found\\n\");\n  }\n  console.log(response.statusCode, request.method, path);\n}", "note": "O fim do tratador da aula 1, igual."},
 {"code": "\nif (process.env.CERT) {\n  const options = { cert: await readFile(process.env.CERT), key: await readFile(process.env.KEY) };\n  createSecureServer(options, handle).listen(port, \"127.0.0.1\");", "note": "Com `CERT` e `KEY` no ambiente, o mesmo tratador é servido por HTTPS na porta dada."},
 {"code": "  createServer((request, response) => {\n    const host = (request.headers.host ?? \"\").replace(/:\\d+$/, \"\");\n    response.writeHead(308, { location: `https://${host}:${port}${request.url}` });\n    response.end();\n    console.log(308, request.method, request.url, \"-> https\");\n  }).listen(8080, \"127.0.0.1\");\n  console.log(`serving ${root} on https://127.0.0.1:${port}, and redirecting http://127.0.0.1:8080`);", "note": "E o HTTP simples na 8080 responde a toda requisição com um redirecionamento para o mesmo caminho por HTTPS, que é o que todo host faz na porta 80."},
 {"code": "} else {\n  createServer(handle).listen(port, \"127.0.0.1\", () => console.log(`serving ${root} on http://127.0.0.1:${port}`));\n}", "note": "Sem certificado, é o servidor da aula 1, com regras."}
]}
```

**A regra de que arquivos ganham é uma escolha, e os hosts divergem nela.** A Netlify só lê uma regra
quando nenhum arquivo bate com o caminho, a menos que o status venha seguido de `!`, o que ela chama de
forçar. O Cloudflare Pages documenta o contrário para os redirecionamentos dele: eles valem havendo
arquivo ou não. Este servidor faz o que a Netlify faz, porque é o comportamento que impede uma regra ampla
como `/*` de engolir os scripts do próprio site. Quando escrever regras para a Cloudflare, escreva de modo
que a ordem não importe.

Faça o commit da versão nova:

```
ana@dev:~/planner$ git add host.mjs
ana@dev:~/planner$ git commit -qm "Rules and HTTPS for the host"
```
