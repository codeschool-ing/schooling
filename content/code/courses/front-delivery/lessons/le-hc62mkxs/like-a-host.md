---
title: Serving the build the way a host does
version: 1
---

**Before a host serves your build, serve it yourself, on your computer, the way a host would.** Most of
what goes wrong on the first deploy (a wrong path, a missing file, a page that only works from the
front door) goes wrong here too, where you can see the request that failed.

Opening `dist/index.html` by double-clicking it does not count. The browser loads it from a `file://`
address, refuses to run a module script from there, and the page stays blank. A host speaks HTTP, so
the test has to as well.

## Two ways

**`npm run preview`** runs `vite preview`, which serves `dist/` on port 4173. It is the quick check,
and Vite's own documentation says what it is not: a production server. It also forgives things a host
does not, as lesson 4 shows.

**A server you can read.** This one is about forty lines of Node with nothing installed, and it does what
every static host does at its core: it turns a path into a file, sends the file with the right
`Content-Type`, and answers 404 when there is none. Save it at the root of the project:

```schooling-example
{"language": "javascript", "file": "host.mjs", "parts": [
 {"code": "// host.mjs\nimport { createServer } from \"node:http\";\nimport { readFile } from \"node:fs/promises\";\nimport { extname, join, normalize } from \"node:path\";\n\nconst root = process.argv[2] ?? \"dist\";\nconst port = Number(process.argv[3] ?? 8080);", "note": "Which folder to serve and on which port, from the command line: `node host.mjs dist 8080` by default."},
 {"code": "const types = {\n  \".html\": \"text/html; charset=utf-8\",\n  \".js\": \"text/javascript; charset=utf-8\",\n  \".css\": \"text/css; charset=utf-8\",\n  \".json\": \"application/json\",\n  \".svg\": \"image/svg+xml\",\n};", "note": "The `Content-Type` for each ending. A browser refuses to run a module script sent as anything but JavaScript, so this table is not decoration."},
 {"code": "\nasync function load(path) {\n  const file = join(root, normalize(path));\n  for (const candidate of [file, join(file, \"index.html\")]) {\n    try {\n      return { body: await readFile(candidate), type: types[extname(candidate)] ?? \"application/octet-stream\" };\n    } catch {\n      // not there, or a folder: try the next candidate\n    }\n  }\n  return null;\n}", "note": "A path names a file, or a folder whose `index.html` is the page. `normalize` resolves any `..` in the path before it is joined to the root, so a request cannot climb out of the folder being served."},
 {"code": "\nconst server = createServer(async (request, response) => {\n  const path = new URL(request.url, \"http://host\").pathname;\n  const found = await load(path);\n  if (found) {\n    response.writeHead(200, { \"content-type\": found.type });\n    response.end(found.body);\n  } else {\n    const page = await load(\"/404.html\");\n    response.writeHead(404, { \"content-type\": \"text/html; charset=utf-8\" });\n    response.end(page?.body ?? \"not found\\n\");\n  }\n  console.log(response.statusCode, request.method, path);\n});", "note": "Found: 200 and the file. Not found: 404, with the site's own `404.html` if it has one, which is the convention all four hosts in this lesson follow. Each request is logged with its status."},
 {"code": "\nserver.listen(port, \"127.0.0.1\", () => console.log(`serving ${root} on http://127.0.0.1:${port}`));", "note": "Only this computer can reach `127.0.0.1`."}
]}
```

Build, and start it in one terminal:

```
ana@dev:~/planner$ node host.mjs
serving dist on http://127.0.0.1:8080
```

Ask it for the page, the data and a file that does not exist, from a second one:

```
ana@dev:~/planner$ curl -si http://127.0.0.1:8080/ | head -3
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
Date: Fri, 23 Oct 2026 22:17:01 GMT
ana@dev:~/planner$ curl -s http://127.0.0.1:8080/courses.json | head -2
{
  "courses": [
ana@dev:~/planner$ curl -si http://127.0.0.1:8080/nothing-here
HTTP/1.1 404 Not Found
content-type: text/html; charset=utf-8
Date: Fri, 23 Oct 2026 22:17:01 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

not found
```

Back in the first terminal, the server logged each request:

```
ana@dev:~/planner$ node host.mjs
serving dist on http://127.0.0.1:8080
200 GET /
200 GET /courses.json
404 GET /nothing-here
^C
```

Open `http://127.0.0.1:8080/` in your browser and the planner works as it did under `npm run dev`,
except that now nothing is being compiled: these are the four files a host would hold. The log shows
the browser asking for the page, then the script and the stylesheet the page names, then
`courses.json` when the script runs.

## What a real host adds

Everything in this server is something all four hosts do. What they add on top is what you pay them
for, or what their free plan gives away:

- **many copies**: the files on servers in many cities, and each request answered by the nearest;
- **HTTPS**, with a certificate they obtain and renew for you, lesson 4;
- **compression**, so `index-BVi82VJx.js` travels at its gzip size;
- **caching headers**, so a browser keeps the hashed files, front-performance lesson 9;
- **rules**: redirects, rewrites and headers, read from a file in your repository, lesson 4;
- **a build**, from your repository, on every push, lesson 3.

The point of this server is not to compete with any of that. It is that every one of those is a
**rule about the same folder**, and you now have the folder and a server whose behaviour you can read
line by line when one of those rules surprises you.

Commit it, so the next lessons can grow it:

```
ana@dev:~/planner$ git add host.mjs
ana@dev:~/planner$ git commit -qm "Serve dist/ the way a static host does"
```
