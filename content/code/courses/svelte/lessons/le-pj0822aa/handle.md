---
title: handle, around every request
version: 1
---

**`handle` is a function SvelteKit calls for every request its server answers, with the request and a
function, `resolve`, that does everything SvelteKit would have done without it.** Code before `resolve`
runs before the page, the action or the data is worked out; code after it sees the response before it
leaves. It lives in **`src/hooks.server.js`**, a file SvelteKit looks for by that name, and it runs on
the server only.

The built server from lesson 15 says nothing about the requests it answers, where the dev server printed
a line for each. A deployed planner with a problem is a deployed planner nobody can see into, so the
first hook is a log. Save this as `src/hooks.server.js`:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers."},
 {"code": "export async function handle({ event, resolve }) {\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);", "note": "`event` is the same object a server load function receives: the request, the URL, the cookies. `resolve` renders the page, runs the action or answers the endpoint."},
 {"code": "\tconsole.log(`${event.request.method} ${event.url.pathname}${event.url.search} ${response.status} ${ms} ms`);\n\treturn response;\n}", "note": "One line per request: the method, the path with its query, the status, and how long it took."}
]}
```

Build it:

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A4 'SvelteKit error'
SvelteKit error: url_search_unavailable_prerender
Cannot access `url.search` on a page with prerendering enabled
https://svelte.dev/e/kit/url_search_unavailable_prerender
    at URL.get (node_modules/@sveltejs/kit/src/utils/url.js:205:12)
    at Object.handle (src/hooks.server.js:6:72)
```

## Hooks run while the site is built, too

**The build failed, in the hook.** Lesson 15 made About prerendered, which means SvelteKit renders it
during the build, and to render it, it calls `handle`, the same as for any request. A request made at
build time has no real query string, because no visitor sent one, and SvelteKit refuses to let anything
read `url.search` then, so that a page cannot quietly be built from a query that will never exist.

`building`, from `$app/env`, is `true` while the build is prerendering, and the log can leave the query
out then. Replace `src/hooks.server.js`:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers."},
 {"code": "import { building } from '$app/env';\n\nexport async function handle({ event, resolve }) {\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n}", "note": "`building` is true while `npm run build` prerenders pages, and false when a real visitor asks."}
]}
```

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A3 Prerendering
Prerendering
GET /about 200 11 ms
GET / 204 0 ms
```

The build passes, and **the log shows the hook at work while building**: About rendered, and `/`, which
the prerenderer found through About's link and skipped, since it is not to be prerendered. Start the
server, use the planner for a moment with JavaScript on, and read the terminal:

```
ana@dev:~/planner$ look http://localhost:3000/ --click Guitar --fill 'Date=2026-10-23' --click 'Add session' --wait 500 | sed -n 1,6p
-- click Guitar
-- fill Date=2026-10-23
-- click Add session
-- wait 500
at /courses/guitar?week=2026-10-19
title: Guitar · Study planner
```

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
GET / 200 40 ms
POST /courses/guitar?week=2026-10-19&/add 200 6 ms
GET /courses/guitar?week=2026-10-19 200 2 ms
```

**Three lines for three trips to the server**: the week page; the form's `POST`, which `use:enhance`
sent and got JSON back for, hence the 200; and the data for the page it was redirected to. That last
request was for `__data.json`, which SvelteKit takes off the address before the hooks see it, so the
log shows the page the data is for. Following the link to Guitar is not there, because it needed nothing
from the server: the layout's data was still good and the course page's load function runs in the
browser. And About will never be there, because it is a file now, and `adapter-node` hands out files
without asking SvelteKit, which is the next section's subject too.
