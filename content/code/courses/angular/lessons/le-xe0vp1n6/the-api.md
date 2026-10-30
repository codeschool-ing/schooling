---
title: A small server of the planner's own
version: 1
---

**Until now the planner read a file the dev server handed over as it was, and nothing it changed
outlived a reload.** Ticking a session done changed a signal in the browser; reload the page and the
tick was gone, because `courses.json` never heard about it. An application that keeps what you do
needs somebody on the other end to keep it. This lesson writes that somebody: a server of about
seventy lines, in plain Node.js, with no package to install.

The data moves first. `git mv` moves the file and tells git it is the same file under a new name:

```
ana@dev:~/planner$ mkdir server && git mv public/courses.json server/seed.json
```

`seed.json` is where the data starts. The server keeps what changes in a second file beside it,
`planner.json`, made from the seed the first time it runs, so deleting `planner.json` puts
everything back the way the course started.

```schooling-example
{"language": "javascript", "file": "server/api.mjs", "parts": [
 {"code": "// server/api.mjs\nimport { createServer } from 'node:http';\nimport { copyFile, readFile, writeFile } from 'node:fs/promises';\nimport { existsSync } from 'node:fs';\n\nconst port = 3000;\nconst seed = new URL('./seed.json', import.meta.url);\nconst file = new URL('./planner.json', import.meta.url);\n\nif (!existsSync(file)) await copyFile(seed, file);\nconst load = async () => JSON.parse(await readFile(file, 'utf8'));\nconst save = (data) => writeFile(file, JSON.stringify(data, null, 2) + '\\n');", "note": "Node's own HTTP server and file functions. The two files are found next to this one, wherever the project is."},
 {"code": "function send(res, status, body) {\n  res.writeHead(status, { 'content-type': 'application/json' });\n  res.end(JSON.stringify(body));\n}\n\nasync function readBody(req) {\n  let text = '';\n  for await (const chunk of req) text += chunk;\n  try {\n    return JSON.parse(text);\n  } catch {\n    return undefined;\n  }\n}", "note": "Every answer is JSON, with a status. An error is JSON too, `{ \"error\": \"...\" }`, so the application can show the server's own sentence."},
 {"code": "const server = createServer(async (req, res) => {\n  const { pathname } = new URL(req.url, 'http://localhost');\n  console.log(req.method, pathname, req.headers['x-requested-by'] ?? '-');\n\n  if (req.method === 'GET' && pathname === '/api/planner') {\n    return send(res, 200, await load());\n  }", "note": "One line per request: the method, the path, and one header this lesson's interceptor will add. Until then it is `-`."},
 {"code": "  const one = pathname.match(/^\\/api\\/sessions\\/(\\d+)$/);\n  if (req.method === 'PATCH' && one) {\n    const data = await load();\n    const session = data.sessions.find((s) => s.id === Number(one[1]));\n    if (!session) return send(res, 404, { error: `there is no session ${one[1]}` });\n    const body = await readBody(req);\n    if (typeof body?.done !== 'boolean') return send(res, 400, { error: 'done must be true or false' });\n    session.done = body.done;\n    await save(data);\n    return send(res, 200, session);\n  }", "note": "Marking a session done or not. The body must say `done` and nothing vaguer: `\"yes\"` is refused with 400, an unknown session with 404."},
 {"code": "  if (req.method === 'POST' && pathname === '/api/sessions') {\n    const data = await load();\n    const body = await readBody(req);\n    if (!data.courses.some((c) => c.id === body?.courseId)) return send(res, 400, { error: 'courseId names no course' });\n    if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(body.date ?? '')) return send(res, 400, { error: 'date must be YYYY-MM-DD' });\n    if (!Number.isInteger(body.minutes) || body.minutes < 1) return send(res, 400, { error: 'minutes must be a whole number above 0' });\n    const id = Math.max(0, ...data.sessions.map((s) => s.id)) + 1;\n    const session = { id, courseId: body.courseId, date: body.date, minutes: body.minutes, done: false };\n    data.sessions.push(session);\n    await save(data);\n    return send(res, 201, session);\n  }\n\n  send(res, 404, { error: `nothing answers ${req.method} ${pathname}` });\n});\n\nserver.listen(port, () => console.log(`the planner's API is on http://localhost:${port}`));", "note": "Adding a session, which lesson 14's form uses. The server checks every field itself: whatever the form checked, a request can come from anywhere."}
]}
```

`planner.json` is the server's working copy, not part of the program, so git leaves it out:

```
ana@dev:~/planner$ echo 'server/planner.json' >> .gitignore
```

The server runs in a terminal of its own, a third one beside the dev server's, and stays there:
type `node server/api.mjs` in it. It prints one line to say it is listening.

`curl` from the first terminal asks it a question it answers and two it refuses. `head -c 120`
keeps the first 120 bytes of a long answer, `-X PATCH -d` sends a method and a body, and `echo` ends
the line each answer leaves open:

```
ana@dev:~/planner$ curl -s http://localhost:3000/api/planner | head -c 120; echo
{"courses":[{"id":"html-css","name":"HTML and CSS"},{"id":"javascript","name":"JavaScript"},{"id":"git","name":"Git"}],"
ana@dev:~/planner$ curl -s -X PATCH http://localhost:3000/api/sessions/5 -d '{"done":"yes"}'; echo
{"error":"done must be true or false"}
ana@dev:~/planner$ curl -s -X PATCH http://localhost:3000/api/sessions/9 -d '{"done":true}'; echo
{"error":"there is no session 9"}
```

The server says why in each refusal, in a sentence the application can show. Its own terminal has a
line for every request:

```
ana@dev:~/planner$ node server/api.mjs
the planner's API is on http://localhost:3000
GET /api/planner -
PATCH /api/sessions/5 -
PATCH /api/sessions/9 -
```

## The proxy

The application runs at `localhost:4200` and the API at `localhost:3000`, and to a browser those are
two different origins. A page may ask another origin for data only if that origin says it may, with
CORS headers, and this server sends none. Rather than open the API to every page on the internet, the
dev server can pass requests on: the browser asks `localhost:4200/api/planner`, and the dev server
fetches the answer from port 3000 and hands it back as its own.

```schooling-example
{"language": "json", "file": "proxy.conf.json", "parts": [
 {"code": "{\n  \"/api\": {\n    \"target\": \"http://localhost:3000\",\n    \"secure\": false\n  }\n}", "note": "Every request whose path starts with `/api` goes to the API; everything else is the application, as before."}
]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The browser sends every request to one address, localhost:4200, the dev server. Requests whose path starts with /api the dev server passes on to the API at localhost:3000, which reads and writes planner.json, and the answer comes back the same way. Every other request the dev server answers itself, with the application&#x27;s files.\"><rect x=\"20\" y=\"90\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">browser</text><text x=\"85.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one origin</text><rect x=\"250\" y=\"90\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dev server</text><text x=\"335.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:4200</text><rect x=\"540\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><text x=\"620.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:3000</text><rect x=\"540\" y=\"160\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the application</text><text x=\"620.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main.js, index.html</text><line x1=\"150\" y1=\"112\" x2=\"248\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,112.0 240.6,115.1 240.6,108.9\" fill=\"var(--wire)\"></polygon><line x1=\"250\" y1=\"126\" x2=\"152\" y2=\"126\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"152.0,126.0 159.4,122.9 159.4,129.1\" fill=\"var(--wire)\"></polygon><text x=\"200\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">every request</text><line x1=\"420\" y1=\"104\" x2=\"538\" y2=\"64\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,64.0 532.0,69.3 530.0,63.4\" fill=\"var(--amber)\"></polygon><text x=\"478\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">/api/...</text><line x1=\"420\" y1=\"134\" x2=\"538\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,184.0 530.0,184.0 532.4,178.3\" fill=\"var(--wire)\"></polygon><text x=\"462\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">everything else</text><rect x=\"560\" y=\"102\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"620\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner.json</text><line x1=\"620\" y1=\"86\" x2=\"620\" y2=\"100\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"335\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">proxy.conf.json</text><text x=\"335\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">decides which way</text></svg>", "caption": "The browser only ever talks to localhost:4200; the dev server sends /api on to the API and answers the rest itself."}
```

`ng config` writes the setting into `angular.json` for the `serve` command, so a plain `ng serve` uses
it:

```
ana@dev:~/planner$ npx ng config projects.planner.architect.serve.options.proxyConfig proxy.conf.json
```

The dev server reads the proxy when it starts, so stop it with `Ctrl-C` in its terminal and start it
again with `npx ng serve`. Then the same question, asked of the application's own address:

```
ana@dev:~/planner$ curl -s http://localhost:4200/api/planner | head -c 120; echo
{"courses":[{"id":"html-css","name":"HTML and CSS"},{"id":"javascript","name":"JavaScript"},{"id":"git","name":"Git"}],"
```

The same answer, through the dev server. In production the same arrangement is made by whatever
serves the application, a web server or a cloud's load balancer, sending `/api` to the API and the
rest to the built files. The page never learns there are two
programs, and there is no CORS to configure, because there is only one origin.
