---
title: Installing Express, and what came with it
version: 1
---

**Lessons 6 and 7 are about Express, the web framework most Node servers are built on, and installing
it is the first thing to look at closely.** One command, one name:

```
ana@dev:~/server/links$ npm install express@5.3.0

added 65 packages, and audited 66 packages in 723ms

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

**You asked for one package and received 65.** Express depends on body parsers, a router, a cookie
parser, MIME tables and more, each of those on others, and npm installed the whole tree, flattened
into `node_modules` wherever two packages could share a copy. `npm ls` shows the top of the tree and
`--all` shows all of it; the count of lines is a rough count of the tree:

```
ana@dev:~/server/links$ npm ls
links@0.1.0 /home/ana/server/links
└── express@5.3.0

ana@dev:~/server/links$ npm ls --all | wc -l
127
ana@dev:~/server/links$ du -sh node_modules
4.3M	node_modules
```

`package.json` now has a `dependencies` field that npm wrote, holding `"express": "^5.3.0"`. **The
caret is npm's default**: you asked for 5.3.0 and npm recorded a range that accepts any later 5.x,
because it assumes the package follows semantic versioning and that no 5.x will break you. The
lockfile holds what was actually installed, 5.3.0 exactly, and that is the version that runs.

## Why is this package here?

Every one of the 65 is code your server loads and runs with your server's permissions. **`npm explain`
says which packages pulled one in**, and it is the first command to run when a name you never asked
for turns up in a warning:

```
ana@dev:~/server/links$ npm explain debug
debug@4.4.3
node_modules/debug
  debug@"^4.4.3" from body-parser@2.3.0
  node_modules/body-parser
    body-parser@"^2.3.0" from express@5.3.0
    node_modules/express
      express@"^5.3.0" from the root project
  debug@"^4.4.0" from express@5.3.0
  node_modules/express
    express@"^5.3.0" from the root project
  debug@"^4.4.0" from finalhandler@2.1.1
  node_modules/finalhandler
    finalhandler@"^2.1.0" from express@5.3.0
    node_modules/express
      express@"^5.3.0" from the root project
  debug@"^4.4.0" from router@2.2.0
  node_modules/router
    router@"^2.2.0" from express@5.3.0
    node_modules/express
      express@"^5.3.0" from the root project
  debug@"^4.4.3" from send@1.2.1
  node_modules/send
    send@"^1.1.0" from express@5.3.0
    node_modules/express
      express@"^5.3.0" from the root project
    send@"^1.2.0" from serve-static@2.2.1
    node_modules/serve-static
      serve-static@"^2.2.0" from express@5.3.0
      node_modules/express
        express@"^5.3.0" from the root project
```

`debug` is wanted five times over: Express asks for `^4.4.0` directly, and four of its own
dependencies ask for it too. Every one of those ranges accepts 4.4.3, so npm installed one copy and all
five share it, which is the flattening the first paragraph mentioned.

## A first use

To show the install works, `server.js` answers one route with a new code. Lesson 6 explains every line
of an Express application; here, it is enough that it runs:

```javascript
// server.js
import express from "express";
import { makeCode } from "./src/code.js";

const app = express();
app.get("/", (req, res) => res.send(`a new code: ${makeCode()}\n`));
app.listen(3000, "127.0.0.1", () => console.log("listening on http://127.0.0.1:3000"));
```

```
ana@dev:~/server/links$ node server.js
listening on http://127.0.0.1:3000
```

and from a second terminal:

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/
a new code: t25yvu
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/
a new code: aj69pv
```

Two requests, two codes. **Keep `node_modules` out of git**: it is 4.3 MB of other people's code that
`npm ci` puts back exactly from the lockfile in a few seconds, so a `.gitignore` with the single line
`node_modules/` belongs in the project from now on, beside a committed `package-lock.json`.
