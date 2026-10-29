---
title: Estado num módulo .svelte.js
version: 1
---

**As runes funcionam fora de componentes, em qualquer arquivo cujo nome termina em `.svelte.js`**, e
foi isso que substituiu a maioria dos stores no Svelte 5. Uma classe com campos `$state` e campos
`$derived` é estado reativo que você pode criar, passar adiante e testar, escrito como uma classe
comum. O estado do planner vem crescendo dentro do `Planner.svelte` desde a aula 3: três estados, sete
valores derivados e duas funções, tudo misturado com a marcação. Esta seção os leva para uma classe
própria.

Salve isto como `src/lib/planner.svelte.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/planner.svelte.js", "parts": [
 {"code": "// planner.svelte.js: the planner's state and its rules, outside any component.\nimport { mondayOf, addDays, inWeek } from '#lib/week.js';", "note": "O nome do arquivo é o que deixa o compilador ler runes aqui: `.svelte.js`, não `.js`."},
 {"code": "export class Planner {\n\tcourses;\n\tsessions = $state([]);\n\tweek = $state('');\n\tselected = $state('');", "note": "Um campo declarado com `$state` é um signal, como uma variável `$state` num componente. O proxy torna o array de sessões profundo, como antes."},
 {"code": "\tthisWeek = $derived(this.sessions.filter((s) => inWeek(s.date, this.week)));\n\ttotal = $derived(minutesOf(this.thisWeek));\n\tdoneMinutes = $derived(minutesOf(this.thisWeek.filter((s) => s.done)));\n\tbyCourse = $derived(totalsBy(this.thisWeek, 'course'));\n\tbyDay = $derived(totalsBy(this.thisWeek, 'date'));\n\tcourse = $derived(this.courses.find((c) => c.id === this.selected));\n\tofCourse = $derived(\n\t\tthis.thisWeek.filter((s) => s.course === this.selected).toSorted((a, b) => (a.date < b.date ? -1 : 1))\n\t);", "note": "Um campo `$derived` é calculado a partir de outros campos quando lido, e memorizado. Eles leem `this`, que é a instância."},
 {"code": "\tconstructor(data) {\n\t\tthis.courses = data.courses;\n\t\tthis.sessions = data.sessions;\n\t\tthis.week = mondayOf(data.sessions.at(-1).date);\n\t\tthis.selected = data.courses[0].id;\n\t}", "note": "O construtor recebe os dados carregados e define os valores iniciais. Nada aqui é uma cópia que possa ficar velha: os campos são o estado."},
 {"code": "\tadd({ date, minutes }) {\n\t\tthis.sessions.push({ id: this.sessions.length + 1, course: this.selected, date, minutes, done: false });\n\t}\n\n\tmove(days) {\n\t\tthis.week = addDays(this.week, days);\n\t}\n}", "note": "As duas coisas que mudam o estado são métodos, então toda mudança no planner passa por este arquivo."},
 {"code": "function minutesOf(sessions) {\n\treturn sessions.reduce((sum, s) => sum + s.minutes, 0);\n}\n\nfunction totalsBy(sessions, field) {\n\tconst minutes = {};\n\tfor (const s of sessions) minutes[s[field]] = (minutes[s[field]] ?? 0) + s.minutes;\n\treturn minutes;\n}", "note": "Funções auxiliares comuns. Não são exportadas, e não sabem nada de runes."}
]}
```

O `Planner.svelte` vira o componente que mostra um `Planner`. Ele cria um a partir dos dados que
recebe, e o lê e o muda através de `planner.`:

```schooling-example
{"language": "html", "file": "src/lib/Planner.svelte", "parts": [
 {"code": "<script>\n\timport { untrack } from 'svelte';\n\timport { Tween, prefersReducedMotion } from 'svelte/motion';\n\timport { addDays, format } from '#lib/week.js';\n\timport { Planner } from '#lib/planner.svelte.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = new Planner(untrack(() => data));\n\tconst shownDone = Tween.of(() => planner.doneMinutes, {\n\t\tduration: prefersReducedMotion.current ? 0 : 400\n\t});\n\n\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') planner.move(-7);\n\t\tif (event.key === 'ArrowRight') planner.move(7);\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${planner.total} min this week · Study planner`;\n\t});\n</script>\n<svelte:window onkeydown={shortcut} />", "note": "Um import substitui os imports do próprio estado. O `untrack` continua, pelo mesmo motivo da aula 8: o planner é criado uma vez, a partir dos dados como foram entregues."},
 {"code": "<p>Left and right arrows move the week.</p>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<CourseList courses={planner.courses} minutes={planner.byCourse} bind:selected={planner.selected} />\n<WeekTotal minutes={planner.total} />\n{#if planner.total === 0}\n\t<p>Nothing planned this week.</p>\n{:else if planner.doneMinutes === planner.total}\n\t<p>Every session this week is done.</p>\n{:else}\n\t<p>{Math.round(shownDone.current)} of {planner.total} minutes done.</p>\n{/if}\n<ol aria-label=\"Minutes per day\">\n\t{#each { length: 7 }, i}\n\t\t{const day = $derived(addDays(planner.week, i))}\n\t\t<li>{format(day)}: {planner.byDay[day] ?? 0} min</li>\n\t{/each}\n</ol>\n\n<Panel title={planner.course.name}>\n\t<List items={planner.ofCourse}>\n\t\t{#snippet row(session)}\n\t\t\t<label class:done={session.done}>\n\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t</label>\n\t\t{/snippet}\n\t\t{#snippet empty()}\n\t\t\t<p>Nothing planned for {planner.course.name} this week.</p>\n\t\t{/snippet}\n\t</List>\n\t<WeekTotal minutes={planner.byCourse[planner.selected] ?? 0} label=\"for {planner.course.name} this week\" />\n\t{#key planner.week}\n\t\t<AddSession onadd={(session) => planner.add(session)} />\n\t{/key}\n</Panel>\n\n<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "A marcação lê os campos da classe. `bind:selected={planner.selected}` liga a um campo, o que funciona porque o campo é `$state`."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Spanish' --fill 'Date=2026-10-21' --press Enter --click 'Previous week' --wait 500
-- click Spanish
-- fill Date=2026-10-21
-- press Enter
-- click Previous week
-- wait 500
at /
title: 90 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra"
      - text: 60 min
    - listitem:
      - button "Spanish" [pressed]
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 0 min
  - paragraph: 90 minutes this week (1 h 30 min)
  - paragraph: Every session this week is done.
  - list "Minutes per day":
    - listitem: "12 Oct 2026: 0 min"
    - listitem: "13 Oct 2026: 60 min"
    - listitem: "14 Oct 2026: 0 min"
    - listitem: "15 Oct 2026: 30 min"
    - listitem: "16 Oct 2026: 0 min"
    - listitem: "17 Oct 2026: 0 min"
    - listitem: "18 Oct 2026: 0 min"
  - region "Spanish":
    - heading "Spanish" [level=2]
    - list:
      - listitem:
        - checkbox "15 Oct 2026, 30 min" [checked]
        - text: 15 Oct 2026, 30 min
    - paragraph: 30 minutes for Spanish this week (0 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

Tudo como antes, que é o teste de uma refatoração: Spanish selecionado, uma sessão acrescentada no dia
21, e depois de volta à semana de 12 de outubro, onde a meia hora de espanhol do dia 15 é a única
sessão mostrada.

## O que a classe dá a você

**Um nome para as regras do planner, e um arquivo onde elas moram.** "Acrescentar uma sessão" e "mover
a semana" agora são métodos, então a pergunta "o que pode mudar o planner?" tem uma resposta curta: os
métodos, e os três campos que o componente liga. E a classe não precisa de um componente para existir:
a aula 19 cria um `Planner` num teste, acrescenta uma sessão e confere o total, sem navegador e sem
página.

Dois detalhes importam. **Uma rune num campo de classe torna o campo reativo**: `total = $derived(…)`
é transformado pelo compilador num signal privado com um getter na frente, então ler `planner.total`
é rastreado, a partir de um componente ou de qualquer outro lugar. E **desestruturar perde isso**,
exatamente como a aula 2 avisou: `const { total } = planner` copia o número uma vez. Leia através de
`planner.` onde precisar do valor.
