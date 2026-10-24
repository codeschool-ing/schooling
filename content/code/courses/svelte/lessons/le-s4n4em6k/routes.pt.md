---
title: As rotas, os hooks e o ./$types
version: 1
---

**O SvelteKit escreve um arquivo de tipos para cada rota**, descrevendo os parâmetros dela, o que as
funções load dos pais devolvem e o que as dela devolvem. Um arquivo de rota os importa de
**`./$types`**, um módulo que parece estar ao lado do arquivo e na verdade fica em `.svelte-kit`, onde o
`svelte-kit sync` o põe. Anote uma função load com um deles, e o verificador sabe o que `params`,
`parent()` e `data` guardam sem ninguém dizer.

Renomeie os arquivos de rota e os hooks:

```
ana@dev:~/planner$ git mv 'src/routes/(planner)/+layout.server.js' 'src/routes/(planner)/+layout.server.ts'
ana@dev:~/planner$ git mv 'src/routes/(planner)/+layout.js' 'src/routes/(planner)/+layout.ts'
ana@dev:~/planner$ git mv 'src/routes/(planner)/courses/[id=slug]/+page.js' 'src/routes/(planner)/courses/[id=slug]/+page.ts'
ana@dev:~/planner$ git mv 'src/routes/(planner)/courses/[id=slug]/+page.server.js' 'src/routes/(planner)/courses/[id=slug]/+page.server.ts'
ana@dev:~/planner$ git mv 'src/routes/(planner)/courses/[id=slug]/+server.js' 'src/routes/(planner)/courses/[id=slug]/+server.ts'
ana@dev:~/planner$ git mv 'src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.js' 'src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.ts'
ana@dev:~/planner$ git mv src/routes/planner.json/+server.js src/routes/planner.json/+server.ts
ana@dev:~/planner$ git mv src/routes/api/sessions/+server.js src/routes/api/sessions/+server.ts
ana@dev:~/planner$ git mv src/hooks.server.js src/hooks.server.ts
```

As duas funções load do layout de `(planner)` vêm primeiro, já que tudo abaixo delas lê o que elas
devolvem. Substitua `src/routes/(planner)/+layout.server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/+layout.server.ts", "parts": [
 {"code": "// +layout.server.ts: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';\nimport type { LayoutServerLoad } from './$types';\n\nexport const load: LayoutServerLoad = async () => {\n\treturn readPlanner();\n};", "note": "`LayoutServerLoad` é o tipo da função load de servidor deste layout. Escrever `load` como uma `const` com esse tipo é o que deixa o verificador checar o argumento e o resultado dela."}
]}
```

e `src/routes/(planner)/+layout.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/+layout.ts", "parts": [
 {"code": "// +layout.ts: the week the address asks for, added to what the server loaded.\nimport { isDate, mondayOf } from '#lib/week.js';\nimport type { LayoutLoad } from './$types';\n\nexport const load: LayoutLoad = ({ data, url }) => {\n\tconst asked = url.searchParams.get('week');\n\tconst week = isDate(asked) ? mondayOf(asked) : mondayOf(data.sessions.at(-1)!.date);\n\treturn { ...data, week };\n};", "note": "`data` recebe o tipo do que o `+layout.server.ts` devolve, um `PlannerData`, então se sabe que `data.sessions` é um array de sessões. O `!` depois de `at(-1)` diz ao verificador que o array não está vazio, o que ele não tem como saber: um planner sem sessões falharia aqui, e o `!` é uma promessa que alguém tem de cumprir."}
]}
```

A função load da página do curso. Substitua `src/routes/(planner)/courses/[id=slug]/+page.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/courses/[id=slug]/+page.ts", "parts": [
 {"code": "// +page.ts: the course a course page is about, or a 404.\nimport { error } from '@sveltejs/kit';\nimport type { PageLoad } from './$types';\n\nexport const load: PageLoad = async ({ params, parent }) => {\n\tconst { courses } = await parent();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn { course };\n};", "note": "`parent()` devolve os dados juntos dos layouts de cima, com tipo, então `courses` é um `Course[]` e `c.id` é checado. Depois do `if`, o verificador sabe que `course` não pode ser `undefined`, porque `error()` nunca retorna."}
]}
```

As actions dela. Substitua `src/routes/(planner)/courses/[id=slug]/+page.server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.ts", "parts": [
 {"code": "// +page.server.ts: what a course page's forms do, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession, setDone } from '#lib/server/planner.js';\nimport { problemWith } from '#lib/server/check.js';\nimport { mondayOf } from '#lib/week.js';\nimport type { Actions } from './$types';\n\nexport const actions = {\n\tadd: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));\n\n\t\tconst problem = problemWith({ date, minutes });\n\t\tif (problem) return fail(400, { date, minutes, problem });\n\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(date)}`);\n\t},\n\n\tdone: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst session = await setDone(Number(form.get('id')), form.get('done') === 'yes');\n\t\tif (!session) error(404, 'There is no such session.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(session.date)}`);\n\t}\n} satisfies Actions;", "note": "`satisfies Actions` checa o objeto contra o tipo e mantém o tipo do próprio objeto, mais exato, que é o que deixa a página saber o que cada action pode devolver em `form`."}
]}
```

Os três endpoints ganham `RequestHandler`, que dá tipo ao `event` que as funções deles recebem.
`src/routes/(planner)/courses/[id=slug]/+server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/courses/[id=slug]/+server.ts", "parts": [
 {"code": "// +server.ts: a course and all its sessions, as JSON, for a request that does not ask for HTML.\nimport { error, json } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';\nimport type { RequestHandler } from './$types';\n\nexport const GET: RequestHandler = async ({ params }) => {\n\tconst { courses, sessions } = await readPlanner();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn json({ course, sessions: sessions.filter((s) => s.course === course.id) });\n};", "note": "A mesma função da aula 17, com o seu tipo. `params.id` é uma `string`, vinda do nome da pasta da rota."}
]}
```

`src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.ts", "parts": [
 {"code": "// +server.ts: a course's sessions as a CSV file, for a spreadsheet.\nimport { error } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';\nimport type { RequestHandler } from './$types';\n\nexport const GET: RequestHandler = async ({ params }) => {\n\tconst { courses, sessions } = await readPlanner();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\n\tconst rows = sessions\n\t\t.filter((s) => s.course === course.id)\n\t\t.toSorted((a, b) => (a.date < b.date ? -1 : 1))\n\t\t.map((s) => [course.name, s.date, s.minutes, s.done ? 'yes' : 'no']);\n\tconst text = [['course', 'date', 'minutes', 'done'], ...rows].map((row) => row.map(cell).join(',')).join('\\r\\n') + '\\r\\n';\n\n\treturn new Response(text, {\n\t\theaders: {\n\t\t\t'Content-Type': 'text/csv; charset=utf-8',\n\t\t\t'Content-Disposition': `attachment; filename=\"${course.id}-sessions.csv\"`\n\t\t}\n\t});\n};\n\n// A value as a CSV cell: with a leading apostrophe if a spreadsheet would take it for a\n// formula, and in quotes if it holds a comma, a quote or a line break.\nfunction cell(value: string | number) {\n\tlet text = String(value);\n\tif (/^[=+\\-@]/.test(text)) text = `'${text}`;\n\treturn /[\",\\r\\n]/.test(text) ? `\"${text.replaceAll('\"', '\"\"')}\"` : text;\n}", "note": "Só duas coisas mudam em relação à aula 17: o tipo `RequestHandler`, e um tipo no parâmetro de `cell`, que recebe as strings e os números que uma linha guarda."}
]}
```

`src/routes/planner.json/+server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/planner.json/+server.ts", "parts": [
 {"code": "// +server.ts: the planner's data, as JSON, at /planner.json.\nimport { json } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';\nimport type { RequestHandler } from './$types';\n\nexport const GET: RequestHandler = async () => {\n\treturn json(await readPlanner());\n};", "note": "O mais curto deles, e mesmo assim vale o seu tipo: checa-se que `json()` é o que ele devolve."}
]}
```

e `src/routes/api/sessions/+server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/api/sessions/+server.ts", "parts": [
 {"code": "// +server.ts: add a session from another program, as JSON, at /api/sessions.\nimport { error, json } from '@sveltejs/kit';\nimport { addSession } from '#lib/server/planner.js';\nimport { problemWith } from '#lib/server/check.js';\nimport type { RequestHandler } from './$types';\n\nexport const POST: RequestHandler = async ({ request }) => {\n\tif (!request.headers.get('content-type')?.startsWith('application/json')) {\n\t\terror(415, 'Send the session as JSON, with Content-Type: application/json.');\n\t}\n\tconst body = await request.json().catch(() => error(400, 'The body is not valid JSON.'));\n\n\tconst problem = problemWith(body);\n\tif (problem) error(400, problem);\n\tconst session = { course: String(body.course), date: body.date, minutes: body.minutes };\n\tif (!(await addSession(session))) error(404, `There is no course called “${session.course}”.`);\n\n\treturn json(session, { status: 201 });\n};", "note": "`request.json()` devolve `any`, que o verificador deixa usar do jeito que se quiser. Por isso `body` passa pelo `problemWith`, que recebe `unknown`, antes de qualquer coisa depender dos campos dele, e `course` vira string explicitamente, já que nada checou que é uma."}
]}
```

## locals e App.Error

O hook da aula 16 pôs um `id` em `event.locals` e no erro que devolvia, e o verificador não conhece
nenhum dos dois: `App.Locals` e `App.Error` são os tipos do SvelteKit para esses dois objetos, vazios até
a aplicação dizer o que guarda neles. Isso se faz em **`src/app.d.ts`**, um arquivo só de declarações.
Salve-o:

```schooling-example
{"language": "typescript", "file": "src/app.d.ts", "parts": [
 {"code": "// app.d.ts: the types SvelteKit lets an application add to its own.\ndeclare global {\n\tnamespace App {\n\t\tinterface Locals {\n\t\t\t/** A short id for the request, set by the log hook. */\n\t\t\tid: string;\n\t\t}\n\t\tinterface Error {\n\t\t\t/** The request's id, on errors that handleError answered. */\n\t\t\tid?: string;\n\t\t}\n\t}\n}\n\nexport {};", "note": "`declare global` acrescenta ao namespace `App` que o SvelteKit declara, em vez de criar um novo. `id` é opcional nos erros porque só os inesperados ganham um."}
]}
```

e os hooks pegam os seus tipos de `@sveltejs/kit/hooks`. Substitua `src/hooks.server.ts`:

```schooling-example
{"language": "typescript", "file": "src/hooks.server.ts", "parts": [
 {"code": "// hooks.server.ts: code that runs around every request the server answers.\nimport { sequence } from '@sveltejs/kit/hooks';\nimport type { Handle, HandleServerError } from '@sveltejs/kit/hooks';\nimport { building } from '$app/env';\n\nconst log: Handle = async ({ event, resolve }) => {\n\tevent.locals.id = crypto.randomUUID().slice(0, 8);\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.locals.id} ${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n};\n\nconst headers: Handle = async ({ event, resolve }) => {\n\tconst response = await resolve(event);\n\tresponse.headers.set('X-Content-Type-Options', 'nosniff');\n\tresponse.headers.set('Referrer-Policy', 'same-origin');\n\tresponse.headers.set('X-Frame-Options', 'DENY');\n\treturn response;\n};\n\nexport const handle = sequence(log, headers);\n\nexport const handleError: HandleServerError = ({ kind, error, event }) => {\n\tif (kind !== 'unknown') return error;\n\tconsole.error(`${event.locals.id} failed:`, error);\n\treturn { message: 'Something went wrong on the server.', id: event.locals.id };\n};", "note": "As funções viram `const`s com um tipo, `Handle` e `HandleServerError`, então os argumentos delas têm tipo e se sabe que `event.locals.id` é uma string."}
]}
```

```
ana@dev:~/planner$ npm run check 2>&1 | tail -1
svelte-check found 24 errors and 0 warnings in 5 files
```

**Vinte e quatro.** O que sobra está na classe do planner, nos dois módulos pequenos ao lado dela e em
dois componentes, que a próxima seção converte.
