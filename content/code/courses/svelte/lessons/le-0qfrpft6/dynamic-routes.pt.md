---
title: Uma rota com um parâmetro
version: 1
---

**Uma pasta cujo nome está entre colchetes é um parâmetro**: `src/routes/(planner)/courses/[id]/+page.svelte`
responde a `/courses/algebra`, `/courses/spanish` e `/courses/anything`, e entrega à página a parte do
endereço que casou, como `params.id`. Um arquivo faz uma página para cada curso, inclusive os que ninguém
criou ainda.

## O planner, sem uma seleção

Desde a aula 3 o planner guarda um curso `selected` no seu estado, porque a página mostrava um curso de
cada vez. Com uma página por curso, o endereço diz qual é o curso, e um curso selecionado no estado seria
uma segunda resposta para a mesma pergunta, que poderia discordar da primeira. Então a classe perde o
`selected` e os dois valores derivados dele, e ganha dois métodos que recebem o curso como argumento.
Substitua o `src/lib/planner.svelte.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/planner.svelte.js", "parts": [
 {"code": "// planner.svelte.js: the planner's state and its rules, outside any component.\nimport { mondayOf, addDays, inWeek } from '#lib/week.js';\n\nexport class Planner {\n\tcourses;\n\tsessions = $state([]);\n\tweek = $state('');\n\n\tthisWeek = $derived(this.sessions.filter((s) => inWeek(s.date, this.week)));\n\ttotal = $derived(minutesOf(this.thisWeek));\n\tdoneMinutes = $derived(minutesOf(this.thisWeek.filter((s) => s.done)));\n\tbyCourse = $derived(totalsBy(this.thisWeek, 'course'));\n\tbyDay = $derived(totalsBy(this.thisWeek, 'date'));\n\n\tconstructor(data) {\n\t\tthis.courses = data.courses;\n\t\tthis.sessions = data.sessions;\n\t\tthis.week = mondayOf(data.sessions.at(-1).date);\n\t}", "note": "Dois campos de estado agora: as sessões e a semana. Qual curso está sendo visto pertence ao endereço."},
 {"code": "\tcourse(id) {\n\t\treturn this.courses.find((c) => c.id === id);\n\t}\n\n\tsessionsFor(id) {\n\t\treturn this.thisWeek.filter((s) => s.course === id).toSorted((a, b) => (a.date < b.date ? -1 : 1));\n\t}", "note": "Métodos que leem estado são reativos quando chamados de um `$derived` ou da marcação: o que eles leem por dentro é rastreado como qualquer leitura."},
 {"code": "\tadd({ course, date, minutes }) {\n\t\tthis.sessions.push({ id: this.sessions.length + 1, course, date, minutes, done: false });\n\t}\n\n\tmove(days) {\n\t\tthis.week = addDays(this.week, days);\n\t}\n}\n\nfunction minutesOf(sessions) {\n\treturn sessions.reduce((sum, s) => sum + s.minutes, 0);\n}\n\nfunction totalsBy(sessions, field) {\n\tconst minutes = {};\n\tfor (const s of sessions) minutes[s[field]] = (minutes[s[field]] ?? 0) + s.minutes;\n\treturn minutes;\n}", "note": "`add` agora recebe o curso junto com o resto da sessão, de qualquer página que a esteja acrescentando."}
]}
```

## A página do curso

Salve isto como `src/routes/(planner)/courses/[id]/+page.svelte`. É o painel da aula 6, promovido a
página: as sessões do curso nesta semana, o total dele e o formulário, com a navegação da semana no topo
para que o estudante possa passar pelas semanas sem voltar:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { params } = $props();\n\n\tconst planner = getPlanner();", "note": "Uma página recebe os parâmetros da rota como a prop `params`. `params.id` é a parte do endereço no lugar de `[id]`."},
 {"code": "\tlet course = $derived(planner.course(params.id));\n\tlet sessions = $derived(planner.sessionsFor(params.id));\n</script>\n\n<svelte:head>\n\t<title>{course?.name ?? 'No such course'} · Study planner</title>\n</svelte:head>", "note": "Derivado do parâmetro, então seguir um link de um curso para outro atualiza a página sem recriá-la."},
 {"code": "{#if course}\n\t<h1>{course.name}</h1>\n\t<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n\t<List items={sessions}>\n\t\t{#snippet row(session)}\n\t\t\t<label class:done={session.done}>\n\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t</label>\n\t\t{/snippet}\n\t\t{#snippet empty()}\n\t\t\t<p>Nothing planned for {course.name} this week.</p>\n\t\t{/snippet}\n\t</List>\n\t<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n\t{#key planner.week}\n\t\t<AddSession onadd={(session) => planner.add({ ...session, course: course.id })} />\n\t{/key}\n{:else}\n\t<h1>No such course</h1>\n\t<p>There is no course called “{params.id}”. <a href=\"/\">Back to the planner</a></p>\n{/if}\n\n<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "Um endereço pode nomear um curso que não existe. A página diz isso, em vez de falhar em `course.name`."}
]}
```

A partir da semana, siga o link de um curso:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Spanish'
-- click Spanish
at /courses/spanish
title: Spanish · Study planner
- main:
  - heading "Spanish" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - checkbox "22 Oct 2026, 30 min"
      - text: 22 Oct 2026, 30 min
  - paragraph: 30 minutes for Spanish this week (0 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

`at /courses/spanish`, com a única sessão de espanhol desta semana. **A semana veio junto**: o planner
mora no layout `(planner)`, que ficou enquanto a página dentro dele mudava, então o planner, a semana e
cada sessão acrescentada são os mesmos nas duas páginas. Vá para a semana anterior, acrescente uma
sessão, volte para a página da semana, e está tudo lá:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --click 'Previous week' --fill 'Date=2026-10-14' --press Enter --click 'Study planner'
-- click Previous week
-- fill Date=2026-10-14
-- press Enter
-- click Study planner
at /
title: 120 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - link "Linear algebra":
        - /url: /courses/algebra
      - text: 60 min
    - listitem:
      - link "Spanish":
        - /url: /courses/spanish
      - text: 30 min
    - listitem:
      - link "Guitar":
        - /url: /courses/guitar
      - text: 30 min
  - paragraph: 120 minutes this week (2 h 0 min)
  - paragraph: 90 of 120 minutes done.
  - list "Minutes per day":
    - listitem: "12 Oct 2026: 0 min"
    - listitem: "13 Oct 2026: 60 min"
    - listitem: "14 Oct 2026: 30 min"
    - listitem: "15 Oct 2026: 30 min"
    - listitem: "16 Oct 2026: 0 min"
    - listitem: "17 Oct 2026: 0 min"
    - listitem: "18 Oct 2026: 0 min"
```

Trinta minutos de violão no dia 14, acrescentados na página do curso, contados na página da semana, com
a semana de 12 de outubro ainda aparecendo. E um endereço com um curso que ninguém planejou:

```
ana@dev:~/planner$ look http://localhost:5173/courses/piano
at /courses/piano
title: No such course · Study planner
- main:
  - heading "No such course" [level=1]
  - paragraph:
    - text: There is no course called “piano”.
    - link "Back to the planner":
      - /url: /
```

O `Panel.svelte` não tem mais nada a fazer: a página do curso agora é o painel. Ele pode ficar em
`src/lib`, ou ser apagado com `git rm src/lib/Panel.svelte`; nada o importa.
