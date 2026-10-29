---
title: Chaves, o nome com que os dados andam
version: 1
---

**Todo `useFetch` e `useAsyncData` guarda os seus dados sob uma chave, e a chave decide três coisas:
onde o payload guarda a resposta, quais chamadas a compartilham e quando ela é buscada de novo.** O
`useFetch` faz a chave a partir da URL e das opções; o `useAsyncData` a recebe como primeiro
argumento.

A página do curso mostra a chave em ação. Ela buscava o planner inteiro e ficava com um curso dele, o
que punha as sessões de todos os cursos no payload de cada página de curso. Uma rota para um curso
resolve isso:

```typescript
// server/api/courses/[id].get.ts: GET /api/courses/spanish, one course and its sessions.
export default defineEventHandler((event) => {
  const id = getRouterParam(event, 'id')
  const course = planner.courses.find((c) => c.id === id)
  if (!course) {
    throw createError({ statusCode: 404, statusMessage: `No course called ${id}` })
  }
  return { course, sessions: planner.sessions.filter((s) => s.course === id) }
})
```

e a página a pede com uma URL que é uma função da rota:

```html
<!-- app/pages/courses/[id].vue: one course, at /courses/statistics and the like -->
<script setup lang="ts">
const route = useRoute()
const { data, error, refresh } = await useFetch(() => `/api/courses/${route.params.id}`)
if (error.value) {
  throw createError({ statusCode: error.value.statusCode, statusMessage: error.value.statusMessage })
}
const sessions = computed(() =>
  (data.value?.sessions ?? []).toSorted((a, b) => a.date.localeCompare(b.date)),
)

async function toggle(id: string) {
  await $fetch(`/api/sessions/${id}`, { method: 'PATCH' })
  await refresh()
}
</script>

<template>
  <h1>{{ data?.course.title }}</h1>
  <p>Goal: {{ data?.course.goal }} minutes a week</p>
  <ul>
    <SessionRow
      v-for="s in sessions"
      :key="s.id"
      :session="s"
      :title="data?.course.title ?? s.course"
      @toggle="toggle"
    />
  </ul>
</template>
```

**Uma função como URL torna a chave reativa**: quando o `id` da rota muda, a URL muda, e a chave
também, e o `useFetch` busca o curso novo sozinho. Visite dois cursos, um depois do outro, dentro de
uma página:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --do 'click text=Spanish' --do 'click .brand a' --do 'click text=Guitar' --text main | grep '/api/\|^-- '
-- click text=Spanish
net  GET /api/courses/spanish  200
-- click .brand a
net  GET /api/courses  200
-- click text=Guitar
net  GET /api/courses/guitar  200
```

Uma requisição por página mostrada, cada uma para o seu endereço. A semana, visitada no meio, também
perguntou: os dados dela vieram com a página quando a página foi carregada pela primeira vez, e uma
navegação de volta para ela roda o seu `useFetch` no navegador, sob a chave da própria semana.

## Uma chave, dois sentidos

Uma chave que duas chamadas compartilham é um dado só, o que é o objetivo quando as duas querem dizer
a mesma coisa, e um bug quando não querem. Duas chamadas de `useAsyncData` com o mesmo nome, numa
página feita para isso:

```html
<!-- app/pages/demo/clash.vue: two different things under one key -->
<script setup lang="ts">
const { data: count } = await useAsyncData('planner', () =>
  $fetch('/api/courses').then((planner) => planner.sessions.length),
)
const { data: planner } = await useAsyncData('planner', () => $fetch('/api/courses'))
</script>

<template>
  <p>{{ count }} sessions in {{ planner?.courses?.length }} courses</p>
</template>
```

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/demo/clash --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
[warn] [NUXT_E3004] Incompatible options detected for "planner":
- different handler
├▶ fix: You can use a different key or move the call to a composable to ensure the options are shared across calls.
╰▶ sources: http://localhost:3000/_nuxt/pages/demo/clash.vue:10:76
== the text of main
6 sessions in courses
```

**`NUXT_E3004`, e uma página com um buraco.** A segunda chamada achou a chave ocupada por uma função
diferente, avisou e recebeu os dados da primeira chamada, um número, que não tem `courses`. Chaves
escritas à mão precisam ser nomes que ninguém mais vai escolher, e o jeito mais seguro de conseguir
isso é um composable por dado, `useSessionCount()`, para que a chave seja escrita uma vez. Apague a
demonstração:

```
ana@dev:~/vue/planner-nuxt$ rm -r app/pages/demo
```
