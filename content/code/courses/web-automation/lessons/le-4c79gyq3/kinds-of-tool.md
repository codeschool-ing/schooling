---
title: Four kinds of tool, three protocols
version: 1
---

A list like this lesson's title reads as seven rivals, each one a way to do what Playwright does.
**They are not rivals, and two of them never touch a browser.** They sit at different layers of
the same machine, several of them work together in one project, and one of them is not software
you install at all. Placing a tool on the right layer answers most of what you need to know about
it before you read its documentation.

## The layers

Every browser test you have written in this course went through four layers, and Playwright hid
three of them by doing them all:

- **the runner** finds the test files, runs each test, keeps one test's failure from stopping the
  rest, and prints the report. `npx playwright test` is a runner. So are Jest, Jasmine, Mocha and
  Node's own `node --test`;
- **the assertions** are how a test says what should be true: `expect(count).toBe(1)` in Jest
  and Jasmine, `assert.equal(count, 1)` in Node. They usually come with the runner, and the
  difference between them is mostly spelling;
- **the driver library** turns `click()` in your code into a message the browser understands.
  Puppeteer, `selenium-webdriver`, `webdriverio` and Playwright's own library are this layer;
- **the protocol** is the message format between the library and the browser, and **the
  browser** is what obeys it.

Two kinds of tool do not fit that stack. **A keyword-driven framework**, Robot Framework here,
writes tests as rows of plain words and calls a driver library underneath. **A hosted service**,
QA Wolf here, is a company: people who write and run the tests for you, with tools of their own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 304\" role=\"img\" aria-label=\"Four layers from top to bottom: runner and assertions, driver library, protocol, browser. Playwright Test sits on Playwright, which speaks CDP. Jest, Jasmine or another runner sits on Puppeteer, which speaks CDP and WebDriver BiDi. The WDIO runner sits on webdriverio, which speaks WebDriver BiDi and WebDriver. Nightwatch sits on selenium-webdriver, which speaks WebDriver. Robot Framework sits on SeleniumLibrary or the Browser library; SeleniumLibrary speaks WebDriver. QA Wolf stands apart as a service whose people write and run Playwright tests. All three protocols reach the browser.\"><text x=\"14\" y=\"58\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">runner and</text><text x=\"14\" y=\"73\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">assertions</text><text x=\"14\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">driver</text><text x=\"14\" y=\"137\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">library</text><text x=\"14\" y=\"196\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">protocol</text><text x=\"14\" y=\"270\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">browser</text><rect x=\"144.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"190\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Playwright Test</text><rect x=\"244.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"290\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Jest, Jasmine,</text><text x=\"290\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">or another</text><rect x=\"344.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"390\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WDIO runner</text><text x=\"390\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Mocha · Jasmine</text><rect x=\"444.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"490\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Nightwatch</text><rect x=\"544.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"590\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Robot</text><text x=\"590\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Framework</text><rect x=\"144.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"190\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Playwright</text><rect x=\"244.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"290\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Puppeteer</text><rect x=\"344.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"390\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">webdriverio</text><rect x=\"444.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"490\" y=\"123\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">selenium-</text><text x=\"490\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">webdriver</text><rect x=\"544.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"590\" y=\"123\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SeleniumLibrary</text><text x=\"590\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">or Browser</text><path d=\"M190 84 L190 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M290 84 L290 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M390 84 L390 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M490 84 L490 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M590 84 L590 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"644\" y=\"40\" width=\"92\" height=\"108\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"5 4\"></rect><text x=\"690\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">QA Wolf</text><text x=\"690\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a service:</text><text x=\"690\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">its people write</text><text x=\"690\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and run Playwright</text><text x=\"690\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tests for you</text><rect x=\"140\" y=\"176\" width=\"190\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"235.0\" y=\"197\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">CDP</text><text x=\"235.0\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Chromium browsers only</text><rect x=\"345\" y=\"176\" width=\"185\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"437.5\" y=\"197\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">WebDriver BiDi</text><text x=\"437.5\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">two-way, several browsers</text><rect x=\"545\" y=\"176\" width=\"195\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"642.5\" y=\"197\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">WebDriver</text><text x=\"642.5\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every browser, via a driver</text><path d=\"M190 148 L190 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M290 148 L300 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M290 148 L385 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M390 148 L415 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M390 148 L575 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M490 148 L600 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M590 148 L625 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><rect x=\"140\" y=\"250\" width=\"600\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"440\" y=\"275\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Chrome · Edge · Firefox · Safari</text><path d=\"M235 226 L235 250\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M437 226 L437 250\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M642 226 L642 250\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path></svg>", "caption": "Where each tool sits. Two things are left out to keep it readable: Playwright drives Firefox and WebKit through patched builds of its own, and Robot's Browser library runs on Playwright."}
```

## Three protocols

A protocol decides what a tool can see, which browsers it reaches, and how much it breaks when a
browser updates. There are three in use.

**WebDriver** is a W3C standard, and it is what Selenium speaks; lesson 8 draws its architecture.
The library sends an HTTP request to a separate **driver** program, `chromedriver` for Chrome,
`geckodriver` for Firefox, `safaridriver` for Safari, and the driver works the browser and
answers. One request, one answer. Because every browser maker ships a driver, it reaches every
browser. What it cannot do is tell you something you did not ask about: a request the page made,
or a message it wrote to the console.

**The Chrome DevTools Protocol**, CDP, is the one the DevTools panels from lesson 1 use. The
library opens a WebSocket straight into the browser, with no driver in between, and the browser
**sends events back** as they happen: every response, every console message, every error. That
is how `look.mjs` in lesson 1 printed the Network panel. The cost is reach: **only Chromium-based
browsers speak it**, Chrome and Edge among them, and it is Chrome's internal interface rather than
a standard, so it changes with Chrome.

**WebDriver BiDi** is the W3C's answer to that gap: WebDriver's standard reach, over a two-way
connection that carries events like CDP's. It is still a draft standard. Puppeteer already uses it
to drive Firefox, and WebdriverIO's documentation says it switches to it by itself whenever the
browser supports it.

## The map as a table

| tool | kind | language | drives the browser with | comes with a runner |
|---|---|---|---|---|
| Puppeteer | driver library | JavaScript | CDP for Chrome, WebDriver BiDi for Firefox | no |
| Playwright | library and runner | JavaScript, also Python, Java and .NET | CDP for Chromium; patched builds of Firefox and WebKit | yes |
| Selenium | driver library | Java, Python, JavaScript, C# and more | WebDriver, with BiDi for some features | no |
| WebdriverIO | library and runner | JavaScript | WebDriver BiDi where it can, WebDriver otherwise | yes |
| Nightwatch | framework | JavaScript | WebDriver, through `selenium-webdriver` | yes |
| Jest | runner and assertions | JavaScript | none of its own | it is one |
| Jasmine | runner and assertions | JavaScript | none of its own | it is one |
| Robot Framework | keyword-driven framework | plain-text keywords, extended in Python | a library underneath: Selenium or Playwright | it is one |
| QA Wolf | service | its engineers write Playwright tests | what Playwright uses | they run it |

Cypress is missing on purpose. It runs inside the page rather than talking to the browser from
outside, which puts it on no row of this table; lesson 9 is about what that buys and costs.

**Most of the choice is made before anybody compares features.** A team whose application is
tested in Python already has a runner, and Robot Framework or Selenium's Python binding fits it. A
team with a hundred WebDriver tests and a grid of machines to run them on, which lesson 8 shows,
moves to WebdriverIO more cheaply than to anything else. A front-end team whose unit tests already
run in Jest adds a browser library to Jest rather than a second runner. The sections that follow
place each tool on the map, and the one you run for real is Puppeteer.
