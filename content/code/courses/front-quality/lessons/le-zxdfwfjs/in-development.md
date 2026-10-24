---
title: Why the dev server gets no policy
version: 1
---

**The headers went on the preview server and not on the dev server, and that was deliberate.** The dev server is a different program serving a different page. It injects the client that reloads the
page on every save, and it puts the CSS into the page with `<style>` elements created by JavaScript, which
is how it can swap styles without a reload. A strict policy refuses both.

As an experiment, give the dev server the same headers:

```
ana@dev:~/planner$ git diff vite.config.ts
diff --git a/vite.config.ts b/vite.config.ts
index 1d4af3d..dae0f3f 100644
--- a/vite.config.ts
+++ b/vite.config.ts
@@ -22,6 +22,7 @@ const securityHeaders = {
 export default defineConfig({
   server: {
     proxy: { "/api": "http://127.0.0.1:3000" },
+    headers: securityHeaders,
   },
   preview: {
     headers: securityHeaders,
```

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ "getComputedStyle(document.body).maxWidth"
console:  Applying inline style violates the following Content Security Policy directive 'style-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-v87a+Ohf0OBFYYXZLz7mQ5d74zDQIpY3VrMCOtCRpTo='), or a nonce ('nonce-...') is required to enable inline execution. The action has been blocked.
result:   none
```

**The inline style was refused**: `style-src 'self'` allows stylesheet files from the origin and no
inline styles, and in development the planner's CSS arrives as exactly that. The page works and draws
without its styles: the body's `max-width`, 36rem in `style.css`, came back as `none`. Relaxing the policy to make development work, with `'unsafe-inline'`, would then be one
careless copy away from production.

So the rule is: **the policy is tested where it is served, on the build**, as `e2e/headers.spec.ts` does,
and the dev server stays free to do what development needs. Vite can also put a nonce on the elements it
creates, with its `html.cspNonce` option, for a server that writes a fresh nonce into every page; the
planner, a static site, does not need one. Undo the experiment:

```
ana@dev:~/planner$ git checkout vite.config.ts
Updated 1 path from the index
```
