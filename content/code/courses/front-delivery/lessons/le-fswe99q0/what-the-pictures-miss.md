---
title: What the pictures miss, and what audits catch
version: 1
---

**A screenshot comparison catches changes, not mistakes, and only changes larger than its tolerance.**
That is the reason the test runs axe beside it, and the clearest way to see why is a change the pictures
let through.

## A grey the pictures accepted

Lesson 5's `grey-400`, the grey that failed the contrast script, put back as the light theme's quiet text,
with the tokens regenerated and the workshop rebuilt:

```
ana@dev:~/planner$ sed -i 's/{color.grey-600}/{color.grey-400}/' tokens.json
ana@dev:~/planner$ npm run tokens > /dev/null
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test -g 'done in light' 2>&1 | sed -n '/Error:/,/^    + \]/p'
    Error: expect(received).toEqual(expected) // deep equality

    - Expected  - 1
    + Received  + 3

    - Array []
    + Array [
    +   "color-contrast",
    + ]
```

**The screenshot comparison passed.** The word *done* changed from one grey to a lighter one, and
Playwright's comparison, by default, forgives a small difference in colour per pixel. Anti-aliasing
and font smoothing vary slightly between runs, and a test that failed on those would be ignored within a
week. A threshold that tolerates that tolerates a slightly lighter grey too.

**Axe did not pass it**: `color-contrast`, the rule that measures the same WCAG ratio lesson 5's script
computed, against the colours the browser actually drew. The two checks see different things, and a test
needs both. Put the right grey back:

```
ana@dev:~/planner$ git checkout tokens.json src/tokens.css
Updated 2 paths from the index
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test 2>&1 | tail -2

  10 passed (14.8s)
```

## Pictures belong to one machine

Screenshots depend on the fonts, the browser build and the operating system that drew them, so Playwright
names each picture after the platform: these are `…-chromium-linux.png`. On a Mac the same test looks for
`…-chromium-darwin.png`, finds none, and writes new ones. The usual answer is to make **one machine the
photographer**: CI, on Linux, with the pictures it approved committed, and developers on other systems
updating them through CI rather than from their own computer.

## And what neither sees

Neither check knows whether the component is right. A screenshot that has always been wrong passes
forever, and axe checks only what can be decided from the page: a missing label, a contrast ratio, a role.
Whether *Mark done* is the right words, whether the focus order makes sense, whether a screen reader
announces the change: those are front-quality lessons 10 to 13, and somebody's judgement. The tests make
sure that judgement, once made, stays made.

Commit the workshop, the tests and their pictures:

```
ana@dev:~/planner$ git add .storybook src playwright.config.ts tests package.json package-lock.json .gitignore
ana@dev:~/planner$ git commit -qm "A component library, documented in Storybook and tested story by story"
```
