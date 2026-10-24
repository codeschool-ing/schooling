---
title: The fix, and the tests green
version: 1
---

**Three changes to `server/api.mjs`, one for each test**: the cookie gets the prefix and the two
attributes, a login records when it ends, and signing out deletes the login on the server.

```
ana@dev:~/planner$ git diff server/api.mjs
diff --git a/server/api.mjs b/server/api.mjs
index a6bbc41..855a6cd 100644
--- a/server/api.mjs
+++ b/server/api.mjs
@@ -42,17 +42,21 @@ function send(res, status, body, headers = {}) {
 export function createApi() {
   return http.createServer(async (req, res) => {
     const path = new URL(req.url, "http://localhost").pathname;
-    const user = logins.get(cookie(req, "sid"));
+    const login = logins.get(cookie(req, "__Host-sid"));
+    const user = login && Date.now() < login.until ? login.name : undefined;
 
     if (req.method === "POST" && path === "/api/login") {
       const { name, password } = await readJson(req);
       if (!passwordIsRight(name, password)) return send(res, 401, { error: "wrong name or password" });
       const sid = randomBytes(32).toString("base64url");
-      logins.set(sid, name);
-      return send(res, 200, { name }, { "set-cookie": `sid=${sid}; HttpOnly; SameSite=Lax; Path=/` });
+      logins.set(sid, { name, until: Date.now() + 8 * 60 * 60 * 1000 });
+      return send(res, 200, { name }, {
+        "set-cookie": `__Host-sid=${sid}; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=28800`,
+      });
     }
     if (req.method === "POST" && path === "/api/logout") {
-      return send(res, 200, {}, { "set-cookie": "sid=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0" });
+      logins.delete(cookie(req, "__Host-sid"));
+      return send(res, 200, {}, { "set-cookie": "__Host-sid=; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=0" });
     }
     if (req.method === "GET" && path === "/api/plan") {
       if (!user) return send(res, 401, { error: "sign in first" });
```

- `logins` now maps an id to **a name and a time**, `until`, eight hours from sign-in, and a login
  past its `until` is treated as no login at all. The same eight hours go in the cookie's `Max-Age`, so
  the browser forgets it at the moment the server would refuse it.
- **Signing out deletes the entry**, so the id stops meaning anything wherever a copy of it is.
- The cookie is `__Host-sid`, with `Secure`, and the server reads that name.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  20:13:26
   Duration  405ms (tests 61%, import 27%, transform 10%, worker 1%)
```

All three green, and the whole of both suites still passes, the browser test of the last section
included, since it asked about `httpOnly` and not about a name:

```
ana@dev:~/planner$ npm run check 2>&1 | grep -E "Tests |[0-9] (passed|failed)"
 Test Files  5 passed (5)
      Tests  30 passed (30)
  6 passed (3.0s)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "End a login on sign-out and after eight hours, and mark its cookie __Host-"
```
