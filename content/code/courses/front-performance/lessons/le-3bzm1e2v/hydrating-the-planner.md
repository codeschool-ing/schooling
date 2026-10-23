---
title: Hydrating the planner
version: 1
---

**Three changes make the planner hydrate**: the server puts the plan in the page, the script reads
it from there instead of fetching it, and `mount` keeps the HTML it found instead of replacing it.
This section also adds one small feature, the day of the week beside each session's date, because a
real page always has something like it, and the next section shows what it does.

## The server puts the data in the page

In `server.ts`, the line that builds the page now adds a `<script type="application/json">` after the
`<main>`. A script of that type is never run; it is a place to keep data that the page's own script
can read. Replace the line that builds `html` with these:

```typescript
  // The plan goes into the page as data, so the browser does not fetch it again. A "<" is
  // written as <, so no title can close the script element early.
  const data = JSON.stringify(plan).replace(/</g, "\\u003c");
  const html = shell.replace('<main id="app"></main>',
    `<main id="app">${page(plan, pathname)}</main><script type="application/json" id="plan">${data}</script>`);
```

**The `replace` is not decoration.** A course titled `</script><script>…` would otherwise end the
data element in the middle and start a script of its own, written by whoever named the course. JSON
allows `<` to be written as `<`, which means the same character to `JSON.parse` and means
nothing at all to the HTML parser.

## The script reads it

`src/main.ts` looks for that element first, and fetches only when it is not there, as on the
client-rendered build:

```typescript
// src/main.ts: take the plan the server put in the page, or fetch it, and hand it to the view.
import "./style.css";
import type { Plan } from "./planner.ts";
import { mount } from "./view.ts";

const embedded = document.getElementById("plan");
const plan: Plan = embedded
  ? JSON.parse(embedded.textContent!)
  : await (await fetch("/courses.json")).json();
mount(document.querySelector<HTMLElement>("#app")!, plan);
```

## The view keeps what it found

`src/view.ts` changes in three places, so here it is whole. The new `day` function adds the weekday;
the new `same` compares the HTML on the screen with the HTML the script would draw; and `mount`
draws only when it has to:

```schooling-example
{"language": "typescript", "file": "src/view.ts", "parts": [
 {"code": "// src/view.ts: the planner's pages as HTML, and the DOM that shows them.\nimport { addSession, markDone, weekTotal, weeks, type Plan } from \"./planner.ts\";\n\nconst esc = (s: string) => s.replace(/[&<>\"']/g, (c) => `&#${c.charCodeAt(0)};`);", "note": "The escape, as before."},
 {"code": "// \"2026-10-24\" as \"Sat 2026-10-24\", the day of the week it falls on.\nconst day = (date: string) => `${new Date(date).toLocaleDateString(\"en-GB\", { weekday: \"short\" })} ${date}`;", "note": "New: the day of the week, from the date, in English, as \"Sat 2026-10-24\"."},
 {"code": "export function homePage(plan: Plan): string {\n  const courses = plan.courses.map((c) => {\n    const n = plan.sessions.filter((s) => s.course === c.slug).length;\n    return `<li><a href=\"/courses/${esc(c.slug)}\">${esc(c.title)}</a> · ${n} sessions</li>`;\n  });\n  const totals = weeks(plan.sessions).map((monday) => {\n    const done = weekTotal(plan.sessions.filter((s) => s.done), monday);\n    return `<li>Week of ${monday}: ${weekTotal(plan.sessions, monday)} min, ${done} done</li>`;\n  });\n  return `<h1>Study planner</h1>\n<ul class=\"courses\">${courses.join(\"\")}</ul>\n<h2>Weeks</h2>\n<ul class=\"weeks\">${totals.join(\"\")}</ul>`;\n}", "note": "The home page is unchanged."},
 {"code": "export function coursePage(plan: Plan, slug: string): string {\n  const course = plan.courses.find((c) => c.slug === slug);\n  if (!course) return `<h1>No such course</h1><p><a href=\"/\">All courses</a></p>`;\n  const rows = plan.sessions.filter((s) => s.course === slug).map((s) =>\n    `<li>${day(s.date)} · ${s.minutes} min ${s.done ? \"· done\" : `<button data-done=\"${s.id}\">Mark done</button>`}</li>`);\n  return `<p><a href=\"/\">All courses</a></p>\n<h1>${esc(course.title)}</h1>\n<ul class=\"sessions\">${rows.join(\"\")}</ul>\n<form>\n  <label>Date <input name=\"date\" type=\"date\" required></label>\n  <label>Minutes <input name=\"minutes\" type=\"number\" min=\"5\" step=\"5\" required></label>\n  <button>Add session</button>\n</form>`;\n}\n\n// The page an address names: /courses/<slug> is one course, anything else the list.\nexport function page(plan: Plan, path: string): string {\n  const m = path.match(/^\\/courses\\/([a-z0-9-]+)$/);\n  return m ? coursePage(plan, m[1]) : homePage(plan);\n}", "note": "A course's page calls day() where it used to print the date alone."},
 {"code": "// Whether the HTML already in root says what html says, letter for letter.\nfunction same(root: HTMLElement, html: string): boolean {\n  const drawn = document.createElement(\"template\");\n  drawn.innerHTML = html;\n  return drawn.content.textContent === root.textContent;\n}", "note": "New: the HTML the script would draw is parsed, off the page, and its text compared with the text already on the screen. Text, not markup, because the browser writes attributes back differently from the way the string spelled them."},
 {"code": "// Take over the page the server drew, or draw it if the server sent none.\nexport function mount(root: HTMLElement, start: Plan): void {\n  let plan = start;\n  const draw = () => { root.innerHTML = page(plan, location.pathname); };\n  root.addEventListener(\"click\", (e) => {\n    const target = e.target as HTMLElement;\n    const link = target.closest(\"a\");\n    if (link) {\n      e.preventDefault();\n      history.pushState(null, \"\", link.pathname);\n      draw();\n    } else if (target.dataset.done) {\n      plan = markDone(plan, Number(target.dataset.done));\n      draw();\n    }\n  });\n  root.addEventListener(\"submit\", (e) => {\n    e.preventDefault();\n    const form = new FormData(e.target as HTMLFormElement);\n    const slug = location.pathname.split(\"/\")[2];\n    plan = addSession(plan, slug, String(form.get(\"date\")), Number(form.get(\"minutes\")));\n    draw();\n  });\n  addEventListener(\"popstate\", draw);", "note": "The listeners are the same as before. They hang on the container, so they work on HTML the server drew exactly as on HTML the script drew."},
 {"code": "  if (!root.firstElementChild) {\n    draw();\n  } else if (!same(root, page(plan, location.pathname))) {\n    console.warn(\"hydration mismatch: the page the server sent is not the page this script draws; drawing again\");\n    draw();\n  }\n  document.documentElement.dataset.hydrated = String(Math.round(performance.now()));\n}", "note": "The new part. An empty main is drawn, as on the client-rendered build. A main that says something else is drawn again, with a warning, because the script must not act on a page it does not understand. And when it is done, the time goes into an attribute that a measuring tool can read."}
]}
```

## A tool that watches it happen

`tools/hydrate.ts` opens a page in Chromium **as a person in São Paulo would**, with that time zone,
and prints what the console said, when the page painted, and when the script took it over. It has
two options the section after next uses. Save it in `tools/`:

```typescript
// tools/hydrate.ts: open a page as a person in São Paulo would, and report what
// its console said, when it painted, and when the script took it over.
//
//   node tools/hydrate.ts URL [--script-delay MS] [--click-at MS]
//
// --script-delay MS  every script arrives MS milliseconds late, as on a slow network
// --click-at MS      click the first "Mark done" button MS milliseconds after the
//                    page arrived, whether or not the script has run yet
import { chromium } from "playwright";

const [url, ...rest] = process.argv.slice(2);
const option = (name: string) => (rest.includes(name) ? Number(rest[rest.indexOf(name) + 1]) : null);
const delay = option("--script-delay");
const clickAt = option("--click-at");

const browser = await chromium.launch();
const page = await browser.newPage({ timezoneId: "America/Sao_Paulo" });
page.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
if (delay) {
  await page.route("**/*.js", async (route) => {
    await new Promise((done) => setTimeout(done, delay));
    await route.continue();
  });
}
await page.goto(url, { waitUntil: "commit" });
if (clickAt !== null) {
  await page.waitForTimeout(clickAt);
  await page.click("[data-done]");
  console.log(`clicked Mark done ${clickAt} ms after the page arrived`);
}
await page.waitForFunction(() =>
  document.documentElement.dataset.hydrated && performance.getEntriesByName("first-contentful-paint").length);
const t = await page.evaluate(() => ({
  paint: Math.round(performance.getEntriesByName("first-contentful-paint")[0]?.startTime ?? 0),
  hydrated: document.documentElement.dataset.hydrated,
}));
console.log(`painted at ${t.paint} ms, taken over by the script at ${t.hydrated} ms`);
console.log((await page.locator("main li").allInnerTexts()).join("\n"));
await browser.close();
```

Build, and start `server.ts` in the second terminal **with `TZ=UTC`**, the time zone almost every
server in a data centre runs in:

```sh
npm run build && TZ=UTC node server.ts
```

Then ask for the Git course, and open it as the person in São Paulo:

```
ana@dev:~/planner$ curl -s http://localhost:3000/courses/git | grep -o '<li>[^<]*'
```

**The server said Saturday and the browser said Friday**, warned, and drew its own version over the
server's. `look.ts`, in the last line, lists the requests: there is no `/courses.json` among them, so
the data in the page did its job. Everything else is the next section.
