---
title: A semana pertence ao endereço
version: 1
---

**Todo formulário agora termina num redirecionamento, e todo redirecionamento esquece a semana.** A
semana é um campo do planner na memória, então qualquer carregamento completo de página recomeça do
padrão, a semana da sessão acrescentada por último. Com o JavaScript ligado, volte uma semana na página
de espanhol e mude de ideia sobre o dia 15:

```
ana@dev:~/planner$ look http://localhost:5173/courses/spanish --click 'Previous week' --click 'Mark not done: 15 Oct 2026'
-- click Previous week
-- click Mark not done: 15 Oct 2026
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
      - text: 22 Oct 2026, 30 min
      - 'button "Mark done: 22 Oct 2026"': Mark done
  - paragraph: 30 minutes for Spanish this week (0 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

A mudança foi salva, e o estudante, que estava olhando a semana do dia 12, agora está olhando a semana
do dia 19, onde a sessão que ele acabou de mudar não está. Com o JavaScript desligado é pior: os botões
da semana não fazem nada, então a semana do dia 19 é a única que existe.

**Estado que diz o que a pessoa está olhando pertence ao endereço.** Assim um link pode levá-lo, um
redirecionamento pode voltar a ele, um recarregamento o mantém, um favorito o guarda, e o servidor pode
renderizá-lo, porque o servidor vê o endereço. A semana vira um parâmetro da query, `?week=2026-10-12`,
e os botões viram links para as semanas de cada lado.

## Lendo a semana

A semana vem da URL, então é lida numa função load, e numa universal: ela não precisa de nada do
servidor, e no navegador consegue mudar a semana sem perguntar nada ao servidor. O grupo `(planner)` já
tem um `+layout.server.js`. Um `+layout.js` ao lado dele recebe o que a função do servidor devolveu,
como `data`, e o que ele devolve por sua vez é o que as páginas recebem. Salve-o como
`src/routes/(planner)/+layout.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.js", "parts": [
 {"code": "// +layout.js: the week the address asks for, added to what the server loaded.\nimport { isDate, mondayOf } from '#lib/week.js';"},
 {"code": "export function load({ data, url }) {\n\tconst asked = url.searchParams.get('week');", "note": "`data` é o que o `+layout.server.js` devolveu. Ler `url.searchParams` faz esta função rodar de novo sempre que `?week` muda, e só então."},
 {"code": "\tconst week = isDate(asked ?? '') ? mondayOf(asked) : mondayOf(data.sessions.at(-1).date);\n\treturn { ...data, week };\n}", "note": "Um endereço pode conter qualquer coisa, então `?week=banana` recebe a semana padrão em vez de um erro."}
]}
```

e os botões viram links. Substitua o `src/lib/WeekNav.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/WeekNav.svelte", "parts": [
 {"code": "<script>\n\timport { addDays, format } from '#lib/week.js';\n\n\tlet { week, label = 'Week of' } = $props();\n</script>"},
 {"code": "<p data-sveltekit-reset=\"false\">\n\t<a href=\"?week={addDays(week, -7)}\">Previous week</a>\n\t{label} {format(week)}\n\t<a href=\"?week={addDays(week, 7)}\">Next week</a>\n</p>", "note": "`data-sveltekit-reset=\"false\"` mantém o foco no link que foi pressionado e a página onde estava rolada, para que uma pessoa que aperta Enter em \"Next week\" possa apertar de novo."}
]}
```

Um link que começa com `?` mantém a página e muda só a query, então o mesmo componente funciona na
página da semana e na página de um curso. Experimente:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week'
-- click Next week
at /?week=2026-10-26
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-12"
    - text: Week of 19 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-26"
  - list:
    - listitem:
      - link "Linear algebra":
        - /url: /courses/algebra
      - text: 150 min
    - listitem:
      - link "Spanish":
        - /url: /courses/spanish
      - text: 30 min
    - listitem:
      - link "Guitar":
        - /url: /courses/guitar
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 150 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
```

**O endereço diz dia 26 e a página diz dia 19.** O link funcionou e a função load devolveu a semana
nova: o planner nunca perguntou. Ele ainda tem um `week` próprio, definido uma vez no construtor a
partir dos dados que recebeu, e o `PlannerProvider` lhe deu esses dados uma vez, por meio do `untrack`,
como a aula 13 avisou no fim de "Quando uma função load roda de novo". Agora há duas respostas para
"qual semana", o endereço e a cópia do planner, que é a situação que a aula 12 tirou o curso
selecionado para evitar.

## Um planner que lê os dados em vez de copiá-los

A cura é o planner não guardar cópia nenhuma: ele recebe uma **função que devolve os dados atuais**, e
cada campo que ele tem é derivado do que essa função devolve. Quando uma função load roda de novo,
`data` muda, a função devolve os dados novos, e todo campo derivado é recalculado. Substitua o
`src/lib/planner.svelte.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/planner.svelte.js", "parts": [
 {"code": "// planner.svelte.js: the planner's rules, over data that arrives from the load functions.\nimport { inWeek } from '#lib/week.js';\n\nexport class Planner {\n\t#data;"},
 {"code": "\tcourses = $derived(this.#data().courses);\n\tsessions = $derived(this.#data().sessions);\n\tweek = $derived(this.#data().week);\n\n\tthisWeek = $derived(this.sessions.filter((s) => inWeek(s.date, this.week)));\n\ttotal = $derived(minutesOf(this.thisWeek));\n\tdoneMinutes = $derived(minutesOf(this.thisWeek.filter((s) => s.done)));\n\tbyCourse = $derived(totalsBy(this.thisWeek, 'course'));\n\tbyDay = $derived(totalsBy(this.thisWeek, 'date'));", "note": "Três campos que eram estado agora são derivados. Nada no planner é mais definido; ele só lê."},
 {"code": "\t/** @param {() => any} data a function that returns the current data */\n\tconstructor(data) {\n\t\tthis.#data = data;\n\t}\n\n\tcourse(id) {\n\t\treturn this.courses.find((c) => c.id === id);\n\t}\n\n\tsessionsFor(id) {\n\t\treturn this.thisWeek.filter((s) => s.course === id).toSorted((a, b) => (a.date < b.date ? -1 : 1));\n\t}\n}\n\nfunction minutesOf(sessions) {\n\treturn sessions.reduce((sum, s) => sum + s.minutes, 0);\n}\n\nfunction totalsBy(sessions, field) {\n\tconst minutes = {};\n\tfor (const s of sessions) minutes[s[field]] = (minutes[s[field]] ?? 0) + s.minutes;\n\treturn minutes;\n}", "note": "Um campo derivado é calculado quando é lido pela primeira vez, o que acontece depois de o construtor guardar a função."}
]}
```

`add` e `move` foram embora: acrescentar agora é trabalho do servidor, e mudar a semana é uma mudança de
endereço. O atalho de teclado muda a semana do mesmo jeito, com `goto` de `$app/navigation`, que é um
clique num link escrito em código. Substitua o `src/lib/PlannerProvider.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/PlannerProvider.svelte", "parts": [
 {"code": "<script>\n\timport { goto } from '$app/navigation';\n\timport { addDays } from '#lib/week.js';\n\timport { Planner } from '#lib/planner.svelte.js';\n\timport { setPlanner } from '#lib/context.js';\n\n\tlet { data, children } = $props();"},
 {"code": "\tconst planner = setPlanner(new Planner(() => data));\n\n\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tconst days = { ArrowLeft: -7, ArrowRight: 7 }[event.key];", "note": "`() => data` lê a prop cada vez que é chamada, então sempre devolve os dados mais novos. Sem `untrack`: nada é lido aqui, só depois."},
 {"code": "\t\tif (days) goto(`?week=${addDays(planner.week, days)}`, { reset: false });\n\t}\n</script>\n\n<svelte:window onkeydown={shortcut} />\n\n{@render children()}", "note": "`reset: false` é o mesmo que o atributo nos links: o foco e a rolagem ficam onde estão."}
]}
```

O comentário no topo de `src/lib/context.js` ainda cita `Planner.svelte`, de antes da aula 12. Faça
ele dizer o que é verdade:

```schooling-example
{"language": "javascript", "file": "src/lib/context.js", "parts": [
 {"code": "// context.js: the planner, shared with the pages inside PlannerProvider.svelte.\nimport { createContext } from 'svelte';\n\nexport const [getPlanner, setPlanner] = createContext();", "note": "Só o comentário muda. O contexto continua guardando um único objeto planner enquanto o provider existir; o que muda é o que esse objeto lê."}
]}
```

## Levando a semana a todo lugar aonde ela deve ir

Os links de curso na página da semana levam a semana para a página do curso. Substitua o
`src/lib/CourseList.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes, week } = $props();\n</script>\n\n<ul>\n\t{#each courses as c}\n\t\t<li><a href=\"/courses/{c.id}?week={week}\">{c.name}</a> {minutes[c.id] ?? 0} min</li>\n\t{/each}\n</ul>", "note": "`week` é novo: cada link leva a semana que o estudante está olhando."},
 {"code": "<style>\n\tul {\n\t\tlist-style: none;\n\t\tpadding: 0;\n\t}\n\n\tli {\n\t\tdisplay: flex;\n\t\tjustify-content: space-between;\n\t\tmax-width: 20rem;\n\t}\n</style>"}
]}
```

e a página da semana a repassa, e não tem mais semana para mudar. Substitua o
`src/routes/(planner)/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/+page.svelte", "parts": [
 {"code": "<script>\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport Status from '#lib/Status.svelte';\n\timport Days from '#lib/Days.svelte';\n\n\tconst planner = getPlanner();\n</script>\n\n<svelte:head>\n\t<title>{planner.total} min this week · Study planner</title>\n</svelte:head>\n\n<h1>Study planner</h1>\n<p>Left and right arrows move the week.</p>\n<WeekNav week={planner.week} />\n<CourseList courses={planner.courses} minutes={planner.byCourse} week={planner.week} />\n<WeekTotal minutes={planner.total} />\n<Status />\n<Days />", "note": "Nada de `onchange` no `WeekNav`, e a semana é passada ao `CourseList`."}
]}
```

As actions redirecionam para a semana da sessão que mudaram, então uma sessão acrescentada no dia 14
aparece na semana do dia 12. Substitua o `+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's forms do, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession, setDone } from '#lib/server/planner.js';\nimport { isDate, mondayOf } from '#lib/week.js';\n\nexport const actions = {\n\tadd: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));\n\n\t\tif (!isDate(date)) return fail(400, { date, minutes, problem: 'The session needs a date.' });\n\t\tif (!Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\t\treturn fail(400, { date, minutes, problem: 'Minutes must be a whole number from 5 to 600.' });\n\t\t}\n\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(date)}`);\n\t},\n\n\tdone: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst session = await setDone(Number(form.get('id')), form.get('done') === 'yes');\n\t\tif (!session) error(404, 'There is no such session.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(session.date)}`);\n\t}\n};", "note": "Os dois redirecionamentos agora nomeiam uma semana: a semana da data acrescentada, ou da sessão marcada."}
]}
```

Os formulários da página do curso precisam de mais uma mudança, e é a que passa despercebida com
facilidade. Um formulário cujo `action` é `?/add` é enviado ao caminho da página com **essa** query,
então o `?week=2026-10-12` se perde no caminho. Um formulário que falhou renderiza então a semana
padrão. A semana vai também no endereço do formulário, antes do nome da action:
`?week=2026-10-12&/add`. Substitua o `src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} />\n<List items={sessions}>\n\t{#snippet row(session)}"},
 {"code": "\t\t<form method=\"POST\" action=\"?week={planner.week}&/done\">\n\t\t\t<input type=\"hidden\" name=\"id\" value={session.id} />\n\t\t\t<input type=\"hidden\" name=\"done\" value={session.done ? 'no' : 'yes'} />\n\t\t\t<span class:done={session.done}>{format(session.date)}, {session.minutes} min</span>\n\t\t\t<button aria-label=\"{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}\">\n\t\t\t\t{session.done ? 'Mark not done' : 'Mark done'}\n\t\t\t</button>\n\t\t</form>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession action=\"?week={planner.week}&/add\" />\n{/key}", "note": "A semana primeiro, depois `&`, depois o nome da action, que o SvelteKit lê do fim da query."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

## Com o JavaScript desligado, cada parte

```
ana@dev:~/planner$ look http://localhost:5173/ --no-js --click 'Previous week' --click 'Guitar' --fill 'Date=2026-10-14' --click 'Add session'
-- click Previous week
-- click Guitar
-- fill Date=2026-10-14
-- click Add session
at /courses/guitar?week=2026-10-12
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-05"
    - text: Week of 12 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-19"
  - list:
    - listitem:
      - text: 14 Oct 2026, 30 min
      - 'button "Mark done: 14 Oct 2026"': Mark done
  - paragraph: 30 minutes for Guitar this week (0 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

**Uma semana para trás, para dentro de Guitar, uma sessão no dia 14, e a página mostra a semana em que
ela está**, tudo sem uma linha de JavaScript no navegador. O link `Guitar` na página da semana levou a
semana para a página do curso, o formulário a levou para a action, e o redirecionamento da action
mandou o navegador para a semana do dia 14. Com o JavaScript ligado, os mesmos links são navegações no
cliente, e as setas do teclado voltam a funcionar:

```
ana@dev:~/planner$ look 'http://localhost:5173/?week=2026-10-19' --press ArrowLeft --wait 300 | head -10
-- press ArrowLeft
-- wait 300
at /?week=2026-10-12
title: 120 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-05"
```
