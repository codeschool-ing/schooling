---
title: Receiving data, and checking it in one place
version: 1
---

**An endpoint can receive data too, with `POST`, and for a program rather than a person that is often
the right door.** A script that imports sessions from a calendar, or a phone shortcut, has no use for an
HTML form; it sends JSON and reads JSON back. The planner can take sessions that way at
`/api/sessions`.

An endpoint that adds sessions must check them exactly as the form's action does, and a rule written
twice is two rules that will drift apart. So the check moves out of the action into a module of its own,
and both use it. Save this as `src/lib/server/check.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/server/check.js", "parts": [
 {"code": "// check.js: what a session must look like, wherever it comes from.\nimport { isDate } from '#lib/week.js';"},
 {"code": "/** What is wrong with a session's date and minutes, or undefined if nothing is. */\nexport function problemWith({ date, minutes }) {\n\tif (!isDate(date)) return 'The session needs a date.';\n\tif (!Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\treturn 'Minutes must be a whole number from 5 to 600.';\n\t}\n}", "note": "It returns the sentence to show, or nothing when the session is fine, so each caller decides how to answer."}
]}
```

The action uses it. Replace `src/routes/(planner)/courses/[id=slug]/+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's forms do, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession, setDone } from '#lib/server/planner.js';\nimport { problemWith } from '#lib/server/check.js';\nimport { mondayOf } from '#lib/week.js';\n\nexport const actions = {\n\tadd: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));"},
 {"code": "\t\tconst problem = problemWith({ date, minutes });\n\t\tif (problem) return fail(400, { date, minutes, problem });\n\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(date)}`);\n\t},\n\n\tdone: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst session = await setDone(Number(form.get('id')), form.get('done') === 'yes');\n\t\tif (!session) error(404, 'There is no such session.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(session.date)}`);\n\t}\n};", "note": "The two `if`s of lesson 14 became one call. What the action does with a problem, `fail()` and the values back to the form, stays here, because it is about forms."}
]}
```

and so does the endpoint. Save this as `src/routes/api/sessions/+server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/api/sessions/+server.js", "parts": [
 {"code": "// +server.js: add a session from another program, as JSON, at /api/sessions.\nimport { error, json } from '@sveltejs/kit';\nimport { addSession } from '#lib/server/planner.js';\nimport { problemWith } from '#lib/server/check.js';\n\nexport async function POST({ request }) {"},
 {"code": "\tif (!request.headers.get('content-type')?.startsWith('application/json')) {\n\t\terror(415, 'Send the session as JSON, with Content-Type: application/json.');\n\t}\n\tconst body = await request.json().catch(() => error(400, 'The body is not valid JSON.'));", "note": "Refusing anything that is not JSON is a protection as well as a courtesy: the next part says why."},
 {"code": "\tconst session = { course: body.course, date: body.date, minutes: body.minutes };\n\tconst problem = problemWith(session);\n\tif (problem) error(400, problem);\n\tif (!(await addSession(session))) error(404, `There is no course called “${session.course}”.`);", "note": "Only the three fields a session needs are taken from the body. Anything else in it, an `id` or a `done`, is ignored rather than written to the file."},
 {"code": "\treturn json(session, { status: 201 });\n}", "note": "201 Created is the status for a request that made something new."}
]}
```

```
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -H 'Content-Type: application/json' -d '{"course":"spanish","date":"2026-10-24","minutes":20}' http://localhost:5173/api/sessions
{"course":"spanish","date":"2026-10-24","minutes":20} 201
```

```
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -H 'Content-Type: application/json' -d '{"course":"spanish","date":"2026-10-24","minutes":2}' http://localhost:5173/api/sessions
{"status":400,"message":"Minutes must be a whole number from 5 to 600."} 400
```

**A 201 with the session, and a 400 with the action's sentence**, from the one function both use. The
form says the same thing:

```
ana@dev:~/planner$ curl -s -H 'Accept: text/html' -d 'date=2026-10-24&minutes=2' 'http://localhost:5173/courses/spanish?/add' | grep -o '<p role="alert">[^<]*</p>'
<p role="alert">Minutes must be a whole number from 5 to 600.</p>
```

## The form that could pretend to be JSON

Lesson 15's check refuses form posts from other sites, and an endpoint is not a form. What protects it?
A page on another site cannot send `Content-Type: application/json` with `fetch` to the planner without
the browser asking the planner first, with an `OPTIONS` request, whether that is allowed. The planner
has no `OPTIONS` handler and says nothing that allows it, so the browser refuses to send the real
request. A plain HTML form on that site cannot set the type at all: it can only send the three kinds
forms send, `application/x-www-form-urlencoded`, `multipart/form-data` and `text/plain`, and `text/plain`
can carry a body that looks exactly like JSON.

**That is why the endpoint checks `Content-Type` before it reads the body.** `request.json()` parses
whatever text arrives, whatever the header says, so without the check a forged `text/plain` form with
`{"course":"spanish",...}` in it would be read as JSON and saved. With it, the request is answered 415
before anything is read. SvelteKit's own check from lesson 15 also refuses cross-site `text/plain`
posts in a build, so there are two locks on that door; each would hold on its own, and neither costs
anything.

```
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -H 'Content-Type: text/plain' -d '{"course":"spanish","date":"2026-10-24","minutes":20}' http://localhost:5173/api/sessions
{"status":415,"message":"Send the session as JSON, with Content-Type: application/json."} 415
```
