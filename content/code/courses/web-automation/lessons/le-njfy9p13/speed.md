---
title: Is headless faster?
version: 1
---

The usual claim is that headless is much faster, and it is repeated as if it were a measurement.
**It is a direction, and how much it is worth depends on what the suite spends its time on.** A
browser with no window skips putting pixels on a screen; it still parses, runs and lays out every
page, so the saving can only come from the part the screen took. The way to know is to time the
same tests both ways on the same machine.

## The suite

Five of the project's test files, from lessons 1, 2, 3, 5 and 6, run in one worker so that the
browser starts once and the tests run one after another. One run in full, so you can see what is
being timed:

```
%%CAP speed-one%%
```

## Three modes, three times each

The same command, in the shell, in new headless through `headless.config.js`, and headed under
Xvfb, repeated three times. `tail -1` keeps the summary line, which carries the run's total:

```
%%CAP speed%%
```

@@SPEED_READING@@

## What the number is made of

**Most of these seconds belong to the shop, not to the browser.** The search test waits for slow
answers on purpose (lesson 3), the server-rendered page holds its script back for a second and a
half (lesson 6), and the expected failure in `tests/search.spec.js` spends its whole timeout before
it counts as a pass. None of that gets faster without a window. A suite of a thousand short tests
that each open a page and click once would spend a larger share of its time in the browser, and
there the difference would be larger; a suite like this one, dominated by waits it means to have,
barely notices.

Two more things decide the time far more than the mode. Workers: lesson 19 runs these files in
parallel, which divides the total in a way no headless switch can. And the browser starting: each
worker starts one browser, so a suite of many small files pays that cost once per worker, not once
per test.

So the case for headless on a build server is mostly not speed. It needs no display, so there is
nothing to install and nothing to break; and it is what everybody else's pipeline runs, so a
failure there is one somebody has seen before. Run headed when you need the window, under Xvfb on
the server, and measure your own suite before you believe anybody's number, this lesson's
included.
