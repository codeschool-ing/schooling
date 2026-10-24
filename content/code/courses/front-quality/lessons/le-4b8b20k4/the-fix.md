---
title: An allowlist, a preflight answer, and two tests
version: 1
---

**The fix is a list of the origins the API trusts, which for the planner is one, and the headers that
say so on every answer to one of them.** First the tests. Add these two to the end of
`server/api.test.mjs`:

```javascript
// server/api.test.mjs, below what is there
test("a preflight from the planner's page is allowed, with credentials", async () => {
  const response = await fetch(`${base}/api/login`, {
    method: "OPTIONS",
    headers: {
      origin: "http://localhost:5173",
      "access-control-request-method": "POST",
      "access-control-request-headers": "content-type",
    },
  });
  expect(response.status).toBe(204);
  expect(response.headers.get("access-control-allow-origin")).toBe("http://localhost:5173");
  expect(response.headers.get("access-control-allow-credentials")).toBe("true");
  expect(response.headers.get("access-control-allow-headers")).toBe("content-type");
});

test("any other origin is given no permission to read", async () => {
  const response = await fetch(`${base}/api/plan`, { headers: { origin: "https://elsewhere.example" } });
  expect(response.headers.get("access-control-allow-origin")).toBeNull();
});
```

Node's `fetch` lets a test set `Origin` by hand, which a browser never would; that is exactly what makes
it the tool for asking the server what it does for an origin it should refuse.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs 2>&1 | grep -E "^( FAIL|AssertionError| Test Files|      Tests)"
 FAIL  server/api.test.mjs > a preflight from the planner's page is allowed, with credentials
AssertionError: expected 404 to be 204 // Object.is equality
 Test Files  1 failed (1)
      Tests  1 failed | 4 passed (5)
```

**The first test fails with a 404**, the server knowing nothing of `OPTIONS`, and the second passes,
because a server that grants nothing grants nothing to strangers either. It is there to keep it that
way: the wildcard of the last section would have turned it red.

The change to the server:

```
ana@dev:~/planner$ git diff server/api.mjs
diff --git a/server/api.mjs b/server/api.mjs
index 855a6cd..5dc126a 100644
--- a/server/api.mjs
+++ b/server/api.mjs
@@ -39,11 +39,28 @@ function send(res, status, body, headers = {}) {
   res.end(JSON.stringify(body) + "\n");
 }
 
+const allowed = new Set(["http://localhost:5173"]);
+
+function corsHeaders(req) {
+  if (!allowed.has(req.headers.origin)) return {};
+  return { "access-control-allow-origin": req.headers.origin, "access-control-allow-credentials": "true", vary: "Origin" };
+}
+
 export function createApi() {
   return http.createServer(async (req, res) => {
     const path = new URL(req.url, "http://localhost").pathname;
     const login = logins.get(cookie(req, "__Host-sid"));
     const user = login && Date.now() < login.until ? login.name : undefined;
+    for (const [name, value] of Object.entries(corsHeaders(req))) res.setHeader(name, value);
+
+    if (req.method === "OPTIONS") {
+      res.writeHead(204, {
+        "access-control-allow-methods": "GET, POST",
+        "access-control-allow-headers": "content-type",
+        "access-control-max-age": "600",
+      });
+      return res.end();
+    }
 
     if (req.method === "POST" && path === "/api/login") {
       const { name, password } = await readJson(req);
```

- **`allowed` is the list**, and `corsHeaders` returns permission only for an origin on it. Everything
  else gets no CORS headers at all, which the browser reads as no.
- **`Vary: Origin`** tells any cache between the browser and the server that the answer depends on the
  `Origin` header, so a response permitted to one origin is never served from a cache to another.
- **`OPTIONS` is answered with 204** and the methods and headers the API accepts. `Max-Age: 600` lets the
  browser remember the answer for ten minutes instead of asking before every request.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  5 passed (5)
   Start at  20:21:02
   Duration  505ms (tests 51%, import 24%, transform 24%, worker 1%)
```

And from the page, with the server restarted: the sign-in, preflighted and with credentials, and then
the plan, with the cookie that sign-in set. Both are read:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ '(async () => { const login = await fetch("http://localhost:3000/api/login", { method: "POST", credentials: "include", headers: { "content-type": "application/json" }, body: JSON.stringify({ name: "ana", password: "correct horse battery staple" }) }); const plan = await fetch("http://localhost:3000/api/plan", { credentials: "include" }); return `sign-in ${login.status}, plan ${plan.status}`; })()'
request:  POST http://localhost:3000/api/login
request:  GET http://localhost:3000/api/plan
result:   sign-in 200, plan 200
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Allow the planner's own origin, and no other, to read the API"
```
