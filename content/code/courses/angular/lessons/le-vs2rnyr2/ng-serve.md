---
title: The dev server, and a way to read what it serves
version: 1
---

**`ng serve` builds the application into memory, serves it at `http://localhost:4200`, and builds it
again every time you save a file.** It is the command you leave running all day, in a terminal of
its own. Start it in a second terminal, in `~/planner`:

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Initial chunk files | Names         | Raw size
main.js             | main          | 47.76 kB | 
styles.css          | styles        | 95 bytes | 

                    | Initial total | 47.85 kB

Application bundle generation complete. [1.450 seconds] - 2026-10-23T22:43:50.048Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
```

The table is the build: `main.js` is your application, `styles.css` the global styles. The
framework's own packages are not in it: in development they are served as separate files, prepared
once and reused, which is part of why a change rebuilds in a fraction of a second. `Watch mode enabled` means it is now waiting for you to change something. It keeps that
terminal; stop it with Ctrl-C when you are done for the day.

**The memory it holds** is the figure lesson 1's table quoted. `ps` lists the processes and the
memory each one holds, in kilobytes, in its first column:

```
ana@dev:~/planner$ ps -o rss=,args= -u ana | sort -rn | head -3
370528 ng serve (planner)
82496 npm exec ng serve
17724 /home/ana/planner/node_modules/@esbuild/linux-x64/bin/esbuild --service=0.28.1 --ping
```

The first line is the dev server, the second the `npx` that started it, the third `esbuild`, the
compiler the CLI uses underneath.

Two things go wrong with it often enough to know in advance. Start a second one while the first is
running and it refuses, because the port is taken:

```
ana@dev:~/planner$ npx ng serve
An unhandled exception occurred: Port 4200 is already in use. Use '--port' to specify a different port.
See "/tmp/ng-WloOfH/angular-errors.log" for further details.
```

At a terminal it asks instead whether to use another port. Either way, the fix is usually to find
the terminal where the first one is running. And inside a virtual machine, `npx ng serve --host
0.0.0.0` makes it listen on every address of the guest rather than only its own `localhost`, which
is what a browser on the host needs.

## look: reading a page from the terminal

Open `http://localhost:4200` in a browser and you see Angular's welcome page. A browser window cannot
be pasted into a lesson, so this course reads pages with a short program instead, the way
`javascript` used `page`. Save it beside `page.mjs`, as `~/js-tools/look.mjs`:

```javascript
// look.mjs: open a page of your app in a real browser, and print what a
// person would see on it. The transcripts in this course that start with
// `look` were made with it.
//
//   look URL [options]
//
// The browser is Chromium with no window, driven by Playwright, the same one
// page.mjs drives. What it prints, in order:
//   - each console message, as page.mjs prints them ([warn], [error], and
//     "Uncaught" for an exception nobody caught)
//   - each action it performs, as "-- " and the action
//   - at the end, the text of the page as a reader sees it: what the browser
//     renders, with hidden elements left out
//
// Options, applied in order after the page has loaded:
//   --do 'click TEXT' | 'fill LABEL = TEXT' | 'check LABEL' | 'press KEY'
//        | 'select LABEL = OPTION' | 'go PATH' | 'wait MS'
//        click finds a button or a link by what it says; fill, check and
//        select find a form field by its label, as a screen reader would
//   --text SEL     print the text of SEL instead of the whole page
//   --html SEL     print SEL's HTML instead of text, without the attributes
//                  Angular adds to keep a component's styles to itself
//                  (_ngcontent-…, _nghost-…); --raw keeps them
//   --a11y SEL     print SEL's accessibility tree: the roles and names a
//                  screen reader announces
//   --styles       print the CSS rules the page's stylesheets hold, as the
//                  browser read them
//   --today DATE   make the browser's clock say DATE (YYYY-MM-DD), at 09:00
//   --network      list every request the page made, and its status
//   --no-js        open the page with JavaScript turned off
//   --wait MS      how long to let the page settle after each step (500)
import { chromium } from "playwright";

const args = process.argv.slice(2);
const url = args.shift();
if (!url) { console.error("usage: look URL [options]"); process.exit(2); }
const opt = { do: [], wait: 500 };
while (args.length) {
  const a = args.shift();
  if (a === "--do") opt.do.push(args.shift());
  else if (a === "--text") opt.text = args.shift();
  else if (a === "--html") opt.html = args.shift();
  else if (a === "--raw") opt.raw = true;
  else if (a === "--a11y") opt.a11y = args.shift();
  else if (a === "--styles") opt.styles = true;
  else if (a === "--today") opt.today = args.shift();
  else if (a === "--network") opt.network = true;
  else if (a === "--no-js") opt.noJs = true;
  else if (a === "--wait") opt.wait = Number(args.shift());
  else { console.error(`look: unknown option ${a}`); process.exit(2); }
}

const browser = await chromium.launch();
const context = await browser.newContext({
  locale: "en-GB", // so the browser's own messages are in the course's language
  timezoneId: process.env.TZ || undefined,
  javaScriptEnabled: !opt.noJs,
});
const page = await context.newPage();
if (opt.today) await page.clock.setFixedTime(new Date(`${opt.today}T09:00:00`));

const say = (s) => process.stdout.write(s + "\n");
page.on("console", (m) => {
  const t = m.type();
  if (t === "error") say(`[error] ${m.text()}`);
  else if (t === "warning") say(`[warn] ${m.text()}`);
  else say(m.text());
});
page.on("pageerror", (e) => say(`Uncaught ${e.name}: ${e.message}`));
const origin = new URL(url).origin;
if (opt.network) {
  page.on("response", (r) => say(`net  ${r.request().method()} ${r.url().replace(origin, "")}  ${r.status()}`));
  page.on("requestfailed", (r) => say(`net  ${r.method()} ${r.url().replace(origin, "")}  failed: ${r.failure()?.errorText}`));
}

const settle = () => page.waitForTimeout(opt.wait);
const field = (label) => page.getByLabel(label, { exact: true });
await page.goto(url);
await settle();
for (const action of opt.do) {
  say(`-- ${action}`);
  const [verb, ...rest] = action.split(" ");
  const arg = rest.join(" ");
  const [label, value] = arg.split(" = ");
  if (verb === "click") await page.getByRole("button", { name: arg, exact: true })
    .or(page.getByRole("link", { name: arg, exact: true })).first().click();
  else if (verb === "fill") await field(label).fill(value ?? "");
  else if (verb === "check") await field(arg).check();
  else if (verb === "select") await field(label).selectOption(value);
  else if (verb === "press") await page.keyboard.press(arg);
  else if (verb === "go") await page.goto(new URL(arg, origin).href);
  else if (verb === "wait") await page.waitForTimeout(Number(arg));
  else say(`look: unknown action ${verb}`);
  await settle();
}

if (opt.html) {
  let html = await page.locator(opt.html).first().evaluate((e) => e.outerHTML);
  if (!opt.raw) html = html.replace(/ _ng(content|host)-[\w-]+=""/g, "");
  say(html);
} else if (opt.a11y) {
  say(await page.locator(opt.a11y).first().ariaSnapshot());
} else if (opt.styles) {
  const rules = await page.evaluate(() =>
    [...document.styleSheets].flatMap((sheet) => [...sheet.cssRules].map((r) => r.cssText)));
  say(rules.join("\n"));
} else {
  say((await page.locator(opt.text || "body").first().innerText()).trim());
}
await browser.close();
```

and give it a command of its own, as `javascript` lesson 1 did for `page`:

```sh
cat > ~/.local/bin/look <<'END'
#!/bin/sh
exec node "$HOME/js-tools/look.mjs" "$@"
END
chmod +x ~/.local/bin/look
```

You do not need to read the program now; its first lines say what it does. It opens the address
you give it in Chromium, through the Playwright you installed for `javascript`, and prints what the
page put in the console and then the text a person would read. With `--text h1` it prints only the
first heading:

```
ana@dev:~/planner$ look http://localhost:4200/ --text h1
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Hello, planner
```

The three lines before the heading are the console. `[vite]` is the dev server's live-reload
connection, which `ng serve` builds on Vite, and `Angular is running in development mode` is
Angular saying that the checks lessons 7 and 9 rely on are switched on. A production build, two
sections on, prints neither.

## Your first edit

`src/app/app.html` is 20 kilobytes of welcome page. Replace all of it with two lines:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<router-outlet />
```

`<router-outlet />` is where the router will draw a screen, from lesson 17; it draws nothing yet.
The first line is an HTML comment naming the file, as every file this course asks you to save does,
and the build drops comments from templates. As soon as you save, the dev server's terminal adds a
line:

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Initial chunk files | Names         | Raw size
main.js             | main          | 47.76 kB | 
styles.css          | styles        | 95 bytes | 

                    | Initial total | 47.85 kB

Application bundle generation complete. [1.450 seconds] - 2026-10-23T22:43:50.048Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
❯ Changes detected. Rebuilding...
✔ Changes detected. Rebuilding...
Initial chunk files | Names | Raw size
main.js             | main  |  2.39 kB | 

Application bundle generation complete. [0.135 seconds] - 2026-10-23T22:43:53.033Z

Component update sent to client(s).
```

**Only the template was rebuilt and sent**, and the open page swapped it in place without
reloading. Ask again:

```
ana@dev:~/planner$ look http://localhost:4200/
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Study planner
```

## The data, in public/

Last, the planner's data from lesson 1, in the folder the build copies as it is. Save it as
`public/courses.json`:

```schooling-example
{"language": "json", "file": "public/courses.json", "parts": [
 {"code": "{\n  \"courses\": [\n    { \"id\": \"html-css\", \"name\": \"HTML and CSS\" },\n    { \"id\": \"javascript\", \"name\": \"JavaScript\" },\n    { \"id\": \"git\", \"name\": \"Git\" }\n  ],", "note": "Three courses. A course's `id` is how its sessions find it, and its `name` is what a person reads."},
 {"code": "  \"sessions\": [\n    { \"id\": 1, \"courseId\": \"javascript\", \"date\": \"2026-10-13\", \"minutes\": 45, \"done\": true },\n    { \"id\": 2, \"courseId\": \"html-css\", \"date\": \"2026-10-19\", \"minutes\": 30, \"done\": true },\n    { \"id\": 3, \"courseId\": \"javascript\", \"date\": \"2026-10-20\", \"minutes\": 60, \"done\": true },\n    { \"id\": 4, \"courseId\": \"git\", \"date\": \"2026-10-22\", \"minutes\": 25, \"done\": false },\n    { \"id\": 5, \"courseId\": \"javascript\", \"date\": \"2026-10-24\", \"minutes\": 50, \"done\": false },\n    { \"id\": 6, \"courseId\": \"html-css\", \"date\": \"2026-10-27\", \"minutes\": 40, \"done\": false }\n  ]\n}", "note": "Six sessions. `courseId` is the `id` of the course the session belongs to. `date` is written `YYYY-MM-DD`, so dates sort correctly as text, and `minutes` is a whole number."}
]}
```

Anything in `public/` is served at the root of the site, so the file should now be at
`/courses.json`:

```
ana@dev:~/planner$ curl -s http://localhost:4200/courses.json | head -4
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
```

That is not JSON. It is the start of the page, `index.html`, and two facts about the dev server
explain it. **It reads `public/` when it starts**, so a file added while it runs is not there for it
yet. And **it answers every address it has no file for with `index.html`**, which is what an
Angular application needs from a server, for a reason the build section shows in a moment. Stop the
server with Ctrl-C in its terminal, and start it again:

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Initial chunk files | Names         | Raw size
main.js             | main          |  2.39 kB | 
styles.css          | styles        | 95 bytes | 

                    | Initial total |  2.48 kB

Application bundle generation complete. [1.468 seconds] - 2026-10-23T22:43:59.268Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
```

```
ana@dev:~/planner$ curl -s http://localhost:4200/courses.json | head -4
{
  "courses": [
    { "id": "html-css", "name": "HTML and CSS" },
    { "id": "javascript", "name": "JavaScript" },
```

Nothing in the application reads it yet. Lesson 6 does, with the first signal that waits for
something.
