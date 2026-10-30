---
title: The web build, and a program that reads it
version: 1
---

**The same project runs in a browser**, with `react-native-web` drawing each component as HTML: a
`<View>` becomes a `<div>`, a `<Text>` a `<div>` or `<span>` with text in it, and the roles you give
them become ARIA roles. It is not the native app, and the differences are real: no native scrolling
physics, no camera, a different keyboard. But components, state, layout and logic all run, which is
most of what lessons 4 to 11 build, and it needs nothing but the computer you have.

## Exporting it

`npx expo export --platform web` writes a static site into `dist/`, the way lesson 1 wrote an Android
bundle. `npx expo serve` serves that folder on a port of your choice. Start it in the second terminal
and leave it there:

```
ana@dev:~/planner$ npx expo export --platform web > /dev/null 2>&1
ana@dev:~/planner$ ls dist
_expo
favicon.ico
index.html
metadata.json
```

`index.html` is the page, `_expo/` holds the JavaScript bundle, and `assets/` the images and fonts.
Open `http://localhost:8082/?today=2026-10-21` in your browser and the planner's first screen is
there. The `?today=` pins this course's week, as `src/today.ts` reads it.

## A program that reads the page

Looking at a screen is one way to check it. **A transcript of what assistive technology is told is a
better one**, because it is exact, it can be compared from one day to the next, and it checks that a
screen reader has something to read. Every web transcript in this course comes from the program
below, built on **Playwright**, which drives a real Chromium from Node.js. You installed it with the
project; it also needs the browser itself, once:

```sh
npx playwright install chromium
```

Then save this in the project as `look.mjs`. You do not need to follow every line today: lesson 11 is
the first to use `--fill`, lesson 13 `--file`, and lesson 15 `--grant` and `--geo`.

```javascript
// look.mjs: open a page in Chromium and print what a screen reader is given.
//
//   node look.mjs URL [--click NAME] [--fill LABEL=TEXT] [--grant PERMISSION]
//                     [--geo LAT,LON] [--file LABEL=PATH] [--wait MS] ...
//
// The options run in order, after the page has loaded. --click presses the
// control whose accessible name is NAME, --fill types TEXT into the field
// labelled LABEL, --grant and --geo answer the permission questions a page
// asks, --file picks PATH in the file chooser that pressing LABEL opens, and
// --wait lets timers run. Then it prints the accessibility tree of the page,
// and every console message and uncaught error on the way.
import { chromium } from "playwright";

const [url, ...args] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext({ locale: "en-GB", timezoneId: process.env.TZ });
const page = await context.newPage();
page.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
page.on("pageerror", (e) => console.log(`uncaught: ${e.message}`));
for (let i = 0; i < args.length; i += 2) {
  if (args[i] === "--grant") await context.grantPermissions([args[i + 1]], { origin: new URL(url).origin });
  if (args[i] === "--geo") {
    const [latitude, longitude] = args[i + 1].split(",").map(Number);
    await context.setGeolocation({ latitude, longitude });
  }
}
await page.goto(url);
await page.waitForLoadState("networkidle");
for (let i = 0; i < args.length; i += 2) {
  const [flag, value] = [args[i], args[i + 1]];
  if (flag === "--click") await page.getByRole("button", { name: value, exact: true }).first().click();
  else if (flag === "--fill") {
    const [label, text] = value.split("=");
    await page.getByLabel(label, { exact: true }).fill(text);
  } else if (flag === "--file") {
    const [label, path] = value.split("=");
    const chooser = page.waitForEvent("filechooser");
    await page.getByRole("button", { name: label, exact: true }).click();
    await (await chooser).setFiles(path);
  } else if (flag === "--wait") await page.waitForTimeout(Number(value));
  else if (flag !== "--grant" && flag !== "--geo") throw new Error(`look: unknown option ${flag}`);
}
await page.waitForTimeout(300);
console.log(await page.locator("body").ariaSnapshot());
await browser.close();
```

Ask it for the page:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done Spanish A2 Statistics Guitar"
```

That is the **accessibility tree**: every element a screen reader would announce, with its role and
its name. `role="heading"` on the first `<Text>` in `App.tsx` is why the first line says `heading`;
without it, the title would be one more piece of text, and a screen-reader user moving by headings
would not find the screen's title at all.

**The second line is the problem this tree is for.** The total and the three course names arrive as
one run of text, because nothing told the browser they are separate things: no paragraph, no list, no
buttons. On a phone the same screen would be read as one block too. Lesson 4 gives every element of
the planner the role it should have, and checks each one this way.

**What this does not show** is how the native app looks. The tree in a browser and the tree a phone
builds from the same components are close, because both come from the same props, but they are two
renderings, and lessons that depend on the difference say so.
