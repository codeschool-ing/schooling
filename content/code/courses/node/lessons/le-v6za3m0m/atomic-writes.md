---
title: Writing a file that survives a crash
version: 1
---

**`writeFile` is not one step.** It truncates the file, then writes the new bytes, and a process
killed between the two — a deploy, a crash, a power cut — leaves the file half written. For a store,
that is every link lost at once, because half a JSON document is not JSON.

This program writes a large array to a file, and is killed partway, as a crash would kill it:

```javascript
// torn.js
import { writeFile } from "node:fs/promises";

const links = Array.from({ length: 200_000 }, (_, i) => ({ code: `c${i}`, url: `https://example.com/${i}` }));
await writeFile("store.json", JSON.stringify([{ code: "first", url: "https://example.com/" }]));
console.log("a good store.json is on disk");
setTimeout(() => process.kill(process.pid, "SIGKILL"), 15);
await writeFile("store.json", JSON.stringify(links));
console.log("never printed");
```

```
ana@dev:~/server/files$ node torn.js; ls -l store.json; node -e 'JSON.parse(require("fs").readFileSync("store.json", "utf8"))' 2>&1 | grep -E '^SyntaxError'
a good store.json is on disk
bash: line 3:  4596 Killed                  node torn.js
-rw-r--r-- 1 ana ana 0 Oct 22 19:16 store.json
SyntaxError: Unexpected end of JSON input
```

`writeFile` had already emptied the good file, and the new bytes had not arrived: zero bytes, which
do not parse. With a moment's difference in timing it is half of the new array instead, which does not
parse either. **The old data and the new are both gone.**

## Write beside it, then rename

The fix is a rename, which on the same disk is a single step the operating system does all or
nothing: **write the new contents to a temporary file next to the real one, then rename it over the
real one.** A crash before the rename leaves the old file whole; a crash after it leaves the new one
whole. There is no moment at which `links.json` holds half of anything.

The links service's store keeps its links in `data/links.json` that way from now on, which is the
change lesson 6 made every function `async` for:

```schooling-example
{"language": "javascript", "file": "src/store.js", "parts": [
 {"code": "// src/store.js: where the links live, in a JSON file written so that a crash cannot tear it.\nimport { mkdir, readFile, rename, writeFile } from \"node:fs/promises\";\nimport path from \"node:path\";\nimport { makeCode } from \"./code.js\";\n\nconst file = path.join(import.meta.dirname, \"..\", \"data\", \"links.json\");", "note": "**The file lives beside the code**, in `data/`, built from `import.meta.dirname` as lesson 3 said. Lesson 9 lets the environment choose it."},
 {"code": "let links = null;\nasync function load() {\n  if (links) return links;\n  try {\n    links = new Map(JSON.parse(await readFile(file, \"utf8\")).map((l) => [l.code, l]));\n  } catch (err) {\n    if (err.code !== \"ENOENT\") throw err;\n    links = new Map();\n  }\n  return links;\n}", "note": "Loaded once, the first time anything asks. A missing file is an empty store; any other error stops the service, as the previous section said it should."},
 {"code": "let saving = Promise.resolve();\nfunction save() {\n  const run = saving.catch(() => {}).then(async () => {\n    await mkdir(path.dirname(file), { recursive: true });\n    const temp = `${file}.${process.pid}.tmp`;\n    await writeFile(temp, JSON.stringify([...links.values()], null, 2) + \"\\n\");\n    await rename(temp, file);\n  });\n  saving = run;\n  return run;\n}", "note": "**Every save waits for the one before it.** Two requests changing links at once would otherwise write two temporary files and rename them in either order, and the older could win. A save that failed is reported to its own caller and does not stop the next one."},
 {"code": "export async function add(url) {\n  await load();\n  let code;\n  do code = makeCode();\n  while (links.has(code));\n  const link = { code, url, visits: 0, created: new Date().toISOString() };\n  links.set(code, link);\n  await save();\n  return link;\n}\n\nexport async function find(code) {\n  return (await load()).get(code);\n}\n\nexport async function all() {\n  return [...(await load()).values()];\n}\n\nexport async function remove(code) {\n  const gone = (await load()).delete(code);\n  if (gone) await save();\n  return gone;\n}\n\nexport async function visit(code) {\n  const link = (await load()).get(code);\n  if (link) {\n    link.visits++;\n    await save();\n  }\n  return link;\n}", "note": "The five functions lesson 6's routes call, with the same names and the same answers. Every one that changes a link saves before it returns, so a 201 means the link is on disk."}
]}
```

`data/` holds the service's data, so it joins `node_modules/` in `.gitignore`. Now the links survive
a restart:

```
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' -H 'content-type: application/json' -d '{"url": "https://nodejs.org/"}' http://127.0.0.1:3000/links
201
ana@dev:~/server/links$ cat data/links.json
[
  {
    "code": "jsfgve",
    "url": "https://nodejs.org/",
    "visits": 0,
    "created": "2026-10-22T22:17:00.026Z"
  }
]
ana@dev:~/server/links$ cat .gitignore
node_modules/
data/
```

and with the server stopped and started again, the link is still there:

```
ana@dev:~/server/links$ curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links
[{"code":"jsfgve","url":"https://nodejs.org/","visits":0,"created":"2026-10-22T22:17:00.026Z"}]
```

**One file for the whole store is right for a few thousand links and wrong for millions**: every
change rewrites all of them. A database is the answer at that size, and the `sql-databases` course,
the next on this track, is where the store moves to one. The routes will not notice that move either.
