---
title: O planner no Nuxt
version: 1
---

**As duas páginas agora leem os dados do servidor e os desenham com os componentes trazidos para cá.**
Primeiro a configuração ganha uma linha, a folha de estilo do planner, que `app/assets/` guarda e de que
toda página precisa. Uma folha de estilo listada em `css` é carregada em toda página, como fazia o import
no `main.ts` do planner do Vite:

```typescript
// nuxt.config.ts: the study planner, made by Nuxt.
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  // Off, as lesson 1 left Vue's: a button and requests of their own in every page.
  devtools: { enabled: false },
  css: ['~/assets/main.css'],
  app: {
    head: { htmlAttrs: { lang: 'en' }, title: 'Study planner' },
  },
})
```

O `~` é a pasta `app`, a versão do Nuxt do alias `@` da aula 1.

## A semana

```html
<!-- app/pages/index.vue: the week, at / -->
<script setup lang="ts">
const { data, refresh } = await useFetch('/api/courses')
const monday = ref(weekStart(new Date()))
const today = isoDate(new Date())

const sessions = computed(() => data.value?.sessions ?? [])
const titles = computed(() => Object.fromEntries((data.value?.courses ?? []).map((c) => [c.id, c.title])))
const thisWeek = computed(() =>
  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),
)
const perCourse = computed(() =>
  (data.value?.courses ?? []).map((course) => ({
    ...course,
    ...weekTotal(
      sessions.value.filter((s) => s.course === course.id),
      monday.value,
    ),
  })),
)
const total = computed(() => weekTotal(sessions.value, monday.value))

async function toggle(id: string) {
  await $fetch(`/api/sessions/${id}`, { method: 'PATCH' })
  await refresh()
}
</script>

<template>
  <h1>This week</h1>
  <PlannerPanel title="Courses">
    <ul>
      <CourseCard
        v-for="course in perCourse"
        :key="course.id"
        :id="course.id"
        :title="course.title"
        :goal="course.goal"
        :planned="course.planned"
        :done="course.done"
      />
    </ul>
  </PlannerPanel>
  <PlannerPanel :title="`Week of ${formatDay(monday)}`">
    <template #actions>
      <nav aria-label="Weeks">
        <button @click="monday = addDays(monday, -7)">Previous week</button>
        <button @click="monday = addDays(monday, 7)">Next week</button>
      </nav>
    </template>
    <ul v-if="thisWeek.length > 0">
      <SessionRow
        v-for="session in thisWeek"
        :key="session.id"
        :session="session"
        :title="titles[session.course] ?? session.course"
        :today="session.date === today"
        @toggle="toggle"
      />
    </ul>
    <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>
  </PlannerPanel>
</template>
```

O template é o `HomeView` do planner do Vite sem o diálogo da aula 15, e o script é mais curto do que
era, porque três coisas saíram dele. Os dados vêm de **`useFetch('/api/courses')`**, que pede ao endpoint
do servidor e devolve uma ref, `data`, e uma função, `refresh`, que pede de novo. A aula 20 desmonta o
`useFetch`: por que ele é aguardado no topo de um script, e o que ele faz que um `fetch` no `onMounted`
não faria. Marcar uma sessão é `$fetch`, o `fetch` do Nuxt que lança erro num status de erro e
interpreta o JSON, depois um `refresh()` para a página mostrar o que o servidor tem agora. E todo
auxiliar, `weekStart`, `isoDate`, `formatDay`, `weekTotal`, é importado automaticamente de
`shared/utils`.

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of main
This week
Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

Guitar

0 of 20 minutes done, goal 90

 0% of the weekly goal

Week of 19 October 2026
Previous weekNext week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
75 of 195 minutes done
```

A mesma semana que o planner do Vite mostrava, com os totais da aula 3. Marque a sessão do dia 21 e
carregue a página de novo a partir do servidor, com `goto`, como faria outra visita:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --do 'check label:has-text("21 October") input' --do 'wait 500' --do 'goto /' --text 'main section:nth-child(3) footer'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
-- check label:has-text("21 October") input
-- wait 500
-- goto /
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of main section:nth-child(3) footer
135 of 195 minutes done
```

**A página carregada de novo ainda tem a marcação**, 135 de 195: ela está na memória do servidor, não no
`localStorage` de um navegador, então um segundo navegador, ou o `curl`, também a vê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Onde ficam os dados do planner em Nuxt. Quando o servidor inicia, o server/utils/planner-data.ts copia o server/data/courses.json para a memória. A página da semana pede GET /api/courses com o useFetch e desenha o que volta; marcar uma sessão envia PATCH /api/sessions/s4, que muda a cópia na memória, e a página então atualiza. Um segundo navegador que pede GET /api/courses recebe a mesma cópia. Reiniciar o servidor copia o courses.json de novo.\"><rect x=\"20\" y=\"40\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">navegador</text><text x=\"115\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pages/index.vue</text><rect x=\"20\" y=\"160\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">outro navegador</text><rect x=\"270\" y=\"25\" width=\"270\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"405\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">Nitro, o servidor</text><rect x=\"290\" y=\"60\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">api/courses.get.ts</text><rect x=\"290\" y=\"100\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">api/sessions/[id].patch.ts</text><rect x=\"290\" y=\"160\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">planner</text><text x=\"405\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a cópia na memória</text><line x1=\"405\" y1=\"92\" x2=\"405\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"520\" y1=\"115\" x2=\"540\" y2=\"115\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"540\" y1=\"75\" x2=\"540\" y2=\"183\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"540\" y1=\"75\" x2=\"522\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"522.0,75.0 529.4,71.9 529.4,78.1\" fill=\"var(--wire)\"></polygon><line x1=\"540\" y1=\"183\" x2=\"522\" y2=\"183\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"522.0,183.0 529.4,179.9 529.4,186.1\" fill=\"var(--wire)\"></polygon><rect x=\"580\" y=\"160\" width=\"125\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"642\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses.json</text><text x=\"642\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lido ao iniciar</text><line x1=\"578\" y1=\"183\" x2=\"524\" y2=\"183\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"524.0,183.0 531.4,179.9 531.4,186.1\" fill=\"var(--amber)\"></polygon><line x1=\"212\" y1=\"66\" x2=\"288\" y2=\"66\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"288.0,66.0 280.6,69.1 280.6,62.9\" fill=\"var(--phosphor)\"></polygon><text x=\"250\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">GET</text><line x1=\"212\" y1=\"106\" x2=\"288\" y2=\"106\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"288.0,106.0 280.6,109.1 280.6,102.9\" fill=\"var(--phosphor)\"></polygon><text x=\"250\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">PATCH</text><line x1=\"212\" y1=\"180\" x2=\"288\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"288.0,80.0 286.0,87.8 281.1,84.0\" fill=\"var(--wire)\"></polygon></svg>", "caption": "Todo navegador lê a única cópia do servidor, e reiniciar recomeça a partir do arquivo."}
```

Desmarque, para que os dados fiquem como o `courses.json` os tem:

```
ana@dev:~/vue/planner-nuxt$ curl -s -X PATCH http://localhost:3000/api/sessions/s4 | grep done
  "done": false
```

## Um curso, e um que não existe

```html
<!-- app/pages/courses/[id].vue: one course, at /courses/statistics and the like -->
<script setup lang="ts">
const route = useRoute()
const { data, refresh } = await useFetch('/api/courses')
const course = computed(() => data.value?.courses.find((c) => c.id === route.params.id))
if (!course.value) {
  throw createError({ statusCode: 404, statusMessage: `No course called ${route.params.id}` })
}
const sessions = computed(() =>
  (data.value?.sessions ?? [])
    .filter((s) => s.course === route.params.id)
    .toSorted((a, b) => a.date.localeCompare(b.date)),
)

async function toggle(id: string) {
  await $fetch(`/api/sessions/${id}`, { method: 'PATCH' })
  await refresh()
}
</script>

<template>
  <h1>{{ course?.title }}</h1>
  <p>Goal: {{ course?.goal }} minutes a week</p>
  <ul>
    <SessionRow v-for="s in sessions" :key="s.id" :session="s" :title="course!.title" @toggle="toggle" />
  </ul>
</template>
```

`throw createError(...)` no setup de uma página interrompe a página e desenha o `error.vue` com esse
status, a mesma função que a rota do servidor usou. Como a página também é desenhada no servidor, o `404`
é o status HTTP da resposta, não só uma mensagem na tela:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/courses/spanish --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of main
Spanish

Goal: 120 minutes a week

 19 October 2026, Spanish, 30 minutes
 23 October 2026, Spanish, 40 minutes
```

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/courses/piano --text main
[error] Failed to load resource: the server responded with a status of 404 (No course called piano)
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of main
Nothing here

No course called piano

Back to this week
```

**`No course called piano`, num `404`**, onde a aula 12 precisou de um guard, uma rota catch-all e uma
página `not-found` para dizer o mesmo, e ainda respondia `200`.

O planner agora existe duas vezes. O do Vite desenha tudo no navegador a partir de um arquivo; o do Nuxt
é desenhado primeiro pelo servidor, a partir de dados que o servidor tem. A aula 19 olha o que é esse
primeiro desenho, o que o navegador faz com ele, e onde os dois podem discordar.
