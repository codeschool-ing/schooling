---
title: Saving to the file
version: 1
---

First, take out the two `console.log` lines lesson 13 added to watch the load functions, so that the
dev server's terminal shows only what this lesson does. `src/routes/(planner)/+layout.server.js` goes
back to:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.server.js", "parts": [
 {"code": "// +layout.server.js: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';\n\nexport async function load() {\n\treturn readPlanner();\n}", "note": "As lesson 13 first wrote it, before the `console.log`."}
]}
```

and `src/routes/(planner)/courses/[id=slug]/+page.js` to:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.js", "parts": [
 {"code": "// +page.js: the course a course page is about, or a 404.\nimport { error } from '@sveltejs/kit';\n\nexport async function load({ params, parent }) {\n\tconst { courses } = await parent();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn { course };\n}", "note": "As lesson 13 first wrote it, before the `console.log`."}
]}
```

## Writing the file

**Before a form can save anything, the server needs code that writes the planner's file.** It goes in
the module that already reads it, `src/lib/server/planner.js`, which stays on the server. Two changes
are worth having from the start, and both are about what happens when things go wrong. Replace the
file:

```schooling-example
{"language": "javascript", "file": "src/lib/server/planner.js", "parts": [
 {"code": "// planner.js: the planner's data, read from and written to the file the server keeps it in.\nimport { readFile, writeFile, rename } from 'node:fs/promises';\n\nconst FILE = 'data/planner.json';\n\nexport async function readPlanner() {\n\treturn JSON.parse(await readFile(FILE, 'utf8'));\n}"},
 {"code": "// Changes run one at a time: each waits for the one before it to finish, so two\n// requests arriving together cannot both read the old file and lose a change.\nlet queue = Promise.resolve();", "note": "Each change waits for the one before it. Without this, two requests arriving together would both read the old file, and the second to write would undo the first."},
 {"code": "function change(edit) {\n\tconst result = queue.then(async () => {\n\t\tconst planner = await readPlanner();\n\t\tconst answer = edit(planner);", "note": "`edit` changes the planner object it is given, and its return value is what the caller gets back."},
 {"code": "\t\t// Write a new file and then put it in the old one's place, so that a crash\n\t\t// halfway through leaves the old file whole rather than half of a new one.\n\t\tawait writeFile(`${FILE}.new`, JSON.stringify(planner, null, '\\t') + '\\n');\n\t\tawait rename(`${FILE}.new`, FILE);\n\t\treturn answer;\n\t});", "note": "`rename` replaces a file in one step, so the file on disk is always a whole planner, the old one or the new one."},
 {"code": "\tqueue = result.catch(() => {});\n\treturn result;\n}\n\n/** Add a session; false if there is no such course. */\nexport function addSession({ course, date, minutes }) {\n\treturn change((planner) => {\n\t\tif (!planner.courses.some((c) => c.id === course)) return false;\n\t\tconst id = Math.max(0, ...planner.sessions.map((s) => s.id)) + 1;\n\t\tplanner.sessions.push({ id, course, date, minutes, done: false });\n\t\treturn true;\n\t});\n}\n\n/** Mark a session done or not done; the session, or undefined if there is none. */\nexport function setDone(id, done) {\n\treturn change((planner) => {\n\t\tconst session = planner.sessions.find((s) => s.id === id);\n\t\tif (session) session.done = done;\n\t\treturn session;\n\t});\n}", "note": "A change that failed must not block the ones after it, so the queue carries on whether it worked or not. The caller still gets the failure, through `result`."}
]}
```

**The queue works because there is one server process.** Every request is answered by the same Node
process, so one promise chain in one module sees every change. An application with several servers,
or one that runs as many short-lived functions in the cloud, has no single place for a queue, and that
is one of the reasons such applications keep their data in a database, which puts changes in order
itself. For one person's planner on one computer, a file and a queue are enough, and they keep the
lesson about forms rather than about databases.

A new session's id is one more than the largest id there is. The id is what the planner uses to tell
sessions apart, as the `{#each}` key in lesson 8 does, so it must never be reused while the session it
named still exists. Counting the sessions instead would reuse one the moment a session was deleted.
