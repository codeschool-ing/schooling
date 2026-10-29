---
title: Playwright, and the planner in a real browser
version: 1
---

**An end-to-end test starts the real application and uses it through a real browser**, the way `look`
has done all
through the course, except that it checks what it finds instead of printing it. Playwright, which `look` is
built on, has a test runner of its own. Install it, at the version `look` uses, so that it finds the
browser lesson 1 installed and needs nothing downloaded:

```
ana@dev:~/planner$ npm install --save-dev @playwright/test@1.63.0

added 3 packages, removed 1 package, and audited 77 packages in 1s

17 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## A copy of the data for the tests

The tests will add sessions, and they must not add them to the planner you actually use. The server
module gets one change: the data file's name can come from an environment variable, which the tests'
server sets and nothing else does. Replace `src/lib/server/planner.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/server/planner.ts", "parts": [
 {"code": "// planner.ts: the planner's data, read from and written to the file the server keeps it in.\nimport { readFile, writeFile, rename } from 'node:fs/promises';\nimport type { PlannerData, Session } from '#lib/types.js';\n"},
 {"code": "// The data file: PLANNER_FILE when it is set, as the end-to-end tests set it.\nconst FILE = process.env.PLANNER_FILE ?? 'data/planner.json';\nexport async function readPlanner(): Promise<PlannerData> {\n\treturn JSON.parse(await readFile(FILE, 'utf8'));\n}\n\n// Changes run one at a time: each waits for the one before it to finish, so two\n// requests arriving together cannot both read the old file and lose a change.\nlet queue: Promise<unknown> = Promise.resolve();\n\nfunction change<T>(edit: (planner: PlannerData) => T): Promise<T> {\n\tconst result = queue.then(async () => {\n\t\tconst planner = await readPlanner();\n\t\tconst answer = edit(planner);\n\t\t// Write a new file and then put it in the old one's place, so that a crash\n\t\t// halfway through leaves the old file whole rather than half of a new one.\n\t\tawait writeFile(`${FILE}.new`, JSON.stringify(planner, null, '\\t') + '\\n');\n\t\tawait rename(`${FILE}.new`, FILE);\n\t\treturn answer;\n\t});\n\tqueue = result.catch(() => {});\n\treturn result;\n}\n\n/** Add a session; false if there is no such course. */\nexport function addSession({ course, date, minutes }: Omit<Session, 'id' | 'done'>) {\n\treturn change((planner) => {\n\t\tif (!planner.courses.some((c) => c.id === course)) return false;\n\t\tconst id = Math.max(0, ...planner.sessions.map((s) => s.id)) + 1;\n\t\tplanner.sessions.push({ id, course, date, minutes, done: false });\n\t\treturn true;\n\t});\n}\n\n/** Mark a session done or not done; the session, or undefined if there is none. */\nexport function setDone(id: number, done: boolean) {\n\treturn change((planner) => {\n\t\tconst session = planner.sessions.find((s) => s.id === id);\n\t\tif (session) session.done = done;\n\t\treturn session;\n\t});\n}", "note": "`process.env` holds the environment variables Node was started with. Unset, the planner uses its own file, as before."}
]}
```

Playwright writes its results into two folders, which do not belong in Git:

```
ana@dev:~/planner$ printf '/test-results\n/playwright-report\n' >> .gitignore
```

## The configuration

Save this as `playwright.config.ts`, at the top of the project:

```schooling-example
{"language": "typescript", "file": "playwright.config.ts", "parts": [
 {"code": "// playwright.config.ts: build the planner, start it on a copy of the data, and test it in Chromium.\nimport { defineConfig } from '@playwright/test';\n\nexport default defineConfig({\n\ttestDir: 'e2e',"},
 {"code": "\twebServer: {\n\t\tcommand: 'npm run build && cp data/planner.json build/planner-e2e.json && node build',\n\t\tport: 4173,", "note": "`webServer` is how Playwright starts the planner before the tests and stops it after. The command builds it, copies the data into `build`, which Git ignores, and starts the built server on that copy."},
 {"code": "\t\treuseExistingServer: false,", "note": "A server already running, from an earlier run, would still hold the sessions those tests added. Starting a fresh one every time means every run starts from the same data."},
 {"code": "\t\tenv: {\n\t\t\tPORT: '4173',\n\t\t\tORIGIN: 'http://localhost:4173',\n\t\t\tPLANNER_FILE: 'build/planner-e2e.json'\n\t\t}\n\t},\n\tuse: {\n\t\tbaseURL: 'http://localhost:4173'\n\t}\n});", "note": "The variables the build and the server read: the port, the origin lesson 15's CSRF check compares with, and the data file."}
]}
```

## The tests

Save this as `e2e/planner.test.ts`:

```schooling-example
{"language": "typescript", "file": "e2e/planner.test.ts", "parts": [
 {"code": "// planner.test.ts: the planner in a real browser, as a person uses it.\nimport { expect, test } from '@playwright/test';\n"},
 {"code": "test('the week page shows the week of the newest session', async ({ page }) => {\n\tawait page.goto('/');\n\tawait expect(page.getByText('Week of 19 Oct 2026')).toBeVisible();\n\tawait expect(page.getByText('225 minutes this week (3 h 45 min)')).toBeVisible();\n});\n", "note": "`page` is a browser tab, opened for this test and closed after it. `getByText`, `getByRole` and `getByLabel` find elements the way `look` names them: by what a person, or a screen reader, sees."},
 {"code": "test('a session added on a course page is on the page and in the week', async ({ page }) => {\n\tawait page.goto('/courses/guitar?week=2026-10-19');\n\tawait page.getByLabel('Date').fill('2026-10-21');\n\tawait page.getByRole('button', { name: 'Add session' }).click();\n\tawait expect(page.getByText('21 Oct 2026, 30 min')).toBeVisible();\n\n\tawait page.getByRole('link', { name: 'Study planner' }).click();\n\tawait expect(page.getByText('255 minutes this week')).toBeVisible();\n});\n", "note": "`expect(...).toBeVisible()` waits, up to five seconds, for the element to appear. That is what makes a test like this reliable: it waits for the answer instead of guessing how long the server takes."},
 {"code": "test('a wrong number of minutes is refused with a message', async ({ page }) => {\n\tawait page.goto('/courses/guitar?week=2026-10-19');\n\tawait page.getByLabel('Date').fill('2026-10-22');\n\tawait page.getByLabel('Minutes').fill('3');\n\t// The browser would refuse three minutes itself. Switch its checks off for this form,\n\t// so that the server's are the ones being tested.\n\tawait page.getByRole('button', { name: 'Add session' }).evaluate((button) => {\n\t\t(button as HTMLButtonElement).form!.noValidate = true;\n\t});\n\tawait page.getByRole('button', { name: 'Add session' }).click();\n\tawait expect(page.getByRole('alert')).toHaveText('Minutes must be a whole number from 5 to 600.');\n});\n", "note": "The browser would refuse three minutes before sending the form. This test is about the server's check, so it switches the browser's off for this one form."},
 {"code": "test.describe('with JavaScript off', () => {\n\ttest.use({ javaScriptEnabled: false });\n\n\ttest('a session can still be added', async ({ page }) => {\n\t\tawait page.goto('/courses/spanish?week=2026-10-19');\n\t\tawait page.getByLabel('Date').fill('2026-10-23');\n\t\tawait page.getByRole('button', { name: 'Add session' }).click();\n\t\tawait expect(page).toHaveURL(/\\/courses\\/spanish\\?week=2026-10-19$/);\n\t\tawait expect(page.getByText('23 Oct 2026, 30 min')).toBeVisible();\n\t});\n\n\ttest('the week moves with a link', async ({ page }) => {\n\t\tawait page.goto('/');\n\t\tawait page.getByRole('link', { name: 'Previous week' }).click();\n\t\tawait expect(page.getByText('Week of 12 Oct 2026')).toBeVisible();\n\t});\n});", "note": "`test.use` changes the browser for the tests in this group: JavaScript off, for lesson 14's promise."}
]}
```

and a script for it:

```
ana@dev:~/planner$ npm pkg set scripts.test:e2e='playwright test'
```

```
ana@dev:~/planner$ npm run test:e2e

> planner@0.0.1 test:e2e
> playwright test


Running 5 tests using 1 worker

  ✓  1 e2e/planner.test.ts:4:1 › the week page shows the week of the newest session (293ms)
  ✓  2 e2e/planner.test.ts:10:1 › a session added on a course page is on the page and in the week (430ms)
  ✓  3 e2e/planner.test.ts:20:1 › a wrong number of minutes is refused with a message (301ms)
  ✓  4 e2e/planner.test.ts:36:2 › with JavaScript off › a session can still be added (259ms)
  ✓  5 e2e/planner.test.ts:44:2 › with JavaScript off › the week moves with a link (194ms)

  5 passed (7.4s)
```

**Five tests, in a real browser, against the built planner**, in a few seconds. The two at the end are
the ones no other kind of test can write: they open the planner with JavaScript switched off, add a
session and move the week, and pass only if the forms and links of lesson 14 still work on their own.
A change that quietly made the planner depend on JavaScript again, a button that only works with a
click handler, a form sent with `fetch` and no `action`, would fail them on the next run, long before
anybody with a slow connection noticed.
