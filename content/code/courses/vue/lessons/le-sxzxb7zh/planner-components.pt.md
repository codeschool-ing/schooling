---
title: O planner, em componentes
version: 1
---

**Os itens das listas do planner viram dois componentes, `CourseCard` e `SessionRow`, e o `App.vue` volta
a ser dono do estado e a arrumar as peças.** Nada muda na tela, exceto uma barra de progresso por curso. O
que muda é que cada peça agora tem um contrato, e pode ser lida, mudada e testada sozinha.

## CourseCard

Um card recebe um título e três números, e os desenha. Ele não é dono de nada:

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
    <h2>{{ title }}</h2>
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

As props são desestruturadas, o que desde o Vue 3.5 as mantém reativas (a primeira seção desta aula),
então `percent` acompanha `done`. Um elemento `<progress>` é a barra de progresso do próprio navegador,
anunciada por um leitor de tela com o seu valor; o texto dentro dele é o que mostraria um navegador sem
suporte a ele.

## SessionRow

Uma linha recebe uma sessão e o título do curso dela, e relata uma marcação:

```html
<!-- src/components/SessionRow.vue -->
<script setup>
import { formatDay } from '../planner.js'

defineProps({
  session: { type: Object, required: true },
  title: { type: String, required: true },
})
const emit = defineEmits(['toggle'])
</script>

<template>
  <li :class="{ done: session.done }">
    <label>
      <input type="checkbox" :checked="session.done" @change="emit('toggle', session.id)" />
      {{ formatDay(session.date) }}, {{ title }}, {{ session.minutes }} minutes
    </label>
  </li>
</template>

<style scoped>
.done {
  text-decoration: line-through;
}
</style>
```

**Ela emite `toggle` com o id da sessão e não faz mais nada.** Não importa `toggleDone`, e não faz ideia
de que existe uma lista, de que ela é salva ou de que um total depende dela. É o contrato das últimas
seções, aplicado: a linha relata, o `App` decide.

O estilo da linha para uma sessão feita veio para cá junto com o markup que ele estiliza, e saiu do
`App.vue`.

## App

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed, watch } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport CourseCard from './components/CourseCard.vue'\nimport SessionRow from './components/SessionRow.vue'", "note": "Os dois componentes são importados e usados como tags no template."},
 {"code": "import { weekStart, addDays, formatDay, weekTotal, sessionsInWeek, toggleDone } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')\nconst source = ref('')\nconst monday = ref(weekStart(new Date()))\n\nconst total = computed(() => weekTotal(sessions.value, monday.value))\nconst thisWeek = computed(() =>\n  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),\n)\nconst titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))\n\nfunction toggle(id) {\n  sessions.value = toggleDone(sessions.value, id)\n}\n\nconst perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)\n\nconst STORAGE_KEY = 'planner.sessions'\n\nfetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    const saved = localStorage.getItem(STORAGE_KEY)\n    sessions.value = saved ? JSON.parse(saved) : data.sessions\n    source.value = saved ? 'this browser' : 'courses.json'\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n\n// Every time the list of sessions is replaced, this browser keeps a copy.\nwatch(sessions, (list) => {\n  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n})\n</script>\n\n<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>\n      Week of {{ formatDay(monday) }}: {{ total.done }} of {{ total.planned }} minutes done\n    </p>\n    <p v-if=\"source\">{{ sessions.length }} sessions, read from {{ source }}</p>\n    <nav>\n      <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n      <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n    </nav>\n  </header>", "note": "O script é o da aula 5, sem mudanças: o estado, as regras e o `toggle` ficam todos aqui, com os dados a que pertencem."},
 {"code": "  <main>\n    <ul class=\"courses\">\n      <CourseCard\n        v-for=\"course in perCourse\"\n        :key=\"course.id\"\n        :title=\"course.title\"\n        :goal=\"course.goal\"\n        :planned=\"course.planned\"\n        :done=\"course.done\"\n      />\n    </ul>", "note": "Um `CourseCard` por curso, cada um recebendo os seus quatro valores como props."},
 {"code": "    <h2>This week</h2>\n    <p v-if=\"thisWeek.length === 0\">Nothing planned this week.</p>\n    <ul v-else class=\"sessions\">\n      <SessionRow\n        v-for=\"session in thisWeek\"\n        :key=\"session.id\"\n        :session=\"session\"\n        :title=\"titles[session.course]\"\n        @toggle=\"toggle\"\n      />\n    </ul>\n  </main>\n  <AppFooter />\n</template>", "note": "Um `SessionRow` por sessão. `@toggle=\"toggle\"` entrega o id emitido direto à mesma função `toggle` que a aula 5 escreveu."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses,\n.sessions {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "O estilo perde `.done`, que foi para o `SessionRow`."}
]}
```

Com o servidor do planner rodando, marque a sessão de guitar:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'check label:has-text("Guitar") input' --text main
[vite] connecting...
[vite] connected.
-- check label:has-text("Guitar") input
== the text of main
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

Guitar

20 of 20 minutes done, goal 90

 22% of the weekly goal

This week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
```

**Guitar foi para 20 de 20 e 22% da meta**: a linha emitiu, o `App` substituiu a lista, `perCourse`
recalculou, e a prop `done` do card mudou, então o `percent` dele acompanhou. Três componentes
participaram, e cada um fez só a sua parte.

## O que o App é agora

O `App.vue` guarda os dados, as regras e o arranjo. Ele continua sendo o arquivo mais longo do planner, e
vai continuar sendo o lugar onde o estado mora até a aula 13 levar o estado para uma store, quando o `App`
passa a ser o arranjo e nada mais. A aula 7 dá aos cards uma moldura compartilhada com slots, e a aula 8
deixa um componente lá no fundo da árvore alcançar os títulos sem que eles sejam passados nível por nível.
