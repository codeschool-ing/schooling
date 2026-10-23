---
title: Reading a page as text
version: 1
---

**A transcript cannot hold a screenshot, so this course reads pages as text.** The tool that does it
is called `look`, and you build it in this section: a short program that opens a page in a real
browser, with no window, and prints two things. First, whatever the page wrote to its console while
it loaded, which is where React reports its mistakes. Then the page itself, as **an accessibility
snapshot**: one line per thing a screen reader would announce, with its role and its name.

You do not need `look` to follow the course, because your own browser shows you the same page. You
will want it anyway. It answers "what is on the screen right now" in a form you can compare with the
transcripts, and the snapshot is the same view of a page that lesson 22's tests query, so reading it
now is practice for writing those.

## Playwright, and a browser it can drive

`look` is built on **Playwright**, a library that drives a browser from a program. It goes in a
folder of its own, `~/react-tools`, so that the course's tools never mix with your app:

```
ana@dev:~$ mkdir ~/react-tools
ana@dev:~/react-tools$ npm init -y
Wrote to /home/ana/react-tools/package.json:

{
  "name": "react-tools",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}



ana@dev:~/react-tools$ npm install --save-exact playwright@1.63.0

added 2 packages, and audited 3 packages in 965ms

found 0 vulnerabilities
```

`npm init -y` wrote a `package.json` with every default accepted, and `--save-exact` pins the
library at 1.63.0 without a project `.npmrc`. **The browser is a separate download.** This asks
Playwright which one it wants and where it would put it:

```
ana@dev:~/react-tools$ npx playwright install --dry-run --only-shell chromium
Chrome Headless Shell 153.0.8010.12 (playwright chromium-headless-shell v1243)
  Install location:    /home/ana/.cache/ms-playwright/chromium_headless_shell-1243
  Download url:        https://cdn.playwright.dev/builds/cft/153.0.8010.12/linux64/chrome-headless-shell-linux64.zip

FFmpeg (playwright ffmpeg v1011)
  Install location:    /home/ana/.cache/ms-playwright/ffmpeg-1011
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/ffmpeg/1011/ffmpeg-linux.zip
```

Chrome Headless Shell is Chromium built to run with no window, 153 in this version of Playwright,
and it unpacks to about 260 MB. On Linux, `--with-deps` also installs the system libraries it needs
and asks for your password to do it:

```sh
npx playwright install --with-deps --only-shell chromium
```

*This one line was not run where the course was recorded.* That machine already had the same build,
153.0.8010.12, which every transcript in the course used. On Windows inside WSL, and in a virtual
machine, the line is the same. On a Mac, leave out `--with-deps`.

## The program

Save this in `~/react-tools` as `look.mjs`. You do not need to follow every line of it; the comment
at the top says what it does and which options it takes, and the transcripts use only those.

```javascript
// look.mjs: open a page of yours in Chromium and print what it shows, as text.
//
//   look URL [options]
//
// It prints what the page wrote to its console while it loaded, then the page
// itself as an accessibility snapshot: one line per thing a screen reader
// would announce, with its role and its name. That is what most transcripts
// in this course show instead of a screenshot.
//
// Options, applied in order after the page has loaded:
//   --do 'click ROLE NAME'   press the button, link or checkbox with that name
//   --do 'fill LABEL=TEXT'   type TEXT into the field labelled LABEL
//   --do 'press KEY'         a key on the keyboard, such as Tab or Enter
//   --do 'wait MS'           let the page run for MS milliseconds
//   --today YYYY-MM-DD       the date the page's clock reads (default: today)
//   --network                list every request the page made
//   --html SELECTOR          at the end, print that element's HTML as well
//   --quiet                  print the console only, without the snapshot
import { chromium } from "playwright";

const args = process.argv.slice(2);
const url = args.shift();
if (!url) {
  console.error("usage: look URL [--do ACTION]... [--today DATE] [--network] [--html SELECTOR]");
  process.exit(2);
}
const opt = { do: [] };
while (args.length) {
  const a = args.shift();
  if (a === "--do") opt.do.push(args.shift());
  else if (a === "--today") opt.today = args.shift();
  else if (a === "--network") opt.network = true;
  else if (a === "--html") opt.html = args.shift();
  else if (a === "--quiet") opt.quiet = true;
  else { console.error(`look: unknown option ${a}`); process.exit(2); }
}

const say = (s) => process.stdout.write(s + "\n");
const browser = await chromium.launch();
const page = await browser.newPage({ locale: "en-GB", timezoneId: process.env.TZ || undefined });
if (opt.today) await page.clock.setFixedTime(new Date(`${opt.today}T10:00:00`));

page.on("console", (m) => {
  const t = m.type();
  if (t === "debug") return; // Vite's own "[vite] connecting..." lines
  const text = m.text();
  if (text.startsWith("[vite]")) return;
  if (text.includes("Download the React DevTools")) return; // React's own advert
  say(t === "error" ? `[error] ${text}` : t === "warning" ? `[warn] ${text}` : text);
});
page.on("pageerror", (e) => say(`Uncaught ${e.name}: ${e.message}`));
if (opt.network) {
  const origin = new URL(url).origin;
  page.on("response", (r) => say(`net  ${r.request().method()} ${r.url().replace(origin, "")}  ${r.status()}`));
}

await page.goto(url, { waitUntil: "networkidle" });
for (const action of opt.do) {
  say(`-- ${action}`);
  const [verb, ...rest] = action.split(" ");
  if (verb === "click") {
    const [role, ...name] = rest;
    await page.getByRole(role, { name: name.join(" "), exact: true }).click();
  } else if (verb === "fill") {
    const [label, ...text] = rest.join(" ").split("=");
    await page.getByLabel(label, { exact: true }).fill(text.join("="));
  } else if (verb === "press") await page.keyboard.press(rest[0]);
  else if (verb === "wait") await page.waitForTimeout(Number(rest[0]));
  else say(`look: unknown action ${verb}`);
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(100);
}
await page.waitForTimeout(200);
if (!opt.quiet) say((await page.locator("body").ariaSnapshot()).trimEnd());
if (opt.html) say(await page.locator(opt.html).first().evaluate((e) => e.outerHTML));
await browser.close();
```

Then a three-line command, so that `look` works from any folder. Save it as `~/.local/bin/look`, the
folder `node` is linked from, and make it executable:

```sh
#!/bin/sh
exec node ~/react-tools/look.mjs "$@"
```

```
ana@dev:~$ chmod +x ~/.local/bin/look
```

## Using it

With the development server still running in its own terminal:

```
ana@dev:~/planner$ look http://localhost:5173/
- img "React logo"
- img "Vite logo"
- heading "Get started" [level=1]
- paragraph:
  - text: Edit
  - code: src/App.tsx
  - text: and save to test
  - code: HMR
- button "Count is 0"
- heading "Documentation" [level=2]
- paragraph: Your questions, answered
- list:
  - listitem:
    - link "Explore Vite":
      - /url: https://vite.dev/
  - listitem:
    - link "Learn more":
      - /url: https://react.dev/
- heading "Connect with us" [level=2]
- paragraph: Join the Vite community
- list:
  - listitem:
    - link "GitHub":
      - /url: https://github.com/vitejs/vite
  - listitem:
    - link "Discord":
      - /url: https://chat.vite.dev/
  - listitem:
    - link "X.com":
      - /url: https://x.com/vite_js
  - listitem:
    - link "Bluesky":
      - /url: https://bsky.app/profile/vite.dev
```

Read it as the outline a screen reader would give. Each `-` line is one element, indented under the
one that contains it: an image announced as "React logo", a heading at level 1, a paragraph made of
text and code, a button whose name is its label. The hero image is missing from the list because the
template gave it `alt=""`, which says it is decoration, and a screen reader skips it. Links show
where they go on the `/url:` line underneath.

Nothing came before the snapshot, which means the page wrote nothing to its console. React's
development build does print one line, an advert for its browser extension, and `look` leaves it
out; anything else the page says appears above the snapshot, marked `[error]` or `[warn]` when it
is one.

`--do` performs an action before the snapshot is taken, and the actions run in the order given:

```
ana@dev:~/planner$ look http://localhost:5173/ --do 'click button Count is 0' --do 'click button Count is 1'
-- click button Count is 0
-- click button Count is 1
- img "React logo"
- img "Vite logo"
- heading "Get started" [level=1]
- paragraph:
  - text: Edit
  - code: src/App.tsx
  - text: and save to test
  - code: HMR
- button "Count is 2"
- heading "Documentation" [level=2]
- paragraph: Your questions, answered
- list:
  - listitem:
    - link "Explore Vite":
      - /url: https://vite.dev/
  - listitem:
    - link "Learn more":
      - /url: https://react.dev/
- heading "Connect with us" [level=2]
- paragraph: Join the Vite community
- list:
  - listitem:
    - link "GitHub":
      - /url: https://github.com/vitejs/vite
  - listitem:
    - link "Discord":
      - /url: https://chat.vite.dev/
  - listitem:
    - link "X.com":
      - /url: https://x.com/vite_js
  - listitem:
    - link "Bluesky":
      - /url: https://bsky.app/profile/vite.dev
```

Two clicks, and the button's name went from "Count is 0" to "Count is 2". Each `look` opens a fresh
page, so the count starts from zero every time; the button you press in your own browser keeps its
own count. **A button is found by its role and its name, never by where it sits on the page**, and
that is the same rule lesson 22's tests follow.
