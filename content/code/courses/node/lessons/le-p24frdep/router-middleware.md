---
title: Middleware for one part of the application
version: 1
---

**Middleware can be attached to one router or one route instead of the whole application**, and
that is how a rule that applies to some paths is kept off the others. The usual example is a check
that the caller is allowed to do something. In the links service, anybody may create a link and follow
one, and only whoever runs the service may list them all or delete one.

```schooling-example
{"language": "javascript", "file": "demo/admin.js", "parts": [
 {"code": "import express from \"express\";\nimport { timingSafeEqual } from \"node:crypto\";\n\nconst ADMIN_KEY = \"change-me-in-lesson-9\"; // lesson 9 moves it to the environment\n\nfunction requireKey(req, res, next) {\n  const given = Buffer.from(req.get(\"x-admin-key\") ?? \"\");\n  const wanted = Buffer.from(ADMIN_KEY);\n  if (given.length !== wanted.length || !timingSafeEqual(given, wanted)) {\n    return res.status(401).json({ error: \"this needs the admin key\" });\n  }\n  next();\n}", "note": "**The key is compared in constant time.** `===` stops at the first character that differs, so how long a comparison takes says how much of a guess was right; `timingSafeEqual` takes the same time whatever the input, as long as the lengths match, which is checked first."},
 {"code": "const app = express();\napp.get(\"/links\", requireKey, (req, res) => res.json([]));\napp.post(\"/links\", (req, res) => res.status(201).json({ code: \"7ctxqn\" }));", "note": "**On one route**, the middleware is an argument before the handler. Express runs them left to right, and the handler only if `requireKey` called `next()`."},
 {"code": "const admin = express.Router();\nadmin.use(requireKey);\nadmin.get(\"/stats\", (req, res) => res.json({ links: 0 }));\napp.use(\"/admin\", admin);\n\napp.listen(3000, \"127.0.0.1\");", "note": "**On a whole router**, `router.use` puts it in front of everything mounted under it."}
]}
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links
{"error":"this needs the admin key"}
ana@dev:~/server/links$ curl -s -H 'x-admin-key: guess' http://127.0.0.1:3000/links
{"error":"this needs the admin key"}
ana@dev:~/server/links$ curl -s -H 'X-Admin-Key: change-me-in-lesson-9' http://127.0.0.1:3000/links
[]
ana@dev:~/server/links$ curl -s -X POST http://127.0.0.1:3000/links
{"code":"7ctxqn"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/admin/stats
{"error":"this needs the admin key"}
```

`req.get` reads a header by any capitalisation, the helper for lesson 5's `req.headers[…]`. **401
means "who are you?"**: the request had no credentials, or wrong ones. Its sibling 403 means "I know
who you are, and no", which this service has no use for yet.

A key in the source code is a key in every copy of the repository, and the comment says so on
purpose. Lesson 9 reads it from the environment, and keeps it out of git. A shared key is also the
simplest possible scheme, right for one operator and a few scripts; a service with users signs them
in, which the `apis` course covers.
