---
title: Server-side rendering, by hand
version: 1
---

**Server-side rendering means the server runs the same view code before it answers, and sends the
finished page.** The frameworks of lesson 2 do this with a great deal of machinery, and it is
easy to come away thinking the machinery is the idea. It is not. The idea fits in one small file,
because `src/view.ts` already turns a plan into HTML without touching the page.

## The server

Save this as `server.ts` beside `package.json`. It serves the files the build wrote, and for any
address that is not a file it reads the plan, calls `page` from `src/view.ts`, and puts the result
inside the `<main>` of the page the build wrote:

```schooling-example
{"language": "typescript", "file": "server.ts", "parts": [
 {"code": "// server.ts: the same planner, with each page drawn here before it is sent.\nimport { createServer } from \"node:http\";\nimport { readFile } from \"node:fs/promises\";\nimport { extname, join } from \"node:path\";\nimport type { Plan } from \"./src/planner.ts\";\nimport { page } from \"./src/view.ts\";", "note": "The server imports the planner's own code. Node 22 strips the types from both files as it loads them."},
 {"code": "const dist = join(import.meta.dirname, \"dist\");\nconst types: Record<string, string> = {\n  \".js\": \"text/javascript\", \".css\": \"text/css\", \".json\": \"application/json\", \".svg\": \"image/svg+xml\",\n};\nconst shell = await readFile(join(dist, \"index.html\"), \"utf8\");", "note": "The shell is dist/index.html, read once at start-up. It already names the hashed script and stylesheet, so the server never needs to know their names."},
 {"code": "createServer(async (req, res) => {\n  const { pathname } = new URL(req.url ?? \"/\", \"http://localhost\");\n  if (extname(pathname)) {\n    // A file the build wrote: a script, a stylesheet, the data.\n    try {\n      const body = await readFile(join(dist, pathname));\n      res.writeHead(200, { \"content-type\": types[extname(pathname)] ?? \"application/octet-stream\" });\n      res.end(body);\n    } catch {\n      res.writeHead(404).end();\n    }\n    return;\n  }", "note": "An address with an extension is a file from the build. new URL has already resolved any ../ in the path, so the join stays inside dist."},
 {"code": "  // A page: read the plan and draw it into the shell the build wrote.\n  const plan: Plan = JSON.parse(await readFile(join(dist, \"courses.json\"), \"utf8\"));\n  const html = shell.replace('<main id=\"app\"></main>', `<main id=\"app\">${page(plan, pathname)}</main>`);\n  res.writeHead(200, { \"content-type\": \"text/html; charset=utf-8\" });\n  res.end(html);\n}).listen(3000, () => console.log(\"planner on http://localhost:3000\"));", "note": "Anything else is a page. The plan is read on every request, so an edit to the data shows on the next one. The empty main is replaced by the page the address names."}
]}
```

It is about thirty lines and it does nothing the browser half does not also do. That sameness is
the point: **one `page` function, called in two places**, so the server's HTML and the browser's
HTML cannot disagree. Lesson 4 shows what happens when they do.

## Running it

Stop the preview server, build again so that `dist/` is current, and start this one in the second
terminal:

```
ana@dev:~/planner$ npm run build >/dev/null && node server.ts
planner on http://localhost:3000
```

In the first terminal, ask for a course page:

```
ana@dev:~/planner$ curl -s http://localhost:3000/courses/git
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-Dv4jVJdV.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-1yLCgpWc.css">
  </head>
  <body>
    <main id="app"><p><a href="/">All courses</a></p>
<h1>Git</h1>
<ul class="sessions"><li>2026-10-24 · 25 min <button data-done="5">Mark done</button></li><li>2026-10-27 · 40 min <button data-done="6">Mark done</button></li></ul>
<form>
  <label>Date <input name="date" type="date" required></label>
  <label>Minutes <input name="minutes" type="number" min="5" step="5" required></label>
  <button>Add session</button>
</form></main>
  </body>
</html>
```

**The sessions are in the first response.** The same two links and the same script tag are there
as before, but `<main>` now holds the heading, the two sessions of the Git course with their
buttons, and the form. And the browser, with and without JavaScript:

```
ana@dev:~/planner$ node tools/look.ts http://localhost:3000/ --no-js
requests: / /assets/index-1yLCgpWc.css
first contentful paint: 44 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
ana@dev:~/planner$ node tools/look.ts http://localhost:3000/
requests: / /assets/index-Dv4jVJdV.js /assets/index-1yLCgpWc.css /courses.json
first contentful paint: 36 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
```

Without JavaScript the browser fetched two things, painted, and the page reads exactly as it does
with JavaScript. **What it cannot do without JavaScript is anything else**: a click on *Mark done*
runs no code, and the form's *Add session* would send the form to the server, which has no handler
for it. With JavaScript, the script still runs, fetches `/courses.json` and draws the page again,
over the one the server sent.

That redraw is wasteful, and it is worse than wasteful on a slow phone, where the page is visible
and does nothing for as long as the script takes to arrive. Lesson 4 replaces it with
**hydration**: the script attaches its listeners to the HTML that is already there instead of
throwing it away. For this lesson the redraw is fine, because the HTML it draws is identical.

## What the server now does that it did not

Every request for a page reads a file, parses it and builds a string. For three courses that is
nothing; the next sections measure it anyway. On a real site it is a database query and a
template, for every visitor, on every page they open, and the server needs a running program and
enough processor to do it. A client-rendered site needed only somebody to hand out files.
