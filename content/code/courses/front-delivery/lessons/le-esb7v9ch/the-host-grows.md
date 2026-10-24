---
title: The host grows: rules and HTTPS
version: 1
---

**The rest of this lesson needs two things from `host.mjs` that a real host has and it does not yet: a
rules file, and HTTPS.** This is the whole file again, grown to about ninety lines. The parts from lesson
1 are unchanged; the new parts read a `_redirects` file in the format Netlify and Cloudflare Pages use,
and serve over TLS when given a certificate. Replace the old file with it:

```schooling-example
{"language": "javascript", "file": "host.mjs", "parts": [
 {"code": "// host.mjs\nimport { createServer } from \"node:http\";\nimport { createServer as createSecureServer } from \"node:https\";\nimport { readFile } from \"node:fs/promises\";\nimport { extname, join, normalize } from \"node:path\";\n\nconst root = process.argv[2] ?? \"dist\";\nconst port = Number(process.argv[3] ?? 8080);\nconst types = {\n  \".html\": \"text/html; charset=utf-8\",\n  \".js\": \"text/javascript; charset=utf-8\",\n  \".css\": \"text/css; charset=utf-8\",\n  \".json\": \"application/json\",\n  \".svg\": \"image/svg+xml\",\n};", "note": "As in lesson 1, plus `node:https`, Node's own TLS server, which takes a certificate and a key and otherwise behaves like `node:http`."},
 {"code": "\nasync function load(path) {\n  if (path === \"/_redirects\") return null;\n  const file = join(root, normalize(path));\n  for (const candidate of [file, join(file, \"index.html\")]) {\n    try {\n      return { body: await readFile(candidate), type: types[extname(candidate)] ?? \"application/octet-stream\" };\n    } catch {\n      // not there, or a folder: try the next candidate\n    }\n  }\n  return null;\n}", "note": "Unchanged, except for the first line: the rules file is read by the host and never served, which is what Netlify and Cloudflare do with it too."},
 {"code": "\nasync function rules() {\n  const text = await readFile(join(root, \"_redirects\"), \"utf8\").catch(() => \"\");\n  return text\n    .split(\"\\n\")\n    .map((line) => line.trim())\n    .filter((line) => line && !line.startsWith(\"#\"))\n    .map((line) => {\n      const [from, to, status = \"301\"] = line.split(/\\s+/);\n      return { from, to, status: Number(status) };\n    });\n}", "note": "One rule per line: where from, where to, and a status that defaults to 301. A missing file is no rules, so a site without one is served exactly as before. Lines starting with `#` are comments."},
 {"code": "\nfunction target(rule, path) {\n  if (!rule.from.endsWith(\"*\")) return path === rule.from ? rule.to : null;\n  const prefix = rule.from.slice(0, -1);\n  return path.startsWith(prefix) ? rule.to.replace(\":splat\", path.slice(prefix.length)) : null;\n}", "note": "A rule matches a path exactly, or by its start when it ends in `*`, the **splat**. Whatever the `*` matched replaces `:splat` in the destination."},
 {"code": "\nasync function handle(request, response) {\n  const path = new URL(request.url, \"http://host\").pathname;\n  let found = await load(path);\n  for (const rule of found ? [] : await rules()) {\n    const to = target(rule, path);\n    if (to === null) continue;\n    if (rule.status === 200) {\n      found = await load(to);\n      break;\n    }\n    response.writeHead(rule.status, { location: to });\n    response.end();\n    console.log(rule.status, request.method, path, \"->\", to);\n    return;\n  }", "note": "A file that exists wins, and the rules are read only when there is none. The first rule that matches decides: a 200 is a **rewrite**, which serves another file at the same address; anything else is a **redirect**, which tells the browser to go elsewhere."},
 {"code": "  if (found) {\n    response.writeHead(200, { \"content-type\": found.type });\n    response.end(found.body);\n  } else {\n    const page = await load(\"/404.html\");\n    response.writeHead(404, { \"content-type\": \"text/html; charset=utf-8\" });\n    response.end(page?.body ?? \"not found\\n\");\n  }\n  console.log(response.statusCode, request.method, path);\n}", "note": "The end of lesson 1's handler, unchanged."},
 {"code": "\nif (process.env.CERT) {\n  const options = { cert: await readFile(process.env.CERT), key: await readFile(process.env.KEY) };\n  createSecureServer(options, handle).listen(port, \"127.0.0.1\");", "note": "With `CERT` and `KEY` in the environment, the same handler is served over HTTPS on the port given."},
 {"code": "  createServer((request, response) => {\n    const host = (request.headers.host ?? \"\").replace(/:\\d+$/, \"\");\n    response.writeHead(308, { location: `https://${host}:${port}${request.url}` });\n    response.end();\n    console.log(308, request.method, request.url, \"-> https\");\n  }).listen(8080, \"127.0.0.1\");\n  console.log(`serving ${root} on https://127.0.0.1:${port}, and redirecting http://127.0.0.1:8080`);", "note": "And plain HTTP on 8080 answers every request with a redirect to the same path over HTTPS, which is what every host does on port 80."},
 {"code": "} else {\n  createServer(handle).listen(port, \"127.0.0.1\", () => console.log(`serving ${root} on http://127.0.0.1:${port}`));\n}", "note": "Without a certificate, it is lesson 1's server, with rules."}
]}
```

**The rule that files win is a choice, and the hosts differ on it.** Netlify reads a rule only when no
file matches the path, unless the status is followed by `!`, which it calls forcing. Cloudflare Pages
documents the opposite for its redirects: they are followed whether or not a file matches. This server
does what Netlify does, because it is the behaviour that keeps a broad rule such as `/*` from swallowing
the site's own scripts. When you write rules for Cloudflare, write them so the order does not matter.

Commit the new version:

```
ana@dev:~/planner$ git add host.mjs
ana@dev:~/planner$ git commit -qm "Rules and HTTPS for the host"
```
