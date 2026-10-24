---
title: What crosses to the browser
version: 1
---

**A server load function's result travels to the browser as data, and the browser can read every byte
of it.** On the first visit it is written into the HTML, like the response in the first section. After
that, each time a client-side navigation needs it, the browser asks for it at the page's address with
`__data.json` on the end. You can ask too:

```
ana@dev:~/planner$ curl -s http://localhost:5173/__data.json
{"type":"data","nodes":[null,{"type":"data","data":[{"courses":1,"sessions":11},[2,5,8],{"id":3,"name":4},"algebra","Linear algebra",{"id":6,"name":7},"spanish","Spanish",{"id":9,"name":10},"guitar","Guitar",[12,17,21,25,30,33],{"id":13,"course":3,"date":14,"minutes":15,"done":16},1,"2026-10-13",60,true,{"id":18,"course":6,"date":19,"minutes":20,"done":16},2,"2026-10-15",30,{"id":22,"course":3,"date":23,"minutes":24,"done":16},3,"2026-10-19",90,{"id":26,"course":9,"date":27,"minutes":28,"done":29},4,"2026-10-20",45,false,{"id":31,"course":6,"date":32,"minutes":20,"done":29},5,"2026-10-22",{"id":34,"course":3,"date":35,"minutes":15,"done":29},6,"2026-10-24"],"uses":{}},null]}
```

That is the planner, all of it, in the format of **devalue**, the library SvelteKit uses to write data
down. Every value appears once in a flat list and the objects point at positions in it: `"done":16` is
the entry at position 16, counting from zero, which is `true`, and every session that is done shares it. The format exists because it can
carry more than JSON: a `Date`, a `Map`, a `Set`, a `BigInt`, a regular expression, and an object that
appears twice in the data, which arrives as one object referenced twice and not as two copies.

## What it cannot carry

**Code.** A function cannot be written down as data and rebuilt on the other side, and neither can an
instance of your own class, whose methods are code. Suppose the layout tried to be helpful and handed
the pages a function for finding a course's name. Replace `src/routes/(planner)/+layout.server.js`
for a moment:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.server.js", "parts": [
 {"code": "// +layout.server.js: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';"},
 {"code": "export async function load() {\n\tconst planner = await readPlanner();\n\treturn { ...planner, courseName: (id) => planner.courses.find((c) => c.id === id)?.name };\n}", "note": "This returns a function along with the data. It will not get as far as the browser."}
]}
```

Stop the dev server with Ctrl-C and start it again, so that its terminal shows only what happens next,
and ask for the page:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/
500
```

**A 500**, and the terminal running `npm run dev` says why:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:22:04 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 591 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
SvelteKit error: load_not_serializable
Data returned from `load` while rendering `/(planner)` is not serializable: Cannot stringify a function (`data.courseName`). If you need to serialize/deserialize custom types, use transport hooks: https://svelte.dev/docs/kit/hooks#transport.
https://svelte.dev/e/kit/load_not_serializable

DevalueError: Cannot stringify a function

500 GET /
```

`load_not_serializable`, and the path to the value, `data.courseName`. The error appears on every
request, not only when a client-side navigation would have needed the data, which is the helpful
choice: a page that worked on a first visit and broke on the second would be much harder to find.
Put the file back as it was, returning `readPlanner()`.

A universal load function has no such limit. Its result is never sent anywhere: it runs in the
browser and hands its return value straight to the component, functions, class instances and all. That
is one reason to write a `+page.js` even when there is a server. The other is that, after the first
page, it runs in the browser and does not have to ask the server anything, which the next sections
use.

## Everything returned is public

**Whatever a server load returns, the visitor can read**, in the HTML or at `__data.json`, whether or
not any component displays it. The planner returns the whole file because the pages use the whole file.
If the file also held something private, a password hash, another user's sessions, an API key, the load
function would publish it. Return what the pages need and nothing more. A server load function is the
one place in a SvelteKit application that decides what leaves the server, which makes it the place to
be careful.
