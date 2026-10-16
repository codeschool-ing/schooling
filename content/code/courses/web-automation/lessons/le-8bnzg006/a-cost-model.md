---
title: What a test costs, and what it is worth
version: 1
---

**A test is not free once it is written.** The usual picture is that writing it is the cost and
everything after is profit: it runs for ever, for nothing, and catches whatever comes. Every lesson
of this course has shown a piece of the opposite. Lesson 2's test broke on its first run because of
a locator, lesson 8's driver stopped matching the browser, lesson 14's tests went red when nothing
was wrong. Each of those is a bill, and it arrives after the test is written.

## The model

A check costs four things, and three of them recur:

- **writing it**, once;
- **maintaining it**: the minutes somebody spends on it each time the application changes in a way
  that breaks the test and not the product;
- **running it**: its seconds, times the number of runs;
- **false alarms**: each red run that turns out to be nothing, times the time it takes to find
  that out.

And it is worth one thing: the defects it catches, each one worth **what that defect would have
cost had it escaped, minus what it costs when the test finds it**. Why a defect found late costs so
much more than one found early is `qa-fundamentals` lesson 3; here that difference is one number
you put into the sum. Which defects are likely enough to deserve a check at all is
`qa-fundamentals` lesson 20, on prioritisation by risk.

```localised
cost a year  = writing + changes × minutes per change + false alarms × minutes each
             + runs × seconds per run (machine time, kept in its own column)
value a year = defects caught × (minutes if it escapes − minutes when the test finds it)
```

Machine time is in a column of its own on purpose. A minute of a runner is cheaper than a minute of
a person, and any rate that turned one into the other would be an invention. It matters in another
way, which is how long somebody waits for an answer, and the section on the suite as a product
deals with that.

## An experiment the reader can repeat

Two tests from this course, run against the same five versions of the shop: lesson 7's check that
nothing scrolls sideways, and lesson 16's comparison of the whole page with a screenshot. The first
run of the screenshot test writes its baseline:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (1.1s)
    Error: A snapshot doesn't exist at /home/ana/quitanda/evidence/visual.spec.js-snapshots/shop-linux.png, writing actual.
  1 failed
```

Then the shop as it stands, with lesson 7's defect in it:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✓  1 evidence/visual.spec.js:5:1 › the shop looks as it did (470ms)
  1 passed (1.8s)
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✘  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (177ms)
  ✘  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (164ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (142ms)
  3 passed (1.9s)
```

Then four edits of the kind a shop makes every week, each undone before the next. Two are changes
somebody meant, one is a defect, and one is the fix lesson 7 asked for. The border goes darker, in
`app/public/style.css`:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (1.0s)
      4794 pixels (ratio 0.01 of all image pixels) are different.
  1 failed
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✘  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (181ms)
  ✘  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (156ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (131ms)
  3 passed (1.8s)
```

The banana costs R$ 6,20 instead of R$ 5,90, in `app/store.js`:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (1.0s)
      25 pixels (ratio 0.01 of all image pixels) are different.
  1 failed
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✘  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (208ms)
  ✘  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (161ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (163ms)
  3 passed (2.0s)
```

Somebody writes `color: #fff` into `.price`, so every price is white on a white card. The page
still holds the prices, and lesson 1's smoke test runs too:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (1.2s)
      1383 pixels (ratio 0.01 of all image pixels) are different.
  1 failed
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✘  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (201ms)
  ✘  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (148ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (165ms)
  3 passed (1.8s)
ana@laptop:~/quitanda$ npx playwright test tests/smoke.spec.js | grep -E '✓|✘|^  [0-9]+ (passed|failed)'
  ✓  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (183ms)
  1 passed (1.5s)
```

And the fix: `white-space: nowrap; min-width: 24rem;` deleted from `.basket`:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✓  1 evidence/visual.spec.js:5:1 › the shop looks as it did (491ms)
  1 passed (1.8s)
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✓  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (190ms)
  ✓  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (204ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (177ms)
    Expected to fail, but passed.
    Expected to fail, but passed.
  2 failed
  1 passed (3.9s)
```

| the edit | was it a defect? | screenshot | sideways check |
|---|---|---|---|
| none: lesson 7's defect | yes, on phones | passed | failed as declared |
| darker border | no | **failed** | passed |
| new price | no | **failed** | passed |
| white prices | yes | **failed** | passed |
| the fix | no, a repair | passed | **passed, and said so** |

**Read the table by column.** The sideways check went red once, on the one thing it asks about, and
it is blind to everything else, the white prices included, which the smoke test also passed. The
screenshot went red on every edit that moved a pixel at its one width, the defect and the two
changes alike, and it cannot see lesson 7's defect at all, because it takes its picture in a window
1280 wide, Playwright's default, where the basket fits.

## The two tests in the model

The numbers below are **assumptions, stated so you can change them**: a suite that runs 20 times a
working day for 250 days, 5,000 runs a year. A person needs ten minutes to open a red run, look at a
diff and decide. The shop's look changes once a week, 50 times a year. A defect found by a test in
review costs 15 minutes, and one found by a customer costs a working day, 480. The run times
come from the runs above: 177, 164 and 142 ms for the three widths, and 470 ms for the screenshot, on the shop as it stands.

| | sideways check (lesson 7) | screenshot (lesson 16) |
|---|---|---|
| writing | 15 min | 10 min |
| changes of look that break it | 0 of the 2 above: 0 min | 2 of 2, so all 50: **50 × 10 = 500 min** |
| runs, machine time | 0.48 s a run: 2,415 s, 40 min | 0.47 s a run: 2,350 s, 39 min |
| defects caught, a year | assume 1: 465 min | assume 1: 465 min |
| **person cost : value** | **15 : 465** | **510 : 465** |

**The two cost about the same to run**, so run time is not where they differ. The screenshot is the more
powerful test, and in this shop it **costs more than the defect it
catches**, because the shop changes its look more often than it breaks it. That is a statement
about the shop and not about screenshots: change the assumption to one change of look a month and
its person cost is 10 + 12 × 10 = 130, comfortably under its value. The sideways check is cheap for
a reason that does not depend on the assumptions. It asks one question that has **one right answer
at every width**, so nothing harmless can turn it red.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"A chart with cost on the horizontal axis and value on the vertical, both in person-minutes a year from 0 to 600, and a dashed diagonal where value equals cost. The sideways check from lesson 7 sits at cost 15 and value 465, far above the diagonal. The screenshot test with the look changing every week sits at cost 510 and value 465, below the diagonal. An arrow moves it to cost 130, above the diagonal, for a look that changes once a month.\"><polygon points=\"90,320 680,40 90,40\" fill=\"var(--panel)\"></polygon><line x1=\"90\" y1=\"320\" x2=\"680\" y2=\"320\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"90\" y1=\"320\" x2=\"90\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"90\" y=\"338\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">0</text><text x=\"82\" y=\"324\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">0</text><text x=\"287\" y=\"338\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">200</text><text x=\"82\" y=\"231\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">200</text><text x=\"483\" y=\"338\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">400</text><text x=\"82\" y=\"137\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">400</text><text x=\"680\" y=\"338\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">600</text><text x=\"82\" y=\"44\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">600</text><line x1=\"90\" y1=\"320\" x2=\"680\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line><text x=\"414\" y=\"203\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">value = cost</text><text x=\"102\" y=\"180\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" text-anchor=\"start\">worth more than it costs</text><text x=\"672\" y=\"306\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"end\">costs more than it is worth</text><text x=\"385\" y=\"360\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">cost, person-minutes a year</text><text x=\"60\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\" text-anchor=\"start\">value, person-minutes a year</text><line x1=\"582\" y1=\"103\" x2=\"230\" y2=\"103\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></line><polygon points=\"226,103 238,98 238,108\" fill=\"var(--amber)\"></polygon><circle cx=\"105\" cy=\"103\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"115\" y=\"73\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">sideways check</text><text x=\"115\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">15 : 465</text><circle cx=\"218\" cy=\"103\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"226\" y=\"73\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">screenshot, look changes monthly</text><text x=\"226\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">130 : 465</text><circle cx=\"592\" cy=\"103\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"600\" y=\"129\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"end\">screenshot, look changes weekly</text><text x=\"600\" y=\"144\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">510 : 465</text></svg>", "caption": "Three points from the cost model, with this section's assumptions. The sideways check costs about a thirtieth of what it is worth. The screenshot costs more than it is worth while the look changes weekly, and less once it changes monthly: the test did not change, the shop did."}
```

## What to do with an expensive test

- **Narrow it.** `expect(page.locator('.card').first()).toHaveScreenshot()` compares one card rather
  than the page, so an edit anywhere else on the page no longer turns it red.
- **Ask for the fact instead of the picture**, where there is one. The white prices are a contrast
  failure, and a contrast check has a right answer, which `non-functional-testing` lessons 12 to 15
  test.
- **Run it less often**, at night rather than on every push, so that it is a report somebody reads
  rather than a gate somebody waits behind.
- **Delete it**, with the reason written down, which is two sections on.
