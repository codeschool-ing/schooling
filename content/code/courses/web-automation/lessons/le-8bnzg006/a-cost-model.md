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
cost had it escapes, minus what it costs when the test finds it**. Why a defect found late costs so
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
%%CAP baseline%%
```

Then the shop as it stands, with lesson 7's defect in it:

```
%%CAP as-it-is%%
```

Then four edits of the kind a shop makes every week, each undone before the next. Two are changes
somebody meant, one is a defect, and one is the fix lesson 7 asked for. The border goes darker, in
`app/public/style.css`:

```
%%CAP border%%
```

The banana costs R$ 6,20 instead of R$ 5,90, in `app/store.js`:

```
%%CAP price%%
```

Somebody writes `color: #fff` into `.price`, so every price is white on a white card. The page
still holds the prices, and lesson 1's smoke test runs too:

```
%%CAP hidden-price%%
```

And the fix: `white-space: nowrap; min-width: 24rem;` deleted from `.basket`:

```
%%CAP basket-fixed%%
```

| the edit | was it a defect? | screenshot | sideways check |
|---|---|---|---|
| none: lesson 7's defect | yes, on phones | passed | failed as declared |
| darker border | no | **failed** | passed |
| new price | no | **failed** | passed |
| white prices | yes | **failed** | passed |
| the fix | no, a repair | PIXELS | **passed, and said so** |

**Read the table by column.** The sideways check went red once, on the one thing it asks about, and
it is blind to everything else, the white prices included, which the smoke test also passed. The
screenshot went red on every edit that moved a pixel at its one width, the defect and the two
changes alike, and it cannot see lesson 7's defect at all, because it takes its picture in a window
1280 wide, where the basket fits.

## The two tests in the model

The numbers below are **assumptions, stated so you can change them**: a suite that runs 20 times a
working day for 250 days, 5,000 runs a year; ten minutes for a person to open a red run, look at a
diff and decide; the shop's look changed once a week, 50 times a year; a defect found by a test in
review costing 15 minutes and one found by a customer costing a working day, 480. The run times
come from the captures.

| | sideways check (lesson 7) | screenshot (lesson 16) |
|---|---|---|
| writing | 15 min | 10 min |
| changes that break it, a year | 0 of the 3 harmless edits above: 0 | 3 of 3: **50 × 10 = 500 min** |
| false alarms | 0 | counted in the line above: every one was a change |
| runs, machine time | RUNTIME | VISTIME |
| defects caught, a year | assume 1: 465 min | assume 1: 465 min |
| **person cost : value** | **15 : 465** | **510 : 465** |

The screenshot is the more powerful test, and in this shop it **costs more than the defect it
catches**, because the shop changes its look more often than it breaks it. That is a statement
about the shop and not about screenshots: change the assumption to one change of look a month and
its person cost is 10 + 12 × 10 = 130, comfortably under its value. The sideways check is cheap for
a reason that does not depend on the assumptions. It asks one question that has **one right answer
at every width**, so nothing harmless can turn it red.

```schooling-figure
FIGURE
```

## What to do with an expensive test

- **Narrow it.** `expect(page.locator('.card').first()).toHaveScreenshot()` compares one card rather
  than the page, and stops failing when the header changes.
- **Ask for the fact instead of the picture**, where there is one. The white prices are a contrast
  failure, and a contrast check has a right answer, which `non-functional-testing` lessons 12 to 15
  test.
- **Run it less often**, at night rather than on every push, so that it is a report somebody reads
  rather than a gate somebody waits behind.
- **Delete it**, with the reason written down, which is the section after next.
