---
title: The wildcard, and why it is not the fix
version: 1
---

**The first answer most people find is one header, `Access-Control-Allow-Origin: *`, and it is wrong
in a way the browser itself refuses.** Try it, to see why. Add this line at the top of the request
handler in `server/api.mjs`, as an experiment:

```
ana@dev:~/planner$ git diff server/api.mjs
diff --git a/server/api.mjs b/server/api.mjs
index 855a6cd..95e9548 100644
--- a/server/api.mjs
+++ b/server/api.mjs
@@ -42,6 +42,7 @@ function send(res, status, body, headers = {}) {
 export function createApi() {
   return http.createServer(async (req, res) => {
     const path = new URL(req.url, "http://localhost").pathname;
+    res.setHeader("access-control-allow-origin", "*");
     const login = logins.get(cookie(req, "__Host-sid"));
     const user = login && Date.now() < login.until ? login.name : undefined;
 
```

The plain `GET` from the last section but one is readable now, and the page sees the 401:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ 'fetch("http://localhost:3000/api/plan").then((r) => r.status, (e) => String(e))'
request:  GET http://localhost:3000/api/plan
console:  Failed to load resource: the server responded with a status of 401 (Unauthorized)
result:   401
```

But the planner's API is only worth calling with a cookie, and a cross-origin `fetch` sends cookies only
when asked to, with `credentials: "include"`. Ask:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ 'fetch("http://localhost:3000/api/plan", { credentials: "include" }).then((r) => r.status, (e) => String(e))'
request:  GET http://localhost:3000/api/plan
console:  Access to fetch at 'http://localhost:3000/api/plan' from origin 'http://localhost:5173' has been blocked by CORS policy: The value of the 'Access-Control-Allow-Origin' header in the response must not be the wildcard '*' when the request's credentials mode is 'include'.
console:  Failed to load resource: net::ERR_FAILED
result:   TypeError: Failed to fetch
```

**The browser refuses the wildcard when credentials are involved**, and the message says so in full.
That rule is the reason `*` is merely untidy rather than dangerous: a response any site may read is one
read without the person's cookies, so it carries nothing that was only theirs. The moment cookies are
in play, the server must name the one origin it trusts, every time, and say `Allow-Credentials: true`
as well.

Take the experiment out before going on:

```
ana@dev:~/planner$ git checkout server/api.mjs
Updated 1 path from the index
```

## The other wrong answer

There is a second shortcut, worse than the first because the browser cannot see it: **reading the
request's `Origin` header and sending it straight back**, whatever it says, with credentials allowed.
That passes every check a browser makes and lets every site on the internet read every response with
the person's cookies attached. It is the same-origin policy switched off, written in three lines. An
allowlist is the only answer: a fixed list of the origins this API was built for, and nothing for anyone
else.
