---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, and this section sets it up.** You need
two things: **Node.js**, which runs JavaScript as an ordinary program, and a way to open a page in a
browser and read what its scripts printed. The second is a short program you will save in a
moment, called `page`. Every transcript in the course that starts with `page` was made with it.

## Three ways to have one

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Node.js and `page` on the computer you already use | about 540 MB of disk | match as printed on Linux; close elsewhere |
| a virtual machine | Ubuntu Server 24.04 apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** Nothing here touches the rest of your system: Node goes
into a folder in your home directory, and the browser `page` drives is its own copy, not the one
you browse with. On **Linux** the commands below work as printed. On **Windows**, every command in
this course is typed in a Linux terminal, so install WSL first: `wsl --install -d Ubuntu-24.04` in a
PowerShell opened as administrator, restart, open Ubuntu from the Start menu, and follow the Linux
steps inside it. On a **Mac**, take the installer for Node.js 22 from nodejs.org and skip to
"The page command"; that path was not run for this course, so a path or a version in a transcript
may differ from yours.

**A virtual machine** is the same Linux steps inside a machine of its own: VirtualBox on Windows or
Linux, UTM on a Mac with an Apple chip, and Ubuntu Server 24.04 LTS as the guest. It is how this
course was recorded. A server has no desktop, so there is no browser window to open there, and
`page` is the only way to see a page.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in a browser tab. It costs
your computer nothing, and GitHub gives personal accounts a monthly allowance and charges past it,
on terms it sets and can change. It was not run for this course. `cat /etc/os-release` tells you
which Linux you got before you start.

## Node.js

Node comes from nodejs.org as one compressed folder. Which one depends on the processor, and
`uname -m` says which: `x86_64` takes the file ending `linux-x64`, `aarch64` the one ending
`linux-arm64`. This course was recorded on 22.22.0, and any later 22 works the same. One terminal,
from the top:

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

`curl -O` saves the file under its own name, and `tar` unpacks it into `~/.local/node`. The `ln`
line puts the three programs where Ubuntu looks for your own: `~/.local/bin` is on your `PATH`, the
list of folders the shell searches, **from the next time you log in**. That is why the last line
fails. The terminal decided its `PATH` when it opened, before the folder existed. Close it and open
a new one:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
```

`npm` came in the same folder. It installs JavaScript packages, and lesson 21 is about it.

## The page command

`page` is built on **Playwright**, a library that drives a real browser from a program. It lives in
a folder of its own, `~/js-tools`, so the course's tools never mix with your work in `~/js`:

```
ana@dev:~$ mkdir ~/js-tools ~/js
ana@dev:~$ cd ~/js-tools
ana@dev:~/js-tools$ npm install playwright@1.56.0

added 2 packages in 2s
npm notice
npm notice New major version of npm available! 10.9.4 -> 12.2.0
npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.0
npm notice To update run: npm install -g npm@12.2.0
npm notice
```

`npm install` fetched the library into `~/js-tools/node_modules`. The notice under it is npm
offering a newer version of itself, which you can ignore: the one that came with Node is the one
this course uses. **The browser is a separate
download**, and this asks Playwright where it would put it:

```
ana@dev:~$ cd ~/js-tools
ana@dev:~/js-tools$ npx playwright install --dry-run --only-shell chromium
browser: chromium-headless-shell version 141.0.7390.37
  Install location:    /home/ana/.cache/ms-playwright/chromium_headless_shell-1194
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/chromium/1194/chromium-headless-shell-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/chromium/1194/chromium-headless-shell-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/chromium/1194/chromium-headless-shell-linux.zip

browser: ffmpeg
  Install location:    /home/ana/.cache/ms-playwright/ffmpeg-1011
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/ffmpeg/1011/ffmpeg-linux.zip
```

Then the download itself, which is about 320 MB on disk once unpacked. `--only-shell` takes the
build of Chromium that runs with no window, which is all `page` needs; on Linux, `--with-deps` also
installs the system libraries it runs on, and asks for your password to do it:

```sh
npx playwright install --with-deps --only-shell chromium
```

*This one line was not run where the course was recorded. That machine could not reach Playwright's
download server, and already had the same build, 141.0.7390.37, which `page` used for every
transcript.*

Now the two programs. Save each one in `~/js-tools` under the name in its first line. You do not
need to read them yet: `page.mjs` opens a page and prints what its console said, and `serve.mjs` is
the small web server it opens the page from. Lesson 16 adds a third file beside them and lesson 22
a fourth, each shown whole where it is needed.

```javascript
// page.mjs: open one of your pages in a real browser, and print what its
// console said. The transcripts in this course that start with `page` were
// made with it.
//
//   page FILE.html [options]
//
// The browser is Chromium with no window, driven by Playwright. The page is
// served from the folder you are in, at http://127.0.0.1:8080, by serve.mjs.
//
// Each line is one console message. console.warn and console.error are marked
// [warn] and [error]; an exception nobody caught is printed as "Uncaught" and
// its message, as the browser's own console prints it; and an action this
// program performed is printed as "-- " and the action.
//
// Options, applied in order after the page has loaded:
//   --do 'click SEL' | 'fill SEL TEXT' (SEL without spaces) | 'press KEY' | 'focus SEL'
//        | 'wait MS' | 'reload' | 'newtab' | 'eval CODE'
//   --dom SEL        at the end, print SEL's outerHTML
//   --wait MS        how long to let timers run after the last action (300)
//   --geo LAT,LON    the position the browser reports, and permission for it
//   --grant PERM     grant a permission (notifications, geolocation)
//   --fresh          forget everything the browser stored (localStorage)
//   --network        list every request the page made
//   --file           open the page from file:// instead of the server, as a
//                    file double-clicked on a desktop would be
// Lesson 22 adds devtools.mjs beside this file, and with it --break, --if,
// --step, --profile and --waterfall.
import { chromium } from "playwright";
import { createServer } from "./serve.mjs";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const args = process.argv.slice(2);
const file = args.shift();
if (!file) { console.error("usage: page FILE.html [options]"); process.exit(2); }
const opt = { do: [], wait: 300, grant: [], step: [] };
while (args.length) {
  const a = args.shift();
  if (a === "--do") opt.do.push(args.shift());
  else if (a === "--dom") opt.dom = args.shift();
  else if (a === "--wait") opt.wait = Number(args.shift());
  else if (a === "--geo") opt.geo = args.shift().split(",").map(Number);
  else if (a === "--grant") opt.grant.push(args.shift());
  else if (a === "--fresh") opt.fresh = true;
  else if (a === "--network") opt.network = true;
  else if (a === "--file") opt.file = true;
  else if (a === "--break") opt.break = args.shift();
  else if (a === "--if") opt.if = args.shift();
  else if (a === "--step") opt.step.push(args.shift());
  else if (a === "--profile") opt.profile = true;
  else if (a === "--waterfall") opt.waterfall = true;
  else { console.error(`page: unknown option ${a}`); process.exit(2); }
}

let devtools = null;
if (opt.break || opt.profile || opt.waterfall) {
  if (!fs.existsSync(new URL("./devtools.mjs", import.meta.url))) {
    console.error("page: --break, --profile and --waterfall need devtools.mjs beside page.mjs (lesson 22)");
    process.exit(2);
  }
  devtools = await import("./devtools.mjs");
}

const root = process.cwd();
const server = createServer(root);
await new Promise((ok) => server.listen(8080, "127.0.0.1", ok));

// The browser keeps what pages store, as yours does, in a folder of its own.
const profileDir = path.join(os.homedir(), ".page-profile");
if (opt.fresh) fs.rmSync(profileDir, { recursive: true, force: true });
const context = await chromium.launchPersistentContext(profileDir, {
  headless: true,
  locale: "en-GB", // so the browser's own messages are in the course's language
  timezoneId: process.env.TZ || undefined,
  ...(opt.geo ? { geolocation: { latitude: opt.geo[0], longitude: opt.geo[1] } } : {}),
});
const origin = "http://127.0.0.1:8080";
if (opt.geo) await context.grantPermissions(["geolocation"], { origin });
if (opt.grant.length) await context.grantPermissions(opt.grant, { origin });

const say = (s) => process.stdout.write(s + "\n");
function watch(page) {
  page.on("console", (m) => {
    const t = m.type();
    const text = m.text();
    if (t === "error") say(`[error] ${text}`);
    else if (t === "warning") say(`[warn] ${text}`);
    else say(text);
  });
  page.on("pageerror", (e) => say(`Uncaught ${String(e.message).startsWith(e.name) ? e.message : `${e.name}: ${e.message}`}`));
}

let page = context.pages()[0] || (await context.newPage());
watch(page);
if (opt.network) {
  page.on("requestfailed", (r) => say(`net  ${r.method()} ${r.url().replace(origin, "")}  failed: ${r.failure()?.errorText}`));
  page.on("response", async (r) => {
    const q = r.request();
    let size = "?";
    try { size = (await r.body()).length; } catch {} // a body that is gone is printed as "?"
    say(`net  ${q.method()} ${r.url().replace(origin, "")}  ${r.status()}  ${q.resourceType()}  ${size} B`);
  });
}
const tools = devtools && (await devtools.attach({ context, page, opt, say, origin }));

await page.goto(opt.file ? `file://${path.resolve(root, file)}` : `${origin}/${file}`);
for (const action of opt.do) {
  say(`-- ${action}`);
  const [verb, ...rest] = action.split(" ");
  const sel = rest[0];
  const text = rest.slice(1).join(" ");
  if (verb === "click") await page.click(rest.join(" "));
  else if (verb === "fill") await page.fill(sel, text);
  else if (verb === "press") await page.keyboard.press(sel);
  else if (verb === "focus") await page.focus(rest.join(" "));
  else if (verb === "wait") await page.waitForTimeout(Number(sel));
  else if (verb === "reload") await page.reload();
  else if (verb === "newtab") { page = await context.newPage(); watch(page); await page.goto(`${origin}/${file}`); }
  else if (verb === "eval") { const r = await page.evaluate(rest.join(" ")); if (r !== undefined) say(String(r)); }
  else { say(`page: unknown action ${verb}`); }
}
await page.waitForTimeout(opt.wait);
if (tools) await tools.finish();

if (opt.dom) {
  const html = await page.$eval(opt.dom, (e) => e.outerHTML).catch(() => `(no element matches ${opt.dom})`);
  say(html);
}
await context.close();
server.close();
```

```javascript
// serve.mjs: a web server for the pages in this course.
//
//   node serve.mjs [FOLDER] [PORT]      FOLDER defaults to this one, PORT to 8080
//
// It sends the files in FOLDER as they are, so a page has a real address,
// http://127.0.0.1:8080/, as it would on the web. Lesson 16 puts api.mjs
// beside it, and from then on it also answers the addresses under /api/.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const TYPES = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8", ".svg": "image/svg+xml",
  ".txt": "text/plain; charset=utf-8",
};

// api.mjs is optional until lesson 16 writes it.
let api = null;
if (fs.existsSync(new URL("./api.mjs", import.meta.url))) ({ api } = await import("./api.mjs"));

export function createServer(root) {
  const state = {};
  return http.createServer((req, res) => {
    const url = new URL(req.url, "http://127.0.0.1");
    if (url.pathname.startsWith("/api/")) {
      if (api) return api(req, res, url, state);
      res.writeHead(404, { "content-type": "text/plain" });
      return res.end("no api.mjs beside serve.mjs: lesson 16 writes it\n");
    }
    const file = path.join(root, decodeURIComponent(url.pathname));
    if (!file.startsWith(path.resolve(root))) { res.writeHead(403); return res.end(); }
    fs.readFile(file, (err, data) => {
      if (err) { res.writeHead(404, { "content-type": "text/plain" }); return res.end("not found\n"); }
      res.writeHead(200, { "content-type": TYPES[path.extname(file)] || "application/octet-stream" });
      res.end(data);
    });
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const root = path.resolve(process.argv[2] || ".");
  const port = Number(process.argv[3] || 8080);
  createServer(root).listen(port, "127.0.0.1", () => console.log(`serving ${root} on http://127.0.0.1:${port}`));
}
```

Last, a command called `page` that runs the first one, wherever you are:

```sh
cat > ~/.local/bin/page <<'EOF'
#!/bin/sh
exec node "$HOME/js-tools/page.mjs" "$@"
EOF
chmod +x ~/.local/bin/page
```

A file in `~/.local/bin` that starts with `#!/bin/sh` and is marked executable is a command, and
`"$@"` hands it everything typed after its name. On a Mac, `~/.local/bin` is not on the `PATH` until
`export PATH="$HOME/.local/bin:$PATH"` is added to `~/.zprofile`.

## Checking it works

Your own work goes in `~/js`. A page with one line of script is enough to try:

```
ana@dev:~$ cd ~/js
ana@dev:~/js$ echo '<script>console.log("the browser works")</script>' > check.html
ana@dev:~/js$ page check.html
the browser works
```

**That line came from Chromium**: `page` served `~/js` at `http://127.0.0.1:8080`, opened
`check.html` there, and printed the console. If you have a desktop, open the same address in your own
browser with `node ~/js-tools/serve.mjs` running in a second terminal, and press F12 to see the
console. The transcripts use `page` because a terminal can show its output, and a window cannot be
pasted.
