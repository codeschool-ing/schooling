---
title: Traces and the HTML report
version: 1
---

A failure in a terminal is a few lines: the assertion, the value it got, a call log. That is often
enough on your own computer, where you can run the test again and watch. **On a build server
nobody watches**, and the run that failed is gone by the time anybody reads the message. A
**trace** is Playwright's answer: a file recorded during the run that holds every action the test
took, what the page looked like before and after each one, every request and response, and the
console. Lesson 16 uses traces to diagnose real failures; this section shows what one is.

## Recording one

`--trace on` records a trace for every test in the run:

```
ana@laptop:~/quitanda$ npx playwright test tests/contexts.spec.js --trace on

Running 4 tests using 1 worker

Ana's page reads ana
Bia's page reads null
  ✓  1 tests/contexts.spec.js:8:1 › two contexts share nothing in the browser (534ms)
cookies: Ana [], Bia []
Ana's total after Bia's mango: R$ 10,40
  ✓  2 tests/contexts.spec.js:31:1 › two shoppers, one basket: the shop's flaw (615ms)
  ✓  3 tests/contexts.spec.js:57:1 › the page fixture: storage written in one test (151ms)
  ✓  4 tests/contexts.spec.js:63:1 › the next test in the same browser starts without it (165ms)

  4 passed (3.0s)
```

Nothing in the output mentions it. The traces are in `test-results/`, one folder per test, each
named after the file and the test:

```
ana@laptop:~/quitanda$ ls test-results
contexts-the-next-test-in-the-same-browser-starts-without-it
contexts-the-page-fixture-storage-written-in-one-test
contexts-two-contexts-share-nothing-in-the-browser
contexts-two-shoppers-one-basket-the-shop-s-flaw
```

## What is inside

A trace is a zip archive, and any tool that lists a zip will show its contents. The one from the
two shoppers:

```
ana@laptop:~/quitanda$ unzip -l test-results/contexts-two-shoppers-*/trace.zip
Archive:  test-results/contexts-two-shoppers-one-basket-the-shop-s-flaw/trace.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
     2524  2026-10-15 21:50   resources/src@6ce6e52f7b3ff0cadddbf49cff84b497dd93146a.txt
    10478  2026-10-15 21:50   test.trace
     1950  2026-10-15 21:50   2-trace.trace
     1153  2026-10-15 21:50   2-trace.network
       14  2026-10-15 21:50   resources/e7e8acd9614309b836bf29744b10316e7e9ae74c.json
      455  2026-10-15 21:50   2-trace.stacks
    12334  2026-10-15 21:50   1-trace.trace
    11743  2026-10-15 21:50   1-trace.network
     2459  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821187.jpeg
     9481  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821419.jpeg
    33113  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821439.jpeg
    33130  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821448.jpeg
    33655  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821565.jpeg
      777  2026-10-15 21:50   resources/1ce73c06221cd554cd0d9b5e41880a93864b7397.html
     1240  2026-10-15 21:50   resources/39dfe74803f515f71990df1b2934669d13b07de7.css
      479  2026-10-15 21:50   resources/1c9a406b53395251437640846f6d28fb68008123.json
       47  2026-10-15 21:50   resources/6e6f9bda0f8670a0c478f30e68530a696865f42f.json
       14  2026-10-15 21:50   resources/a7f393e2fef8da8622e971e616554e89ac8ecb76.json
       71  2026-10-15 21:50   resources/ee0f2e8073ce999113f321888e8e5cdc95ea7ae2.json
      376  2026-10-15 21:50   1-trace.stacks
    21213  2026-10-15 21:50   0-trace.trace
    21134  2026-10-15 21:50   0-trace.network
     2459  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821155.jpeg
     9481  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821230.jpeg
    33113  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821261.jpeg
    33113  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821271.jpeg
    33509  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821362.jpeg
    33190  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821589.jpeg
       22  2026-10-15 21:50   resources/e08a78924b70868ee32e65ed1f50e8617a496356.json
       15  2026-10-15 21:50   resources/ecd48961d64df9c15fe3c56d69856ba51244c7f6.json
      377  2026-10-15 21:50   0-trace.stacks
---------                     -------
   343119                     31 files
```

Thirty-one files on this run, of four kinds:

- **`test.trace`** is the test as the runner saw it: each step, the hooks, and where in the source
  each one was called. The test's own source is in `resources/src@….txt`, so the viewer can show
  the line that ran;
- **a numbered `trace` and `network` file for each context**, with the actions and the requests
  that context made;
- **`.jpeg` screenshots**, named after the page they came from and taken as the test acted, which
  is how the viewer shows the page at each step;
- **`.html`, `.css` and `.json` resources**: the bodies of the responses, so the viewer can
  rebuild the page as it was rather than as the shop serves it today.

There are three numbered contexts in a test that made two. The network files say whose is whose:

```
ana@laptop:~/quitanda$ unzip -p test-results/contexts-two-shoppers-*/trace.zip 0-trace.network | grep -o '"url":"[^"]*"' | sort | uniq -c
      2 "url":"http://localhost:3000/"
      3 "url":"http://localhost:3000/api/basket"
      2 "url":"http://localhost:3000/api/products"
      2 "url":"http://localhost:3000/app.js"
      2 "url":"http://localhost:3000/style.css"
ana@laptop:~/quitanda$ unzip -p test-results/contexts-two-shoppers-*/trace.zip 1-trace.network | grep -o '"url":"[^"]*"' | sort | uniq -c
      1 "url":"http://localhost:3000/"
      2 "url":"http://localhost:3000/api/basket"
      1 "url":"http://localhost:3000/api/products"
      1 "url":"http://localhost:3000/app.js"
      1 "url":"http://localhost:3000/style.css"
ana@laptop:~/quitanda$ unzip -p test-results/contexts-two-shoppers-*/trace.zip 2-trace.network | grep -o '"url":"[^"]*"' | sort | uniq -c
      1 "url":"http://localhost:3000/api/reset"
```

`0-` is Ana: the page twice, because she reloaded, and the basket three times, once on each load
and once for her banana. `2-` holds one request, the reset in `beforeEach`, because the `request`
fixture is a request context of its own, with no page in it. `1-` is Bia: one load and her mango.

**A trace is a record of the run**, and it says what happened without anybody running the test
again. It also holds whatever the pages showed and whatever the requests carried, which on an
application with real accounts means data you would not paste into a public issue.

## Opening it

The trace is meant to be read in Playwright's **trace viewer**:

```sh
npx playwright show-trace test-results/contexts-two-shoppers-one-basket-the-shop-s-flaw/trace.zip
```

It opens a window with a timeline of the test across the top, the list of actions down the side, and
for the action you pick, the page as it was at that moment, with the network and console panels of
lesson 1 beside it. **The viewer was not run for this course**: it needs a screen, and the machine
these lessons were recorded on has none. Playwright's documentation also points to
`trace.playwright.dev`, a page that opens a trace file you drop on it inside your own browser.

Recording every test costs disk space and some time, so teams rarely leave `--trace on` in a
configuration. Playwright's documentation suggests `trace: 'on-first-retry'` under `use`, which
records only when a failed test is retried, and `'retain-on-failure'` keeps the trace only for
tests that failed. Lesson 16 picks between them.

## The HTML report

The `list` reporter this course uses prints one line per test. The **HTML reporter** writes a
whole site instead: every test, its steps, its errors, and a link to its trace when there is one.
Reporters can be combined, so `--reporter=list,html` keeps the lines in the terminal and writes the
site as well:

```
ana@laptop:~/quitanda$ npx playwright test tests/smoke.spec.js --reporter=list,html

Running 1 test using 1 worker

  ✓  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (158ms)

  1 passed (1.5s)

To open last HTML report run:

  npx playwright show-report
```

```
ana@laptop:~/quitanda$ ls playwright-report
index.html
```

`playwright-report/index.html` is the report, and it is a single page that can be published as a
build artefact. `npx playwright show-report`, the command the run suggests, serves that folder and
opens it in a browser window; **it was not run here** either, for the same reason as the viewer.
Its documentation says that on a run with failures the HTML reporter opens the report by itself,
unless its `open` option is set to `'never'` in a configuration.

## Codegen and the inspector

Two more tools come with Playwright, and both need a screen. `npx playwright codegen
localhost:3000` opens the shop in a window and writes test code as you click; lesson 20 is about
recorders like it, and why code written by hand wins. `npx playwright test --debug` runs a test
step by step in the **inspector**, with the browser on screen and a button to advance each action.
Neither was run for this course.
