---
title: What a script on the page can see
version: 1
---

**The difference between the rows of that table can be tested, in the planner's own browser.** Two
tests: sign in through the page and look for the session cookie from a script, then put a token in
`localStorage` and look for it from a second script, as any library on the page could.

The tests need the API running beside the dev server, so `webServer` in `playwright.config.ts` becomes
a list of two:

```
ana@dev:~/planner$ git diff playwright.config.ts
diff --git a/playwright.config.ts b/playwright.config.ts
index cea6ae4..2894629 100644
--- a/playwright.config.ts
+++ b/playwright.config.ts
@@ -9,9 +9,8 @@ export default defineConfig({
     trace: "retain-on-failure",
   },
   projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
-  webServer: {
-    command: "npm run dev",
-    url: "http://localhost:5173",
-    reuseExistingServer: true,
-  },
+  webServer: [
+    { command: "npm run api", url: "http://127.0.0.1:3000/api/plan", reuseExistingServer: true },
+    { command: "npm run dev", url: "http://localhost:5173", reuseExistingServer: true },
+  ],
 });
```

Playwright waits for each address to answer before the first test. `/api/plan` answers 401 with no
cookie, and a 401 counts as an answer: it means the server is up and asking for a sign-in. Save the first as
`e2e/storage.spec.ts`:

```typescript
// e2e/storage.spec.ts
import { expect, test } from "@playwright/test";

test("the session cookie is out of reach of the page's scripts", async ({ page, context }) => {
  await page.goto("/");
  const status = await page.evaluate(async () => {
    const response = await fetch("/api/login", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ name: "ana", password: "correct horse battery staple" }),
    });
    return response.status;
  });
  expect(status).toBe(200);
  const cookies = await context.cookies();
  expect(cookies).toHaveLength(1);
  expect(cookies[0].httpOnly).toBe(true);
  expect(await page.evaluate(() => document.cookie)).toBe("");
});
```

And the second, which is about the browser rather than the planner, in a file of its own so it can go
once it has made its point. Save this as `e2e/local-storage.spec.ts`:

```typescript
// e2e/local-storage.spec.ts
import { expect, test } from "@playwright/test";

test("a token in localStorage is in reach of every script", async ({ page }) => {
  await page.goto("/");
  await page.evaluate(() => localStorage.setItem("token", "eyJhbGciOiJIUzI1NiJ9.e30.x"));
  await page.addScriptTag({ content: "document.title = localStorage.getItem('token')" });
  await expect(page).toHaveTitle("eyJhbGciOiJIUzI1NiJ9.e30.x");
});
```

The first test signs in the way the page would, with `fetch`, and then asks two questions. The browser
has the cookie, as `context.cookies()` shows from outside the page, marked `httpOnly`. And
`document.cookie`, which is what a script on the page sees, is empty.

The second test is the other row. `addScriptTag` adds a second script to the page, standing for any
other code that runs there, and all it does is copy what it finds in `localStorage` into the page's
title, where the test can read it. **A benign witness is enough**: if one script can put the token in
the title, another can put it in a request to anywhere.

```
ana@dev:~/planner$ npx playwright test e2e/storage.spec.ts e2e/local-storage.spec.ts --reporter=list

Running 2 tests using 2 workers

  ✓  1 [chromium] › e2e/storage.spec.ts:4:1 › the session cookie is out of reach of the page's scripts (395ms)
  ✓  2 [chromium] › e2e/local-storage.spec.ts:4:1 › a token in localStorage is in reach of every script (420ms)

  2 passed (2.0s)
```

Both pass, and both say what they promise. **The first is a test of the planner and it stays**: if a
change ever made the session cookie readable, it fails. The second tests the browser, which is not
yours to test, as lesson 1 put it, and the planner keeps nothing in `localStorage`; it has shown the
row of the table working, and it goes:

```
ana@dev:~/planner$ rm e2e/local-storage.spec.ts
```
