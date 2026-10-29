---
title: handleError, for the errors nobody planned
version: 1
---

**An error that nobody raised on purpose reaches `handleError`, a second hook in the same file, before
it reaches the error page.** Lesson 12's 404s and lesson 13's `error(404, …)` are errors somebody meant;
they arrive with a status and a message written to be shown. An exception thrown by code that broke, a
file that is not there, a bug, carries a message written for a programmer, sometimes with a path or a
piece of data in it, and SvelteKit never shows that to a visitor.

See what happens without the hook first. Move the data file out of the way, so that reading it fails:

```
ana@dev:~/planner$ mv data/planner.json data/planner.json.away
```

```
ana@dev:~/planner$ look http://localhost:3000/
at /
title: 500 · Study planner
- main:
  - heading "Something went wrong" [level=1]
  - paragraph: Internal Error
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

**A 500 and "Internal Error"**, which is SvelteKit's safe default for an error it knows nothing about.
The real message went to the server's terminal. The request's log line has its id and the error above
it has none, so nothing connects the two:

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
Error: ENOENT: no such file or directory, open 'data/planner.json'
    at async open (node:internal/fs/promises:636:25)
    at async readFile (node:internal/fs/promises:1235:14)
    at async readPlanner (src/lib/server/planner.js:7:20)
889c1bbc GET / 500 31 ms
```

`handleError` receives the error, the request's `event`, and a **`kind`**: `'app'` for an error raised
with `error()`, `'framework'` for SvelteKit's own, such as a 404 for an address with no route, and
`'unknown'` for the rest. What it returns is what the error page gets as `page.error`. Add it to the end
of `src/hooks.server.js`, which becomes:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers.\nimport { sequence } from '@sveltejs/kit/hooks';\nimport { building } from '$app/env';\n\nasync function log({ event, resolve }) {\n\tevent.locals.id = crypto.randomUUID().slice(0, 8);\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.locals.id} ${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n}\n\nasync function headers({ event, resolve }) {\n\tconst response = await resolve(event);\n\tresponse.headers.set('X-Content-Type-Options', 'nosniff');\n\tresponse.headers.set('Referrer-Policy', 'same-origin');\n\tresponse.headers.set('X-Frame-Options', 'DENY');\n\treturn response;\n}\n\nexport const handle = sequence(log, headers);"},
 {"code": "export function handleError({ kind, error, event }) {\n\tif (kind !== 'unknown') return error;", "note": "An error raised on purpose already says what it should, so it goes through unchanged."},
 {"code": "\tconsole.error(`${event.locals.id} failed:`, error);\n\treturn { message: 'Something went wrong on the server.', id: event.locals.id };\n}", "note": "The whole error, stack and all, goes to the log, under the request's id. The visitor gets a plain sentence and the id, and nothing from the error itself."}
]}
```

**`handleError` must never throw.** It runs because something already went wrong, and an error inside it
has nowhere left to go. Keep it to logging and building an object.

The error page shows the id when there is one, so that a person who writes in about it can quote it.
Replace `src/routes/+error.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/+error.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';\n</script>\n\n<svelte:head>\n\t<title>{page.status} · Study planner</title>\n</svelte:head>\n<h1>{page.status === 404 ? 'Nothing at this address' : 'Something went wrong'}</h1>\n<p>{page.error?.message}</p>"},
 {"code": "{#if page.error?.id}\n\t<p>If you write to us about this, quote the reference {page.error.id}.</p>\n{/if}\n<p><a href=\"/\">Back to the planner</a></p>", "note": "`page.error` is the object `handleError` returned, so `id` is there for the errors it handled and absent for the others."}
]}
```

Build, restart, and ask again, with the file still away:

```
ana@dev:~/planner$ look http://localhost:3000/
at /
title: 500 · Study planner
- main:
  - heading "Something went wrong" [level=1]
  - paragraph: Something went wrong on the server.
  - paragraph: If you write to us about this, quote the reference bb0a065d.
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
bb0a065d failed: Error: ENOENT: no such file or directory, open 'data/planner.json'
    at async open (node:internal/fs/promises:636:25)
    at async readFile (node:internal/fs/promises:1235:14)
    at async readPlanner (src/lib/server/planner.js:7:20) {
  errno: -2,
  code: 'ENOENT',
  syscall: 'open',
  path: 'data/planner.json'
}
bb0a065d GET / 500 31 ms
```

**The reference on the page is the id in the log**, beside the full error: `ENOENT`, the file it could
not open, and where in the code it was. Put the file back:

```
ana@dev:~/planner$ mv data/planner.json.away data/planner.json
```

A 404 for a course that does not exist still says what it said before. It is `kind: 'app'`, raised by
the course page's load function, and the hook passed it through:

```
ana@dev:~/planner$ look http://localhost:3000/courses/piano | head -5
at /courses/piano
title: 404 · Study planner
- main:
  - heading "Nothing at this address" [level=1]
  - paragraph: There is no course called “piano”.
```
