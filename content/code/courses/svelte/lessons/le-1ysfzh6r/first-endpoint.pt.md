---
title: Uma rota que responde com dados
version: 1
---

**Um arquivo `+server.js` cria uma rota que responde com o que ele devolver, em vez de uma página.** Ele
exporta uma função por método HTTP, `GET`, `POST` e os outros, cada uma chamada com o mesmo `event` que
uma função load de servidor recebe e cada uma devolvendo um `Response` comum. Nada é renderizado, nenhum
layout o envolve, e o SvelteKit não acrescenta nada ao corpo. Uma rota assim costuma ser chamada de
**endpoint**, ou rota de API.

Esta aula volta a ser sobre escrever código, então ela volta ao servidor de desenvolvimento: pare o
servidor de build com Ctrl-C e rode `npm run dev` no lugar dele. Os hooks da aula 16 rodam lá também.

Os dados do planner já estiveram em `/planner.json`, como um arquivo em `static`, até a aula 13 levá-los
para onde só o servidor consegue ler. Um endpoint pode devolvê-los a esse endereço, produzidos pelo
servidor com a mesma função que as páginas usam. Salve isto como `src/routes/planner.json/+server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/planner.json/+server.js", "parts": [
 {"code": "// +server.js: the planner's data, as JSON, at /planner.json.\nimport { json } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';"},
 {"code": "export async function GET() {", "note": "A pasta se chama `planner.json`, então o endereço é `/planner.json`. O ponto faz parte do nome, como qualquer outro caractere."},
 {"code": "\treturn json(await readPlanner());\n}", "note": "`json()` é um `Response` com o corpo escrito em JSON e o cabeçalho `Content-Type` dizendo isso."}
]}
```

```
ana@dev:~/planner$ curl -si http://localhost:5173/planner.json | head -7
HTTP/1.1 200 OK
Vary: Origin
content-length: 573
content-type: application/json
referrer-policy: same-origin
x-content-type-options: nosniff
x-frame-options: DENY
```

**`application/json`, com os cabeçalhos da aula 16**: os hooks rodam para endpoints do mesmo jeito que
para páginas. (O `Vary: Origin` é do próprio servidor de desenvolvimento, e um build não o manda.) O
corpo é o arquivo, todo curso e toda sessão, então outro programa consegue ler o planner sem saber nada
do HTML dele.

O aviso da aula 13 sobre funções load de servidor vale aqui palavra por palavra: **o que um endpoint
devolve, qualquer um que alcance o endereço consegue ler.** O planner não tem nada privado. Uma aplicação
com usuários confere quem está pedindo no começo de todo `GET`, ou num hook, antes de ler qualquer coisa,
porque um endpoint não tem página em volta atrás da qual se esconder, e nenhum link precisa apontar para
ele para alguém achá-lo.
