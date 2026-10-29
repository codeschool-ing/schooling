---
title: Report-only first, then enforce
version: 1
---

**A policy added to a live site breaks whatever the site did that nobody remembered**: an analytics tag,
an inline handler in a template nobody has opened in a year. So a policy goes out in two steps. The
same header with `-Report-Only` on its name makes the browser report every violation and block none.

As an experiment, change the header's name in `vite.config.ts`:

```
ana@dev:~/planner$ git diff vite.config.ts
diff --git a/vite.config.ts b/vite.config.ts
index 1d4af3d..581d486 100644
--- a/vite.config.ts
+++ b/vite.config.ts
@@ -2,7 +2,7 @@
 import { configDefaults, defineConfig } from "vitest/config";
 
 const securityHeaders = {
-  "Content-Security-Policy": [
+  "Content-Security-Policy-Report-Only": [
     "default-src 'self'",
     "script-src 'self'",
     "style-src 'self'",
```

```
ana@dev:~/planner$ node server/look.mjs http://localhost:4173/ "$(cat server/witness.js)"
console:  Executing inline script violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-pEY6BBBxZAVxAefxgixuyIDc9Sf/P5B1/XuTyDX/02k='), or a nonce ('nonce-...') is required to enable inline execution. The policy is report-only, so the violation has been logged but no further action has been taken.
result:   an inline script ran
```

**The script ran, and the console reported it**, with the same sentence an enforced policy gives
and a different ending: the policy is report-only, so the violation was logged and nothing else done. That is the whole point of the mode: the site keeps working while the report
says what enforcing would break.

The browser can also send those reports to the server, so they arrive from every visitor rather than
from whoever opened the console: the `report-to` directive names an endpoint, and the server collects
what arrives. A week of reports with nothing unexpected in them is the evidence for removing
`-Report-Only`. The planner's policy has been tested in a real browser from its first line, so it goes
straight to enforcement, and the experiment goes back:

```
ana@dev:~/planner$ git checkout vite.config.ts
Updated 1 path from the index
```
