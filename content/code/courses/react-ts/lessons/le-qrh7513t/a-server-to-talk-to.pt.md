---
title: Um servidor com quem conversar
version: 1
---

**Até agora o planejador lia um arquivo e guardava toda mudança na memória, então recarregar
perdia tudo.** Um app de verdade manda as mudanças a um servidor e as lê de volta. Esta aula dá ao
planejador uma API pequena, escrita só com os módulos do próprio Node para que cada linha dela esteja
aqui, e depois deixa uma biblioteca conversar com ela. Salve como `server/api.mjs`, ao lado de `src/`
e fora dela, porque ela roda no Node e nunca chega a um navegador:

```javascript
// server/api.mjs: the planner's API, from lesson 11 on. Node.js and nothing else.
//
//   node server/api.mjs      listens on http://localhost:3001
//
// It keeps the planner in data/planner.json, made from public/courses.json the
// first time. DELAY=ms makes every answer wait that long, to see loading states.
import { randomUUID } from 'node:crypto'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { createServer } from 'node:http'

const DATA = new URL('../data/planner.json', import.meta.url)
const SEED = new URL('../public/courses.json', import.meta.url)
const DELAY = Number(process.env.DELAY ?? 0)

async function load() {
  try {
    return JSON.parse(await readFile(DATA, 'utf8'))
  } catch {
    return JSON.parse(await readFile(SEED, 'utf8'))
  }
}

async function save(planner) {
  await mkdir(new URL('.', DATA), { recursive: true })
  await writeFile(DATA, JSON.stringify(planner, null, 2) + '\n')
}

async function readBody(request) {
  let text = ''
  for await (const chunk of request) text += chunk
  return text ? JSON.parse(text) : {}
}

function send(response, status, body) {
  response.writeHead(status, { 'content-type': 'application/json' })
  response.end(JSON.stringify(body))
}

createServer(async (request, response) => {
  await new Promise((resolve) => setTimeout(resolve, DELAY))
  const url = new URL(request.url, 'http://localhost')
  console.log(request.method, url.pathname)
  const planner = await load()

  if (request.method === 'GET' && url.pathname === '/api/planner') {
    return send(response, 200, planner)
  }

  if (request.method === 'POST' && url.pathname === '/api/sessions') {
    const { course, date, minutes } = await readBody(request)
    const valid =
      planner.courses.some((c) => c.id === course) &&
      /^\d{4}-\d\d-\d\d$/.test(date) &&
      Number.isInteger(minutes) && minutes >= 5 && minutes <= 240
    if (!valid) return send(response, 400, { error: 'not a valid session' })
    const session = { id: randomUUID(), course, date, minutes, done: false }
    planner.sessions.push(session)
    await save(planner)
    return send(response, 201, session)
  }

  const match = url.pathname.match(/^\/api\/sessions\/([\w-]+)$/)
  if (request.method === 'PATCH' && match) {
    const session = planner.sessions.find((s) => s.id === match[1])
    if (!session) return send(response, 404, { error: 'no such session' })
    const { done } = await readBody(request)
    if (typeof done !== 'boolean') return send(response, 400, { error: 'done must be true or false' })
    session.done = done
    await save(planner)
    return send(response, 200, session)
  }

  send(response, 404, { error: 'not found' })
}).listen(3001, () => console.log('planner API on http://localhost:3001'))
```

Três rotas, que é tudo de que o planejador precisa: **`GET /api/planner`** responde os cursos e as
sessões, **`POST /api/sessions`** acrescenta uma, e **`PATCH /api/sessions/:id`** muda se uma está
feita. Os dados começam como cópia do `public/courses.json` e são gravados em `data/planner.json` a
partir da primeira mudança, então sobrevivem a um reinício. O `DELAY` deixa cada resposta mais lenta
de propósito, o que a aula 13 usa.

**O servidor confere tudo o que recebe**, como o formulário da aula 10 fazia. As conferências do
formulário são para quem digita; estas são para o que quer que chegue ao servidor, que pode nem ser o
formulário. As ferramentas de desenvolvedor de um navegador mandam qualquer requisição, e uma API que
confiasse no próprio front-end aceitaria qualquer coisa que elas mandassem.

O `data/` guarda estado, não código, então vai no `.gitignore`. Depois inicie o servidor num terminal
próprio, e pergunte algo a ele de outro:

```
ana@dev:~/planner$ printf 'data/\n' >> .gitignore && tail -n 2 .gitignore
*.sw?
data/
ana@dev:~/planner$ node server/api.mjs
ana@dev:~/planner$ curl -s http://localhost:3001/api/planner | head -c 160; echo
{"courses":[{"id":"statistics","name":"Statistics"},{"id":"spanish","name":"Spanish"},{"id":"chemistry","name":"Organic chemistry"}],"sessions":[{"id":"s1","cou
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -X PATCH http://localhost:3001/api/sessions/s2 -H 'content-type: application/json' -d '{"done":true}'
{"id":"s2","course":"statistics","date":"2026-10-21","minutes":40,"done":true} 200
ana@dev:~/planner$ curl -s -X PATCH http://localhost:3001/api/sessions/s2 -H 'content-type: application/json' -d '{"done":"yes"}' -w ' %{http_code}\n'
{"error":"done must be true or false"} 400
ana@dev:~/planner$ curl -s -X POST http://localhost:3001/api/sessions -H 'content-type: application/json' -d '{"course":"statistics","date":"","minutes":30}' -w ' %{http_code}\n'
{"error":"not a valid session"} 400
ana@dev:~/planner$ ls data
planner.json
----- the API terminal
planner API on http://localhost:3001
GET /api/planner
PATCH /api/sessions/s2
PATCH /api/sessions/s2
POST /api/sessions
```

Uma mudança boa responde 200 com a sessão como ela está agora; uma malformada, `"yes"` em vez de
`true`, e uma data vazia respondem 400 com uma frase; e o terminal do próprio servidor registra cada
requisição. O arquivo em `data/` agora existe.

## Um endereço para os dois

A página é servida em `localhost:5173` e a API em `localhost:3001`. Uma página que buscasse em outra
porta estaria fazendo uma requisição de outra origem, o que o navegador só permite se o servidor
disser que pode nos cabeçalhos dele, e esse é assunto do `front-quality`. Em desenvolvimento a
resposta mais simples é fazer o servidor da própria página repassar o `/api`, que é o que o **proxy**
do Vite faz. No `vite.config.ts`:

```typescript
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': 'http://localhost:3001',
    },
  },
})
```

O Vite se reinicia sozinho quando a configuração muda. Daí em diante, uma requisição a `/api/planner`
mandada ao Vite é encaminhada à porta 3001, e a página nunca fica sabendo que há dois servidores:

```
ana@dev:~/planner$ curl -s http://localhost:5173/api/planner | head -c 80; echo
{"courses":[{"id":"statistics","name":"Statistics"},{"id":"spanish","name":"Span
```

A aula 20 diz mais sobre o proxy e o que o substitui num build.
