---
title: Looking at it, in your browser and from the terminal
version: 1
---

**`npm run dev` serves the planner while you work on it**, and reloads the page whenever you save a
file. Start it in a terminal of its own with `npm run dev` and leave it running. It prints the address it
serves, `http://localhost:5173/`, and waits.

Open `http://localhost:5173/?today=2026-10-21` in your browser. The page lists the three courses
under a line saying this week holds 125 minutes and 75 of them are done: the week of Monday 19
October, which has four of the six sessions. Press **Statistics**, add a session, mark one done, and
watch the line change. `q` and Enter in the terminal stop the server.

## The same page, in a transcript

A window cannot be pasted into a lesson, so the transcripts in this course show a page another way:
**the accessibility tree**, which is what the browser hands a screen reader. Every heading, button,
field and line of text is in it, with its role and its name, and nothing that is only decoration.
It is also a check on your own app: a control missing from the tree is a control a screen-reader
user cannot find.

The program that prints it is `look.mjs`, built on **Playwright**, the library that drives a real
browser from a program. Install it into the planner at the version this course used, then the
browser it drives:

```
ana@dev:~/planner$ npm install -E -D playwright@1.63.0

added 4 packages, and audited 21 packages in 991ms

found 0 vulnerabilities
```

```sh
npx playwright install chromium
```

*That last line downloads Chromium and was not run where this course was recorded:
that machine could not reach Playwright's download server, and it already had the same build that
Playwright 1.63.0 asks for, which every transcript used. On Linux, add `--with-deps` to it and it
installs the system libraries Chromium needs as well, asking for your password to do so.*

Now the program. Save it in the planner's folder as `look.mjs`. You do not have to follow every line
today; lesson 4 is the first to use the permission options.

```javascript
// look.mjs: open a page in Chromium and print what a screen reader is given.
//
//   node look.mjs URL [--click NAME] [--fill LABEL=TEXT] [--grant PERMISSION]
//                     [--geo LAT,LON] [--wait MS] ...
//
// The options run in order, after the page has loaded. --click presses the
// button whose accessible name is NAME, --fill types TEXT into the field
// labelled LABEL, --grant and --geo answer the permission questions a page
// asks, and --wait lets timers run. Then it prints the accessibility tree of
// the page, and every console message and uncaught error on the way.
import { chromium } from "playwright";

const [url, ...args] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext({ locale: "en-GB", timezoneId: process.env.TZ });
const page = await context.newPage();
page.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
page.on("pageerror", (e) => console.log(`uncaught: ${e.message}`));
await page.goto(url);
for (let i = 0; i < args.length; i += 2) {
  const [flag, value] = [args[i], args[i + 1]];
  if (flag === "--click") await page.getByRole("button", { name: value, exact: true }).first().click();
  else if (flag === "--fill") {
    const [label, text] = value.split("=");
    await page.getByLabel(label, { exact: true }).fill(text);
  } else if (flag === "--grant") await context.grantPermissions([value], { origin: new URL(url).origin });
  else if (flag === "--geo") {
    const [latitude, longitude] = value.split(",").map(Number);
    await context.setGeolocation({ latitude, longitude });
  } else if (flag === "--wait") await page.waitForTimeout(Number(value));
  else throw new Error(`look: unknown option ${flag}`);
}
console.log(await page.locator("body").ariaSnapshot());
await browser.close();
```

With `npm run dev` still running in its own terminal, open the planner and press a course:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21'
console.debug: [vite] connecting...
console.debug: [vite] connected.
- main:
  - heading "Study planner" [level=1]
  - paragraph: "This week: 75 of 125 minutes done"
  - list:
    - listitem:
      - button "Spanish A2"
    - listitem:
      - button "Statistics"
    - listitem:
      - button "Guitar"
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Statistics --fill Date=2026-10-23 --fill Minutes=25 --click 'Add session'
console.debug: [vite] connecting...
console.debug: [vite] connected.
- main:
  - button "All courses"
  - heading "Statistics" [level=1]
  - paragraph: "This week: 75 of 150 minutes done"
  - list:
    - listitem: 2026-10-20, 45 min done
    - listitem:
      - text: 2026-10-26, 60 min
      - button "Mark done"
    - listitem:
      - text: 2026-10-23, 25 min
      - button "Mark done"
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes"
  - button "Add session"
```

The two `console.debug` lines are Vite's own: the dev server puts a small script in the page that
reloads it when a file changes, and that script says it connected. A built site has neither. Each
other line is one thing a screen reader announces. `heading "Study planner" [level=1]` is the `<h1>`,
`button "Spanish A2"` is a button whose name is its text, and `list` and `listitem` are the `<ul>`
and its `<li>`s. The second run pressed **Statistics**, typed a date and a length into the two
fields the form labels, 23 October and 25 minutes, and pressed **Add session**. The new session is
the last item, and the week's total went from 125 to 150 minutes, because 23 October falls in the
same week.

The data is in memory only. **Reload the page and the added session is gone**, because nothing has
saved it anywhere. Lesson 4 fixes that with a Capacitor plugin, which is the first time the app
needs something a phone gives it and a page does not.
