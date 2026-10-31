---
title: Three browsers, three answers
version: 1
---

On the web the module asks `Intl`, and a Playwright page can be opened in any locale. Save `note.mjs`:

```javascript
// note.mjs: open the planner in a browser set to a locale, and print what it says about the week.
//
//   node note.mjs URL LOCALE
import { chromium } from "playwright";

const [url, locale] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage({ locale });
await page.goto(url);
console.log(`${locale}:`, await page.getByText(/^Your phone's calendar/).innerText());
await browser.close();
```

Start the server, export, and serve with `static.mjs`, then open the planner in Brazilian Portuguese,
British English and European Portuguese:

```
ana@dev:~/planner$ node note.mjs 'http://localhost:8082/?today=2026-10-21' pt-BR
pt-BR: Your phone's calendar starts the week on Sunday; the planner's weeks start on Monday.
ana@dev:~/planner$ node note.mjs 'http://localhost:8082/?today=2026-10-21' en-GB
en-GB: Your phone's calendar starts the week on Monday; the planner's weeks start on Monday.
ana@dev:~/planner$ node note.mjs 'http://localhost:8082/?today=2026-10-21' pt-PT
pt-PT: Your phone's calendar starts the week on Sunday; the planner's weeks start on Monday.
```

**Brazil says Sunday, the United Kingdom Monday, and Portugal Sunday**, the same answer the JVM gave. Three
implementations, Java's calendar, Chromium's `Intl` and, on a phone, Android's or Apple's own, agree
because they read the same CLDR data. When the module and the browser disagree with what you expected,
check the data before the code.
