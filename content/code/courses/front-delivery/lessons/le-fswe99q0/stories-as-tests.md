---
title: Stories as tests: a picture and an audit of each
version: 1
---

**Every story is a state somebody decided was worth seeing, which makes every story a test case
already written.** This section turns them into tests: for each story, in each theme, open its frame,
compare a screenshot with the one approved last time, and run axe on it. A component that changed by
accident fails the first; one that became unreadable fails the second.

## Playwright

**Playwright** drives a real browser from a script; front-quality lesson 4 uses it for end-to-end tests.
Install the test runner and the axe integration, pinned:

```
ana@dev:~/planner$ npm install --save-dev --save-exact @playwright/test@1.63.0 @axe-core/playwright@4.14.0 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/planner$ npm pkg set scripts.test="vitest run src"
ana@dev:~/planner$ npx playwright --version
Version 1.63.0
```

The second command matters as much as the first. Vitest looks for any file ending in `.spec.ts` or
`.test.ts`, so it would try to run the Playwright test as one of its own and fail; pointing the unit tests
at `src` keeps the two runners apart.

**Playwright 1.63.0** drives a particular build of Chromium, which it downloads separately from the
package, once per computer:

```sh
npx playwright install chromium
```

That command was not run in this recording, whose computer already had that build of Chromium;
on yours it downloads about 150 MB into a folder in your home directory. On Linux, if Chromium then fails
to start for want of system libraries, `npx playwright install --with-deps chromium` installs them, and
asks for `sudo` to do it.

## The configuration and the test

The configuration starts the built Storybook with the planner's own host before the tests, and stops it
after:

```typescript
// playwright.config.ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "tests",
  use: { baseURL: "http://127.0.0.1:6007" },
  webServer: {
    command: "node host.mjs storybook-static 6007",
    url: "http://127.0.0.1:6007/iframe.html",
    reuseExistingServer: false,
  },
  projects: [{ name: "chromium", use: { browserName: "chromium", viewport: { width: 480, height: 200 } } }],
});
```

The test visits each story in each theme:

```schooling-example
{"language": "typescript", "file": "tests/stories.spec.ts", "parts": [
 {"code": "// tests/stories.spec.ts\nimport AxeBuilder from \"@axe-core/playwright\";\nimport { expect, test } from \"@playwright/test\";", "note": "Playwright's test runner, and the axe engine wrapped for it, the same one `tools/a11y-test` in this course's own repository uses."},
 {"code": "\nconst stories = [\n  \"planner-session-row--to-do\",\n  \"planner-session-row--done\",\n  \"planner-session-row--long\",\n  \"planner-week-summary--in-progress\",\n  \"planner-week-summary--empty\",\n];", "note": "The stories by id, as `index.json` listed them. A list written out rather than read from the index, so that a new story becomes a test on purpose rather than by accident."},
 {"code": "\nfor (const id of stories) {\n  for (const theme of [\"light\", \"dark\"]) {\n    test(`${id} in ${theme}`, async ({ page }) => {\n      await page.goto(`/iframe.html?id=${id}&viewMode=story&globals=theme:${theme}`);\n      const story = page.locator(\"#storybook-root\");", "note": "One test per story per theme: ten in all. The frame's address carries the theme, as the section on themes showed, and `#storybook-root` is the element Storybook draws the story into."},
 {"code": "      await expect(story).toHaveScreenshot(`${id}-${theme}.png`);", "note": "Photograph the story and compare it with the saved picture of that name. The first run has nothing to compare with, so it saves one and fails, saying so."},
 {"code": "      const results = await new AxeBuilder({ page }).include(\"#storybook-root\").analyze();\n      expect(results.violations.map((v) => v.id)).toEqual([]);\n    });\n  }\n}", "note": "Run axe on the story alone, and expect no violations. Listing the rule ids makes a failure name what broke."}
]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Five stories down the side and two themes across the top make ten tests. Each test opens the story&#x27;s frame, compares a screenshot with the approved picture, and runs axe on it.\"><text x=\"270\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">light</text><text x=\"400\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dark</text><text x=\"20\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session-row--to-do</text><rect x=\"215\" y=\"40\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"295\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"40\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"425\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><text x=\"20\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session-row--done</text><rect x=\"215\" y=\"74\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"295\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"74\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"425\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><text x=\"20\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session-row--long</text><rect x=\"215\" y=\"108\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"295\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"108\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"425\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><text x=\"20\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">week-summary--in-progress</text><rect x=\"215\" y=\"142\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"295\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"142\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"425\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><text x=\"20\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">week-summary--empty</text><rect x=\"215\" y=\"176\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"295\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"176\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">picture</text><text x=\"425\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"500\" y=\"50\" width=\"200\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">each test</text><text x=\"515\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. open the frame</text><text x=\"515\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. compare the picture</text><text x=\"515\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. run axe, expect none</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5 stories × 2 themes = 10 tests</text></svg>", "caption": "Every story in every theme is a test that already knows what it should look like."}
```

Build the workshop and run the tests twice:

```
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test > first-run.txt 2>&1
ana@dev:~/planner$ grep -m1 "doesn't exist" first-run.txt
    Error: A snapshot doesn't exist at /home/ana/planner/tests/stories.spec.ts-snapshots/planner-session-row--to-do-light-chromium-linux.png, writing actual.
ana@dev:~/planner$ grep -E '^  [0-9]+ (failed|passed)' first-run.txt
  10 failed
ana@dev:~/planner$ ls tests/stories.spec.ts-snapshots | head -4
planner-session-row--done-dark-chromium-linux.png
planner-session-row--done-light-chromium-linux.png
planner-session-row--long-dark-chromium-linux.png
planner-session-row--long-light-chromium-linux.png
ana@dev:~/planner$ npx playwright test 2>&1 | tail -1
  10 passed (15.1s)
ana@dev:~/planner$ rm first-run.txt
```

**The first run fails on purpose**: there were no approved pictures, so Playwright wrote each one and
reported a failure, rather than passing a comparison with nothing. Look at the pictures it saved, in
`tests/stories.spec.ts-snapshots/`, and if they are right, they are now the approved state. The second run
compares against them and passes. The pictures are committed with the tests.

## A change nobody asked for

Change the buttons' corner radius, as a refactor of the stylesheet might by accident, rebuild and test:

```
ana@dev:~/planner$ sed -i 's/border-radius: var(--space-1);/border-radius: var(--space-4);/' src/style.css
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test -g 'to-do in light' 2>&1 | grep -E 'pixels \(ratio|1 failed' | head -2
      144 pixels (ratio 0.02 of all image pixels) are different.
      - 144 pixels (ratio 0.02 of all image pixels) are different.
ana@dev:~/planner$ ls test-results/*/
error-context.md
planner-session-row--to-do-light-actual.png
planner-session-row--to-do-light-diff.png
planner-session-row--to-do-light-expected.png
```

**144 pixels differ, two per cent of the picture.** Playwright also wrote three pictures into
`test-results/`: the approved one, the new one, and a diff with the changed pixels in red, which is what a
reviewer looks at. If the change was intended, `npx playwright test --update-snapshots` makes the new
pictures the approved ones, and that update goes into the pull request where somebody sees it. This one
was not intended:

```
ana@dev:~/planner$ git checkout src/style.css
Updated 1 path from the index
```
