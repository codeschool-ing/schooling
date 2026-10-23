---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, and if you took `javascript` most of it is
already there.** That course installed Node.js 22 in its first lesson. This one uses the same Node,
at the same version, installed the same way, so that nobody installs it twice or ends up with two.
What this course adds is small: a folder for your work, and a program called `look` that opens a page
in a real browser and prints what is on it, so that a transcript can show you what the screen showed.

## Three ways to have it

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Node.js and `look` on the computer you already use, with your own browser beside them | about 700 MB of disk once the browser and the projects are in | match as printed on Linux; close elsewhere |
| a virtual machine | Ubuntu Server 24.04 apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** A front-end course is easier where you already have a browser
with a window: you will open every page you build at `http://localhost:5173` and see it change as you
type. Node goes into `~/.local/node` and touches nothing else. On **Linux** the commands below work as
printed. On **Windows**, install WSL first (`wsl --install -d Ubuntu-24.04` in a PowerShell opened as
administrator, restart, open Ubuntu from the Start menu) and type everything inside it; the address a
dev server prints inside WSL opens in your Windows browser as it is. On a **Mac**, the installer for
Node.js 22 from nodejs.org gives you the same `node`, though that path was not run for this course, so
a path in a transcript may differ from yours.

**A virtual machine** is VirtualBox on Windows or Linux, or UTM on a Mac with an Apple chip, with
Ubuntu Server 24.04 LTS as the guest and the Linux steps inside it. It is how this course was
recorded. A server has no desktop, so there is no browser window there, and `look` is how you see a
page. **Online**, GitHub Codespaces and similar services give you a Linux terminal in a browser tab, on
a monthly allowance whose terms the company sets and can change; it was not run for this course, and
a dev server there is reached through an address the service gives you rather than `localhost`.

## Node.js, in brief

This is javascript lesson 1's section "Node.js", without the explanation; read it there if a step is
new to you. `uname -m` says which file to take: `x86_64` takes the one ending `linux-x64`, and
`aarch64` the one ending `linux-arm64`.

```
ana@dev:~$ uname -m
x86_64
ana@dev:~$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
ana@dev:~$ mkdir -p ~/.local/node ~/.local/bin
ana@dev:~$ tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ana@dev:~$ ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
ana@dev:~$ node --version
bash: line 13: node: command not found
```

**The last line fails, and that is expected.** `~/.local/bin` joins your `PATH`, the list of folders
the shell searches for a command, only in a terminal opened after the folder exists. Close this one,
open a new one, and check both programs:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ npm config set update-notifier false
ana@dev:~$ mkdir ~/vue ~/vue-tools
```

`node` must say `v22.22.0`, or a later 22. The third line stops npm offering a newer npm under every
install: the npm that came with Node 22 is the one this course uses. And **`~/vue` is where your work
goes**, with `~/vue-tools` beside it for the one tool of the course.

## The look command

`look` is built on **Playwright**, a library that drives a real browser from a program; javascript
lesson 1 used it for its `page` command. This course pins its own copy, at an exact version, in
`~/vue-tools`:

```
ana@dev:~/vue-tools$ npm init -y > /dev/null
ana@dev:~/vue-tools$ npm install --save-exact playwright@1.63.0

added 2 packages, and audited 3 packages in 2s

found 0 vulnerabilities
```

`--save-exact` writes `1.63.0` into `package.json` rather than `^1.63.0`, which would let a later
install pick a newer Playwright. **Every version in this course is pinned the same way**, for the
reason a transcript needs it: a different version prints different things.

The browser is a separate download of about 300 MB. Playwright 1.63.0 drives Chromium
153.0.8010.12, and this line fetches that build, with the system libraries it needs on Linux (it asks
for your password to install those):

```sh
cd ~/vue-tools && npx playwright install --with-deps --only-shell chromium
```

*That line was not run where the course was recorded. The recording machine already had the same
build, Chromium 153.0.8010.12, and `~/.cache/ms-playwright` was pointed at it.*

Now the program. Save it as `~/vue-tools/look.mjs`. You do not need to read it yet; its first comment
says what it prints and which options it takes, and lessons 2 to 22 use those options one at a time.

```javascript
// look.mjs: open a page in a real browser and print what is on it.
//
//   look URL [options]
//
// The browser is Chromium with no window, driven by Playwright. The page is
// opened at URL, usually the address your dev server printed, and once it
// has loaded this prints, in order: every console message the page wrote
// ([warn] and [error] marked as the browser marks them, an uncaught
// exception as "Uncaught" and its message), a line "-- ACTION" for each
// action below as it is performed, and at the end the text of the page as
// a reader sees it: the innerText of #app, or of the element --text names.
//
// Options, applied in the order given:
//   --do 'click SEL'      click the first element SEL matches
//   --do 'fill SEL TEXT'  type TEXT into a field (SEL without spaces)
//   --do 'check SEL'      tick a checkbox
//   --do 'press KEY'      press a key on whatever has focus (Tab, Enter...)
//   --do 'goto PATH'      go to another address on the same site
//   --do 'wait MS'        let MS milliseconds pass
//   --text SEL            print the text of SEL instead of #app ('-' for none)
//   --html SEL            also print SEL's HTML, as the page has it now
//   --source              also print the HTML the server sent, before any
//                         script ran
//   --no-js               open the page with JavaScript turned off
//   --network             list every request the page made
//   --clock ISO           the date the page's clock says, e.g. 2026-10-21T10:00
//   --width PX            the window's width (1024)
import { chromium } from "playwright";

const args = process.argv.slice(2);
const url = args.shift();
if (!url) { console.error("usage: look URL [options]"); process.exit(2); }
const opt = { do: [], text: "#app", width: 1024 };
while (args.length) {
  const a = args.shift();
  if (a === "--do") opt.do.push(args.shift());
  else if (a === "--text") opt.text = args.shift();
  else if (a === "--html") opt.html = args.shift();
  else if (a === "--source") opt.source = true;
  else if (a === "--no-js") opt.noJs = true;
  else if (a === "--network") opt.network = true;
  else if (a === "--clock") opt.clock = args.shift();
  else if (a === "--width") opt.width = Number(args.shift());
  else { console.error(`look: unknown option ${a}`); process.exit(2); }
}

const browser = await chromium.launch();
const context = await browser.newContext({
  javaScriptEnabled: !opt.noJs,
  locale: "en-GB",
  timezoneId: process.env.TZ || undefined,
  viewport: { width: opt.width, height: 768 },
});
const page = await context.newPage();
const say = (s) => process.stdout.write(s + "\n");
if (opt.clock) await page.clock.setFixedTime(new Date(opt.clock));
page.on("console", (m) => {
  const t = m.type();
  say(t === "error" ? `[error] ${m.text()}` : t === "warning" ? `[warn] ${m.text()}` : m.text());
});
page.on("pageerror", (e) => say(`Uncaught ${e.name}: ${e.message}`));
const origin = new URL(url).origin;
if (opt.network) {
  page.on("response", (r) => say(`net  ${r.request().method()} ${r.url().replace(origin, "")}  ${r.status()}`));
}

const first = await page.goto(url, { waitUntil: "networkidle" });
if (opt.source) {
  say("== the HTML the server sent");
  say((await first.text()).trimEnd());
}
for (const action of opt.do) {
  say(`-- ${action}`);
  const [verb, ...rest] = action.split(" ");
  const sel = rest[0];
  if (verb === "click") await page.click(rest.join(" "));
  else if (verb === "fill") await page.fill(sel, rest.slice(1).join(" "));
  else if (verb === "check") await page.check(rest.join(" "));
  else if (verb === "press") await page.keyboard.press(sel);
  else if (verb === "goto") await page.goto(origin + sel, { waitUntil: "networkidle" });
  else if (verb === "wait") await page.waitForTimeout(Number(sel));
  else say(`look: unknown action ${verb}`);
  await page.waitForTimeout(100);
}
await page.waitForTimeout(200);
if (opt.html) {
  say(`== the HTML of ${opt.html}`);
  say(await page.$eval(opt.html, (e) => e.outerHTML).catch(() => `(nothing matches ${opt.html})`));
}
if (opt.text !== "-") {
  say(`== the text of ${opt.text}`);
  say((await page.innerText(opt.text).catch(() => `(nothing matches ${opt.text})`)).trimEnd());
}
await browser.close();
```

Last, a command called `look` that runs it from wherever you are:

```sh
cat > ~/.local/bin/look <<'END'
#!/bin/sh
exec node "$HOME/vue-tools/look.mjs" "$@"
END
chmod +x ~/.local/bin/look
```

A file in `~/.local/bin` that starts with `#!/bin/sh` and is marked executable is a command, and
`"$@"` hands it everything typed after its name. Both files, as they ended up:

```
ana@dev:~$ cat ~/.local/bin/look
#!/bin/sh
exec node "$HOME/vue-tools/look.mjs" "$@"
ana@dev:~$ cat ~/vue-tools/package.json
{
  "name": "vue-tools",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "playwright": "1.63.0"
  }
}
```

There is nothing to look at yet: `look` needs a page, and the next section makes the first one.
