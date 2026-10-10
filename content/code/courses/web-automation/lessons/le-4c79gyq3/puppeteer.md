---
title: Puppeteer, run for real
version: 1
---

**Puppeteer is a driver library and nothing else.** Its README calls it "a JavaScript library
which provides a high-level API to control Chrome or Firefox over the DevTools Protocol or WebDriver
BiDi". It has no runner, no assertions and no idea what a test file is: you write a Node script,
and the script does what it says. It comes from Google, from the people who build Chrome's
developer tools, and that is where its strength lies. Through CDP it sees everything DevTools sees,
so teams reach for it for jobs that are not tests at all: a screenshot or a PDF of a page, a
performance trace, a page read by a program. When it is used for tests, a runner from elsewhere
goes around it, and the section on Jest shows one.

## Installing it

The project's `package.json` now pins four tools: Playwright since lesson 1, `selenium-webdriver`
from lesson 8, Cypress from lesson 9, and Puppeteer. Save it as `package.json`:

```json
{
  "name": "quitanda",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node app/server.js",
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "1.56.0",
    "cypress": "16.1.1",
    "puppeteer": "25.13.0",
    "selenium-webdriver": "4.51.0"
  }
}
```

and install:

```
ana@laptop:~/quitanda$ npm install

added 212 packages, and audited 213 packages in 5s

56 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

**On your machine this step also downloads a browser.** Like Playwright, each Puppeteer release is
built against one Chrome build, and installing it fetches that build into `~/.cache/puppeteer`. For
25.13.0 its source names Chrome 155.0.8059.39. Its README warns that some package managers skip
install scripts. Then nothing is downloaded, the first run fails, and this command fetches the
browser by hand:

```sh
npx puppeteer browsers install
```

**That download was not run for these transcripts.** The machine they come from cannot reach it,
so every Puppeteer run below was pointed at the Chromium 141 that Playwright already installed, by
setting the variable `PUPPETEER_EXECUTABLE_PATH` to its path. Your runs use the Chrome Puppeteer
downloaded, and the `browser:` line further down prints a different number.

## A banana, by Puppeteer

The script opens the shop, waits for the cards, adds a banana and prints how many items the basket
holds. Make a folder for it with `mkdir puppeteer`. Save it as `puppeteer/basket.mjs`:

```schooling-example
{"language": "javascript", "file": "puppeteer/basket.mjs", "parts": [{"code": "// The shop, driven by Puppeteer: add a banana and read the basket.\nimport puppeteer from 'puppeteer';\n", "note": "One import and nothing from a test runner: Puppeteer is a library, and this is a plain Node script."}, {"code": "const address = 'http://localhost:3000/';\nawait fetch(address + 'api/reset', { method: 'POST' });\n", "note": "The basket is one list shared by everybody, so the script empties it first with the shop's reset route. Node 22 has `fetch` built in."}, {"code": "const browser = await puppeteer.launch();\nconsole.log(`browser: ${await browser.version()}`);\nconst page = await browser.newPage();\nawait page.goto(address);\n", "note": "`launch()` starts a Chrome with no window and connects to it over CDP. The second line prints which browser answered."}, {"code": "await page.waitForSelector('[data-testid=product-banana] button');\nawait page.click('[data-testid=product-banana] button');\n", "note": "The cards are drawn by `app.js` after the page loads. `page.click` does not wait: if the button is not there yet, it throws. So the line before it waits for the button to exist."}, {"code": "await page.waitForFunction(\n  () => document.querySelector('[data-testid=basket-count]').textContent === '1',\n);\n", "note": "The click sends a request, and the count changes when the answer comes back. This function runs inside the page, again and again, until it returns true."}, {"code": "const count = await page.$eval('[data-testid=basket-count]', (el) => el.textContent);\nconsole.log(`basket: ${count}`);\n\nawait browser.close();", "note": "`$eval` finds the element and runs the function on it in the page, and only the text comes back to Node. Without `close()` the script never ends."}]}
```

With the shop started by `npm start` in one terminal, run it in another:

```
ana@laptop:~/quitanda$ node puppeteer/basket.mjs
browser: Chrome/141.0.7390.37
basket: 1
```

**Every wait in that script is written by hand**, and each one stands for something the shop does
later than the line before it. `app.js` draws the cards after `/api/products` answers, so the
script waits for the button. The basket changes after `POST /api/basket` answers, so the script
waits for the count.

## Take one wait out

Delete the `waitForFunction` call, all three of its lines, and run the script five times:

```
ana@laptop:~/quitanda$ for i in 1 2 3 4 5; do node puppeteer/basket.mjs | grep basket; done
basket: 0
basket: 0
basket: 0
basket: 1
basket: 1
```

**Three runs said 0 and two said 1**, from the same script against the same shop. The click was
sent every time. What changed between runs is whether the answer to `POST /api/basket` had come
back before `$eval` read the count, and on this machine the read won three times out of five. Your
split will differ, and five to nothing either way is possible. A script that is right on some runs
and wrong on others is the worst kind a test suite can hold, because a rerun makes the failure
look like it went away.

Nothing in the script was wrong in the sense a reviewer would spot: every line does what it says.
What is missing is a line saying *and now wait for the shop*. Lesson 3 is about this race between a
test and an asynchronous page, and lesson 13 about every way to wait for it. Put the three lines
back before going on.
