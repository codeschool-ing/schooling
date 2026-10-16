---
title: Keeping evidence on a build server
version: 1
---

On your own computer evidence is a convenience. On a build server it is **the only thing left**:
the machine that ran the tests is usually thrown away when the job ends, and with it every file the
run wrote. Whatever you want to read about a failure has to be copied off the machine before then.
`testing-cicd` lesson 5 is about the pipeline itself; this section is about what the test run
should leave for it to keep.

## When to record, and when to keep

The three settings share a family of values, and they differ in **when they record** and **what
they keep**. These four are in Playwright's documentation for both `video` and `trace`:

| value | records | keeps |
|---|---|---|
| `'off'` | nothing | nothing |
| `'on'` | every test | everything |
| `'retain-on-failure'` | every test | only the tests that failed |
| `'on-first-retry'` | only the first retry of a failed test | that retry |

`screenshot` has `'only-on-failure'` instead of the last two, since a picture is taken once, at
the end. **`retain-on-failure` pays the cost of recording on every test** and keeps only what is
needed. **`on-first-retry` records nothing on a first run at all**, and needs retries switched on,
because without a retry it never records. Here it is with one retry, on the click that comes too
early:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/ssr.spec.js --retries 1 --trace on-first-retry

Running 1 test using 1 worker

  ✘  1 evidence/ssr.spec.js:10:1 › a click on /ssr, at once (5.7s)
  ✘  2 evidence/ssr.spec.js:10:1 › a click on /ssr, at once (retry #1) (5.8s)
ana@laptop:~/quitanda$ find test-results -type f | sort
test-results/.last-run.json
test-results/ssr-a-click-on-ssr-at-once-retry1/error-context.md
test-results/ssr-a-click-on-ssr-at-once-retry1/test-failed-1.png
test-results/ssr-a-click-on-ssr-at-once-retry1/trace.zip
test-results/ssr-a-click-on-ssr-at-once-retry1/video.webm
test-results/ssr-a-click-on-ssr-at-once/error-context.md
test-results/ssr-a-click-on-ssr-at-once/test-failed-1.png
test-results/ssr-a-click-on-ssr-at-once/video.webm
```

The first attempt failed and kept its screenshot and its video, as the configuration asks, and
**no trace**: `on-first-retry` does not record a first attempt. The retry failed the same way and
left a folder of its own, ending in `-retry1`, with a trace in it. That is cheap, and it has a blind
spot. A test that fails once and passes on its retry is the one that most needs diagnosing, and
under this setting the only trace you have of it is the trace of the run that passed.

## What it costs

The disk cost is easy to measure. Three files of lesson 1 to 3, six tests, without and then with a
trace for every test:

```
ana@laptop:~/quitanda$ npx playwright test tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js
  6 passed (7.8s)
ana@laptop:~/quitanda$ du -sh test-results
16K	test-results
```

```
ana@laptop:~/quitanda$ npx playwright test tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js --trace on
  6 passed (7.9s)
ana@laptop:~/quitanda$ du -sh test-results; find test-results -name trace.zip | wc -l
344K	test-results
6
```

Without traces the six tests left 16 KB, little more than the folders themselves. With a trace
for every test they left 344 KB, about 55 KB a test, and this shop's pages are tiny. A trace grows with what the page loads and with every action, and
the failing click's folder, video and screenshot included, came to about 270 KB on its own. Multiply
by a suite and by every run of every branch, and `'on'` stops being a setting anybody leaves on.

The other cost is time. The six tests took 7.8 s without traces and 7.9 s with them, one run of
each, which is too few to say more than *small, here*. Video was not measured on its own. A suite of a few hundred tests
pays whatever it costs a few hundred times, on a build server that is usually a smaller machine
than a laptop.

## What a team usually settles on

A common choice, and the one this lesson's configuration makes, is to keep everything **only for
the tests that failed**: `screenshot: 'only-on-failure'`, `trace: 'retain-on-failure'`, and video
either `'retain-on-failure'` or off, since a trace already holds a picture of every action.
The configuration `npm init playwright` writes for a new project uses `trace: 'on-first-retry'`
with retries on the build server, which is cheaper and only diagnoses failures that happen twice.

Three habits make the evidence reach a person:

- **Copy `test-results/` and `playwright-report/` off the machine whatever the outcome.** A step
  that runs only on success never runs when it matters, and that step belongs to the pipeline.
- **Give the copies a lifetime.** Build services delete artefacts after a number of days you set;
  a week or two covers the time between a failure and somebody looking at it, and it bounds the
  disk.
- **Remember what a trace contains.** Everything the page sent and received is in it, headers and
  bodies included, so a trace of a test that signed in holds whatever the sign-in exchanged. Keep
  test accounts fake and artefacts private to the team.

Lesson 19 runs the suite in parallel and splits it across machines, where each machine leaves its
own `test-results/`. Lesson 14 is about tests that fail only sometimes, where the evidence of
the one run that failed is worth more than any number of runs that passed.
