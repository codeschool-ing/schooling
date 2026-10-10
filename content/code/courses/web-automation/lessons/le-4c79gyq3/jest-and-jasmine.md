---
title: Jest and Jasmine, runners that drive nothing
version: 1
---

The usual surprise about Jest and Jasmine is that **neither one can open a browser**. They are
runners with assertions: they find test files, run the functions inside them, compare values and
print a report. Whether a test touches a browser depends on what the test imports. They belong
on this lesson's list because a great deal of browser automation runs inside them, with a driver
library doing the driving.

## Jasmine

Jasmine describes itself as "a simple JavaScript testing framework for browsers and Node", and it
gave JavaScript the shape most of its tests still have: `describe` for a group, `it` for one
test, `expect(value).toBe(other)` for a check, and **spies** for watching whether a function was
called. The test reads like a sentence, the style called behaviour-driven. The `jasmine` package,
at 7.0.0, runs specs in Node; `jasmine-browser-runner` runs them inside a browser page, which
tests the page's own JavaScript without driving the page from outside.

Today Jasmine appears in browser automation mostly as a framework inside somebody else's runner:
WebdriverIO's `@wdio/jasmine-framework` is one, and Angular projects ran their unit tests in it
for years.

## Jest

Jest is the same shape with more in the box: the runner, the assertions, mocks, snapshots,
coverage and a watch mode. It came out of Facebook, now lives in the `jestjs` organisation, and is
at 30.5.2. **Its syntax is Jasmine's**, because Jest began by running on Jasmine, and a simple spec
written for one runs in the other unchanged.

Here is a Jest test that needs no browser at all. It checks lesson 1's trap, the non-breaking space
`Intl.NumberFormat` puts after `R$`:

```javascript
test('a price has a non-breaking space after R$', () => {
  const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
  expect(money.format(5.9)).toBe('R$ 5,90');
});
```

Neither Jest nor Jasmine was installed for this course, and the snippet was not run under either.
The fact it checks was: in Node 22, `money.format(5.9) === 'R$ 5,90'` is `true`.

## jsdom is not a browser

Jest can run a test in an environment called **jsdom**, the package `jest-environment-jsdom`: a
DOM written in JavaScript, inside Node. `document.querySelector` works there, and a component can
be drawn into it and clicked. **What jsdom does not do is lay anything out or paint it.** It has
no CSS layout, so nothing in it has a real size or position, and a button hidden off-screen or
under another element is as clickable as any other. Lesson 7's basket, too wide for a phone, is
invisible to it. Tests in jsdom are fast, and they are unit tests of the page's code;
`testing-cicd` lesson 1 places them on the layers. The browser test is the one that finds what
only a browser shows.

## Jest around a real browser

To put a real browser inside Jest, a team adds a driver library. The preset `jest-puppeteer`, at
11.0.0, starts Puppeteer before the tests and gives every test a `page`; Selenium and WebdriverIO
can be called from a Jest test the same way. Then Jest supplies the runner and the report,
Puppeteer the browser, and the waiting is still written by hand, as in the last section's script.

**A team picks this** when its unit tests already live in Jest and one runner for everything is
worth more to it than Playwright's waiting. The price is the waiting itself, which stays yours to
write in every test.
