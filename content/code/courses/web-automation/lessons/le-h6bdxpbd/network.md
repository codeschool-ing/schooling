---
title: The Network panel, and a robot that reads it
version: 1
---

The **Network** tab lists every request the page makes, while the panel is open: the address, the
**status** the server answered, the **type** of thing asked for, how big it was and how long it
took, and a bar for each one on a shared timeline called the **waterfall**. Open it, reload the
shop, and five rows appear.

For a tester this panel answers the question a screen cannot: **did the page ask for the right
thing, and what came back?** A basket that shows the wrong total is either a page that drew a
right answer wrongly or a server that answered wrongly, and the Network tab says which in one
click: select the request, and its **Response** tab shows exactly what the server sent.

## The same list, printed

Everything the panel shows comes from the browser, and a program that drives the browser can ask
for it too. This script opens the shop in a Chromium nobody is watching, prints one line for each
response as it arrives, and prints whatever the page writes to its console, which the next section
is about. It is the first program in this course that drives a browser, and it uses Playwright's
library rather than its test runner. Save it as `look.mjs`:

```javascript
// What the Network and Console panels show, printed by a browser nobody
// is watching. Run it with the shop started: node look.mjs [address]
import { chromium } from '@playwright/test';

const address = process.argv[2] ?? 'http://localhost:3000/';
const browser = await chromium.launch();
const page = await browser.newPage();
const start = Date.now();
const ms = () => String(Date.now() - start).padStart(5) + ' ms';

page.on('response', (response) => {
  const request = response.request();
  const path = new URL(response.url()).pathname;
  console.log(`${ms()}  ${response.status()} ${request.method()} ${path}  (${request.resourceType()})`);
});
page.on('console', (message) => console.log(`${ms()}  console.${message.type()}: ${message.text()}`));
page.on('pageerror', (error) => console.log(`${ms()}  uncaught error: ${error.message}`));

await page.goto(address);
await page.waitForLoadState('networkidle');
await browser.close();
```

With the shop started in one terminal, run it in another:

```
ana@laptop:~/quitanda$ node look.mjs
   10 ms  200 GET /  (document)
   17 ms  200 GET /style.css  (stylesheet)
   19 ms  200 GET /app.js  (script)
   38 ms  200 GET /api/products  (fetch)
   45 ms  200 GET /api/basket  (fetch)
```

The same five rows the panel shows, in the order they arrived, with the milliseconds since the
script asked for the page. Your times will differ; the order will not, and the order is what
matters:

- **the document comes first**, because nothing else is known until it arrives;
- **the stylesheet and the script come next, together**, because the browser found both while
  reading the HTML and asked for both at once;
- **the two `fetch` requests come last**, because they are made by `app.js`, and `app.js` cannot
  ask for anything until it has arrived and run.

That last gap is the whole of lesson 3. The page is on screen, empty, between the moment the
document arrives and the moment `/api/products` answers. In the Network tab the column called
**Initiator** says the same thing in another way: the document was asked for by you, the script by
the document, and the two fetches by the script.

## What the server saw

The other side of the conversation is the server's. Started with `QUITANDA_LOG=1`, the shop prints
every request it answers, and here is its terminal while `look.mjs` ran once:

```
ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start

> start
> node app/server.js

quitanda is listening on http://localhost:3000
GET / 200
GET /style.css 200
GET /app.js 200
GET /api/products 200
GET /api/basket 200
```

The two lists agree, and they will not always. A request the browser lists and the server does not
was answered by the browser itself, from its cache, and lesson 4 makes that happen on purpose. A
request the server logs and the browser does not show came from somebody else, and with one shared
basket, as lesson 15 shows, that is a problem.

## Three things worth knowing in the panel

- **Preserve log** keeps the list when the page navigates. Without it, clicking a link that loads
  a new page clears the requests that led to it, which are often the ones you wanted.
- **Disable cache**, while the panel is open, makes the browser ask the server for everything.
  Lesson 4 is about when a test should do the same and when it should not.
- **Copy as cURL**, on a request's right-click menu, gives you the request as a command you can
  run in a terminal, which is how a defect report shows that the server, not the page, answered
  wrongly. `manual-testing` lesson 15 is about what evidence a report needs.
