---
title: Atualizando, e quando a requisição falha
version: 1
---

**O `refresh()` roda a busca de novo e troca `data` pela resposta nova, e `error` guarda o que deu
errado quando não há resposta para dar.** O planner usa o `refresh` desde a aula 18: marque uma
sessão, o `$fetch` manda o `PATCH`, e o `refresh()` lê o planner de novo para que a página mostre o
que o servidor tem agora. São duas requisições por marcação, e é uma escolha: o `PATCH` já responde
com a sessão alterada, e uma página poderia pôr essa sessão em `data` ela mesma. Perguntar de novo é
mais simples e não tem como dar errado quando outra pessoa também mudou alguma coisa.

O servidor do planner nunca falha, e esse é o motivo para fazê-lo falhar. O endpoint da semana, por um
momento, responde como um servidor em manutenção:

```
ana@dev:~/vue/planner-nuxt$ sed -i "s#=> planner)#=> {\n  throw createError({ statusCode: 503, statusMessage: 'Down for maintenance' })\n})#" server/api/courses.get.ts
```

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text main
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of main
This week
Courses
Week of 19 October 2026
Previous weekNext week

Nothing here yet.

0 of 0 minutes done
```

**A página desenhou, com zeros e uma semana vazia, e não disse nada sobre o motivo.** O `useFetch` não
lança erro: ele põe a falha em `error`, deixa `data` como estava, `undefined` aqui, e a página segue
com o que tem. Todo `computed` da página da semana cai para `[]`, então o resultado parece um planner
sem sessões, que é uma mentira contada com calma. A página da semana ganha uma linha para isso, acima
do título:

```html
<p v-if="error" role="alert">The planner could not load its data: {{ error.statusMessage }}</p>
```

e `error` ao lado de `data` e `refresh` no seu `useFetch`. O arquivo inteiro:

```html
<!-- app/pages/index.vue: the week, at / -->
<script setup lang="ts">
const { data, error, refresh } = await useFetch('/api/courses')
const monday = ref(weekStart(new Date()))
// The reader's day, which only the reader's browser knows: empty on the
// server, and set once the page is running in the browser.
const today = ref('')
onMounted(() => {
  today.value = isoDate(new Date())
})

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
  <p v-if="error" role="alert">The planner could not load its data: {{ error.statusMessage }}</p>
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

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of main
The planner could not load its data: Down for maintenance

This week
Courses
Week of 19 October 2026
Previous weekNext week

Nothing here yet.

0 of 0 minutes done
```

**Agora a página diz o que aconteceu**, num parágrafo com `role="alert"`, que um leitor de tela lê em
voz alta assim que ele aparece. A contagem do layout falha do mesmo jeito e fica vazia, o que um rodapé
pode se permitir. Ponha o endpoint de volta como a aula 18 o escreveu:

```typescript
// server/api/courses.get.ts: GET /api/courses, every course and every session.
export default defineEventHandler(() => planner)
```

## Um erro que deve parar a página

A semana pode ser desenhada sem os dados, mal; uma página de curso não pode ser desenhada sem o curso.
Então a página do curso da seção sobre chaves faz a outra coisa com `error`: ela o lança adiante, com
`createError`, e o Nuxt desenha o `error.vue` com o status que a rota do servidor deu:

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

**A mensagem da própria rota, `No course called piano`, num `404`**, passada da rota do servidor pelo
`useFetch` até a página e para fora como o status da página. Qual das duas uma página deve fazer é a
pergunta a fazer de cada busca: a página ainda vale a pena sem esses dados? Uma semana sem sessões,
com uma frase dizendo por quê, vale; uma página de curso sem o curso, não.
