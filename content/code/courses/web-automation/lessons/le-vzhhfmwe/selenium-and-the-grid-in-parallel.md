---
title: Selenium in parallel: the runner and the grid's slots
version: 1
---

**Selenium has no workers of its own.** `selenium-webdriver` is a library: it opens a session and
sends commands, and it never decides what runs when. Parallelism in a Selenium suite comes from
two places that are configured apart, and a team that sets only one of them gets less than it
expected.

The first is the **runner**. Lesson 8 ran `selenium/shop.test.js` with Node's own test runner,
`node --test`, which starts one child process per test file and runs several files at once. Its
documentation names the flag `--test-concurrency` for how many, and inside one file a `describe`
or `test` with `{ concurrency: n }` lets several tests of that file run together. Java teams get
the same choice from JUnit or TestNG, Python teams from pytest's `-n` with the `pytest-xdist`
plugin. In every case it is the runner that starts several tests, and each test then asks for a
browser.

The second is **where the browsers come from**. A test that builds its driver against
`chromedriver` on the same machine starts a browser there, so the laptop's processors and memory
are the limit, exactly as with Playwright's workers. A test pointed at a grid with
`SELENIUM_REMOTE_URL`, as in lesson 8, asks the grid instead, and the grid has **slots**. The
standalone grid in lesson 8 printed its own count as it started:

```
17:00:47.282 INFO [NodeOptions.getSessionFactories] - Detected 4 available processors
17:00:47.401 INFO [NodeOptions.report] - Adding Chrome for {"browserName": "chrome","platformName": "linux"} 4 times
```

Four processors, four Chrome slots. Its documentation names `--max-sessions` as the setting that
changes the number. **A request for a fifth session does not fail: it waits in the session
queue** until a slot is released, which is what the queue among the grid's parts in lesson 8 is
for. So a runner set to eight at once against a grid with four slots runs four tests and holds
four more in a queue, and the run takes about as long as it would with four.

| | Playwright Test | Selenium |
|---|---|---|
| what starts several tests | the runner's workers | the runner you chose: `node --test`, JUnit, TestNG, pytest |
| how many | `--workers`, default half the processors | that runner's own setting |
| where the browsers run | inside each worker, on this machine | on this machine, or on a grid's nodes |
| what limits browsers at once | the machine | the machine, or the grid's slots |
| splitting across machines | `--shard` | the CI's own split, or more nodes behind one grid |

The shop's single basket does not care which column you are in. A Selenium suite run four at a
time against one shop collides exactly as the Playwright one did, and the answers are the same:
the runner's way of keeping a group of files together, or one shop per test, which only the
application can give.

None of the Selenium commands named here was run for this lesson: lesson 8's grid already showed
the slots and the queue, and the parallel runs above showed what four browsers at once do to one
shop.
