---
title: The routes, the hooks and ./$types
version: 1
---

**SvelteKit writes a type file for every route**, describing that route's parameters, what its parents'
load functions return, and what its own return. A route file imports them from **`./$types`**, a module
that looks as if it sits beside the file and is really in `.svelte-kit`, where `svelte-kit sync` puts it.
Annotate a load function with one of them, and the checker knows what `params`, `parent()` and `data`
hold without being told.

Rename the route files and the hooks:

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

The `(planner)` layout's two load functions come first, since everything below them reads what they
return. Replace `src/routes/(planner)/+layout.server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/+layout.server.ts", "parts": [
 {"code": "// +layout.server.ts: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';\nimport type { LayoutServerLoad } from './$types';\n\nexport const load: LayoutServerLoad = async () => {\n\treturn readPlanner();\n};", "note": "`LayoutServerLoad` is the type of this layout's server load function. Writing `load` as a `const` with that type is what lets the checker check its argument and its result."}
]}
```

and `src/routes/(planner)/+layout.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/+layout.ts", "parts": [
 {"code": "// +layout.ts: the week the address asks for, added to what the server loaded.\nimport { isDate, mondayOf } from '#lib/week.js';\nimport type { LayoutLoad } from './$types';\n\nexport const load: LayoutLoad = ({ data, url }) => {\n\tconst asked = url.searchParams.get('week');\n\tconst week = isDate(asked) ? mondayOf(asked) : mondayOf(data.sessions.at(-1)!.date);\n\treturn { ...data, week };\n};", "note": "`data` is typed from what `+layout.server.ts` returns, a `PlannerData`, so `data.sessions` is known to be an array of sessions. The `!` after `at(-1)` tells the checker the array is not empty, which it cannot know: a planner with no sessions would fail here, and the `!` is a promise somebody has to keep."}
]}
```

The course page's load function. Replace `src/routes/(planner)/courses/[id=slug]/+page.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/courses/[id=slug]/+page.ts", "parts": [
 {"code": "// +page.ts: the course a course page is about, or a 404.\nimport { error } from '@sveltejs/kit';\nimport type { PageLoad } from './$types';\n\nexport const load: PageLoad = async ({ params, parent }) => {\n\tconst { courses } = await parent();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn { course };\n};", "note": "`parent()` returns the merged data of the layouts above, typed, so `courses` is a `Course[]` and `c.id` is checked. After the `if`, the checker knows `course` cannot be `undefined`, because `error()` never returns."}
]}
```

Its actions. Replace `src/routes/(planner)/courses/[id=slug]/+page.server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.ts", "parts": [
 {"code": "// +page.server.ts: what a course page's forms do, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession, setDone } from '#lib/server/planner.js';\nimport { problemWith } from '#lib/server/check.js';\nimport { mondayOf } from '#lib/week.js';\nimport type { Actions } from './$types';\n\nexport const actions = {\n\tadd: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));\n\n\t\tconst problem = problemWith({ date, minutes });\n\t\tif (problem) return fail(400, { date, minutes, problem });\n\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(date)}`);\n\t},\n\n\tdone: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst session = await setDone(Number(form.get('id')), form.get('done') === 'yes');\n\t\tif (!session) error(404, 'There is no such session.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(session.date)}`);\n\t}\n} satisfies Actions;", "note": "`satisfies Actions` checks the object against the type and keeps its own, more exact type, which is what lets the page know what each action can return in `form`."}
]}
```

The three endpoints get `RequestHandler`, which types the `event` their functions receive.
`src/routes/(planner)/courses/[id=slug]/+server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/courses/[id=slug]/+server.ts", "parts": [
 {"code": "// +server.ts: a course and all its sessions, as JSON, for a request that does not ask for HTML.\nimport { error, json } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';\nimport type { RequestHandler } from './$types';\n\nexport const GET: RequestHandler = async ({ params }) => {\n\tconst { courses, sessions } = await readPlanner();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn json({ course, sessions: sessions.filter((s) => s.course === course.id) });\n};", "note": "The same function as in lesson 17, with its type. `params.id` is a `string`, from the route's folder name."}
]}
```

`src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.ts", "parts": [
 {"code": "// +server.ts: a course's sessions as a CSV file, for a spreadsheet.\nimport { error } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';\nimport type { RequestHandler } from './$types';\n\nexport const GET: RequestHandler = async ({ params }) => {\n\tconst { courses, sessions } = await readPlanner();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\n\tconst rows = sessions\n\t\t.filter((s) => s.course === course.id)\n\t\t.toSorted((a, b) => (a.date < b.date ? -1 : 1))\n\t\t.map((s) => [course.name, s.date, s.minutes, s.done ? 'yes' : 'no']);\n\tconst text = [['course', 'date', 'minutes', 'done'], ...rows].map((row) => row.map(cell).join(',')).join('\\r\\n') + '\\r\\n';\n\n\treturn new Response(text, {\n\t\theaders: {\n\t\t\t'Content-Type': 'text/csv; charset=utf-8',\n\t\t\t'Content-Disposition': `attachment; filename=\"${course.id}-sessions.csv\"`\n\t\t}\n\t});\n};\n\n// A value as a CSV cell: with a leading apostrophe if a spreadsheet would take it for a\n// formula, and in quotes if it holds a comma, a quote or a line break.\nfunction cell(value: string | number) {\n\tlet text = String(value);\n\tif (/^[=+\\-@]/.test(text)) text = `'${text}`;\n\treturn /[\",\\r\\n]/.test(text) ? `\"${text.replaceAll('\"', '\"\"')}\"` : text;\n}", "note": "Only two things change from lesson 17: the `RequestHandler` type, and a type on `cell`'s parameter, which takes the strings and numbers a row holds."}
]}
```

`src/routes/planner.json/+server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/planner.json/+server.ts", "parts": [
 {"code": "// +server.ts: the planner's data, as JSON, at /planner.json.\nimport { json } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';\nimport type { RequestHandler } from './$types';\n\nexport const GET: RequestHandler = async () => {\n\treturn json(await readPlanner());\n};", "note": "The shortest of them, and still worth its type: `json()` is checked to be what it returns."}
]}
```

and `src/routes/api/sessions/+server.ts`:

```schooling-example
{"language": "typescript", "file": "src/routes/api/sessions/+server.ts", "parts": [
 {"code": "// +server.ts: add a session from another program, as JSON, at /api/sessions.\nimport { error, json } from '@sveltejs/kit';\nimport { addSession } from '#lib/server/planner.js';\nimport { problemWith } from '#lib/server/check.js';\nimport type { RequestHandler } from './$types';\n\nexport const POST: RequestHandler = async ({ request }) => {\n\tif (!request.headers.get('content-type')?.startsWith('application/json')) {\n\t\terror(415, 'Send the session as JSON, with Content-Type: application/json.');\n\t}\n\tconst body = await request.json().catch(() => error(400, 'The body is not valid JSON.'));\n\n\tconst problem = problemWith(body);\n\tif (problem) error(400, problem);\n\tconst session = { course: String(body.course), date: body.date, minutes: body.minutes };\n\tif (!(await addSession(session))) error(404, `There is no course called “${session.course}”.`);\n\n\treturn json(session, { status: 201 });\n};", "note": "`request.json()` returns `any`, which the checker lets you use any way you like. So `body` goes through `problemWith`, which takes `unknown`, before anything relies on its fields, and `course` is turned into a string explicitly, since nothing has checked it is one."}
]}
```

## locals and App.Error

Lesson 16's hook put an `id` on `event.locals` and on the error it returned, and the checker knows
neither: `App.Locals` and `App.Error` are SvelteKit's types for those two objects, empty until the
application says what it keeps in them. That is done in **`src/app.d.ts`**, a file of declarations
only. Save it:

```schooling-example
{"language": "typescript", "file": "src/app.d.ts", "parts": [
 {"code": "// app.d.ts: the types SvelteKit lets an application add to its own.\ndeclare global {\n\tnamespace App {\n\t\tinterface Locals {\n\t\t\t/** A short id for the request, set by the log hook. */\n\t\t\tid: string;\n\t\t}\n\t\tinterface Error {\n\t\t\t/** The request's id, on errors that handleError answered. */\n\t\t\tid?: string;\n\t\t}\n\t}\n}\n\nexport {};", "note": "`declare global` adds to the `App` namespace SvelteKit declares, rather than making a new one. `id` is optional on errors because only the unexpected ones get one."}
]}
```

and the hooks take their types from `@sveltejs/kit/hooks`. Replace `src/hooks.server.ts`:

```schooling-example
{"language": "typescript", "file": "src/hooks.server.ts", "parts": [
 {"code": "// hooks.server.ts: code that runs around every request the server answers.\nimport { sequence } from '@sveltejs/kit/hooks';\nimport type { Handle, HandleServerError } from '@sveltejs/kit/hooks';\nimport { building } from '$app/env';\n\nconst log: Handle = async ({ event, resolve }) => {\n\tevent.locals.id = crypto.randomUUID().slice(0, 8);\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.locals.id} ${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n};\n\nconst headers: Handle = async ({ event, resolve }) => {\n\tconst response = await resolve(event);\n\tresponse.headers.set('X-Content-Type-Options', 'nosniff');\n\tresponse.headers.set('Referrer-Policy', 'same-origin');\n\tresponse.headers.set('X-Frame-Options', 'DENY');\n\treturn response;\n};\n\nexport const handle = sequence(log, headers);\n\nexport const handleError: HandleServerError = ({ kind, error, event }) => {\n\tif (kind !== 'unknown') return error;\n\tconsole.error(`${event.locals.id} failed:`, error);\n\treturn { message: 'Something went wrong on the server.', id: event.locals.id };\n};", "note": "The functions become `const`s with a type, `Handle` and `HandleServerError`, so their arguments are typed and `event.locals.id` is known to be a string."}
]}
```

```
ana@dev:~/planner$ npm run check 2>&1 | tail -1
svelte-check found 24 errors and 0 warnings in 5 files
```

**Twenty-four.** What is left is in the planner class, the two small modules beside it and two
components, which the next section converts.
