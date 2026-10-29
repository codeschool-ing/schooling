---
title: O planner soma a semana
version: 1
---

**O planner agora mostra uma semana por vez, com os minutos planejados e feitos nela, para o plano
inteiro e para cada curso, tudo calculado.** O único estado novo é a segunda-feira da semana mostrada;
tudo na tela é calculado a partir dela e das sessões.

## As regras, separadas do Vue

A aritmética de uma semana não tem nada a ver com o Vue, então ela vai num arquivo de funções comuns
que não sabem nada de refs. Salve isto como `src/planner.js`:

```javascript
// src/planner.js: the planner's rules, as plain functions over plain data.
// Nothing here knows about Vue, the page or the clock, which is what makes
// every function testable on its own (lesson 21 does it).

// A date as YYYY-MM-DD, in the computer's own time zone.
export function isoDate(date) {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

// The date n days after a YYYY-MM-DD date (before it, if n is negative).
export function addDays(iso, n) {
  const [y, m, d] = iso.split('-').map(Number)
  return isoDate(new Date(y, m - 1, d + n))
}

// The Monday of the week a date falls in, as YYYY-MM-DD.
export function weekStart(date) {
  const daysSinceMonday = (date.getDay() + 6) % 7
  return addDays(isoDate(date), -daysSinceMonday)
}

// "19 October 2026", for people.
export function formatDay(iso) {
  const [y, m, d] = iso.split('-').map(Number)
  return new Date(y, m - 1, d).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
}

// The sessions from Monday to Sunday of the week that starts on monday.
export function sessionsInWeek(sessions, monday) {
  const sunday = addDays(monday, 6)
  return sessions.filter((s) => s.date >= monday && s.date <= sunday)
}

// Minutes planned and minutes done in that week.
export function weekTotal(sessions, monday) {
  const week = sessionsInWeek(sessions, monday)
  return {
    planned: week.reduce((sum, s) => sum + s.minutes, 0),
    done: week.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0),
  }
}

// A new list with one more session in it. The id is one past the highest.
export function addSession(sessions, { course, date, minutes }) {
  const highest = Math.max(0, ...sessions.map((s) => Number(s.id.slice(1))))
  return [...sessions, { id: `s${highest + 1}`, course, date, minutes, done: false }]
}

// A new list in which one session's done flag is flipped.
export function toggleDone(sessions, id) {
  return sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s))
}
```

Duas dessas funções, `addSession` e `toggleDone`, ainda não são usadas: a aula 5 marca sessões como
feitas com `toggleDone`, e a aula 14 as acrescenta com `addSession`. Elas estão aqui para que o
arquivo de regras seja escrito uma vez, inteiro.

**Nenhuma delas muda o que recebe.** O `addSession` devolve um array novo; o `toggleDone` devolve um
array novo com um objeto novo para a sessão que mudou. É a mesma regra que a última seção deu para um
computed, e pelo mesmo motivo: uma função que só lê a entrada pode ser chamada de qualquer lugar,
inclusive de dentro de um computed, sem surpresas.

As datas são strings em `YYYY-MM-DD` porque essa forma ordena corretamente como texto, então
`s.date >= monday` é uma comparação de datas sem nenhum objeto `Date` envolvido. O `Date` só aparece
onde uma data precisa ser montada ou mostrada, e sempre no fuso horário do próprio computador, então
uma sessão do dia 19 é do dia 19 onde quer que o planner seja aberto.

## O componente

O `App.vue` ganha a segunda-feira, os totais computed e dois botões:

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport { weekStart, addDays, formatDay, weekTotal } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')", "note": "Os imports novos: `computed`, e quatro das regras do planner."},
 {"code": "const monday = ref(weekStart(new Date()))", "note": "A única peça nova de estado: a segunda-feira da semana na tela, começando pela desta semana."},
 {"code": "\nconst total = computed(() => weekTotal(sessions.value, monday.value))\nconst perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)", "note": "Dois valores computed. O `total` é a semana inteira; o `perCourse` é cada curso com os seus totais acrescentados, feitos chamando a mesma regra sobre as sessões daquele curso."},
 {"code": "fetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    sessions.value = data.sessions\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n</script>", "note": "O carregamento não mudou desde a aula 2."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>\n      Week of {{ formatDay(monday) }}: {{ total.done }} of {{ total.planned }} minutes done\n    </p>", "note": "O cabeçalho diz que semana é e quanto foi feito. O `formatDay` é chamado no template porque só formata."},
 {"code": "    <nav>\n      <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n      <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n    </nav>\n  </header>", "note": "Cada botão substitui `monday`, e os dois valores computed acompanham."},
 {"code": "  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in perCourse\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>{{ course.done }} of {{ course.planned }} minutes done, goal {{ course.goal }}</p>\n      </li>\n    </ul>\n  </main>\n  <AppFooter />\n</template>\n\n<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "A lista desenha `perCourse` em vez de `courses`."}
]}
```

O servidor de desenvolvimento do planner está rodando no segundo terminal. O relógio do navegador
decide que semana vem primeiro, então toda transcrição deste curso o fixa na quarta-feira, 21 de
outubro de 2026, com `--clock`:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

Week of 19 October 2026: 75 of 195 minutes done

Previous weekNext week
Statistics

45 of 105 minutes done, goal 180

Spanish

30 of 70 minutes done, goal 120

Guitar

0 of 20 minutes done, goal 90

Built with Vue 3.5.44
```

**75 de 195** são as cinco sessões da semana de 19 de outubro: 45, 30, 60, 20 e 40 minutos
planejados, as duas primeiras feitas. A sessão do dia 12 não está nela. Uma semana para trás:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Previous week' --text header
[vite] connecting...
[vite] connected.
-- click text=Previous week
== the text of header
Study planner

Week of 12 October 2026: 50 of 50 minutes done

Previous weekNext week
```

`text=Previous week` é como o Playwright, e portanto o `look`, encontra um botão pelo que ele diz. A
semana de 12 de outubro tem uma sessão, de 50 minutos, feita.

## De onde vêm os números

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O grafo de dependências do planner. Três refs à esquerda: courses, sessions e monday. Dois valores computed no meio: total lê sessions e monday, e perCourse lê os três refs. O template, à direita, lê total, perCourse e monday. Um clique em Previous week escreve em monday; as setas que saem de monday marcam total, perCourse e o template como desatualizados, e a renderização recalcula cada um uma vez.\"><text x=\"95\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">próprio: ref</text><text x=\"365\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">derivado: computed</text><text x=\"625\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">desenhado</text><rect x=\"30\" y=\"42\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">courses</text><rect x=\"30\" y=\"97\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sessions</text><rect x=\"30\" y=\"152\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">monday</text><rect x=\"300\" y=\"67\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">total</text><rect x=\"300\" y=\"132\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">perCourse</text><rect x=\"560\" y=\"60\" width=\"130\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;template&gt;</text><line x1=\"162\" y1=\"115\" x2=\"298\" y2=\"85\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,85.0 291.5,89.6 290.1,83.5\" fill=\"var(--wire)\"></polygon><line x1=\"162\" y1=\"170\" x2=\"298\" y2=\"85\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,85.0 293.4,91.5 290.1,86.3\" fill=\"var(--amber)\"></polygon><line x1=\"162\" y1=\"60\" x2=\"298\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,150.0 290.1,148.5 293.6,143.3\" fill=\"var(--wire)\"></polygon><line x1=\"162\" y1=\"115\" x2=\"298\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,150.0 290.1,151.2 291.6,145.1\" fill=\"var(--wire)\"></polygon><line x1=\"162\" y1=\"170\" x2=\"298\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,150.0 291.2,154.2 290.3,148.0\" fill=\"var(--amber)\"></polygon><line x1=\"432\" y1=\"85\" x2=\"558\" y2=\"85\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,85.0 550.6,88.1 550.6,81.9\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"432\" y1=\"150\" x2=\"558\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,140.0 550.9,143.7 550.4,137.5\" fill=\"var(--phosphor-dim)\"></polygon><path d=\"M162,180 C300,215 500,215 600,182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"598\" y1=\"186\" x2=\"602\" y2=\"181\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"602.0,181.0 599.8,188.7 595.0,184.8\" fill=\"var(--amber)\"></polygon><text x=\"365\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o template também lê monday</text></svg>", "caption": "Ninguém escreveu estas setas. Cada uma foi registrada quando um computed ou o template leu um valor."}
```

Siga um clique. O `monday` é substituído. O `total` e o `perCourse` leram `monday.value` na última
vez que rodaram, então os dois são marcados como desatualizados. O template leu os dois, então entra
na fila para redesenhar (a fila da aula 2). A renderização lê `total` e `perCourse`, que rodam as suas
funções de novo, uma vez cada. **Nada no código diz "quando a semana mudar, recalcule os totais"**: a
dependência foi registrada quando as funções leram a segunda-feira, e esse é o mecanismo inteiro.

O Guitar mostra 0 de 20 minutos contra uma meta de 90, o que é honesto e um pouco alarmante. A aula 5
deixa você marcar a sessão como feita.
