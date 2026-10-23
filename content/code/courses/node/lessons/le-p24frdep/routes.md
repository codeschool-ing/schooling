---
title: Routes and routers
version: 1
---

**A route is a method, a path pattern and a handler, and Express tries them in the order they were
added.** The first whose method and pattern match the request runs. Three tools organise them:

```schooling-example
{"language": "javascript", "file": "demo/routes.js", "parts": [
 {"code": "import express from \"express\";\n\nconst app = express();\n\napp\n  .route(\"/links\")\n  .get((req, res) => res.send(\"the list of links\\n\"))\n  .post((req, res) => res.send(\"a new link\\n\"));", "note": "**One path, several methods**: `app.route` names the path once. A method missing here is the 405 lesson 5 wrote and Express does not; the section on unmatched routes returns to it."},
 {"code": "const admin = express.Router();\nadmin.get(\"/\", (req, res) => res.send(\"the admin page\\n\"));\nadmin.get(\"/stats\", (req, res) => res.send(\"the numbers\\n\"));\napp.use(\"/admin\", admin);", "note": "**A `Router` is a small application of its own**, with routes written relative to wherever it is mounted. Here `/` inside it is `/admin/` outside."},
 {"code": "app.get(\"/links/new\", (req, res) => res.send(\"a form for a new link\\n\"));\napp.get(\"/links/:code\", (req, res) => res.send(`the link ${req.params.code}\\n`));\n\napp.listen(3000, \"127.0.0.1\");", "note": "**Order decides between two patterns that both match.** `/links/new` is a fixed path, written first so that `:code` does not take it."}
]}
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links
the list of links

ana@dev:~/server/links$ curl -s -X POST http://127.0.0.1:3000/links
a new link

ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/
the list of links

ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/ADMIN/stats
the numbers

ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/new
a form for a new link

ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqn
the link 7ctxqn
```

Three things in those answers are Express's defaults, and each is a decision someone made for you:

- **A trailing slash does not matter**: `/links/` reached the `/links` route. Lesson 5's router
  treated them as two paths.
- **Case does not matter**: `/ADMIN/stats` reached `/admin/stats`. Both defaults can be changed with
  `express.Router({ strict: true, caseSensitive: true })`, and almost nobody does.
- **`/links/new` was not a code**, because it was added first. Swap the two lines and `new` becomes a
  link nobody can create a form for. A route list is read top to bottom like a program, and a broad
  pattern above a narrow one hides it.

A router is how a larger service is split by feature, lesson 3's second layout: `users.js` exports a
router, `billing.js` another, and `app.js` mounts each under its prefix. The links service has one,
and the last section of this lesson writes it.
