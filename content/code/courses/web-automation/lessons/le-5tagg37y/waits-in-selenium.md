---
title: Two kinds of wait, briefly
version: 1
---

**A Selenium command asks once.** `findElement` sends one request, the driver looks at the page as
it is at that instant, and the answer is an element or an error. Nothing in the protocol waits for
the page to finish what its scripts are doing. So Selenium offers two ways to wait, and you need to
recognise both before lesson 13 compares them properly.

- An **implicit wait** is a setting on the session: `driver.manage().setTimeouts({ implicit: 3000 })`.
  From then on, every `findElement` and `findElements` keeps looking for up to three seconds
  before it gives up. It waits for an element **to exist**, and for nothing else.
- An **explicit wait** is a line in the test: `driver.wait(condition, 3000)`. It asks the
  condition again and again until it holds or the time runs out. The conditions in `until` cover
  an element existing, being visible, having a text, a title changing, and you can write your own.
  The test in section 03 used two of them.

The program below times both against the shop. It is not a test, so it lives as a plain script,
and with the shop running you run it with `node`. Save it as `selenium/waits.mjs`:

```javascript
// An implicit wait and an explicit one, timed. Run it with the shop
// started: node selenium/waits.mjs
import { Builder, By, until } from 'selenium-webdriver';
import chrome from 'selenium-webdriver/chrome.js';

const options = new chrome.Options().addArguments('--headless=new');
const driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
const timed = async (label, work) => {
  const start = Date.now();
  const result = await work();
  console.log(`${label.padEnd(36)} ${String(result).padEnd(14)} ${Date.now() - start} ms`);
};

try {
  await driver.get('http://localhost:3000/');

  await driver.manage().setTimeouts({ implicit: 3000 });
  await timed('implicit: the cards', async () =>
    (await driver.findElements(By.css('#products li'))).length);
  await timed('implicit: an element that is absent', async () =>
    (await driver.findElements(By.css('.error'))).length);

  await driver.manage().setTimeouts({ implicit: 0 });
  const toast = await driver.findElement(By.css('.toast'));
  await driver.findElement(By.css('[data-testid=product-banana] button')).click();
  await timed('explicit: the toast says', async () => {
    await driver.wait(until.elementTextIs(toast, 'Added Banana'), 3000);
    return await toast.getText();
  });
  await timed('explicit: the toast is empty again', async () => {
    await driver.wait(until.elementTextIs(toast, ''), 3000);
    return `"${await toast.getText()}"`;
  });
} finally {
  await driver.quit();
}
```

```
ana@laptop:~/quitanda$ node selenium/waits.mjs
implicit: the cards                  8              20 ms
implicit: an element that is absent  0              3036 ms
explicit: the toast says             Added Banana   22 ms
explicit: the toast is empty again   ""             2115 ms
```

Four lines, four facts.

**The implicit wait found the cards at once**, because they were already there. **And it spent
the whole three seconds on an element that is absent**, because an implicit wait cannot tell
*not yet* from *never*. Every check that something is missing, an error message that should not
appear, costs the full timeout, on every run.

**The explicit wait on the toast's text** returned as soon as the text was right. **The last one
waited for the toast to empty again**, which the shop's script does two seconds after a click, and
it took about that long. An implicit wait cannot express that at all: the toast never stops
existing, only its text changes.

Selenium's own documentation warns against **mixing the two** in one session, because their
timeouts combine in ways that are hard to predict; the script above sets the implicit wait back
to `0` before the explicit ones for that reason. Pick explicit waits, write them where the page
does something slowly, and leave the implicit wait at its default of zero, which is what the
`timeouts` in the session you opened by hand in section 02 said: `"implicit":0`.

What a good condition is, how long to wait, and why a test that sleeps for a fixed time is the
worst of the three, are lesson 13.
