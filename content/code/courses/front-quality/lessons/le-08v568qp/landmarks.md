---
title: Landmarks, and the rules axe kept apart
version: 1
---

**A landmark is a region of the page with a role a screen reader can jump to.** HTML gives each one an
element:

| element | landmark | there is |
|---|---|---|
| `<header>`, at the top level | banner | the site's heading area |
| `<nav>` | navigation | a set of links for moving around |
| `<main>` | main | the page's own content, **one per page** |
| `<aside>` | complementary | something beside the content |
| `<footer>`, at the top level | contentinfo | the site's foot |
| `<form>` with a name, `<section>` with a name | form, region | a named part |

Lesson 10 left two findings for this lesson. axe's `best-practice` rules are kept out of the WCAG test,
and two of them fail on the planner. To read them, let `server/axe.mjs` take its tags from the
environment:

```
ana@dev:~/planner$ git diff server/axe.mjs
diff --git a/server/axe.mjs b/server/axe.mjs
index 01bd488..647e39b 100644
--- a/server/axe.mjs
+++ b/server/axe.mjs
@@ -9,7 +9,7 @@ await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
 for (const address of process.argv.slice(2)) {
   await page.goto(address);
   await page.getByRole("heading", { level: 1 }).waitFor();
-  const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
+  const { violations } = await new AxeBuilder({ page }).withTags(process.env.AXE_TAGS?.split(",") ?? wcag22aa).analyze();
   console.log(`${address}: ${violations.length} rule(s) broken`);
   for (const v of violations) {
     console.log(`  ${v.id} (${v.impact}): ${v.help}`);
```

```
ana@dev:~/planner$ AXE_TAGS=best-practice node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/: 2 rule(s) broken
  landmark-one-main (moderate): Document should have one main landmark
    html  
  region (moderate): All page content should be contained by landmarks
    #app  Some page content is not contained by landmarks
http://localhost:5173/#/course/javascript: 2 rule(s) broken
  landmark-one-main (moderate): Document should have one main landmark
    html  
  region (moderate): All page content should be contained by landmarks
    a  Some page content is not contained by landmarks
    h1  Some page content is not contained by landmarks
    ul  Some page content is not contained by landmarks
    label:nth-child(1)  Some page content is not contained by landmarks
    label:nth-child(2)  Some page content is not contained by landmarks
    label:nth-child(3)  Some page content is not contained by landmarks
    p  Some page content is not contained by landmarks
```

**`landmark-one-main`** asks for one `main`; **`region`** asks that everything on the page sits inside some
landmark, so that nothing can be missed by somebody who moves from landmark to landmark. A test that
holds the first, added to `e2e/screen-reader.spec.ts`:

```typescript
// e2e/screen-reader.spec.ts, below what is there
test("every page has one main landmark", async ({ page }) => {
  for (const address of ["/", "/#/course/javascript"]) {
    await page.goto(address);
    await expect(page.getByRole("main")).toHaveCount(1);
  }
});
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts -g 'main landmark' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/screen-reader.spec.ts:13:1 › every page has one main landmark (5.2s)
    Error: expect(locator).toHaveCount(expected) failed
    Locator:  getByRole('main')
    Expected: 1
    Received: 0
  1 failed
```

The planner's content is drawn into `<div id="app">` in `index.html`, so the fix is in the page, not in the
code: the `div` goes inside a `main`.

```
ana@dev:~/planner$ git diff index.html
diff --git a/index.html b/index.html
index 1c36a07..05c7eac 100644
--- a/index.html
+++ b/index.html
@@ -7,7 +7,9 @@
     <title>Study planner</title>
   </head>
   <body>
-    <div id="app"></div>
+    <main>
+      <div id="app"></div>
+    </main>
     <script type="module" src="/src/main.ts"></script>
   </body>
 </html>
```

```
ana@dev:~/planner$ AXE_TAGS=best-practice node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/: 0 rule(s) broken
http://localhost:5173/#/course/javascript: 0 rule(s) broken
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (254ms)
  ✓  2 [chromium] › e2e/screen-reader.spec.ts:13:1 › every page has one main landmark (194ms)
  2 passed (3.6s)
```

**A one-screen app needs one landmark and no more.** The planner has no navigation bar and no footer, and
inventing them to have landmarks would be adding things to jump to that hold nothing.
