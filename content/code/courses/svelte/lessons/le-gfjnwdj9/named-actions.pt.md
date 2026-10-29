---
title: Actions com nome, para mais de um formulário
version: 1
---

**Uma página pode ter várias actions, cada uma com um nome, e um formulário diz para qual delas está
enviando no seu atributo `action`, como `?/nome`.** A página do curso precisa de uma segunda. O
checkbox que marca uma sessão como feita muda o planner na memória, então com o JavaScript desligado
ele não faz nada, e com ele ligado a mudança some no próximo recarregamento. Como formulário, ela pode
ser salva como todo o resto.

`default` não pode conviver com actions com nome, então a action que acrescenta vira `add`. Substitua o
`+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's forms do, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession, setDone } from '#lib/server/planner.js';\nimport { isDate } from '#lib/week.js';\n\nexport const actions = {\n\tadd: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));\n\n\t\tif (!isDate(date)) return fail(400, { date, minutes, problem: 'The session needs a date.' });\n\t\tif (!Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\t\treturn fail(400, { date, minutes, problem: 'Minutes must be a whole number from 5 to 600.' });\n\t\t}\n\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}`);\n\t},"},
 {"code": "\tdone: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst session = await setDone(Number(form.get('id')), form.get('done') === 'yes');\n\t\tif (!session) error(404, 'There is no such session.');\n\n\t\tredirect(303, `/courses/${params.id}`);\n\t}\n};", "note": "O formulário diz qual sessão e para que lado, em dois campos. Um id que não nomeia nenhuma sessão é um 404, como um curso que não existe."}
]}
```

O `AddSession` recebe como prop o endereço para onde enviar, já que é a página que conhece as suas
actions. Substitua o `src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';\n\n\tlet { action } = $props();\n\tlet form = $derived(page.form);\n</script>"},
 {"code": "<form method=\"POST\" {action}>\n\t{#if form?.problem}\n\t\t<p role=\"alert\">{form.problem}</p>\n\t{/if}\n\t<label>Date <input type=\"date\" name=\"date\" required value={form?.date ?? ''} /></label>\n\t<label>Minutes <input type=\"number\" name=\"minutes\" min=\"5\" max=\"600\" step=\"5\" required value={form?.minutes ?? 30} /></label>\n\t<button>Add session</button>\n</form>", "note": "`{action}` é a forma curta de `action={action}`, o atributo definido a partir da prop de mesmo nome."}
]}
```

A linha de cada sessão vira um pequeno formulário próprio, com o id da sessão num campo oculto e um
botão. Substitua o `src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<List items={sessions}>\n\t{#snippet row(session)}"},
 {"code": "\t\t<form method=\"POST\" action=\"?/done\">\n\t\t\t<input type=\"hidden\" name=\"id\" value={session.id} />\n\t\t\t<input type=\"hidden\" name=\"done\" value={session.done ? 'no' : 'yes'} />\n\t\t\t<span class:done={session.done}>{format(session.date)}, {session.minutes} min</span>", "note": "Um input oculto é enviado com o formulário e não aparece. `done` diz o que definir, o contrário do que a sessão é agora."},
 {"code": "\t\t\t<button aria-label=\"{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}\">\n\t\t\t\t{session.done ? 'Mark not done' : 'Mark done'}\n\t\t\t</button>\n\t\t</form>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession action=\"?/add\" />\n{/key}", "note": "Toda linha tem um botão com o mesmo texto, então o label acrescenta a data. Ele começa com as palavras visíveis, para que uma pessoa que diga \"click Mark done\" a um controle por voz seja entendida."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/algebra --no-js --click 'Mark done: 24 Oct 2026'
-- click Mark done: 24 Oct 2026
at /courses/algebra
title: Linear algebra · Study planner
- main:
  - heading "Linear algebra" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - text: 19 Oct 2026, 90 min
      - 'button "Mark not done: 19 Oct 2026"': Mark not done
    - listitem:
      - text: 24 Oct 2026, 60 min
      - 'button "Mark not done: 24 Oct 2026"': Mark not done
  - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

**O dia 24 está feito, e salvo**, com o JavaScript desligado. O navegador enviou `id=6&done=yes` para
`/courses/algebra?/done`, a action `done` salvou e redirecionou para `/courses/algebra`, e a página que
o navegador pediu em seguida leu o arquivo de novo. O `?/done` no endereço para onde o formulário foi
enviado é como o SvelteKit escolhe a action; depois do redirecionamento ele não está na barra de
endereço, mais uma coisa que o Post/Redirect/Get arruma.

O nome do botão, `Mark done: 24 Oct 2026`, é mais longo que o seu texto de propósito. Um leitor de tela
que lista os botões da página leria, de outro modo, "Mark done, Mark done, Mark done", e deixaria a
pessoa adivinhar qual é qual.
