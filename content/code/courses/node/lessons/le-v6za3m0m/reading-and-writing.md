---
title: Reading, writing and looking around
version: 1
---

**`node:fs/promises` has a function for each thing a program does with files**, and a server uses
about eight of them:

```schooling-example
{"language": "javascript", "file": "files.js", "parts": [
 {"code": "import { mkdir, writeFile, appendFile, readFile, readdir, stat, rm } from \"node:fs/promises\";\nimport path from \"node:path\";\n\nconst dir = path.join(import.meta.dirname, \"data\");\nawait mkdir(path.join(dir, \"2026\"), { recursive: true });", "note": "**`mkdir` with `recursive: true`** makes every missing folder in the path, and does not fail when they already exist, which is what a program starting for the first time or the hundredth wants."},
 {"code": "await writeFile(path.join(dir, \"notes.txt\"), \"first line\\n\");\nawait appendFile(path.join(dir, \"notes.txt\"), \"second line\\n\");\nconsole.log(JSON.stringify(await readFile(path.join(dir, \"notes.txt\"), \"utf8\")));", "note": "`writeFile` replaces a file whole, or creates it; `appendFile` adds to the end, which is how a log grows."},
 {"code": "for (const entry of await readdir(dir, { withFileTypes: true })) {\n  console.log(entry.isDirectory() ? \"folder\" : \"file  \", entry.name);\n}", "note": "**`readdir` with `withFileTypes`** says which entries are files and which are folders, without a second call per entry."},
 {"code": "const info = await stat(path.join(dir, \"notes.txt\"));\nconsole.log(`${info.size} bytes, changed ${info.mtime.toISOString()}`);", "note": "`stat` answers questions about a file without reading it: its size in bytes, when it last changed."},
 {"code": "await writeFile(path.join(dir, \"lock\"), String(process.pid), { flag: \"wx\" });\ntry {\n  await writeFile(path.join(dir, \"lock\"), String(process.pid), { flag: \"wx\" });\n} catch (err) {\n  console.log(`second write: ${err.code}`);\n}\nawait rm(dir, { recursive: true, force: true });", "note": "**The `wx` flag writes only if the file does not exist yet**, in one step, so two processes cannot both believe they created it. The second write is refused."}
]}
```

```
ana@dev:~/server/files$ node files.js
"first line\nsecond line\n"
folder 2026
file   notes.txt
23 bytes, changed 2026-10-22T22:16:45.471Z
second write: EEXIST
```

The last line removes the whole `data` folder, which `rm` with `recursive` and `force` does without
asking and without failing if it is already gone. That is the one to be careful with: it is `rm -rf`,
and a path built wrongly, by the rules of the previous section, makes it delete something else.

`readFile` and `writeFile` hold the whole file in memory at once. For a configuration file or a
store of a few thousand links that is right. For a log of a hundred megabytes it is not, and the
section on why streams exist measures the difference.
