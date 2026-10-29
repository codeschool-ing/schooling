---
title: Os composables do planner
version: 1
---

**O `App.vue` do planner entrega dois dos seus trabalhos a composables: carregar e salvar os dados, e
manter a data de hoje.** O que fica no `App` é o que só o `App` pode decidir: qual semana aparece, do
que a tela é feita, e o que uma marcação significa. Nada muda na tela.

## useToday

O relógio da aula 9, tirado do `App` junto com o seu começo e o seu fim:

```javascript
// src/composables/useToday.js: today's date, kept current while the page is open.
import { ref, onMounted, onUnmounted } from 'vue'
import { isoDate } from '../planner.js'

export function useToday() {
  const today = ref(isoDate(new Date()))
  let timer
  onMounted(() => {
    timer = setInterval(() => {
      today.value = isoDate(new Date())
    }, 60_000)
  })
  onUnmounted(() => clearInterval(timer))
  return today
}
```

## usePlannerData

O carregamento da aula 2 e o salvamento da aula 4, juntos, porque são um trabalho só: de onde vêm os
dados do planner e para onde vão.

```javascript
// src/composables/usePlannerData.js: the courses and the sessions, loaded from
// courses.json, with the sessions kept in this browser from then on.
import { ref, watch } from 'vue'

const STORAGE_KEY = 'planner.sessions'

export function usePlannerData() {
  const courses = ref([])
  const sessions = ref([])
  const error = ref('')
  const source = ref('')

  fetch('/courses.json')
    .then((response) => {
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)
      return response.json()
    })
    .then((data) => {
      courses.value = data.courses
      const saved = localStorage.getItem(STORAGE_KEY)
      sessions.value = saved ? JSON.parse(saved) : data.sessions
      source.value = saved ? 'this browser' : 'courses.json'
    })
    .catch((e) => {
      error.value = `Could not load the courses: ${e.message}`
    })

  watch(sessions, (list) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list))
  })

  return { courses, sessions, error, source }
}
```

## O App, inteiro

O arquivo inteiro, já que mudou o bastante nas últimas três aulas para valer a pena lê-lo de uma vez de
novo:

```html
<!-- src/App.vue -->
<script setup>
import { ref, computed, provide } from 'vue'
import AppFooter from './components/AppFooter.vue'
import CourseCard from './components/CourseCard.vue'
import SessionRow from './components/SessionRow.vue'
import PlannerPanel from './components/PlannerPanel.vue'
import { titlesKey } from './keys.js'
import { weekStart, addDays, formatDay, weekTotal, sessionsInWeek, toggleDone } from './planner.js'
import { usePlannerData } from './composables/usePlannerData.js'
import { useToday } from './composables/useToday.js'

const title = 'Study planner'
const { courses, sessions, error, source } = usePlannerData()
const today = useToday()
const monday = ref(weekStart(new Date()))

const thisWeek = computed(() =>
  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),
)
const titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))
provide(titlesKey, titles)

function toggle(id) {
  sessions.value = toggleDone(sessions.value, id)
}

const perCourse = computed(() =>
  courses.value.map((course) => ({
    ...course,
    ...weekTotal(
      sessions.value.filter((s) => s.course === course.id),
      monday.value,
    ),
  })),
)
const total = computed(() => weekTotal(sessions.value, monday.value))
</script>

<template>
  <header>
    <h1>{{ title }}</h1>
    <p v-if="error" role="alert">{{ error }}</p>
    <p v-else-if="courses.length === 0">Loading…</p>
    <p v-if="source">{{ sessions.length }} sessions, read from {{ source }}</p>
  </header>
  <main>
    <PlannerPanel title="Courses">
      <ul>
        <CourseCard
          v-for="course in perCourse"
          :key="course.id"
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
          :today="session.date === today"
          @toggle="toggle"
        />
      </ul>
      <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>
    </PlannerPanel>
  </main>
  <AppFooter />
</template>

<style scoped>
header {
  border-bottom: 2px solid #2f6f4e;
}
</style>
```

Marque a sessão de guitarra e carregue a página de novo, como a aula 5 fez:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'check label:has-text("Guitar") input' --do 'goto /'
[vite] connecting...
[vite] connected.
-- check label:has-text("Guitar") input
-- goto /
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

6 sessions, read from this browser

Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

Guitar

20 of 20 minutes done, goal 90

 22% of the weekly goal

Week of 19 October 2026
Previous weekNext week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
95 of 195 minutes done

Built with Vue 3.5.44
```

**Tudo o que as aulas anteriores construíram continua funcionando**: a marcação foi salva e lida de
volta do navegador, a sessão de hoje está destacada, os totais acompanham. O script do `App.vue` perdeu
o seu `fetch`, o seu watcher, a sua chave de armazenamento, o seu timer e os dois hooks, e ganhou duas
linhas que dizem o que ele usa.

## Onde isso deixa de funcionar

`usePlannerData` é um composable, então cada chamada cria uma nova cópia dos dados e os busca de novo.
Hoje só o `App` o chama, e tudo bem. No dia em que um segundo componente precisar das sessões, a página
de curso da aula 12 por exemplo, chamar `usePlannerData()` ali daria a ele uma lista separada: uma
marcação numa tela não apareceria na outra até recarregar, e os dois watchers sobrescreveriam a cópia um
do outro no armazenamento. **Estado compartilhado precisa de um dono**, e a aula 13 dá um ao planner,
com um store.
