---
title: A lista da semana no planner
version: 1
---

**Agora o planner lista as sessões da semana abaixo dos cursos, em ordem de data, cada uma com uma
checkbox que a marca como feita, e os totais acompanham.** Todas as diretivas desta aula estão nele:
`v-for` com uma chave de verdade, `v-if` e `v-else` para uma semana vazia, `:class` para uma sessão
feita, e uma checkbox ligada à mão em vez de pelo `v-model`.

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed, watch } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport { weekStart, addDays, formatDay, weekTotal, sessionsInWeek, toggleDone } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')\nconst source = ref('')\nconst monday = ref(weekStart(new Date()))\n\nconst total = computed(() => weekTotal(sessions.value, monday.value))", "note": "Mais duas regras do planner são importadas: `sessionsInWeek` e `toggleDone`."},
 {"code": "const thisWeek = computed(() =>\n  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),\n)\nconst titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))", "note": "As sessões da semana, ordenadas por data com o `toSorted`, que deixa a lista intacta (aula 3). `titles` associa o id de um curso ao seu título, para que uma linha possa mostrar \"Statistics\" para `statistics`."},
 {"code": "function toggle(id) {\n  sessions.value = toggleDone(sessions.value, id)\n}", "note": "Marcar uma caixa substitui a lista por uma nova, vinda das regras. O watcher da aula 4 vê a lista nova e a salva."},
 {"code": "const perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)\n\nconst STORAGE_KEY = 'planner.sessions'\n\nfetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    const saved = localStorage.getItem(STORAGE_KEY)\n    sessions.value = saved ? JSON.parse(saved) : data.sessions\n    source.value = saved ? 'this browser' : 'courses.json'\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n\n// Every time the list of sessions is replaced, this browser keeps a copy.\nwatch(sessions, (list) => {\n  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n})\n</script>\n\n<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>\n      Week of {{ formatDay(monday) }}: {{ total.done }} of {{ total.planned }} minutes done\n    </p>\n    <p v-if=\"source\">{{ sessions.length }} sessions, read from {{ source }}</p>\n    <nav>\n      <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n      <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n    </nav>\n  </header>\n  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in perCourse\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>{{ course.done }} of {{ course.planned }} minutes done, goal {{ course.goal }}</p>\n      </li>\n    </ul>", "note": "O resto do script, e o cabeçalho, são da aula 4."},
 {"code": "    <h2>This week</h2>\n    <p v-if=\"thisWeek.length === 0\">Nothing planned this week.</p>\n    <ul v-else class=\"sessions\">\n      <li v-for=\"session in thisWeek\" :key=\"session.id\" :class=\"{ done: session.done }\">\n        <label>\n          <input type=\"checkbox\" :checked=\"session.done\" @change=\"toggle(session.id)\" />\n          {{ formatDay(session.date) }}, {{ titles[session.course] }}, {{ session.minutes }} minutes\n        </label>\n      </li>\n    </ul>\n  </main>\n  <AppFooter />\n</template>", "note": "A lista nova. `:checked` mostra o estado; `@change` pede a mudança. Juntos, são o que o `v-model` teria escrito, passando pelo `toggle`."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses,\n.sessions {\n  list-style: none;\n  padding: 0;\n}\n.done {\n  text-decoration: line-through;\n}\n</style>", "note": "`.sessions` compartilha o estilo de lista, e uma sessão feita aparece riscada."}
]}
```

Com o servidor de desenvolvimento do planner rodando, marque a sessão de guitar e carregue a página de
novo:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'check label:has-text("Guitar") input' --do 'goto /' --text main
[vite] connecting...
[vite] connected.
-- check label:has-text("Guitar") input
-- goto /
[vite] connecting...
[vite] connected.
== the text of main
Statistics

45 of 105 minutes done, goal 180

Spanish

30 of 70 minutes done, goal 120

Guitar

20 of 20 minutes done, goal 90

This week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
```

`label:has-text("Guitar") input` encontra a checkbox dentro do label que menciona Guitar, que é como
uma pessoa a encontraria também. **Depois de recarregar, guitar mostra 20 de 20 minutos**: a marcação
substituiu a lista, o watcher da aula 4 a salvou, e a segunda visita a leu de volta do navegador. A
checkbox em si não aparece no texto, e é por isso que os totais são a evidência.

## Por que a checkbox fica dentro de um label

Clicar nas palavras marca a caixa, o que dá um alvo maior para um dedo, e um leitor de tela anuncia a
caixa com as palavras como nome: *"19 October 2026, Statistics, 45 minutes, checkbox, checked"*. Uma
checkbox com o texto ao lado mas fora de um label, ou sem ligação com ele por `for` e `id`, é anunciada
como *"checkbox, checked"* e nada mais. O seletor do `look` acima encontrou a caixa pelo label pelo
mesmo motivo que um leitor de tela encontra.

## As chaves, mais uma vez

`:key="session.id"`. Marque uma sessão, e a lista é substituída por um array novo, com um objeto novo para aquela sessão, mas os ids são os
mesmos, então o Vue mantém cada `<li>` e só atualiza aquele cujo `done` mudou. Ordenada por data, a
mesma sessão pode mudar de posição quando uma for acrescentada na aula 14, e a linha dela vai junto.
É o comportamento de que as duas últimas seções tratavam, chegando de graça porque os dados carregam
ids.
