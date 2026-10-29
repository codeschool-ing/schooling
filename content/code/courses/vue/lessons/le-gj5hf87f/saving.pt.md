---
title: O planner guarda as suas sessões
version: 1
---

**Agora o planner guarda uma cópia das suas sessões no navegador, salva por um watcher toda vez que a
lista é substituída, e lê essa cópia de volta em vez do arquivo quando ela existe.** Nada no planner
muda as sessões ainda; a aula 5 as marca como feitas e a aula 14 acrescenta novas. Esta aula põe o
salvamento no lugar primeiro, para que dali em diante nada do que for digitado se perca ao recarregar.

Salvar é o efeito colateral de manual: escreve em algo fora do componente, o `localStorage`, que a aula
18 de `javascript` apresentou, e a tela não muda por causa disso.

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed, watch } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport { weekStart, addDays, formatDay, weekTotal } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')\nconst source = ref('')\nconst monday = ref(weekStart(new Date()))\n\nconst total = computed(() => weekTotal(sessions.value, monday.value))\nconst perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)", "note": "O `watch` entra nos imports, e `source` é um ref novo que diz de onde as sessões vieram."},
 {"code": "const STORAGE_KEY = 'planner.sessions'", "note": "A chave sob a qual a cópia é guardada. Prefixá-la com o nome da aplicação a mantém separada de qualquer outra coisa no mesmo endereço."},
 {"code": "fetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    const saved = localStorage.getItem(STORAGE_KEY)\n    sessions.value = saved ? JSON.parse(saved) : data.sessions\n    source.value = saved ? 'this browser' : 'courses.json'\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })", "note": "Os cursos sempre vêm do arquivo. As sessões vêm da cópia do navegador se houver uma, e do arquivo da primeira vez."},
 {"code": "// Every time the list of sessions is replaced, this browser keeps a copy.\nwatch(sessions, (list) => {\n  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n})\n</script>", "note": "O watcher. Ele é raso, e isso basta: as regras do planner substituem a lista em vez de mudá-la, então cada mudança é um `.value` novo."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>\n      Week of {{ formatDay(monday) }}: {{ total.done }} of {{ total.planned }} minutes done\n    </p>\n    <p v-if=\"source\">{{ sessions.length }} sessions, read from {{ source }}</p>\n    <nav>\n      <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n      <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n    </nav>\n  </header>\n  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in perCourse\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>{{ course.done }} of {{ course.planned }} minutes done, goal {{ course.goal }}</p>\n      </li>\n    </ul>\n  </main>\n  <AppFooter />\n</template>\n\n<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "O template é o da aula 3 com uma linha a mais, que diz quantas sessões existem e de onde foram lidas."}
]}
```

O `look` abre um navegador novo toda vez, sem nada guardado, então para ver a cópia funcionando ele
precisa carregar a página duas vezes no mesmo navegador. O `goto /` faz isso:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'goto /' --text header
[vite] connecting...
[vite] connected.
-- goto /
[vite] connecting...
[vite] connected.
== the text of header
Study planner

Week of 19 October 2026: 75 of 195 minutes done

6 sessions, read from this browser

Previous weekNext week
```

A primeira visita leu o arquivo, e o watcher salvou a lista no momento em que ela foi atribuída. **A
segunda visita leu a cópia do navegador**, que é a linha que o cabeçalho imprime. No seu próprio
navegador a cópia fica até você limpar os dados do site; as ferramentas de desenvolvedor do navegador a
mostram em Application, Local Storage, `http://localhost:5173`, como a chave `planner.sessions`.

## Por que o watcher pode ser raso

As regras da aula 3 devolvem arrays novos: `toggleDone` e `addSession` nunca mudam a lista que recebem.
Então cada mudança que o planner vai fazer é uma atribuição a `sessions.value`, que um watcher simples
vê. Se o planner desse push no array em vez disso, este watcher perderia cada mudança, como a demo do
`deep` mostrou, e a cópia ficaria para trás sem ninguém perceber. **A regra nas funções simples e o
watcher raso são uma decisão só**, tomada duas vezes.

## O que ainda não é tratado

Duas coisas ficam declaradas em vez de resolvidas:

- **O arquivo mudar.** Se o `courses.json` ganhar uma sessão, um navegador com uma cópia salva nunca a
  vê, porque a cópia vence. Para um planner cujas sessões pertencem ao estudante, essa é a resposta
  certa; o arquivo é só por onde um estudante novo começa.
- **Uma cópia que não é JSON válido.** O `JSON.parse` lançaria um erro, e o erro cairia no `catch` e
  diria que os cursos não puderam ser carregados, o que é perto o bastante da verdade. A aula 13 leva o
  salvamento para uma store, onde ele ganha um lugar próprio.
