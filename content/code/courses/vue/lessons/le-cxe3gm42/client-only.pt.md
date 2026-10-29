---
title: Só no cliente, para o que só o navegador sabe
version: 1
---

**O dia do leitor pertence ao navegador, então o navegador o decide, depois da hidratação, e o servidor
desenha a semana sem ele.** Na página da semana, a linha da divergência vira um ref que começa vazio e
é definido no `onMounted`, que roda só no navegador e só depois que a página foi hidratada:

```html
<!-- app/pages/index.vue: the week, at / -->
<script setup lang="ts">
const { data, refresh } = await useFetch('/api/courses')
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

No servidor, e na primeira renderização no navegador, `today` é `''`, nenhuma linha bate com ele, e os
dois desenhos concordam. Depois o `onMounted` o define, e a mudança redesenha aquela linha, como
qualquer mudança de um ref faria. O destaque aparece um instante depois da página, e esse é o preço
honesto: até o navegador rodar, ninguém sabe que dia é para o leitor.

## `<ClientOnly>`, para uma parte que não dá para desenhar no servidor

Quando um pedaço inteiro de uma página depende do navegador, o `<ClientOnly>` do Nuxt o deixa fora da
renderização do servidor e o desenha depois da hidratação, com um `#fallback` opcional para o servidor
mandar no lugar dele. O rodapé do planner diz em que fuso os dias são contados, o que é um fato sobre o
navegador e nada mais:

```html
<!-- app/layouts/default.vue: the frame around every page. -->
<script setup lang="ts">
import { version } from 'vue'

// The reader's time zone, as their browser reports it. The server has its own.
const zone = () => Intl.DateTimeFormat().resolvedOptions().timeZone
</script>

<template>
  <header>
    <p class="brand"><NuxtLink to="/">Study planner</NuxtLink></p>
  </header>
  <main>
    <slot />
  </main>
  <footer>
    <p>Built with Vue {{ version }}, by Nuxt</p>
    <ClientOnly>
      <p>Days are counted in {{ zone() }}</p>
      <template #fallback>
        <p>Days are counted in your browser's time zone</p>
      </template>
    </ClientOnly>
  </footer>
</template>

<style scoped>
header {
  border-bottom: 2px solid #2f6f4e;
}
.brand {
  font-size: 1.5rem;
  font-weight: 700;
}
footer p {
  color: #666;
  font-size: 0.875rem;
}
</style>
```

O mesmo momento de antes, onze e meia da noite em São Paulo, com o servidor em UTC:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text 'li.today'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of li.today
 21 October 2026, Statistics, 60 minutes (today)
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text '#__nuxt > footer'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of #__nuxt > footer
Built with Vue 3.5.44, by Nuxt

Days are counted in America/Sao_Paulo
```

**Nenhum aviso, o dia 21 destacado, e o fuso do leitor no rodapé.** E o que o servidor mandou:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o 'Days are counted in [^<]*'
Days are counted in your browser&#39;s time zone
```

O fallback, uma frase verdadeira para todo leitor, e nenhuma menção a UTC em lugar nenhum. Um
componente que só faz sentido no navegador também pode dizer isso no nome: `Clock.client.vue` em
`app/components` é desenhado só no navegador, como se cada uso dele estivesse dentro de um
`<ClientOnly>`. Dentro de um script, `import.meta.client` e `import.meta.server` são `true` de um lado
só, para a linha rara que precisa rodar num e não no outro; o `onMounted` costuma ser a forma mais clara
de dizer *no navegador*.

Uma pergunta fica em aberto de propósito. `monday`, o começo da semana mostrada, ainda é decidido no
servidor, e num domingo à noite a segunda-feira do servidor está uma semana à frente da do leitor. O
planner poderia levá-lo para o `onMounted` também e não desenhar semana nenhuma no servidor, ou
perguntar o fuso do leitor uma vez e guardá-lo num cookie que o servidor lê. As duas são razoáveis, e a
próxima seção é sobre escolher.
