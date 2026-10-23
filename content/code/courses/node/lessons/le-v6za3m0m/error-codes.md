---
title: The codes a file operation fails with
version: 1
---

**Every failure from the file system carries a `code`, and the code is what a program decides on.**
Lesson 1 met `ENOENT`. These are the ones a server meets, provoked on purpose:

```javascript
// codes.js
import { readFile, mkdir, writeFile, readdir } from "node:fs/promises";

const attempts = {
  "read a file that is not there": () => readFile("missing.json"),
  "make a folder that exists": () => mkdir("/tmp"),
  "read a folder as a file": () => readFile("/tmp"),
  "write where you may not": () => writeFile("/etc/links.json", "{}"),
  "list a file as a folder": () => readdir("codes.js"),
};

for (const [what, attempt] of Object.entries(attempts)) {
  try {
    await attempt();
  } catch (err) {
    console.log(`${err.code.padEnd(7)} ${what}`);
  }
}
```

```
ana@dev:~/server/files$ node codes.js
ENOENT  read a file that is not there
EEXIST  make a folder that exists
EISDIR  read a folder as a file
EACCES  write where you may not
ENOTDIR list a file as a folder
```

| code | meaning | what a server usually does |
|---|---|---|
| `ENOENT` | no such file or folder | treat as empty, or answer 404 |
| `EEXIST` | it already exists | carry on, if that was the goal |
| `EISDIR`, `ENOTDIR` | a folder where a file was expected, or the reverse | a bug in a path: 500 |
| `EACCES`, `EPERM` | the process may not | a deployment problem: fail loudly at start-up |
| `EMFILE` | too many files open at once | a leak: something opens files and never closes them |
| `ENOSPC` | the disk is full | nothing a request can fix: 500, and an alert |

The pattern in code is a check on `err.code`, and **re-throwing everything else**:

```javascript
// load.js
import { readFile } from "node:fs/promises";

export async function loadOrEmpty(file) {
  try {
    return JSON.parse(await readFile(file, "utf8"));
  } catch (err) {
    if (err.code === "ENOENT") return [];
    throw err;
  }
}
```

A missing file on the first run is normal, so it becomes an empty list. A file that exists and holds
broken JSON, or a disk that refuses, is not, and swallowing that would make a server start with no
data and say nothing. **A `catch` that handles every error the same way is a bug waiting for the
error you did not think of.**
