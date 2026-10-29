---
title: Rotas do servidor, uma API no mesmo projeto
version: 1
---

**Um arquivo em `server/api/` é um endpoint do servidor que o Nuxt roda, e o nome dele diz o endereço e
o método: `server/api/courses.get.ts` responde `GET /api/courses`.** O planner do Vite lia um arquivo que
o Vite servia de `public`, e não conseguia mudá-lo: marcar uma sessão mudava a cópia do navegador, que a
aula 4 salvava no `localStorage`. Com um servidor próprio, o planner pode guardar os dados onde todo
navegador vê a mesma coisa.

Os dados são o `courses.json` copiado na seção anterior. Um módulo em `server/utils/` os guarda enquanto
o servidor roda, e o `server/utils`, como o `shared/utils`, é importado automaticamente, mas só no código
do servidor:

```typescript
// server/utils/planner-data.ts: the planner's data, held by the server while it runs.
import data from '../data/courses.json'

// A copy, so that a change is made to the server's data and never to the import.
export const planner: { courses: Course[]; sessions: Session[] } = structuredClone(data)
```

O endpoint que os lê tem uma linha:

```typescript
// server/api/courses.get.ts: GET /api/courses, every course and every session.
export default defineEventHandler(() => planner)
```

O `defineEventHandler` recebe uma função do pedido, o *event*, e o que ela devolve é a resposta, um
objeto transformado em JSON. Peça:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/api/courses | head -12
{
  "courses": [
    {
      "id": "statistics",
      "title": "Statistics",
      "goal": 180
    },
    {
      "id": "spanish",
      "title": "Spanish",
      "goal": 120
    },
```

## Uma rota que muda alguma coisa

Marcar uma sessão é um `PATCH` no endereço da própria sessão. Os colchetes funcionam como em `pages`,
então `[id].patch.ts` em `server/api/sessions/` responde `PATCH /api/sessions/s4` e todo outro id:

```typescript
// server/api/sessions/[id].patch.ts: PATCH /api/sessions/s4 ticks or unticks s4.
export default defineEventHandler((event) => {
  const id = getRouterParam(event, 'id')
  if (!planner.sessions.some((s) => s.id === id)) {
    throw createError({ statusCode: 404, statusMessage: `No session ${id}` })
  }
  planner.sessions = toggleDone(planner.sessions, id!)
  return planner.sessions.find((s) => s.id === id)
})
```

O `toggleDone` é o da aula 3, alcançado por `shared/utils`, a mesma função que o navegador chamava. O
handler recusa um id que não tem **antes** de mudar qualquer coisa, com um `404` que o cliente consegue
distinguir de um sucesso. Tente uma sessão real e uma inventada:

```
ana@dev:~/vue/planner-nuxt$ curl -s -X PATCH http://localhost:3000/api/sessions/s4
{
  "id": "s4",
  "course": "statistics",
  "date": "2026-10-21",
  "minutes": 60,
  "done": true
}ana@dev:~/vue/planner-nuxt$ curl -s -X PATCH http://localhost:3000/api/sessions/s99
{
  "error": true,
  "url": "http://localhost:3000/api/sessions/s99",
  "statusCode": 404,
  "statusMessage": "No session s99",
  "message": "No session s99",
  "stack": [
    "No session s99",
    "at createError (/home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:71:15)",
    "at Object.handler (/home/ana/vue/planner-nuxt/server/api/sessions/[id].patch.ts:5:10)",
    "at Object.handler (/home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:1940:24)",
    "at Object.handler (/home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:2263:34)",
    "at /home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:2017:31)",
    "at process.processTicksAndRejections (node:internal/process/task_queues:103:5)",
    "at async Object.callAsync (/home/ana/vue/planner-nuxt/node_modules/nitropack/node_modules/unctx/dist/index.mjs:72:16)",
    "at async Server.toNodeHandle (/home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:2316:7)"
  ]
}ana@dev:~/vue/planner-nuxt$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/api/sessions/s4
404
```

**O s4 está feito agora, e o `s99` é um `404` com a mensagem que o handler escreveu.** Em
desenvolvimento o erro também traz um `stack`, o caminho pelos arquivos do servidor; um build o deixa de
fora, porque os arquivos de um servidor não são da conta de mais ninguém. Um `GET` no mesmo endereço é um
`404` do próprio Nuxt, já que não existe `[id].get.ts`. Marque o s4 de novo para que a próxima seção
comece dos dados como eram:

```
ana@dev:~/vue/planner-nuxt$ curl -s -X PATCH http://localhost:3000/api/sessions/s4 | grep done
  "done": false
```

## O que este servidor ainda não é

**Os dados ficam na memória, então reiniciar o servidor os devolve ao `courses.json`.** Para um planner
usado num computador só, essa é uma troca justa, e um de verdade gravaria num banco de dados, ou num
arquivo pela camada de armazenamento do Nitro. E **qualquer um que alcance a porta 3000 pode marcar a
sessão de qualquer um**: os endpoints conferem que a sessão existe e mais nada. Isso não é problema
enquanto o servidor só responde em `localhost`, que é o que quer dizer o `use --host to expose` no
banner do servidor de desenvolvimento; no dia em que o planner estiver na internet, toda rota que muda
alguma coisa vai precisar saber quem está pedindo, que é o trabalho de um login e fica fora deste curso.
