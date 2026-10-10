---
title: WebdriverIO and Nightwatch, WebDriver with a runner
version: 1
---

Lesson 8's Selenium is a library: it gives you a `driver` and leaves the runner, the waiting
and the report to you. **WebdriverIO and Nightwatch are what you get when somebody wraps that
in a framework.** Both are JavaScript, both reach the browser through a WebDriver driver
rather than a private protocol, and both bring a runner, a configuration file and assertions
of their own. They differ in how far they have moved beyond classic WebDriver.

Neither was installed or run for this course; the snippets below are each tool's ordinary
shape, the same banana test as the last section, so you can compare them on the page.

## WebdriverIO

Its npm package describes it as a "next-gen browser and mobile automation test framework for
Node.js", and the two halves are separate: `webdriverio` is the library, usable from a plain
script, and `@wdio/cli` is the runner, which runs your tests under a framework you choose:
Mocha, Jasmine or Cucumber, each an `@wdio/` package of its own. The current release is 10.0.2,
and it asks for Node 22.19 or later.

```javascript
describe('quitanda', () => {
  it('puts a banana in the basket', async () => {
    await browser.url('/');
    await $('[data-testid=product-banana] button').click();
    await expect($('[data-testid=basket-count]')).toHaveText('1');
  });
});
```

`browser`, `$` and this `expect` are globals the runner provides. Its assertions on an element
wait and retry, much like Playwright's.

**Its protocol is the interesting part.** WebdriverIO speaks classic WebDriver, and its
documentation says it opts in to **WebDriver BiDi** by itself whenever the browser and driver
support it; the capability `wdio:enforceWebDriverClassic` turns that off. So the same tests that
run against a grid of WebDriver machines, or a cloud provider's browsers, can also listen to the
page's network and console the way CDP tools do. It can also hand you a Puppeteer object for the
same Chrome, through `browser.getPuppeteer()`, when you need something only CDP has.

**A team picks it** when it already runs WebDriver infrastructure, writes JavaScript, and wants a
modern runner on top. Mobile apps are the other reason: the same runner drives Appium, which is
the subject of `api-mobile-automation`.

## Nightwatch

Its README calls it "an integrated testing framework powered by Node.js and using the W3C
Webdriver API", developed at BrowserStack, a company that sells cloud browsers. It is the most
all-in-one of the JavaScript tools: `npm init nightwatch@latest` asks a few questions and writes
the configuration, the runner is built in, and so are its assertions.

```javascript
describe('quitanda', function () {
  it('puts a banana in the basket', function (browser) {
    browser
      .navigateTo('http://localhost:3000/')
      .click('[data-testid=product-banana] button')
      .assert.textEquals('[data-testid=basket-count]', '1');
  });
});
```

The chained style is Nightwatch's mark: each command queues, and the runner plays the queue in
order. **Underneath it is Selenium.** The `nightwatch` package 3.16.0 depends on
`selenium-webdriver` 4.27.0, so everything lesson 8 says about drivers, grids and capabilities
holds here too. The npm registry lists its latest release, 3.16.0, on 25 May 2026, and the one
before it in January. How often a tool ships is worth a look before you build on it.

**A team picks it** when its tests already run on BrowserStack, or it inherited a Nightwatch
suite. Starting fresh, compare it with WebdriverIO and Playwright on what the rest of your
tooling already speaks.
