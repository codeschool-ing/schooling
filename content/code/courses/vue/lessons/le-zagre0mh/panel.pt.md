---
title: Um painel para o planner
version: 1
---

**O planner ganha uma moldura, o `PlannerPanel`, com um título, um slot para ações ao lado dele, um
corpo e um rodapé, e as duas metades da tela são desenhadas nele.** Ele também ganha uma folha de
estilos própria para o que todo componente compartilha, que a aula 1 prometeu que chegaria aqui.

## O painel

```html
<!-- src/components/PlannerPanel.vue -->
<script setup>
defineProps({ title: { type: String, required: true } })
</script>

<template>
  <section class="panel">
    <header class="panel-head">
      <h2>{{ title }}</h2>
      <slot name="actions" />
    </header>
    <slot>
      <p>Nothing here yet.</p>
    </slot>
    <footer v-if="$slots.footer" class="panel-foot">
      <slot name="footer" />
    </footer>
  </section>
</template>

<style scoped>
.panel {
  border: 1px solid #c9d8cf;
  border-radius: 6px;
  margin: 1rem 0;
  padding: 0 1rem 1rem;
}
.panel-head {
  align-items: center;
  display: flex;
  gap: 1rem;
  justify-content: space-between;
}
.panel-foot {
  border-top: 1px solid #c9d8cf;
  color: #2f6f4e;
  padding-top: 0.5rem;
}
</style>
```

Todos os slots desta aula estão nele: um título como prop, porque é só texto; um slot `actions`,
porque os botões da semana são marcação; um slot padrão com conteúdo reserva; e um rodapé desenhado só
quando o pai o preenche.

## A aparência compartilhada

Regras que valem para a página inteira não pertencem a nenhum componente, então vão numa folha de
estilos comum, importada uma vez pelo `main.js`:

```css
/* src/main.css: the planner's look, shared by every component. */
body {
  color: #1d2b24;
  font-family: system-ui, sans-serif;
  line-height: 1.5;
  margin: 0 auto;
  max-width: 40rem;
  padding: 0 1rem;
}
ul {
  list-style: none;
  padding: 0;
}
button {
  font: inherit;
}
```

```javascript
// src/main.js
import { createApp } from 'vue'
import App from './App.vue'
import './main.css'

createApp(App).mount('#app')
```

Importar um arquivo `.css` a partir do JavaScript é um recurso do Vite: em desenvolvimento ele injeta
as regras na página, e o build da aula 17 as põe num arquivo próprio. As regras não têm escopo, e esse
é o ponto: o `ul` perde os marcadores em todo lugar, então o `App.vue` não precisa mais das suas
regras `.courses` e `.sessions`.

## Os cards, um nível abaixo

O título do painel é um `<h2>`, então os cards de curso dentro dele viram `<h3>`s. Os títulos são como
quem usa leitor de tela se movimenta numa página, e um nível que pula ou se repete deixa esse mapa
errado. O `CourseCard.vue` muda nessa única linha:

```html
<!-- src/components/CourseCard.vue -->
<script setup>
import { computed } from 'vue'

// Destructured, and still reactive: the compiler turns every use of `done`
// below into `props.done`.
const { title, goal, planned, done } = defineProps({
  title: { type: String, required: true },
  goal: { type: Number, required: true },
  planned: { type: Number, default: 0 },
  done: { type: Number, default: 0 },
})

const percent = computed(() => Math.round((done / goal) * 100))
</script>

<template>
  <li class="card">
    <h3>{{ title }}</h3>
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

## App

O script é o da aula 6, com o `PlannerPanel` importado ao lado dos outros componentes. O template e o
estilo mudam:

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed, watch } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport CourseCard from './components/CourseCard.vue'\nimport SessionRow from './components/SessionRow.vue'\nimport PlannerPanel from './components/PlannerPanel.vue'\nimport { weekStart, addDays, formatDay, weekTotal, sessionsInWeek, toggleDone } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')\nconst source = ref('')\nconst monday = ref(weekStart(new Date()))\n\nconst total = computed(() => weekTotal(sessions.value, monday.value))\nconst thisWeek = computed(() =>\n  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),\n)\nconst titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))\n\nfunction toggle(id) {\n  sessions.value = toggleDone(sessions.value, id)\n}\n\nconst perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)\n\nconst STORAGE_KEY = 'planner.sessions'\n\nfetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    const saved = localStorage.getItem(STORAGE_KEY)\n    sessions.value = saved ? JSON.parse(saved) : data.sessions\n    source.value = saved ? 'this browser' : 'courses.json'\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n\n// Every time the list of sessions is replaced, this browser keeps a copy.\nwatch(sessions, (list) => {\n  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n})\n</script>", "note": "O script: o da aula 6, mais um import."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-if=\"source\">{{ sessions.length }} sessions, read from {{ source }}</p>\n  </header>", "note": "O cabeçalho mantém o título e de onde as sessões vieram. A linha da semana foi para o título do segundo painel."},
 {"code": "  <main>\n    <PlannerPanel title=\"Courses\">\n      <ul>\n        <CourseCard\n          v-for=\"course in perCourse\"\n          :key=\"course.id\"\n          :title=\"course.title\"\n          :goal=\"course.goal\"\n          :planned=\"course.planned\"\n          :done=\"course.done\"\n        />\n      </ul>\n    </PlannerPanel>", "note": "O primeiro painel: só um título e um corpo."},
 {"code": "    <PlannerPanel :title=\"`Week of ${formatDay(monday)}`\">\n      <template #actions>\n        <nav aria-label=\"Weeks\">\n          <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n          <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n        </nav>\n      </template>", "note": "O título do segundo painel é a semana, e o slot `actions` guarda os dois botões, dentro de um `<nav>` com nome para que um leitor de tela possa anunciá-lo."},
 {"code": "      <ul v-if=\"thisWeek.length > 0\">\n        <SessionRow\n          v-for=\"session in thisWeek\"\n          :key=\"session.id\"\n          :session=\"session\"\n          :title=\"titles[session.course]\"\n          @toggle=\"toggle\"\n        />\n      </ul>", "note": "O corpo é a lista, desenhada só quando a semana tem sessões. Quando não tem nenhuma, o conteúdo do slot é um `v-if` que deu falso, o que conta como vazio, então o painel desenha o seu conteúdo reserva."},
 {"code": "      <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>\n    </PlannerPanel>\n  </main>\n  <AppFooter />\n</template>", "note": "O rodapé é o total da semana."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\n</style>", "note": "O que sobra do estilo é a regra do cabeçalho. As regras da lista foram para o `main.css`."}
]}
```

Com o servidor do planner rodando:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

6 sessions, read from courses.json

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
 21 October 2026, Statistics, 60 minutes
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
75 of 195 minutes done

Built with Vue 3.5.44
```

E a semana seguinte, que não tem nada planejado:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --text 'main section:nth-child(2)'
[vite] connecting...
[vite] connected.
-- click text=Next week
== the text of main section:nth-child(2)
Week of 26 October 2026
Previous weekNext week

Nothing here yet.

0 of 0 minutes done
```

**A semana vazia desenhou o conteúdo reserva do painel, `Nothing here yet.`**, e o rodapé ainda mostra
um total de zero, porque o rodapé foi preenchido. O planner da aula 2 dizia "Nothing planned this
week." num parágrafo próprio; agora quem diz é a moldura, para qualquer painel que acabe sem nada para
mostrar.
