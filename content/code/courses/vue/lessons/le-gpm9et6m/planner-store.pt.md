---
title: A store do planner
version: 1
---

**Os dados do planner vão para uma store, `usePlannerStore`, e todas as partes da aplicação os leem dali:
o `App`, as três views, as linhas de sessão e o guard do router.** Duas coisas vão embora com isso, o
`usePlannerData` e as duas chaves que o `App` proveu nas aulas 8 e 12. Nada na tela muda, a não ser que a
página do curso e a semana agora compartilham uma lista de sessões sem ninguém passá-la adiante.

Pare o servidor de desenvolvimento, instale o Pinia no planner, com a versão fixada, e inicie-o de novo:

```
ana@dev:~/vue/planner$ npm install --save-exact pinia@4.1.0

added 1 package, and audited 82 packages in 671ms

24 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## A store, instalada

A store em si é a que a segunda seção desta aula percorreu; salve-a como `src/stores/planner.js`. O
`main.js` instala o Pinia, **antes do router**:

```javascript
// src/main.js
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import { router } from './router.js'
import './main.css'

// Pinia first, so that anything installed after it may use a store.
createApp(App).use(createPinia()).use(router).mount('#app')
```

Aqui qualquer ordem funcionaria: o router começa a primeira navegação ao ser instalado, mas roda os
guards um instante depois, quando o Pinia já está instalado, viesse antes ou depois. Pinia primeiro é um
hábito que vale manter mesmo assim, porque um plugin que usa uma store enquanto é instalado só encontra a
store se o Pinia já estiver lá.

## O guard pergunta à store

O `router.js` perde o `courseExists`, e o guard fica assim:

```javascript
beforeEnter: async (to) => {
  const planner = usePlannerStore()
  await planner.load()
  if (!planner.hasCourse(to.params.id)) {
    return { name: 'not-found', params: { pathMatch: to.path.slice(1).split('/') } }
  }
},
```

com `import { usePlannerStore } from './stores/planner.js'` no topo. O `load()` retorna a mesma promise a
todos que chamam, então o guard e o `App` compartilham uma requisição: quem pergunta primeiro a envia, e o
outro espera pela mesma resposta.

## O App, e as views

O `App.vue` não é mais dono dos dados; ele inicia a carga e desenha a moldura:

```html
<!-- src/App.vue -->
<script setup>
import { RouterLink, RouterView } from 'vue-router'
import AppFooter from './components/AppFooter.vue'
import { usePlannerStore } from './stores/planner.js'

const planner = usePlannerStore()
planner.load()
</script>

<template>
  <header>
    <p class="brand"><RouterLink to="/">Study planner</RouterLink></p>
    <p v-if="planner.error" role="alert">{{ planner.error }}</p>
    <p v-else-if="planner.courses.length === 0">Loading…</p>
    <p v-if="planner.source">{{ planner.sessions.length }} sessions, read from {{ planner.source }}</p>
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

Cada view troca a sua linha `inject(plannerKey)` pela store, e pega o `today` do `useToday` da aula 10 por
conta própria. O script do `HomeView.vue` agora começa assim:

```javascript
import { ref, computed } from 'vue'
import CourseCard from '../components/CourseCard.vue'
import SessionRow from '../components/SessionRow.vue'
import PlannerPanel from '../components/PlannerPanel.vue'
import { storeToRefs } from 'pinia'
import { usePlannerStore } from '../stores/planner.js'
import { useToday } from '../composables/useToday.js'
import { weekStart, addDays, formatDay, weekTotal, sessionsInWeek } from '../planner.js'

const planner = usePlannerStore()
const { courses, sessions } = storeToRefs(planner)
const { toggle } = planner
const today = useToday()
```

e o resto dele não muda. O `CourseWeek.vue` e o `CourseAll.vue` fazem a mesma troca, com
`const { sessions } = storeToRefs(planner)`, e o `CourseView.vue` pega só `courses`. O `SessionRow` lê os
títulos dos cursos da store em vez de injetá-los:

```html
<!-- src/components/SessionRow.vue -->
<script setup>
import { computed } from 'vue'
import { formatDay } from '../planner.js'
import { usePlannerStore } from '../stores/planner.js'

const { session, today } = defineProps({
  session: { type: Object, required: true },
  today: { type: Boolean, default: false },
})
const emit = defineEmits(['toggle'])

// The course's title, from the store; its id until the courses have loaded.
const planner = usePlannerStore()
const title = computed(() => planner.titles[session.course] ?? session.course)
</script>

<template>
  <li :class="{ done: session.done, today }">
    <label>
      <input type="checkbox" :checked="session.done" @change="emit('toggle', session.id)" />
      {{ formatDay(session.date) }}, {{ title }}, {{ session.minutes }} minutes
      <strong v-if="today">(today)</strong>
    </label>
  </li>
</template>

<style scoped>
.done {
  text-decoration: line-through;
}
.today {
  background: #e6f0ea;
}
</style>
```

Apague `src/keys.js` e `src/composables/usePlannerData.js`; nada mais os importa.

## Uma lista, todas as páginas

Abra a semana, vá para Spanish, marque a sessão dele do dia 23 e volte:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Spanish >> nth=0' --do 'check label:has-text("23 October") input' --do 'click text=Study planner' --text main --network
net  GET /  200
net  GET /src/main.js  200
net  GET /node_modules/.vite/deps/vue.js?v=cadb1fb2  200
net  GET /node_modules/.vite/deps/pinia.js?v=23a4d815  200
net  GET /src/main.css  200
net  GET /src/router.js  200
net  GET /src/App.vue  200
net  GET /node_modules/.vite/deps/vue.runtime.esm-bundler-CWNVreLk.js?v=d459ded8  200
net  GET /node_modules/.vite/deps/dist-BZygRcNR.js?v=d459ded8  200
net  GET /@vite/client  200
net  GET /node_modules/.vite/deps/vue-router.js?v=4d308e57  200
net  GET /src/App.vue?vue&type=style&index=0&scoped=7a7a37b1&lang.css  200
net  GET /@id/__x00__plugin-vue:export-helper  200
net  GET /src/stores/planner.js  200
net  GET /src/views/NotFound.vue  200
net  GET /src/views/HomeView.vue  200
net  GET /src/components/AppFooter.vue  200
net  GET /node_modules/vite/dist/client/env.mjs  200
[vite] connecting...
net  GET /src/planner.js  200
net  GET /src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css  200
net  GET /src/composables/useToday.js  200
[vite] connected.
net  GET /src/components/CourseCard.vue  200
net  GET /src/components/PlannerPanel.vue  200
net  GET /src/components/SessionRow.vue  200
net  GET /src/components/CourseCard.vue?vue&type=style&index=0&scoped=a191423e&lang.css  200
net  GET /src/components/PlannerPanel.vue?vue&type=style&index=0&scoped=0710be83&lang.css  200
net  GET /src/components/SessionRow.vue?vue&type=style&index=0&scoped=b7ae2f26&lang.css  200
net  GET /courses.json  200
-- click text=Spanish >> nth=0
net  GET /src/views/CourseView.vue  200
net  GET /src/views/CourseWeek.vue  200
net  GET /src/views/CourseView.vue?vue&type=style&index=0&scoped=62175599&lang.css  200
-- check label:has-text("23 October") input
-- click text=Study planner
== the text of main
This week
Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

70 of 70 minutes done, goal 120

 58% of the weekly goal

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
115 of 195 minutes done
```

**Spanish agora está em 70 de 70 na página da semana**, marcado na página do curso: as duas páginas são
duas vistas de uma store. E a lista da rede tem **uma** requisição para `courses.json`, contra duas na aula
12, onde o guard buscava a própria cópia.
