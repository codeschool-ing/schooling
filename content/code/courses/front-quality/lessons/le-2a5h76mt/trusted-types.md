---
title: Trusted Types, the browser enforcing the list
version: 1
---

**The table in the last section is a habit, and habits slip; Trusted Types is a line of Content Security
Policy that makes the browser refuse a plain string at every one of those sinks.** With
`require-trusted-types-for 'script'` in the policy, `innerHTML = "…"` throws instead of parsing. The only
way to write markup is through a policy object the site creates on purpose, so every place markup is
built is one place in the code, named and reviewable.

It is supported in Chromium-based browsers, and the others ignore the directive rather than break, so it
is a defence that can be added today. Try it on the built planner, as an experiment: add the directive
to the policy in `vite.config.ts`, rebuild, and open a course page.

```
ana@dev:~/planner$ git diff vite.config.ts
diff --git a/vite.config.ts b/vite.config.ts
index 1d4af3d..0d9b638 100644
--- a/vite.config.ts
+++ b/vite.config.ts
@@ -12,6 +12,7 @@ const securityHeaders = {
     "base-uri 'self'",
     "form-action 'self'",
     "frame-ancestors 'none'",
+    "require-trusted-types-for 'script'",
   ].join("; "),
   "X-Content-Type-Options": "nosniff",
   "Referrer-Policy": "strict-origin-when-cross-origin",
ana@dev:~/planner$ npm run build > /dev/null
```

```
ana@dev:~/planner$ node server/look.mjs 'http://localhost:4173/#/course/javascript' 'document.querySelectorAll("form").length'
console:  This document requires 'TrustedHTML' assignment. The action has been blocked.
result:   0
```

**The course page failed to draw, and the console says why.** The note is gone from that file, so the
string the browser refused is the **form**: `view.ts` writes its three fields with `innerHTML`, from a
fixed template, as lesson 1 wrote it. That markup is the site's own and harmless, and Trusted Types
refuses it anyway, because the browser cannot tell a fixed template from a person's text. That is the
point of it: **it moves the question from "is this one safe?" to "why is this a string at all?"**

The planner does not enforce it in this course; take the experiment out again:

```
ana@dev:~/planner$ git checkout vite.config.ts
Updated 1 path from the index
```

To adopt it, the form would be built with `el()` like everything else in `view.ts`, a change of a few
lines, and the policy would then refuse any `innerHTML` anybody adds later. A large application turns it
on the way lesson 8 did with its policy: report-only first, with `Content-Security-Policy-Report-Only`,
until the reports name no sink nobody meant.
