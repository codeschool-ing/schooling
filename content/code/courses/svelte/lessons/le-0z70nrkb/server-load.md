---
title: A server load function, for what the server owns
version: 1
---

**The data file is in `static`, and everything in `static` is served to anybody who asks for it.** That
was fine while the planner only read it. Lesson 14 makes the planner write sessions back, and a file
the server writes to is not one to hand out by its address. It is also not where data lives in an
application that has more than one user: there it is a database, which the browser cannot reach at
all. Either way, the reading has to happen on the server, in code that never goes to the browser.

Move the file out of `static`, into a folder of its own at the top of the project. `git mv` moves it
and tells Git it was moved:

```
ana@dev:~/planner$ mkdir data src/lib/server
ana@dev:~/planner$ git mv static/planner.json data/planner.json
```

`src/lib/server` is a folder SvelteKit treats specially, as the next part shows. Save the code that
reads the file there, as `src/lib/server/planner.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/server/planner.js", "parts": [
 {"code": "// planner.js: the planner's data, read from the file the server keeps it in.\nimport { readFile } from 'node:fs/promises';"},
 {"code": "const FILE = 'data/planner.json';", "note": "A relative path is taken from the folder the server was started in: the project, for `npm run dev`."},
 {"code": "export async function readPlanner() {\n\treturn JSON.parse(await readFile(FILE, 'utf8'));\n}", "note": "`node:fs/promises` is Node's own file system module. It does not exist in a browser."}
]}
```

## The obvious change, and why it fails

The obvious change is to call it from the load function there already is. Replace
`src/routes/(planner)/+layout.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.js", "parts": [
 {"code": "// +layout.js: the data every page of the planner needs. (This is the wrong file for it.)\nimport { readPlanner } from '#lib/server/planner.js';\n\nexport async function load() {\n\treturn readPlanner();\n}", "note": "`#lib/server/planner.js` is the module from above. This file runs in the browser too, which is the problem."}
]}
```

The server is happy with it:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o '<title>.*</title>'
<title>225 min this week · Study planner</title>
```

and the browser is not:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
title: 225 min this week · Study planner
- text: "server_only_import Cannot import `#lib/server/planner.js` into code that runs in the browser, as this could leak sensitive information. src/routes/(planner)/+layout.js imports #lib/server/planner.js If you're only using the import as a type, change it to `import type`. https://svelte.dev/e/kit/server_only_import Click outside, press Esc key, or fix the code to dismiss. You can also disable this overlay by setting"
- code: server.hmr.overlay
- text: to
- code: "false"
- text: in
- code: vite.config.js
- text: .
```

**The title says the server rendered the week; the page underneath is Vite's error overlay.** A
`+layout.js` is universal, so after rendering on the server SvelteKit sends it to the browser to run
again, along with everything it imports. One of those imports reads a file with Node's file system,
which the browser does not have. SvelteKit stops it before it gets that far: a module in
`src/lib/server`, or one named `*.server.js`, may only be imported by code that stays on the server,
and `server_only_import` names the file that broke the rule. The rule is there for the case that
matters, a module holding a database password or an API key, which would otherwise be shipped to every
visitor for them to read.

## `+layout.server.js`

**A load function in a file whose name ends in `.server.js` runs on the server and nowhere else.** The
browser never receives its code; it asks the server for the result. Renaming the file is the whole fix:

```
ana@dev:~/planner$ mv 'src/routes/(planner)/+layout.js' 'src/routes/(planner)/+layout.server.js'
```

Change the comment on its first line, since it is now the right file for the job:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.server.js", "parts": [
 {"code": "// +layout.server.js: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';\n\nexport async function load() {\n\treturn readPlanner();\n}", "note": "The same code as the `+layout.js` it replaces. Only the file's name is different, and with it where the code runs."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ | head -4
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
```

The week is back. The file it came from is not reachable any more:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/planner.json
404
```

The layout component did not change. `data` is the same prop with the same courses and sessions in it,
and the layout cannot tell whether a universal or a server load function produced it.
