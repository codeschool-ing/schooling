---
title: The tree the browser builds
version: 1
---

**Playwright can print the accessibility tree of any part of a page**, in the same YAML it uses for its
own assertions. Here is a small program that prints it for each address it is given. Save it as
`server/tree.mjs`:

```javascript
// server/tree.mjs
import { chromium } from "@playwright/test";

const browser = await chromium.launch();
const page = await browser.newPage();
await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
for (const address of process.argv.slice(2)) {
  await page.goto(address);
  await page.getByRole("heading", { level: 1 }).waitFor();
  console.log(`${address}\n${await page.locator("body").ariaSnapshot()}\n`);
}
await browser.close();
```

`ariaSnapshot()` returns each element of the tree as one line: its role, its name in quotes, and its state
in brackets, with what it contains indented below it. Elements that carry no role a screen reader would
announce, the planner's `div`s, are left out, and their contents are listed in their place.

```
ana@dev:~/planner$ node server/tree.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/
- heading "Study planner" [level=1]
- list:
  - listitem:
    - link "HTML and CSS":
      - /url: "#/course/html-css"
    - text: 45 min this week
  - listitem:
    - link "JavaScript":
      - /url: "#/course/javascript"
    - text: 90 min this week
  - listitem:
    - link "Git":
      - /url: "#/course/git"
    - text: 25 min this week
- paragraph: "This week: 160 min"

http://localhost:5173/#/course/javascript
- link "←":
  - /url: "#/"
- heading "JavaScript" [level=1]
- list:
  - listitem: 2026-10-20 · 60 min done
  - listitem:
    - text: 2026-10-22 · 30 min
    - button "Done"
- text: Date
- textbox "Date"
- text: Minutes
- spinbutton "Minutes"
- text: Note
- textbox "Note"
- button "Add session"
- paragraph: "This week: 90 min"
```

## Reading it as a screen reader would

This is close to what a screen reader user gets, and four things in it are worth a pause.

- **The back link is called *←*.** That is its whole name. A screen reader reads the symbol's name, which
  is something like *left arrow* depending on the reader, and the person has to guess where it goes.
- **There is no landmark.** Nothing says *main*: the page is a heading, a list and some fields floating at
  the top level, so jumping to the main content goes nowhere.
- **The fields are named by their labels**, *Date*, *Minutes*, *Note*, which is lesson 3's work. The
  `text:` lines beside them are the labels' words, read once more in browse mode.
- **The total at the foot changes when a session is added, and nothing says so.** The tree shows what is
  there; it cannot show that a person who pressed **Add session** was told nothing, and lost the focus as
  well, as lesson 11's walk by hand finds.

The next sections fix each of them, and each fix starts with a test that reads the tree.
