---
title: The test first
version: 1
---

**A header is a promise about the site, and the only way to keep one is a test that fails when it
goes.** Playwright can test the built site directly: start the preview as a third web server, then
make requests and open pages against it. Add the preview to `webServer` in `playwright.config.ts`:

```
ana@dev:~/planner$ git diff playwright.config.ts
diff --git a/playwright.config.ts b/playwright.config.ts
index 2894629..8c17527 100644
--- a/playwright.config.ts
+++ b/playwright.config.ts
@@ -12,5 +12,10 @@ export default defineConfig({
   webServer: [
     { command: "npm run api", url: "http://127.0.0.1:3000/api/plan", reuseExistingServer: true },
     { command: "npm run dev", url: "http://localhost:5173", reuseExistingServer: true },
+    {
+      command: "npm run build && npx vite preview --port 4173 --strictPort",
+      url: "http://localhost:4173",
+      reuseExistingServer: true,
+    },
   ],
 });
```

`--strictPort` makes the preview fail rather than drift to another port, the trap of lesson 1. Then
two tests, one reading the headers and one opening the page under them. Save this as
`e2e/headers.spec.ts`:

```typescript
// e2e/headers.spec.ts
import { expect, test } from "@playwright/test";

const built = "http://localhost:4173/";

test("the built site is served with its security headers", async ({ request }) => {
  const headers = (await request.get(built)).headers();
  expect(headers["content-security-policy"]).toContain("script-src 'self'");
  expect(headers["content-security-policy"]).toContain("frame-ancestors 'none'");
  expect(headers["x-content-type-options"]).toBe("nosniff");
  expect(headers["referrer-policy"]).toBe("strict-origin-when-cross-origin");
  expect(headers["permissions-policy"]).toContain("camera=()");
  expect(headers["cross-origin-opener-policy"]).toBe("same-origin");
});

test("the built site works under its own policy", async ({ page }) => {
  const errors: string[] = [];
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
  await page.goto(built);
  await expect(page.getByText("This week: 160 min")).toBeVisible();
  expect(errors).toEqual([]);
});
```

**The second test is the one that keeps a policy honest.** A Content Security Policy that breaks the
page is one somebody will switch off on the day it breaks; a test that opens the page under the policy
and demands no console errors catches the breakage before anybody is tempted.

```
ana@dev:~/planner$ npx playwright test e2e/headers.spec.ts --reporter=list 2>&1 | grep -E "^  (✓|✘)|Error:|Received|passed|failed"
  ✘  1 [chromium] › e2e/headers.spec.ts:6:1 › the built site is served with its security headers (54ms)
  ✓  2 [chromium] › e2e/headers.spec.ts:16:1 › the built site works under its own policy (214ms)
    Error: expect(received).toContain(expected) // indexOf
    Received has value: undefined
  1 failed
  1 passed (4.8s)
```

The first test fails on its first line, because there is no `content-security-policy` at all, and the
second passes, because a page with no policy has nothing to violate. Both are about to change.
