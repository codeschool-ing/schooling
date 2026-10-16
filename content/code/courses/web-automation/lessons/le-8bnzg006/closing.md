---
title: What the course covered, and what comes next
version: 1
---

The course began with a browser's developer tools and a shop with flaws in it, and it ends with a
project of a few dozen tests that you wrote, ran and, in places, decided against. **The course was
never about one tool.** Selenium, Cypress and Playwright each had a lesson, and each will have
changed by the time you read this; what carries over is knowing what the browser is doing while
the test waits, and whether a check is worth its cost.

## The course, lesson by lesson

| | lesson | what it left you with |
|---|---|---|
| 1 | Browser developer tools | the shop, the lab, and a page read in three panels |
| 2 | DOM, CSS selectors and XPath | a locator that survives a reload, and why a copied id did not |
| 3 | Ajax and asynchronous loading | waiting for the right thing, and a race reported as a defect |
| 4 | The browser cache | a stale offer, and a fresh context for each visitor |
| 5 | Single-page applications, PWAs and JAMStack | a deep link that 404s, and a service worker that serves the old shell |
| 6 | Client-side and server-side rendering | a click that arrives before the script, and the layer to test it at |
| 7 | Responsive and adaptive layouts | the check for a sideways scroll, and what a descriptor cannot pretend |
| 8 | Selenium WebDriver | the protocol under every driver, and a grid |
| 9 | Cypress | a test running inside the page, and where that stops |
| 10 | Playwright | browsers, contexts and a trace |
| 11 | The other tools | Puppeteer, WebdriverIO, Nightwatch, Jest, Jasmine, Robot and QA Wolf, placed |
| 12 | The Page Object pattern | one place for each locator, and when abstraction goes too far |
| 13 | Explicit and implicit waits | a fixed sleep measured, the two waits compared, and a condition of your own |
| 14 | Flaky tests | a cause found rather than retried away, and a quarantine |
| 15 | Test data | a test that owns its data and cleans up after itself |
| 16 | Screenshots, video and traces | the evidence a failing test leaves behind |
| 17 | Headless execution | two headless Chromiums, the differences that bite, and whether headless is faster |
| 18 | Zombie.js and HtmlUnit | simulated browsers, jsdom run against the shop, and what a page without layout cannot tell you |
| 19 | Parallel execution | workers and shards, and one worker for the tests that share the shop |
| 20 | Recorders | Selenium IDE and Playwright's recorder, and one change counted against a recording |
| 21 | The testing pyramid | one behaviour at three layers, timed, and what earns a place in the browser |
| 22 | What not to automate | the cost of a test, set against its value |

## What comes next

**`api-mobile-automation` is the next course in the qa track.** It goes one layer down, to the
API: HTTP methods, status codes and headers for a tester, the contract a REST API promises, and
authentication, before it turns to mobile. Much of what this course checked through a page, such
as a basket total or a refusal for a name already taken, is cheaper there, as lesson 21 argued.
Everything you learnt about isolation and cleanup in lesson 15 applies unchanged.

**`non-functional-testing` builds on this one.** It assumes the automation base you now have, and
uses it for what this course kept pointing at and leaving alone: how fast the page is
(`non-functional-testing` lesson 10, front-end performance) and whether everybody can use it
(lessons 12 to 15, accessibility). The contrast check that would have caught the white prices of
this lesson's experiment is that course's subject.

And `testing-cicd` is where the suite you built stops running on your laptop. Lesson 1 there is
the layers again, from the pipeline's side, and lesson 5 is continuous integration, where the run
time and the flaky rate of the previous section become somebody's budget every day.

## The project you keep

`~/quitanda` is yours. It is small enough to read in an afternoon and every flaw in it is labelled,
which makes it a reasonable place to try a tool before you trust it at work: a new release of
Playwright, a reporter, a way of splitting the suite. Fix a flaw and watch which tests notice. If
the answer surprises you, you have learnt something about those tests that no lesson told you.
