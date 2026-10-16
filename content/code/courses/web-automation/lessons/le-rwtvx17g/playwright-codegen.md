---
title: Playwright's own recorder
version: 1
---

Playwright ships a recorder in the same package you installed in lesson 1. `npx playwright codegen
http://localhost:3000/` opens a browser beside a window called the Inspector, and every click you
make in the browser appears in the Inspector as a line of Playwright code. **It was not run for this
course, because both windows need a screen.** Two parts of it can be run without one, and they say
most of what matters: its options, and the function it calls to name an element.

## Its options

```
ana@laptop:~/quitanda$ npx playwright codegen --help
Usage: npx playwright codegen [options] [url]

open page and generate code for user actions

Options:
  -o, --output <file name>             saves the generated script to a file
  --target <language>                  language to generate, one of javascript,
                                       playwright-test, python, python-async,
                                       python-pytest, csharp, csharp-mstest,
                                       csharp-nunit, java, java-junit (default:
                                       "playwright-test")
  --test-id-attribute <attributeName>  use the specified attribute to generate
                                       data test ID selectors
  -b, --browser <browserType>          browser to use, one of cr, chromium, ff,
                                       firefox, wk, webkit (default: "chromium")
  --block-service-workers              block service workers
  --channel <channel>                  Chromium distribution channel, "chrome",
                                       "chrome-beta", "msedge-dev", etc
  --color-scheme <scheme>              emulate preferred color scheme, "light"
                                       or "dark"
  --device <deviceName>                emulate device, for example  "iPhone 11"
  --geolocation <coordinates>          specify geolocation coordinates, for
                                       example "37.819722,-122.478611"
  --ignore-https-errors                ignore https errors
  --load-storage <filename>            load context storage state from the file,
                                       previously saved with --save-storage
  --lang <language>                    specify language / locale, for example
                                       "en-GB"
  --proxy-server <proxy>               specify proxy server, for example
                                       "http://myproxy:3128" or
                                       "socks5://myproxy:8080"
  --proxy-bypass <bypass>              comma-separated domains to bypass proxy,
                                       for example
                                       ".com,chromium.org,.domain.com"
  --save-har <filename>                save HAR file with all network activity
                                       at the end
  --save-har-glob <glob pattern>       filter entries in the HAR by matching url
                                       against this glob pattern
  --save-storage <filename>            save context storage state at the end,
                                       for later use with --load-storage
  --timezone <time zone>               time zone to emulate, for example
                                       "Europe/Rome"
  --timeout <timeout>                  timeout for Playwright actions in
                                       milliseconds, no timeout by default
  --user-agent <ua string>             specify user agent string
  --user-data-dir <directory>          use the specified user data directory
                                       instead of a new context
  --viewport-size <size>               specify browser viewport size in pixels,
                                       for example "1280, 720"
  -h, --help                           display help for command

Examples:

  $ codegen
  $ codegen --target=python
  $ codegen -b webkit https://example.com
```

Three options in that list matter more than the rest. `--target` chooses the language of the code,
and the default, `playwright-test`, is the test files this course writes. `--test-id-attribute`
tells it which attribute counts as a test id, for an application that spells it differently from
`data-testid`. And `-o` saves what it wrote to a file when the recording ends, instead of leaving it
in the Inspector for you to copy.

## Asking it how it would name the shop

When you click an element during a recording, codegen asks a function inside Playwright what to call
that element, and writes the answer into the line. The same function can be asked directly: with
the environment variable `PWDEBUG=console`, Playwright puts an object called `playwright` into every
page it opens, and its `generateLocator` method returns the name for an element you hand it. In
`playwright-core` 1.56.0 the two go through the same `generateSelector` code, so the answers below
are the names codegen would write.

This script opens the shop, finds twelve elements by a CSS selector of its own, and asks the
generator what it would call each one. Save it as `pick.mjs`:

```javascript
import { chromium } from '@playwright/test';

const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto('http://localhost:3000/');
await page.locator('#products[aria-busy="false"]').waitFor();

// Each element is found here by a stable CSS selector, then Playwright's
// generator is asked what IT would call that element.
const fruit = ['banana', 'mango', 'papaya', 'guava', 'cashew', 'passion', 'acerola', 'pineapple'];
const elements = [
  ...fruit.map((id) => `[data-testid=product-${id}] button`),
  '[data-testid=product-banana] h2',
  '[data-testid=basket-count]',
  '.basket-total',
  '.toast',
];
for (const css of elements) {
  const name = await page.evaluate(
    (s) => playwright.generateLocator(document.querySelector(s)),
    css,
  );
  console.log(css.padEnd(38), name);
}
await browser.close();
```

Start the shop with `npm start` in one terminal, then run it twice in another. On Windows, in
PowerShell, set the variable first with `$env:PWDEBUG = 'console'` and run `node pick.mjs`.

```
ana@laptop:~/quitanda$ PWDEBUG=console node pick.mjs
[data-testid=product-banana] button    getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })
[data-testid=product-mango] button     getByTestId('product-mango').getByRole('button', { name: 'Add to basket' })
[data-testid=product-papaya] button    getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' })
[data-testid=product-guava] button     getByTestId('product-guava').getByRole('button', { name: 'Add to basket' })
[data-testid=product-cashew] button    getByTestId('product-cashew').getByRole('button', { name: 'Add to basket' })
[data-testid=product-passion] button   getByTestId('product-passion').getByRole('button', { name: 'Add to basket' })
[data-testid=product-acerola] button   locator('#card-3585 > button')
[data-testid=product-pineapple] button locator('#card-3215 > button')
[data-testid=product-banana] h2        getByRole('heading', { name: 'Banana' })
[data-testid=basket-count]             getByTestId('basket-count')
.basket-total                          getByText('R$ 0,00')
.toast                                 getByRole('status')
ana@laptop:~/quitanda$ PWDEBUG=console node pick.mjs
[data-testid=product-banana] button    getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })
[data-testid=product-mango] button     getByTestId('product-mango').getByRole('button', { name: 'Add to basket' })
[data-testid=product-papaya] button    getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' })
[data-testid=product-guava] button     getByTestId('product-guava').getByRole('button', { name: 'Add to basket' })
[data-testid=product-cashew] button    getByTestId('product-cashew').getByRole('button', { name: 'Add to basket' })
[data-testid=product-passion] button   getByTestId('product-passion').getByRole('button', { name: 'Add to basket' })
[data-testid=product-acerola] button   locator('#card-8452 > button')
[data-testid=product-pineapple] button locator('#card-5129 > button')
[data-testid=product-banana] h2        getByRole('heading', { name: 'Banana' })
[data-testid=basket-count]             getByTestId('basket-count')
.basket-total                          getByText('R$ 0,00')
.toast                                 getByRole('status')
```

**Most of the answers are the ones lesson 2 recommended.** The heading is named by its role and its
text, the toast by its role, the count by its test id, and six of the buttons by the card's test id
and the button's role and name. A recording of those clicks would be close to the test you would
write by hand.

**Two answers are wrong, and they are the same two in both runs.** The Acerola and Pineapple
buttons, the seventh and eighth of eight identical buttons, are named by the card's random `id`,
and the number changes between the runs because the page drew it again. That is the split lesson 2's
strict-mode error showed for the same buttons: six named by test id, the last two by `#card-NNNN`.
Why the generator changes its mind at the seventh is inside its scoring, and this course did not
take it apart. What a tester needs is the fact that it does, every time.

**One answer is right today and wrong after the first click.** The total has no role, no label and
no test id, so the generator named it by the text it showed, `getByText('R$ 0,00')`. After a banana
goes into the basket the total says `R$ 5,90`, and that locator finds nothing. A recorder names an
element by what it is at the moment you point at it, and a total is the one element in the shop
whose whole job is to change.

## What a recorded test looks like

Codegen writes a whole file per session. Its JavaScript generator in the same version starts every
file with an import of `test` and `expect` and one test called `test`, writes the address you typed
in full, and turns the Inspector's "assert text" into `toContainText`. A session that adds a banana
and checks the count would come out in this shape; it was written for this lesson from that source,
not saved by codegen:

```javascript
import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toContainText('1');
});
```

**It is better than Selenium IDE's recording in one way that matters.** The assertion is a
web-first one, the kind lesson 11 compared with Puppeteer's: it asks again until the count says `1`
or five seconds pass, so the recording needs no pause. It is still a transcript. Nothing empties the
basket before the click, the full address ignores the `baseURL` in `playwright.config.js`, the test
is called `test`, and the next session will repeat the same three lines in a file of its own.
