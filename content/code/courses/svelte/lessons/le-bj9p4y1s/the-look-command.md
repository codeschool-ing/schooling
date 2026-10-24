---
title: The look command
version: 1
---

**A page is something you look at, and a transcript can only show text, so this course reads pages
the way a screen reader does.** `look` is a short program you will save in a moment. It opens an
address in Chromium, a real browser with no window, and prints the page as a tree of roles and
names: a heading and its level, a list and its items, a button and the words on it. That tree is
exactly what assistive technology announces, so every time you read one you are also checking that
the page makes sense to somebody who cannot see it.

If you have a desktop, open the same addresses in your own browser too. `look` is for the
transcripts, and for a virtual machine with no screen; it is not a replacement for looking.

## Playwright and its browser

`look` is built on **Playwright**, a library that drives a real browser from a program. Lesson 19
uses it again to test the planner. It lives in a folder of its own, `~/svelte-tools`, so the
course's tools never mix with the project:

```
ana@dev:~$ mkdir ~/svelte-tools && cd ~/svelte-tools
ana@dev:~/svelte-tools$ npm init -y > /dev/null
ana@dev:~/svelte-tools$ npm install --save-exact playwright@1.63.0

added 2 packages, and audited 3 packages in 2s

found 0 vulnerabilities
ana@dev:~/svelte-tools$ npx playwright install --dry-run --only-shell chromium
Chrome Headless Shell 153.0.8010.12 (playwright chromium-headless-shell v1243)
  Install location:    /home/ana/.cache/ms-playwright/chromium_headless_shell-1243
  Download url:        https://cdn.playwright.dev/builds/cft/153.0.8010.12/linux64/chrome-headless-shell-linux64.zip

FFmpeg (playwright ffmpeg v1011)
  Install location:    /home/ana/.cache/ms-playwright/ffmpeg-1011
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/ffmpeg/1011/ffmpeg-linux.zip
```

`--save-exact` writes the version as `1.63.0` rather than `^1.63.0`, so the folder keeps this
version until you change it. **The browser is a separate download**, and `--dry-run` asks
Playwright where it would put it and which build it wants: Chrome Headless Shell 153, the build of
Chromium that runs with no window. The download itself is about 260 MB once unpacked, and on Linux
`--with-deps` also installs the system libraries it needs, asking for your password to do it:

```sh
npx playwright install --with-deps --only-shell chromium
```

*This one line was not run where the course was recorded. That machine cannot reach Playwright's
download server, and already had the same build, 153.0.8010.12, which every `look` in this course
used.*

## The program

Save this as `~/svelte-tools/look.mjs`. You do not need to follow every line yet. It opens the
address, carries out what the options ask in order, and prints the path it ended up on, the page's title
when it has one, and the tree of the page's `<main>`, or of the whole page when there is no
`<main>`:

```javascript
// look.mjs: open a page in Chromium and print what is on it, as the tree of
// roles and names a screen reader is given. The transcripts in this course
// that start with `look` were made with it.
//
//   look URL [options]
//
// Options, carried out in order once the page has loaded:
//   --click NAME        press the button or link whose name is NAME
//   --fill LABEL=TEXT   type TEXT into the field whose label is LABEL
//   --check LABEL       tick or untick the checkbox whose label is LABEL
//   --press KEY         press a key, such as Enter or ArrowRight
//   --wait MS           let the page run for MS milliseconds
//   --no-js             open the page with JavaScript turned off
//   --reduce-motion     open it as a browser set to prefer reduced motion
//   --console           print what the page wrote to its console, too
// At the end it prints the path it is on, the page's title if it has one,
// and the tree of <main>.
import { chromium } from "playwright";

const [url, ...args] = process.argv.slice(2);
if (!url) { console.error("usage: look URL [options]"); process.exit(2); }
const browser = await chromium.launch();
const page = await browser.newPage({
  javaScriptEnabled: !args.includes("--no-js"),
  reducedMotion: args.includes("--reduce-motion") ? "reduce" : "no-preference",
});
if (args.includes("--console")) page.on("console", (m) => console.log(`console: ${m.text()}`));
page.on("pageerror", (e) => console.log(`error: ${e.message}`));
await page.goto(url, { waitUntil: "networkidle" });

for (let i = 0; i < args.length; i++) {
  const [flag, value] = [args[i], args[i + 1]];
  if (["--no-js", "--console", "--reduce-motion"].includes(flag)) continue;
  i++;
  console.log(`-- ${flag.slice(2)} ${value}`);
  if (flag === "--click") {
    const name = { name: value, exact: true };
    const target = page.getByRole("button", name).or(page.getByRole("link", name));
    const before = page.url();
    const isLink = (await target.evaluate((e) => e.tagName)) === "A";
    await target.click();
    // A link changes the address; wait until it has, before reading the page.
    if (isLink) await page.waitForURL((u) => u.href !== before, { timeout: 5000 }).catch(() => {});
  } else if (flag === "--fill") {
    const [label, ...text] = value.split("=");
    await page.getByLabel(label, { exact: true }).fill(text.join("="));
  } else if (flag === "--check") {
    await page.getByLabel(value, { exact: true }).click();
  } else if (flag === "--press") {
    await page.keyboard.press(value);
  } else if (flag === "--wait") {
    await page.waitForTimeout(Number(value));
  } else {
    console.error(`look: unknown option ${flag}`); process.exit(2);
  }
  await page.waitForLoadState("networkidle");
}

const where = new URL(page.url());
if (where.protocol.startsWith("http")) console.log(`at ${where.pathname}`);
if (await page.title()) console.log(`title: ${await page.title()}`);
const main = page.locator("main");
console.log(await ((await main.count()) ? main : page.locator("body")).ariaSnapshot());
await browser.close();
```

Then a command called `look` that runs it from wherever you are, the same way `javascript` lesson 1
made `page`:

```sh
# ~/.local/bin/look: run look.mjs from any folder
cat > ~/.local/bin/look <<'EOF'
#!/bin/sh
exec node "$HOME/svelte-tools/look.mjs" "$@"
EOF
chmod +x ~/.local/bin/look
```

## Checking it works

A page does not need a server to be looked at. An address starting `data:text/html,` carries the
page inside itself:

```
ana@dev:~$ look 'data:text/html,<main><h1>It works</h1><button>Press me</button></main>'
- main:
  - heading "It works" [level=1]
  - button "Press me"
```

**Each line is one thing a screen reader would announce.** `main` is the page's main region, and
everything indented under it is inside it. `heading "It works" [level=1]` is the `<h1>`, with its
text as its name and its level beside it; `button "Press me"` is the button, named by its text. A
page served at an `http://` address also gets a first line saying which path the browser ended on,
which matters from lesson 12, when links start moving between pages. When you read a tree like this later and a control has no
name, or a heading has the wrong level, you have found an accessibility defect before anybody had
to report it.
