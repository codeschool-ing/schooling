---
title: A route that answers with data
version: 1
---

**A `+server.js` file makes a route that answers with whatever it returns, instead of with a page.** It
exports one function per HTTP method, `GET`, `POST` and the others, each called with the same `event` a
server load function gets and each returning a standard `Response`. Nothing is rendered, no layout
wraps it, and SvelteKit adds nothing to the body. Such a route is usually called an **endpoint**, or an
API route.

This lesson is about writing code again, so it goes back to the dev server: stop the built server with
Ctrl-C and start `npm run dev` in its place. The hooks from lesson 16 run there too.

The planner's data used to be at `/planner.json`, as a file in `static`, until lesson 13 moved it where
only the server can read it. An endpoint can put it back at that address, produced by the server from
the same function the pages use. Save this as `src/routes/planner.json/+server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/planner.json/+server.js", "parts": [
 {"code": "// +server.js: the planner's data, as JSON, at /planner.json.\nimport { json } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';"},
 {"code": "export async function GET() {", "note": "The folder is named `planner.json`, so the address is `/planner.json`. The dot is part of the name, like any other character."},
 {"code": "\treturn json(await readPlanner());\n}", "note": "`json()` is a `Response` with the body written as JSON and the `Content-Type` header saying so."}
]}
```

```
ana@dev:~/planner$ curl -si http://localhost:5173/planner.json | head -7
HTTP/1.1 200 OK
Vary: Origin
content-length: 573
content-type: application/json
referrer-policy: same-origin
x-content-type-options: nosniff
x-frame-options: DENY
```

**`application/json`, with lesson 16's headers on it**: the hooks run for endpoints as they do for
pages. (`Vary: Origin` is the dev server's own, and a build does not send it.) The body is the file,
every course and session, so another program can read the planner without knowing anything about its
HTML.

Lesson 13's warning about server load functions applies here word for word: **whatever an endpoint
returns, anybody who can reach the address can read.** The planner has nothing private in it. An
application with users checks who is asking at the top of every `GET`, or in a hook, before it reads
anything, because an endpoint has no page around it to hide behind and no link needs to point at it for
somebody to find it.
