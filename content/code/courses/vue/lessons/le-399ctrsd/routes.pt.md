---
title: Rotas, RouterView e RouterLink
version: 1
---

**Uma rota liga um caminho a um componente; o `<RouterView>` é onde o componente encontrado é desenhado;
e o `<RouterLink>` é um link que muda o endereço sem recarregar a página.** Essas três coisas são a ideia
inteira, e todo outro recurso do router é um refinamento de uma delas.

As rotas do planner, na forma final desta aula. As notas dizem qual seção explica cada parte:

```schooling-example
{"language": "javascript", "file": "src/router.js", "parts": [
 {"code": "import { createRouter, createWebHistory } from 'vue-router'\nimport HomeView from './views/HomeView.vue'\nimport NotFound from './views/NotFound.vue'", "note": "O router é feito de uma lista de rotas e de um histórico, que é a forma como os endereços são escritos. `createWebHistory` dá caminhos de verdade, `/courses/spanish`; a última seção desta aula trata disso."},
 {"code": "// Asks the data file whether a course exists. Lesson 13 replaces this with the store.\nasync function courseExists(id) {\n  const response = await fetch('/courses.json')\n  const { courses } = await response.json()\n  return courses.some((course) => course.id === id)\n}", "note": "Um auxiliar de guard: pergunta ao arquivo de dados se um curso existe. A seção sobre guards explica por quê, e a aula 13 o substitui."},
 {"code": "const routes = [\n  { path: '/', name: 'home', component: HomeView, meta: { title: 'Study planner' } },", "note": "A semana, em `/`. O `name` deixa o código e os links se referirem a uma rota sem escrever o caminho; `meta` são dados livres que os guards leem."},
 {"code": "  {\n    path: '/courses/:id',\n    // Loaded only when somebody opens a course: a separate file in the build.\n    component: () => import('./views/CourseView.vue'),\n    props: true,", "note": "Um curso. `:id` é um parâmetro: casa com qualquer segmento e o entrega, como prop, por causa de `props: true`. A seção sobre parâmetros."},
 {"code": "    beforeEnter: async (to) => {\n      if (!(await courseExists(to.params.id))) {\n        return { name: 'not-found', params: { pathMatch: to.path.slice(1).split('/') } }\n      }\n    },", "note": "Um guard que roda antes de entrar nesta rota e manda um curso desconhecido para a página de endereços desconhecidos."},
 {"code": "    children: [\n      { path: '', name: 'course-week', component: () => import('./views/CourseWeek.vue') },\n      { path: 'all', name: 'course-all', component: () => import('./views/CourseAll.vue') },\n    ],\n    meta: { title: 'Course' },\n  },", "note": "Duas rotas filhas, desenhadas dentro da página do curso: a semana do curso em `/courses/spanish`, e todas as sessões em `/courses/spanish/all`. A seção sobre rotas aninhadas."},
 {"code": "  { path: '/:pathMatch(.*)*', name: 'not-found', component: NotFound, meta: { title: 'Not found' } },\n]\n\nexport const router = createRouter({\n  history: createWebHistory(),\n  routes,\n})", "note": "Todo o resto. `(.*)*` casa com qualquer caminho. O lugar dela na lista não importa, porque o router ordena as rotas pelo quanto são específicas e tenta primeiro a mais específica; ela vem por último porque é ali que quem lê procura."},
 {"code": "// After every navigation that happened, the tab says where the student is.\nrouter.afterEach((to, from, failure) => {\n  if (!failure) document.title = `${to.meta.title} · Study planner`\n})", "note": "Depois de toda navegação, o título da aba nomeia a página, a menos que um guard a tenha cancelado ou redirecionado: o terceiro argumento diz isso. O título é como a aba, o histórico e um favorito nomeiam a página."}
]}
```

## As páginas são componentes

Um componente que uma rota desenha se chama **view**, e as views ficam em `src/views`, separadas das
peças reutilizáveis de `src/components`. A semana, que era o corpo do `App.vue`, agora é a primeira view,
com o próprio título:

```html
<!-- src/views/HomeView.vue -->
<script setup>
import { ref, computed, inject } from 'vue'
import CourseCard from '../components/CourseCard.vue'
import SessionRow from '../components/SessionRow.vue'
import PlannerPanel from '../components/PlannerPanel.vue'
import { plannerKey } from '../keys.js'
import { weekStart, addDays, formatDay, weekTotal, sessionsInWeek } from '../planner.js'

const { courses, sessions, today, toggle } = inject(plannerKey)
const monday = ref(weekStart(new Date()))

const thisWeek = computed(() =>
  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),
)
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
        :today="session.date === today"
        @toggle="toggle"
      />
    </ul>
    <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>
  </PlannerPanel>
</template>
```

Ela lê os dados do planner com `inject`, a partir do `App`, que continua sendo o dono deles. A aula 8
disse que estado compartilhado por várias páginas pertence a uma store; até a aula 13 construir uma, o
`App` fornece os dados sob uma segunda chave, `plannerKey`, acrescentada ao lado de `titlesKey` em
`src/keys.js`:

```javascript
// src/keys.js: the keys the planner provides values under. A Symbol is unique,
// so no other code can provide or inject under the same key by accident.
export const titlesKey = Symbol('course titles')
export const plannerKey = Symbol('planner data')
```

E o `App.vue` vira a moldura em volta do que o router desenhar:

```html
<!-- src/App.vue -->
<script setup>
import { computed, provide } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import AppFooter from './components/AppFooter.vue'
import { titlesKey, plannerKey } from './keys.js'
import { toggleDone } from './planner.js'
import { usePlannerData } from './composables/usePlannerData.js'
import { useToday } from './composables/useToday.js'

const { courses, sessions, error, source } = usePlannerData()
const today = useToday()

const titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))
provide(titlesKey, titles)

function toggle(id) {
  sessions.value = toggleDone(sessions.value, id)
}
// Every view reads the data from here, until lesson 13 gives it a store.
provide(plannerKey, { courses, sessions, today, toggle })
</script>

<template>
  <header>
    <p class="brand"><RouterLink to="/">Study planner</RouterLink></p>
    <p v-if="error" role="alert">{{ error }}</p>
    <p v-else-if="courses.length === 0">Loading…</p>
    <p v-if="source">{{ sessions.length }} sessions, read from {{ source }}</p>
  </header>
  <main>
    <RouterView />
  </main>
  <AppFooter />
</template>

<style scoped>
header {
  border-bottom: 2px solid #2f6f4e;
}
.brand {
  font-size: 1.5rem;
  font-weight: 700;
}
</style>
```

**O `<RouterView />` é onde as views entram.** Tudo em volta dele, o cabeçalho com um link para o início
e o rodapé, é desenhado em toda página. O título do cabeçalho agora é um `<p>`, porque cada view tem o
próprio `<h1>`, e uma página deve ter um só.

Os cards apontam para o seu curso. O `CourseCard` ganha uma prop `id` e um `<RouterLink>` em volta do
título:

```html
<!-- src/components/CourseCard.vue -->
<script setup>
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

// Destructured, and still reactive: the compiler turns every use of `done`
// below into `props.done`.
const { id, title, goal, planned, done } = defineProps({
  id: { type: String, required: true },
  title: { type: String, required: true },
  goal: { type: Number, required: true },
  planned: { type: Number, default: 0 },
  done: { type: Number, default: 0 },
})

const percent = computed(() => Math.round((done / goal) * 100))
</script>

<template>
  <li class="card">
    <h3><RouterLink :to="`/courses/${id}`">{{ title }}</RouterLink></h3>
    <p>{{ done }} of {{ planned }} minutes done, goal {{ goal }}</p>
    <p>
      <progress :value="done" :max="goal">{{ percent }}%</progress>
      {{ percent }}% of the weekly goal
    </p>
  </li>
</template>

<style scoped>
.card {
  margin-bottom: 1rem;
}
p {
  color: #2f6f4e;
}
</style>
```

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --text main
[vite] connecting...
[vite] connected.
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

A mesma semana de antes, desenhada pela `HomeView` dentro do `<RouterView>` do `App`.

## RouterLink, não a

`<RouterLink to="/courses/spanish">` desenha um `<a href="/courses/spanish">` comum, então pode ser aberto
numa aba nova, copiado e lido por um leitor de tela como link. O que ele acrescenta é um tratador de
clique que impede o navegador de carregar o endereço e pede ao router que troque a tela. Um `<a>` simples
também funcionaria, e recarregaria a aplicação inteira a cada clique, perdendo todo ref que não tivesse
sido salvo.
