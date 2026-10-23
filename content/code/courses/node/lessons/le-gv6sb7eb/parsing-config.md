---
title: One module that reads the configuration
version: 1
---

**Reading `process.env` all over the code is how a typo in a variable name becomes a bug in
production**: each read is a string that might be missing, converted on the spot, with a default
somebody chose in that one file. Lesson 3's layout gave configuration a module of its own, and this is
it. It reads every variable once, at start-up, turns each into the type the code needs, and **refuses
to start** if anything is wrong, with every problem listed:

```schooling-example
{"language": "javascript", "file": "src/config.js", "parts": [
 {"code": "// src/config.js: every setting the service reads, read once and checked once.\nimport path from \"node:path\";\n\nconst env = process.env;\nconst problems = [];", "note": "Everything this service reads from the environment, in one place. `problems` collects what is wrong, so a bad start lists all of it instead of the first."},
 {"code": "function port(name, fallback) {\n  const raw = env[name] ?? String(fallback);\n  const n = Number(raw);\n  if (!Number.isInteger(n) || n < 1 || n > 65535) problems.push(`${name} must be a port number, not ${JSON.stringify(raw)}`);\n  return n;\n}", "note": "**A port is a whole number from 1 to 65535**, and the string from the environment has to become one; `\"3000a\"`, `\"80.5\"` and an empty string are refused here rather than handed to `listen`."},
 {"code": "const adminKey = env.ADMIN_KEY ?? \"\";\nif (adminKey.length < 24) problems.push(\"ADMIN_KEY must be set, and at least 24 characters long\");", "note": "**The admin key has no default**, so a service that was never given one cannot start with a guessable key. The length is the section on secrets' rule."},
 {"code": "export const config = Object.freeze({\n  production: env.NODE_ENV === \"production\",\n  host: env.HOST ?? \"127.0.0.1\",\n  port: port(\"PORT\", 3000),\n  dataFile: path.resolve(env.DATA_FILE ?? path.join(import.meta.dirname, \"..\", \"data\", \"links.json\")),\n  adminKey,\n});", "note": "**One frozen object**, so nothing can change a setting after start-up; every module that imports it gets the same copy, lesson 3's singleton. The data file can be relative, and is resolved from where the program was started."},
 {"code": "export function summary() {\n  return { ...config, adminKey: `(set, ${config.adminKey.length} characters)` };\n}", "note": "**What may be printed.** The key is replaced by a sentence about it, so the start-up line can show every setting without showing the secret."},
 {"code": "if (problems.length) {\n  console.error(`the configuration is not usable:\\n  ${problems.join(\"\\n  \")}`);\n  process.exit(1);\n}", "note": "**Fail fast.** A service with a bad configuration stops here, at start-up, with the list, rather than at the first request that needs the bad value."}
]}
```

`server.js` reads its port and host from it, and says what it started with:

```javascript
// server.js
import { config, summary } from "./src/config.js";
import { createApp } from "./src/app.js";

createApp().listen(config.port, config.host, () => {
  console.log(`links on http://${config.host}:${config.port}`, summary());
});
```

Two more files take their values from it instead of their own. `src/admin.js` compares against
`config.adminKey`, and `src/store.js` writes to `config.dataFile`. Each is a change to a couple of
lines, and these `sed` commands make them:

```
ana@dev:~/server/links$ sed -i 's|^const ADMIN_KEY = .*|const ADMIN_KEY = config.adminKey;|; s|^import { timingSafeEqual } from "node:crypto";|&\nimport { config } from "./config.js";|' src/admin.js
ana@dev:~/server/links$ sed -i 's|^const file = .*|const file = config.dataFile;|; s|^import { makeCode } from "./code.js";|&\nimport { config } from "./config.js";|' src/store.js
ana@dev:~/server/links$ grep -n config src/admin.js src/store.js
src/admin.js:3:import { config } from "./config.js";
src/admin.js:5:const ADMIN_KEY = config.adminKey;
src/store.js:5:import { config } from "./config.js";
src/store.js:7:const file = config.dataFile;
```

`grep` shows the lines that changed. On a Mac, whose `sed -i` wants an argument, it is as quick to make
the same edits by hand. Started with nothing set, the service now refuses:

```
ana@dev:~/server/links$ node server.js; echo "exit code $?"
the configuration is not usable:
  ADMIN_KEY must be set, and at least 24 characters long
exit code 1
ana@dev:~/server/links$ PORT=80a ADMIN_KEY=short node server.js; echo "exit code $?"
the configuration is not usable:
  ADMIN_KEY must be set, and at least 24 characters long
  PORT must be a port number, not "80a"
exit code 1
```

**Both problems in one message, and exit code 1**, before a port was opened. Which is exactly what a
deployment with a missing variable should do: fail where somebody is watching, at start-up, rather
than serve requests with a key nobody chose.
