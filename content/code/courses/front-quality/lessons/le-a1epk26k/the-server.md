---
title: A server with one account
version: 1
---

**The planner's API is one file, written with nothing but Node's own modules, so every line of what
happens at sign-in is in front of you.** It holds one account, `ana`, with the password
`correct horse battery staple`, and answers three addresses: sign in, sign out, and fetch the plan of
whoever is signed in. Save it as `server/api.mjs`:

```schooling-example
{"language": "javascript", "file": "server/api.mjs", "parts": [{"code": "// server/api.mjs\nimport http from \"node:http\";\nimport { randomBytes, scryptSync, timingSafeEqual } from \"node:crypto\";\nimport { readFileSync } from \"node:fs\";\n\nconst data = JSON.parse(readFileSync(new URL(\"../public/courses.json\", import.meta.url), \"utf8\"));\n", "note": "The planner's own data, read once when the server starts. Everything this server knows lives in memory, so stopping it forgets every change, as reloading the page did in lesson 1."}, {"code": "const salt = randomBytes(16);\nconst users = new Map([[\"ana\", scryptSync(\"correct horse battery staple\", salt, 32)]]);\nconst plans = new Map([[\"ana\", structuredClone(data)]]);\nconst logins = new Map();\n", "note": "One account, `ana`, whose password is stored as a scrypt hash and never as itself. `plans` keeps her sessions apart from anybody else's, and `logins` maps each sign-in to whoever made it."}, {"code": "function passwordIsRight(name, password) {\n  const given = scryptSync(String(password), salt, 32);\n  const stored = users.get(name);\n  return stored !== undefined && timingSafeEqual(stored, given);\n}\n", "note": "A password is right if its hash matches. The hash is computed even for a name that does not exist, so a wrong name and a wrong password take the same time, and `timingSafeEqual` compares in a time that does not depend on how many bytes agree."}, {"code": "function cookie(req, name) {\n  for (const part of (req.headers.cookie ?? \"\").split(\";\")) {\n    const [key, value] = part.trim().split(\"=\");\n    if (key === name) return value;\n  }\n  return undefined;\n}\n", "note": "Reads one cookie out of the `Cookie` header the browser sends, which holds every cookie for this site as `name=value` pairs separated by semicolons."}, {"code": "async function readJson(req) {\n  let text = \"\";\n  for await (const chunk of req) text += chunk;\n  try {\n    return JSON.parse(text);\n  } catch {\n    return {};\n  }\n}\n\nfunction send(res, status, body, headers = {}) {\n  res.writeHead(status, { \"content-type\": \"application/json\", ...headers });\n  res.end(JSON.stringify(body) + \"\\n\");\n}\n", "note": "Two small helpers: read a JSON body, treating anything unreadable as empty, and send a JSON answer with a status and any extra headers."}, {"code": "export function createApi() {\n  return http.createServer(async (req, res) => {\n    const path = new URL(req.url, \"http://localhost\").pathname;\n    const user = logins.get(cookie(req, \"sid\"));\n", "note": "Every request starts the same way: find out who is asking, from the `sid` cookie, if it names a login the server remembers."}, {"code": "    if (req.method === \"POST\" && path === \"/api/login\") {\n      const { name, password } = await readJson(req);\n      if (!passwordIsRight(name, password)) return send(res, 401, { error: \"wrong name or password\" });\n      const sid = randomBytes(32).toString(\"base64url\");\n      logins.set(sid, name);\n      return send(res, 200, { name }, { \"set-cookie\": `sid=${sid}; HttpOnly; SameSite=Lax; Path=/` });\n    }", "note": "Signing in. A right password gets a new session id, 32 random bytes, remembered on the server and sent to the browser in a cookie the page's scripts cannot read."}, {"code": "    if (req.method === \"POST\" && path === \"/api/logout\") {\n      return send(res, 200, {}, { \"set-cookie\": \"sid=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0\" });\n    }", "note": "Signing out tells the browser to drop the cookie. Read what it does not do; lesson 6 does."}, {"code": "    if (req.method === \"GET\" && path === \"/api/plan\") {\n      if (!user) return send(res, 401, { error: \"sign in first\" });\n      return send(res, 200, plans.get(user));\n    }\n    send(res, 404, { error: \"no such address\" });\n  });\n}\n", "note": "The plan, for whoever the cookie says is asking, and a 401 for nobody. Everything else is a 404."}, {"code": "if (import.meta.url === `file://${process.argv[1]}`) {\n  createApi().listen(3000, \"127.0.0.1\", () => console.log(\"api listening on http://127.0.0.1:3000\"));\n}", "note": "Listen on port 3000 when the file is run with `node`, and not when a test imports it, which lesson 6 does."}]}
```

**Two meanings of "session" meet in this file**, so the code keeps them apart. A study *session* is
the planner's, a date and some minutes. A *login* is a sign-in: the id in the cookie and the account
it belongs to. A security text would call the second a session too, and so does the cookie's name,
`sid`, which this course keeps because it is the name you will meet everywhere.

Two lines of `package.json` and `vite.config.ts` put the server beside the app. A script starts it:

```
ana@dev:~/planner$ npm pkg set scripts.api="node server/api.mjs"
ana@dev:~/planner$ npm pkg get scripts.api
"node server/api.mjs"
```

And the dev server passes every request under `/api` on to it, so the page and the API share one
address, `http://localhost:5173`. Lesson 7 is about why that matters. Add `server` to `vite.config.ts`:

```typescript
// vite.config.ts
import { configDefaults, defineConfig } from "vitest/config";

export default defineConfig({
  server: {
    proxy: { "/api": "http://127.0.0.1:3000" },
  },
  test: {
    exclude: [...configDefaults.exclude, "e2e/**"],
  },
});
```

**The server listens on `127.0.0.1` only**, the computer's own address, so nothing on your network can
reach it. A development server never needs more, and lesson 8 is about what a real one needs.

```
ana@dev:~/planner$ npm run api

> planner@0.0.0 api
> node server/api.mjs

api listening on http://127.0.0.1:3000
```
