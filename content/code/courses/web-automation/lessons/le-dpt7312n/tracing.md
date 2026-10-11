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
%%CAP trace-run%%
```

Nothing in the output mentions it. The traces are in `test-results/`, one folder per test, each
named after the file and the test:

```
%%CAP trace-ls%%
```

## What is inside

A trace is a zip archive, and any tool that lists a zip will show its contents. The one from the
two shoppers:

```
%%CAP trace-unzip%%
```

Thirty-three files, of four kinds:

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
%%CAP trace-network%%
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
%%CAP report-run%%
```

```
%%CAP report-ls%%
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
