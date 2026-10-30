---
title: A position from Playwright
version: 1
---

**On the web, `expo-location` asks the browser**, through the same `navigator.geolocation` every web page
uses, and a browser asks the person exactly as a phone does. Playwright can answer for the person: a
context can be granted the `geolocation` permission and handed a position, which is what a test of a
location feature needs. Save `where.mjs`:

```javascript
// where.mjs: on This week, turn on "Note where I study", mark a session done, and print what the screen
// says. The browser is given a position, as a phone's GPS would give one, unless --deny is passed.
//
//   node where.mjs URL BUTTON [--deny]
import { chromium } from "playwright";

const [url, button, flag] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext(
  flag === "--deny" ? {} : { permissions: ["geolocation"], geolocation: { latitude: -23.561414, longitude: -46.655881 } },
);
const page = await context.newPage();
await page.goto(url);
const toggle = page.getByRole("switch", { name: "Note where I study" });
await toggle.click();
await page.waitForTimeout(1000);
console.log("switch on:", await toggle.isChecked());
const alert = page.getByRole("alert");
if (await alert.count()) console.log("alert:", await alert.innerText());
await page.getByRole("button", { name: button }).click();
await page.getByText(/^Logged on this phone: /).waitFor();
for (const line of await page.getByText(/^Logged on this phone: |^Studied at /).allInnerTexts()) console.log(line);
await browser.close();
```

The position is a street in São Paulo, to six decimal places, as a GPS would give it. Start the server,
export, and serve with lesson 14's `static.mjs`, since the journal is SQLite:

```
ana@dev:~/planner$ node where.mjs 'http://localhost:8082/week?today=2026-10-21' 'Mark 20 min on 2026-10-21 done'
switch on: true
Logged on this phone: Guitar 20 min
Studied at -23.56, -46.66 (1)
ana@dev:~/planner$ node where.mjs 'http://localhost:8082/week?today=2026-10-21' 'Mark 30 min on 2026-10-22 done' --deny
switch on: false
alert: Without your location, sessions are logged without a place. You can allow it in Settings.
Logged on this phone: Spanish A2 30 min
```

**The first browser was allowed and handed a position; the journal kept `-23.56, -46.66`**, two decimal
places of the six. The second was never granted anything, so the browser refused when asked, the switch
stayed off, the alert said what that means, and the session was logged anyway, without a place. It is a
new browser, so its journal holds only that one session.

*What a browser cannot show is the phone's own dialog, with its precise-or-approximate choice; the
planner's behaviour does not depend on which one the person picks, and this course did not see either
dialog.*
