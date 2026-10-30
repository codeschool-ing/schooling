---
title: Um pequeno servidor do próprio planner
version: 1
---

**Até agora o planner lia um arquivo que o servidor de desenvolvimento entregava como estava, e nada
que ele mudava sobrevivia a um recarregamento.** Marcar uma sessão como feita mudava um signal no
navegador; recarregue a página e a marcação some, porque o `courses.json` nunca ficou sabendo. Uma
aplicação que guarda o que você faz precisa de alguém do outro lado para guardar. Esta aula escreve
esse alguém: um servidor de umas setenta linhas, em Node.js puro, sem pacote nenhum para instalar.

Os dados vão primeiro. O `git mv` move o arquivo e diz ao git que é o mesmo arquivo com outro nome:

```
ana@dev:~/planner$ mkdir server && git mv public/courses.json server/seed.json
```

O `seed.json` é onde os dados começam. O servidor guarda o que muda num segundo arquivo ao lado,
`planner.json`, feito a partir do seed na primeira vez que roda, então apagar o `planner.json` põe
tudo de volta como o curso começou.

```schooling-example
{"language": "javascript", "file": "server/api.mjs", "parts": [
 {"code": "// server/api.mjs\nimport { createServer } from 'node:http';\nimport { copyFile, readFile, writeFile } from 'node:fs/promises';\nimport { existsSync } from 'node:fs';\n\nconst port = 3000;\nconst seed = new URL('./seed.json', import.meta.url);\nconst file = new URL('./planner.json', import.meta.url);\n\nif (!existsSync(file)) await copyFile(seed, file);\nconst load = async () => JSON.parse(await readFile(file, 'utf8'));\nconst save = (data) => writeFile(file, JSON.stringify(data, null, 2) + '\\n');", "note": "O servidor HTTP e as funções de arquivo do próprio Node. Os dois arquivos são achados ao lado deste, onde quer que o projeto esteja."},
 {"code": "function send(res, status, body) {\n  res.writeHead(status, { 'content-type': 'application/json' });\n  res.end(JSON.stringify(body));\n}\n\nasync function readBody(req) {\n  let text = '';\n  for await (const chunk of req) text += chunk;\n  try {\n    return JSON.parse(text);\n  } catch {\n    return undefined;\n  }\n}", "note": "Toda resposta é JSON, com um status. Um erro também é JSON, `{ \"error\": \"...\" }`, para a aplicação poder mostrar a frase do próprio servidor."},
 {"code": "const server = createServer(async (req, res) => {\n  const { pathname } = new URL(req.url, 'http://localhost');\n  console.log(req.method, pathname, req.headers['x-requested-by'] ?? '-');\n\n  if (req.method === 'GET' && pathname === '/api/planner') {\n    return send(res, 200, await load());\n  }", "note": "Uma linha por pedido: o método, o caminho, e um cabeçalho que o interceptor desta aula vai acrescentar. Até lá é `-`."},
 {"code": "  const one = pathname.match(/^\\/api\\/sessions\\/(\\d+)$/);\n  if (req.method === 'PATCH' && one) {\n    const data = await load();\n    const session = data.sessions.find((s) => s.id === Number(one[1]));\n    if (!session) return send(res, 404, { error: `there is no session ${one[1]}` });\n    const body = await readBody(req);\n    if (typeof body?.done !== 'boolean') return send(res, 400, { error: 'done must be true or false' });\n    session.done = body.done;\n    await save(data);\n    return send(res, 200, session);\n  }", "note": "Marcar uma sessão como feita ou não. O corpo precisa dizer `done` e nada mais vago: `\"yes\"` é recusado com 400, uma sessão desconhecida com 404."},
 {"code": "  if (req.method === 'POST' && pathname === '/api/sessions') {\n    const data = await load();\n    const body = await readBody(req);\n    if (!data.courses.some((c) => c.id === body?.courseId)) return send(res, 400, { error: 'courseId names no course' });\n    if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(body.date ?? '')) return send(res, 400, { error: 'date must be YYYY-MM-DD' });\n    if (!Number.isInteger(body.minutes) || body.minutes < 1) return send(res, 400, { error: 'minutes must be a whole number above 0' });\n    const id = Math.max(0, ...data.sessions.map((s) => s.id)) + 1;\n    const session = { id, courseId: body.courseId, date: body.date, minutes: body.minutes, done: false };\n    data.sessions.push(session);\n    await save(data);\n    return send(res, 201, session);\n  }\n\n  send(res, 404, { error: `nothing answers ${req.method} ${pathname}` });\n});\n\nserver.listen(port, () => console.log(`the planner's API is on http://localhost:${port}`));", "note": "Acrescentar uma sessão, o que o formulário da aula 14 usa. O servidor confere cada campo ele mesmo: o que quer que o formulário tenha conferido, um pedido pode vir de qualquer lugar."}
]}
```

O `planner.json` é a cópia de trabalho do servidor, não parte do programa, então o git o deixa de
fora:

```
ana@dev:~/planner$ echo 'server/planner.json' >> .gitignore
```

O servidor roda num terminal só dele, um terceiro ao lado do do servidor de desenvolvimento, e fica
lá: digite `node server/api.mjs` nele. Ele imprime uma linha para dizer que está escutando.

O `curl` no primeiro terminal faz a ele uma pergunta que ele responde e duas que ele recusa. O
`head -c 120` fica com os primeiros 120 bytes de uma resposta longa, o `-X PATCH -d` manda um método
e um corpo, e o `echo` termina a linha que cada resposta deixa aberta:

```
ana@dev:~/planner$ curl -s http://localhost:3000/api/planner | head -c 120; echo
{"courses":[{"id":"html-css","name":"HTML and CSS"},{"id":"javascript","name":"JavaScript"},{"id":"git","name":"Git"}],"
ana@dev:~/planner$ curl -s -X PATCH http://localhost:3000/api/sessions/5 -d '{"done":"yes"}'; echo
{"error":"done must be true or false"}
ana@dev:~/planner$ curl -s -X PATCH http://localhost:3000/api/sessions/9 -d '{"done":true}'; echo
{"error":"there is no session 9"}
```

O servidor diz o porquê em cada recusa, numa frase que a aplicação pode mostrar. O terminal dele tem
uma linha para cada pedido:

```
ana@dev:~/planner$ node server/api.mjs
the planner's API is on http://localhost:3000
GET /api/planner -
PATCH /api/sessions/5 -
PATCH /api/sessions/9 -
```

## O proxy

A aplicação roda em `localhost:4200` e a API em `localhost:3000`, e para um navegador essas são duas
origens diferentes. Uma página só pode pedir dados a outra origem se essa origem disser que pode, com
cabeçalhos CORS, e este servidor não manda nenhum. Em vez de abrir a API para toda página da
internet, o servidor de desenvolvimento pode repassar pedidos: o navegador pede
`localhost:4200/api/planner`, e o servidor de desenvolvimento busca a resposta na porta 3000 e a
entrega como se fosse dele.

```schooling-example
{"language": "json", "file": "proxy.conf.json", "parts": [
 {"code": "{\n  \"/api\": {\n    \"target\": \"http://localhost:3000\",\n    \"secure\": false\n  }\n}", "note": "Todo pedido cujo caminho começa com `/api` vai para a API; todo o resto é a aplicação, como antes."}
]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O navegador manda todo pedido a um endereço, localhost:4200, o servidor de desenvolvimento. Os pedidos cujo caminho começa com /api o servidor de desenvolvimento repassa à API em localhost:3000, que lê e escreve o planner.json, e a resposta volta pelo mesmo caminho. Todo outro pedido o servidor de desenvolvimento responde sozinho, com os arquivos da aplicação.\"><rect x=\"20\" y=\"90\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">navegador</text><text x=\"85.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma origem</text><rect x=\"250\" y=\"90\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor de dev</text><text x=\"335.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:4200</text><rect x=\"540\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><text x=\"620.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:3000</text><rect x=\"540\" y=\"160\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a aplicação</text><text x=\"620.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main.js, index.html</text><line x1=\"150\" y1=\"112\" x2=\"248\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,112.0 240.6,115.1 240.6,108.9\" fill=\"var(--wire)\"></polygon><line x1=\"250\" y1=\"126\" x2=\"152\" y2=\"126\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"152.0,126.0 159.4,122.9 159.4,129.1\" fill=\"var(--wire)\"></polygon><text x=\"200\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">todo pedido</text><line x1=\"420\" y1=\"104\" x2=\"538\" y2=\"64\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,64.0 532.0,69.3 530.0,63.4\" fill=\"var(--amber)\"></polygon><text x=\"478\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">/api/...</text><line x1=\"420\" y1=\"134\" x2=\"538\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,184.0 530.0,184.0 532.4,178.3\" fill=\"var(--wire)\"></polygon><text x=\"462\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">todo o resto</text><rect x=\"560\" y=\"102\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"620\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner.json</text><line x1=\"620\" y1=\"86\" x2=\"620\" y2=\"100\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"335\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">proxy.conf.json</text><text x=\"335\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">decide para onde</text></svg>", "caption": "O navegador só conversa com localhost:4200; o servidor de desenvolvimento manda /api para a API e responde o resto sozinho.", "same": ["API"]}
```

O `ng config` escreve a configuração no `angular.json` para o comando `serve`, então um `ng serve`
comum a usa:

```
ana@dev:~/planner$ npx ng config projects.planner.architect.serve.options.proxyConfig proxy.conf.json
```

O servidor de desenvolvimento lê o proxy quando inicia, então pare-o com `Ctrl-C` no terminal dele e
inicie de novo com `npx ng serve`. Depois, a mesma pergunta, feita ao endereço da própria aplicação:

```
ana@dev:~/planner$ curl -s http://localhost:4200/api/planner | head -c 120; echo
{"courses":[{"id":"html-css","name":"HTML and CSS"},{"id":"javascript","name":"JavaScript"},{"id":"git","name":"Git"}],"
```

A mesma resposta, pelo servidor de desenvolvimento. Em produção o mesmo arranjo é feito por quem
entrega a aplicação, um servidor web ou o balanceador de carga de uma nuvem, mandando `/api` para a
API e o resto para os arquivos do build. A página nunca fica sabendo que são dois programas, e não há
CORS para configurar, porque só há uma origem.
