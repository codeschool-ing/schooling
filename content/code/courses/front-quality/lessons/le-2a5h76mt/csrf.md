---
title: Cross-site request forgery, and the Origin check
version: 1
---

**A cookie is sent by the browser with every request to its site, whoever started the request.** So a
page on another site can make the person's browser send a request to the planner's API, with the
planner's cookie attached, and the API sees a signed-in request it has every reason to obey. The page
cannot read the answer, as lesson 7 showed; it does not need to, if the request itself does the damage.
That is cross-site request forgery.

The planner is already well defended, and it is worth seeing why before adding to it:

- **The cookie is `SameSite=Lax`**, from lesson 5, so the browser leaves it off requests another site
  starts with `fetch` or a form `POST`. Only a plain link the person follows carries it, and a link is a
  `GET`, which on the planner changes nothing.
- **The API takes JSON**, and a JSON `POST` from another origin is preflighted, which lesson 7's
  allowlist refuses before the request is sent.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l09-csrf\" aria-label=\"A page on another site, open in the person's browser, makes the browser send a POST to the planner's API. Three checks stand on the way. First, SameSite=Lax: the browser leaves the planner's cookie off a request another site started. Second, the preflight: a JSON POST from another origin is announced with OPTIONS, and the API's allowlist refuses it. Third, on the server, the Origin header names the other site, which is not on the list, and the API answers 403. Only a request that passes all three reaches the code that signs a person out.\"><defs><marker id=\"l09-csrf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-csrf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a page on another site</text><rect x=\"10\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the person's browser</text><rect x=\"580\" y=\"75\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the planner's API</text><path d=\"M85 60 L85 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-amber)\"></path><text x=\"92\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">POST /api/logout</text><rect x=\"200\" y=\"120\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"140.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">1  SameSite=Lax</text><text x=\"256.0\" y=\"151.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">cookie left off</text><rect x=\"325\" y=\"120\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"381.0\" y=\"140.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">2  preflight, allowlist</text><text x=\"381.0\" y=\"151.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">JSON POST refused</text><rect x=\"450\" y=\"120\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"506.0\" y=\"140.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">3  Origin check</text><text x=\"506.0\" y=\"151.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">403 on the server</text><path d=\"M160 150 L200 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-paper-dim)\"></path><path d=\"M312 146 L325 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-paper-dim)\"></path><path d=\"M437 146 L450 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-paper-dim)\"></path><path d=\"M562 146 L645 146 L645 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-paper-dim)\"></path></svg>", "caption": "Three defences in a row, two of them the browser's and one the server's own. The third is the one that holds when the other two do not apply."}
```

**Two defences that both come from somewhere else** is the reason to add a third that belongs to the
server. Every request that changes something says where it came from, in the `Origin` header the browser
sets and no page can forge, and the server refuses one from a site it does not know. That check
survives a cookie set without `SameSite`, a browser that does not apply it, and an endpoint that one day
accepts a form. Add the test to the end of `server/api.test.mjs`:

```javascript
// server/api.test.mjs, below what is there
test("a request that changes something, sent from another site, is refused", async () => {
  const cookie = cookieOf(await signIn());
  const response = await fetch(`${base}/api/logout`, {
    method: "POST",
    headers: { cookie, origin: "https://elsewhere.example" },
  });
  expect(response.status).toBe(403);
  const plan = await fetch(`${base}/api/plan`, { headers: { cookie } });
  expect(plan.status).toBe(200);
});
```

**The witness is a sign-out**, the most harmless request the API has: if another site can sign a person
out, it can do whatever else the API allows. The test sends it with the cookie and a foreign `Origin`,
and then checks that the login survived.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs 2>&1 | grep -E "^( FAIL|AssertionError| Test Files|      Tests)"
 FAIL  server/api.test.mjs > a request that changes something, sent from another site, is refused
AssertionError: expected 200 to be 403 // Object.is equality
 Test Files  1 failed (1)
      Tests  1 failed | 5 passed (6)
```

**200**: the API signed ana out on the word of a request from a site it has never heard of. The fix is a
check before any `POST`, and the built site's own origin joins the list, since lesson 8's preview serves
the planner from port 4173:

```
ana@dev:~/planner$ git diff server/api.mjs
diff --git a/server/api.mjs b/server/api.mjs
index 5dc126a..ac162c1 100644
--- a/server/api.mjs
+++ b/server/api.mjs
@@ -39,7 +39,7 @@ function send(res, status, body, headers = {}) {
   res.end(JSON.stringify(body) + "\n");
 }
 
-const allowed = new Set(["http://localhost:5173"]);
+const allowed = new Set(["http://localhost:5173", "http://localhost:4173"]);
 
 function corsHeaders(req) {
   if (!allowed.has(req.headers.origin)) return {};
@@ -61,6 +61,10 @@ export function createApi() {
       });
       return res.end();
     }
+    const origin = req.headers.origin;
+    if (req.method === "POST" && origin !== undefined && !allowed.has(origin)) {
+      return send(res, 403, { error: "cross-site request refused" });
+    }
 
     if (req.method === "POST" && path === "/api/login") {
       const { name, password } = await readJson(req);
```

A request with no `Origin` at all, which is what `curl` and the tests' `signIn()` send, passes, because
browsers always send one on a `POST`, and a request with none did not come from a page. Every request a
browser sends from another site carries it, and is refused.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  6 passed (6)
   Start at  20:42:12
   Duration  487ms (tests 62%, import 30%, transform 7%, worker 1%)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Refuse a POST whose Origin is not the planner's"
```

## Tokens, and when to use them

The classic defence is a **CSRF token**: a random value the server puts in each form and checks on each
submission, which another site cannot read and so cannot send. It is the right tool for an application
built from server-rendered forms, and most frameworks generate it. For an API called with `fetch` and a
`SameSite` cookie, the Origin check above does the same work with no state to keep, and OWASP's
cheat sheet on CSRF describes checking it as a defence to add beside the others.
