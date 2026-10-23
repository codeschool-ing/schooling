---
title: Path patterns in Express 5
version: 1
---

**A route path is a pattern, and Express 5 understands four things in it**: plain text, a named
parameter `:name`, an optional part in braces `{…}`, and a wildcard `*name` that matches the rest of
the path. That is the whole language, and it is smaller than Express 4's on purpose.

```javascript
// demo/patterns.js
import express from "express";

const app = express();

app.get("/links/:code", (req, res) => res.json(req.params));
app.get("/stats{/:period}", (req, res) => res.json(req.params));
app.get("/files/*path", (req, res) => res.json(req.params));

app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqn
{"code":"7ctxqn"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/stats
{}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/stats/week
{"period":"week"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/files/2026/october/report.txt
{"path":["2026","october","report.txt"]}
```

- **`:code`** matches one segment, up to the next `/`, and arrives as a string.
- **`{/:period}`** makes the slash and the parameter optional together: `/stats` and `/stats/week`
  both match, and in the first `period` is simply absent.
- **`*path`** matches one or more segments, and arrives as an **array** of them: `["2026",
  "october", "report.txt"]`. Joining them back is your choice, and so is checking that none of them is
  `..`, which lesson 8's section on paths explains.

## What changed from Express 4

Tutorials written for Express 4 use patterns version 5 refuses, and the refusal comes at start-up:

```javascript
// demo/old-pattern.js
import express from "express";

const app = express();
app.get("*", (req, res) => res.send("everything\n"));
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ node demo/old-pattern.js 2>&1 | grep TypeError
PathError [TypeError]: Missing parameter name at index 1: *; visit https://git.new/pathToRegexpError for info
```

**A wildcard needs a name now**, `*rest` or `*path`, and a bare `*` is an error with an address
explaining it. Three other forms from version 4 went the same way: `:id?` became `{/:id}`, a regular
expression written inside the string is gone, and characters such as `(`, `)` and `+` mean nothing
special any more. The reason was security as much as tidiness: the old patterns compiled to regular
expressions that could take exponential time on some paths, which lesson 4's audit showed as an
advisory against `path-to-regexp`. **The new language cannot express a pattern that backtracks.**

A route that needs more than these four things — "a code is six characters from this alphabet" — says
so in the handler, not in the pattern. Lesson 7's section on parameters does exactly that.
