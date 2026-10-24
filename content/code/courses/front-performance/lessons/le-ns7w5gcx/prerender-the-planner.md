---
title: Prerendering the planner by hand
version: 1
---

**`server.ts` in lesson 1 drew a page when it was asked for one. A prerender draws all of them in
advance and saves each under the address it belongs to.** The code is nearly the same, because the
work is the same: read the plan, call `page`, put the result into the shell the build wrote. Only
the moment moves.

## The script

Save this as `prerender.ts`, beside `server.ts`. It runs after `vite build` and adds a page for
every address to `dist/`:

```schooling-example
{"language": "typescript", "file": "prerender.ts", "parts": [
 {"code": "// prerender.ts: draw every page of the planner once, at build time, as files in dist/.\nimport { mkdir, readFile, writeFile } from \"node:fs/promises\";\nimport { join } from \"node:path\";\nimport type { Plan } from \"./src/planner.ts\";\nimport { page } from \"./src/view.ts\";\n\nconst dist = join(import.meta.dirname, \"dist\");\nconst shell = await readFile(join(dist, \"index.html\"), \"utf8\");\nconst plan: Plan = JSON.parse(await readFile(join(dist, \"courses.json\"), \"utf8\"));\nconst draw = (path: string) =>\n  shell.replace('<main id=\"app\"></main>', `<main id=\"app\">${page(plan, path)}</main>`);", "note": "The same imports as server.ts, and the same shell: the index.html that vite build wrote, with its empty main."},
 {"code": "for (const path of [\"/\", ...plan.courses.map((c) => `/courses/${c.slug}`)]) {\n  await mkdir(join(dist, path), { recursive: true });\n  await writeFile(join(dist, path, \"index.html\"), draw(path));\n  console.log(`${path} -> dist${path === \"/\" ? \"\" : path}/index.html`);\n}", "note": "The list of addresses comes from the data, as generateStaticParams did in Next.js. Each page is written as index.html inside a folder named for its address, which is how a static host finds /courses/git."},
 {"code": "await writeFile(join(dist, \"404.html\"), draw(\"/courses/-\"));\nconsole.log(\"anything else -> dist/404.html\");", "note": "And one page for every address that is not a course. \"/courses/-\" is a slug no course has, so page draws its \"No such course\"."}
]}
```

**It overwrites `dist/index.html` with the home page**, so it must run on a fresh build, never twice
on the same one: the second run would find no empty `<main>` to fill. A script in `package.json`
makes the two one command:

```
ana@dev:~/planner$ npm pkg set scripts.build:static="npm run build && node prerender.ts"
ana@dev:~/planner$ npm run build:static 2>&1 | tail -6
✓ built in 137ms
/ -> dist/index.html
/courses/html-css -> dist/courses/html-css/index.html
/courses/javascript -> dist/courses/javascript/index.html
/courses/git -> dist/courses/git/index.html
anything else -> dist/404.html
ana@dev:~/planner$ find dist -name '*.html' | sort
dist/404.html
dist/courses/git/index.html
dist/courses/html-css/index.html
dist/courses/javascript/index.html
dist/index.html
```

Five files, each a finished page. `npm run build` on its own still makes the empty shell that
`server.ts` needs; the two builds produce different `dist/` folders, and the one you run last is
the one you have.

## A static host, in thirty lines

`vite preview` is the wrong thing to test this with: it was made for an app that draws every page
in the browser, so it answers any address it does not know with `dist/index.html`. A static host
does three things instead, and `static.ts` does exactly those three. Save it beside the others:

```schooling-example
{"language": "typescript", "file": "static.ts", "parts": [
 {"code": "// static.ts: serve dist/ the way a static host does: a file as it is, a folder's\n// index.html for the folder's address, and 404.html, with a 404, for anything else.\nimport { createServer } from \"node:http\";\nimport { readFile, stat } from \"node:fs/promises\";\nimport { extname, join } from \"node:path\";\n\nconst dist = join(import.meta.dirname, \"dist\");\nconst types: Record<string, string> = {\n  \".html\": \"text/html; charset=utf-8\", \".js\": \"text/javascript\", \".css\": \"text/css\",\n  \".json\": \"application/json\", \".svg\": \"image/svg+xml\",\n};", "note": "No rendering at all: every answer is a file that is already in dist/."},
 {"code": "async function find(path: string): Promise<string | null> {\n  for (const candidate of [path, join(path, \"index.html\")]) {\n    try {\n      if ((await stat(candidate)).isFile()) return candidate;\n    } catch {\n      // nothing at this path; the next candidate, or null, says so\n    }\n  }\n  return null;\n}", "note": "An address is tried as a file and then as a folder holding index.html. stat throws for a path that does not exist, and that is the answer \"not this one\", so the loop moves on."},
 {"code": "createServer(async (req, res) => {\n  const { pathname } = new URL(req.url ?? \"/\", \"http://localhost\");\n  const found = await find(join(dist, pathname));\n  const path = found ?? join(dist, \"404.html\");\n  res.writeHead(found ? 200 : 404, { \"content-type\": types[extname(path)] ?? \"application/octet-stream\" });\n  res.end(await readFile(path));\n}).listen(8080, () => console.log(\"dist/ on http://localhost:8080\"));", "note": "Nothing found is a 404 with the site's own 404 page, which is what GitHub Pages, Netlify and Cloudflare Pages do with a 404.html at the root."}
]}
```

Build, and start it in the second terminal:

```sh
npm run build:static && node static.ts
```

In the first terminal, ask for a course, for an address that does not exist, and for the home page
with JavaScript off:

```
ana@dev:~/planner$ curl -s http://localhost:8080/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git</h1>
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/courses/nonsense
404
ana@dev:~/planner$ curl -s http://localhost:8080/courses/nonsense | grep -o '<h1>[^<]*</h1>'
<h1>No such course</h1>
ana@dev:~/planner$ node tools/look.ts http://localhost:8080/ --no-js | head -3
requests: / /assets/index-1yLCgpWc.css
first contentful paint: 32 ms
text on the screen:
```

**The course page is a file, and it reads exactly as `server.ts` drew it**, with JavaScript or
without. The unknown course gets the site's own page and a real 404, which `server.ts` never sent.
And the server that answered has no idea what a course is: it could be any static host on the
internet. Lesson 9 comes back to this server and teaches it the cache headers a host would add.
