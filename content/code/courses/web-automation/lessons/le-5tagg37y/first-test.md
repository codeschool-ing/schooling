---
title: A first test with selenium-webdriver
version: 1
---

The Selenium test in this section does what lesson 1's smoke test did and one step more: it opens
the shop, waits for the eight cards, adds a banana and reads the basket's count. **Selenium brings
no test runner**, which surprises people who met Playwright first. `selenium-webdriver` is a
library for driving a browser, and the runner is your choice: Mocha, Jest, or, as here, the one
built into Node since version 18, `node:test`, which needs nothing installed.

The Selenium tests live in their own folder, `selenium/`, so that `npx playwright test`, which
reads `tests/`, never tries to run them. Make the folder (`mkdir ~/quitanda/selenium`) and save
this as `selenium/shop.test.js`:

```schooling-example
{"language": "javascript", "file": "selenium/shop.test.js", "parts": [{"code": "import { test, before, after } from 'node:test';\nimport assert from 'node:assert/strict';\nimport { Builder, By, until } from 'selenium-webdriver';\nimport chrome from 'selenium-webdriver/chrome.js';", "note": "Node's own test runner and its assertions, so nothing else needs installing. `Builder` makes a driver, `By` says how to find an element, and `until` holds the conditions an explicit wait can wait for."}, {"code": "\nconst shop = 'http://localhost:3000';\nlet driver;", "note": "Nothing starts the shop for you: there is no `webServer` here. Run `npm start` in another terminal first."}, {"code": "\nbefore(async () => {\n  const options = new chrome.Options().addArguments('--headless=new');\n  driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();\n});", "note": "`build()` is where Selenium Manager finds a driver, the driver starts, and a `POST /session` opens Chrome. Selenium opens a window by default; `--headless=new` is Chrome's own switch for running without one. Delete that argument to watch the test."}, {"code": "\nafter(async () => {\n  await driver?.quit();\n});", "note": "`quit()` sends the `DELETE` that ends the session and closes the browser. Without it, every run leaves a Chrome and a driver behind. The `?.` keeps a failed `build()` from adding a second, misleading error."}, {"code": "\ntest('adding a banana puts one item in the basket', async () => {\n  await fetch(`${shop}/api/reset`, { method: 'POST' });\n  await driver.get(`${shop}/`);", "note": "The basket is shared by everybody, so the test empties it first. `get()` returns when the page has loaded, which says nothing about the products, which a script fetches afterwards."}, {"code": "  const cards = await driver.wait(until.elementsLocated(By.css('#products li')), 5000);\n  assert.equal(cards.length, 8);", "note": "An explicit wait: ask again until at least one card exists, for up to five seconds, then hand back what was found."}, {"code": "\n  await driver.findElement(By.css('[data-testid=product-banana] button')).click();\n  const count = await driver.findElement(By.css('[data-testid=basket-count]'));\n  await driver.wait(until.elementTextIs(count, '1'), 5000);\n  assert.equal(await count.getText(), '1');\n});", "note": "`click()` returns once the browser has dispatched the click, not once the shop has answered, so the count is waited for rather than read at once. If it never says 1, the wait throws a `TimeoutError` and the test fails there."}]}
```

## Running it

The shop has to be running first, so start it in one terminal with `npm start` and leave it. In
another, in `~/quitanda`:

```
ana@laptop:~/quitanda$ node --test --test-reporter=spec selenium/shop.test.js
✔ adding a banana puts one item in the basket (633.08805ms)
ℹ tests 1
ℹ suites 0
ℹ pass 1
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 865.904299
```

**One test, one pass.** `--test-reporter=spec` asks for the readable report; it is what Node
prints at a terminal anyway, and it is written out here because a terminal that is not interactive,
a build server's for instance, gets the terse TAP format otherwise. The 633 ms beside the test is
the test alone; starting Chrome happened in `before`, and the `duration_ms` at the foot is the
whole run.

Change the expected count from `'1'` to `'2'` in the wait and run it again to see a failure, then
put it back:

```
ana@laptop:~/quitanda$ node --test --test-reporter=spec selenium/shop.test.js
✖ adding a banana puts one item in the basket (5633.567052ms)
ℹ tests 1
ℹ suites 0
ℹ pass 0
ℹ fail 1
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 5866.427682

✖ failing tests:

test at selenium/shop.test.js:18:1
✖ adding a banana puts one item in the basket (5633.567052ms)
  Error [TimeoutError]: Waiting until element text is
  Wait timed out after 5066ms
      at /home/ana/quitanda/node_modules/selenium-webdriver/lib/webdriver.js:939:22
      at process.processTicksAndRejections (node:internal/process/task_queues:105:5) {
    remoteStacktrace: ''
  }
```

The wait gave up after five seconds, and its message names the kind of condition, *element text
is*, without the text it wanted or the text it found. **`driver.wait` takes a message as its third
argument**, and a wait whose failure you will read at midnight is worth one:
`driver.wait(until.elementTextIs(count, '1'), 5000, 'basket count never became 1')`.

## The same test, said in Playwright

Put this beside `tests/smoke.spec.js` from lesson 1 and the difference is mostly in what **you**
have to say that Playwright said for you:

| | Playwright | Selenium with `node:test` |
|---|---|---|
| starting the shop | `webServer` in the config does it | you run `npm start` first |
| the browser | the `page` fixture opens one per test and closes it | `build()` and `quit()`, written by you |
| a window | headless unless you ask for `--headed` | a window unless you pass `--headless=new` |
| waiting | `expect(...).toHaveCount(8)` retries until it is true | `driver.wait(until...)`, written where it is needed |
| an address | `page.goto('/')`, against `baseURL` | the whole address, every time |
| browsers | the builds Playwright downloads for its version | the browsers already installed, through their drivers |

**The waiting row is the one that costs.** Playwright's assertions keep asking until they pass or
time out; a Selenium `findElement` asks once, and if you forget the wait the test passes on a fast
machine and fails on a slow one. Lesson 10 shows how Playwright does this, and lesson 13 is about
waits in both. The last row is Selenium's strength rather than a cost: it drives the Chrome,
Firefox, Edge or Safari a user actually has, through a standard each browser's maker implements.
