---
title: The implicit wait, and where it stops
version: 1
---

**An implicit wait is a setting on a Selenium session that changes one thing: how long
`findElement` and `findElements` keep looking before they give up.** Lesson 8 set one and timed it.
It found the cards at once, because they were there, and it spent its whole timeout on an element
that was absent, because it cannot tell *not yet* from *never*. This section is about the part
lesson 8 left for later: what the implicit wait does not cover, and what happens when it meets an
explicit wait.

The common belief is that an implicit wait makes Selenium wait *for the page*: set ten seconds
once, and every step waits until the page is ready for it. Selenium's documentation describes
something narrower. In its words, the implicit wait is *"a global setting that applies to every
element location call for the entire session."* Element location means finding. Once a command
holds an element, reading its text, asking whether it is displayed, clicking it, all happen at
once, with no wait at all, whatever the setting says.

## A button that exists and does nothing

The page at `/ssr` from lesson 6 is the clearest case, because the element a test needs exists
from the first byte and is useless for a second and a half. This script sets an implicit wait of
five seconds and works the page twice: once trusting the implicit wait, once with the condition
written into the locator itself. Save it as `selenium/implicit.mjs`:

```schooling-example
{"language": "javascript", "file": "selenium/implicit.mjs", "parts": [{"code": "// What an implicit wait waits for, and what it does not.\n// Run it with the shop started: node selenium/implicit.mjs\nimport { Builder, By, until } from 'selenium-webdriver';\nimport chrome from 'selenium-webdriver/chrome.js';\n\nconst shop = 'http://localhost:3000';\nconst options = new chrome.Options().addArguments('--headless=new');\nconst driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();\nlet start = Date.now();\nconst say = (text) => console.log(`${String(Date.now() - start).padStart(5)} ms  ${text}`);", "note": "A headless Chrome, as in lesson 8, and `say()`, which prints a line with the milliseconds since `start`. Each experiment below resets `start`, so every time is counted from its own beginning."}, {"code": "\ntry {\n  await fetch(`${shop}/api/reset`, { method: 'POST' });\n  await driver.manage().setTimeouts({ implicit: 5000 });\n  console.log('implicit wait: 5000 ms');", "note": "The basket is emptied, and the implicit wait is set once for the whole session: from here on, every `findElement` keeps looking for up to five seconds."}, {"code": "\n  await driver.get(`${shop}/ssr`);\n  start = Date.now();\n  const button = await driver.findElement(By.css('[data-testid=product-banana] button'));\n  say('found the banana button');\n  await button.click();\n  const count = await driver.findElement(By.css('[data-testid=basket-count]'));\n  say(`clicked it; the basket says ${await count.getText()}`);\n  await driver.sleep(2000); // only to show that the click was lost\n  say(`two seconds later it says ${await count.getText()}`);", "note": "The first experiment trusts the implicit wait. It finds the button, clicks it and reads the count. The sleep is not a way to test; it is there to prove that the click was lost rather than slow."}, {"code": "\n  await driver.get(`${shop}/ssr`);\n  start = Date.now();\n  await driver.findElement(By.css('body[data-ready=\"true\"]'));\n  say('found body[data-ready=\"true\"]');\n  await driver.findElement(By.css('[data-testid=product-banana] button')).click();\n  await driver.findElement(By.xpath('//span[@data-testid=\"basket-count\" and text()=\"1\"]'));\n  say('clicked, and found a count that says 1');", "note": "The second puts the condition into the locator. The `<body>` matches only once `ssr.js` has set `data-ready`, and the XPath matches the count only once its text is `1`, so finding each one is waiting for it."}, {"code": "\n  start = Date.now();\n  await driver.wait(until.elementLocated(By.css('.error')), 1000).catch((e) => say(e.message));\n  await driver.manage().setTimeouts({ implicit: 0 });\n  console.log('implicit wait: 0 ms');\n  start = Date.now();\n  await driver.wait(until.elementLocated(By.css('.error')), 1000).catch((e) => say(e.message));\n} finally {\n  await driver.quit();\n}", "note": "The third mixes the two: an explicit wait of one second for an element the shop never draws, first with the implicit wait still at five seconds, then with it at zero. The `catch` prints the timeout instead of ending the script."}]}
```

With the shop started:

```
ana@laptop:~/quitanda$ node selenium/implicit.mjs
implicit wait: 5000 ms
   30 ms  found the banana button
  144 ms  clicked it; the basket says 0
 2162 ms  two seconds later it says 0
 1511 ms  found body[data-ready="true"]
 1683 ms  clicked, and found a count that says 1
 5044 ms  Waiting for element to be located By(css selector, .error)
Wait timed out after 5043ms
implicit wait: 0 ms
 1063 ms  Waiting for element to be located By(css selector, .error)
Wait timed out after 1063ms
```

## Reading it

**The implicit wait found the button in 30 ms, and the click was lost.** The button is in the
HTML the server sends, so there was nothing to wait for. Its handler was still on its way, so the
click did nothing, and two seconds later the basket still said `0`. The implicit wait did exactly
its job; its job was the wrong one.

**The second attempt worked, and it is still the implicit wait doing it.** `body[data-ready="true"]`
matches nothing until `ssr.js` has run, so finding it took 1511 ms, about as long as the script
takes to arrive. The XPath does the same for the count: it matches the `<span>` only once its text
is `1`. A condition written into a locator is a condition the implicit wait can wait for. That
covers anything a selector can say, attributes, text in XPath, an element's position in the tree,
and nothing else: not *the text has changed*, not *two elements agree*, not *the element has
gone*.

## Mixing the two

The last two lines of the output are the ones to remember. Selenium's documentation puts it as a
warning: *"Do not mix implicit and explicit waits. Doing so can cause unpredictable wait times.
For example, setting an implicit wait of 10 seconds and an explicit wait of 15 seconds could
cause a timeout to occur after 20 seconds."*

The script shows one shape of that. **An explicit wait of one second, with the implicit wait at
five, took 5043 ms to give up.** With the implicit wait at zero, the same line took 1063 ms.
The reason is in how the two fit together. `until.elementLocated` calls `findElements`, and with
an implicit wait set, that one call does not come back for five seconds. `driver.wait` checks its
own clock only between calls to its condition, so it found out that its second had passed when the
first call returned, four seconds late. The installed code shows it: the wait compares the elapsed
time only after each evaluation, then waits 200 ms before the next.

The two timeouts do not add up in any fixed way. They interleave, and the result depends on how
many times the condition calls `findElements` and when. That is what *unpredictable* means in the
warning, and the advice that follows from it is the one lesson 8 gave: **leave the implicit wait at
its default of zero and write the waits you need where you need them.**
