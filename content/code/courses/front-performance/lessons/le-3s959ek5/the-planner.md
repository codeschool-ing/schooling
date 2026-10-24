---
title: The planner you will measure
version: 1
---

**This course measures one app, and you build it here, whole, in plain TypeScript.** It is a study
planner: a list of courses, a page per course with its study sessions, a button that marks a
session done, a form that adds one, and the total of minutes per week. It uses no framework, on
purpose. Every technique in this course works the same under React, Angular, Vue or Svelte, and
where a framework does something its own way, the lesson shows all four side by side. A plain app
is the one place where nothing is done for you, so you can see each technique doing its work.

It is small enough to read in five minutes, and every later lesson changes it or measures it.

## Making the project

Vite makes a new project from a template. `vanilla-ts` is the one with no framework and with
TypeScript. In your home directory:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template vanilla-ts
npm warn exec The following package was not found and will be installed: create-vite@9.3.1

> npx
> cva planner --template vanilla-ts


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/planner...
│
└  Done. Now run:

  cd planner
  npm install
  npm run dev

ana@dev:~$ cd planner
ana@dev:~/planner$ rm -r src/assets src/counter.ts public/icons.svg
ana@dev:~/planner$ npm install --save-exact --save-dev vite@8.3.5 typescript@6.0.3

added 16 packages, and audited 17 packages in 16s

8 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "typescript": "6.0.3",
    "vite": "8.3.5"
  }
}
```

`npm create vite@9.3.1` runs the program that makes Vite projects, at an exact version, and
everything after `--` is passed to it. The template comes with a demonstration page, a counter and
three pictures; `rm` deletes them, because the planner replaces all of it. **`--save-exact` writes
each version in `package.json` without the `^` or `~` in front of it**, which would otherwise let a
later install take a newer version. `package-lock.json`, written beside it, records the exact
version of every package installed underneath those two, and both files belong in Git.

Playwright goes into the same project, as the third tool:

```
ana@dev:~/planner$ npm install --save-exact --save-dev playwright@1.63.0

added 4 packages, and audited 21 packages in 2s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

The package and the browser it drives are two downloads. This one fetches the build of Chromium
that this Playwright drives, about 650 MB once unpacked, into `~/.cache/ms-playwright`:

```sh
npx playwright install chromium
```

On Linux, Chromium also needs some system libraries, and `npx playwright install-deps chromium`
installs them if a launch complains (the previous section has the error). *The download was not
run where the course was recorded: that machine cannot reach Playwright's download server and
already had this same build, Chromium 153.0.8010.12, which every transcript in the course used.*

## The data

The planner reads one file, served as it is. Three courses, six sessions, all in October 2026.
Save it as `public/courses.json`:

```json
{
  "courses": [
    { "slug": "html-css", "title": "HTML and CSS" },
    { "slug": "javascript", "title": "JavaScript" },
    { "slug": "git", "title": "Git" }
  ],
  "sessions": [
    { "id": 1, "course": "html-css", "date": "2026-10-19", "minutes": 45, "done": true },
    { "id": 2, "course": "html-css", "date": "2026-10-21", "minutes": 30, "done": false },
    { "id": 3, "course": "javascript", "date": "2026-10-20", "minutes": 60, "done": true },
    { "id": 4, "course": "javascript", "date": "2026-10-23", "minutes": 50, "done": false },
    { "id": 5, "course": "git", "date": "2026-10-24", "minutes": 25, "done": false },
    { "id": 6, "course": "git", "date": "2026-10-27", "minutes": 40, "done": false }
  ]
}
```

Anything in `public/` is served at the root of the site as it is, so this file is at
`/courses.json` in development and is copied into the build unchanged.

## The rules

`src/planner.ts` holds what the planner knows, as pure functions: each takes a plan and returns a
new one, or a number, and none of them touches the page. That is what lets a server use the same
file later in this lesson.

```schooling-example
{"language": "typescript", "file": "src/planner.ts", "parts": [
 {"code": "// src/planner.ts: the planner's rules. No DOM here, so a server can use them too.\nexport interface Course { slug: string; title: string }\nexport interface Session { id: number; course: string; date: string; minutes: number; done: boolean }\nexport interface Plan { courses: Course[]; sessions: Session[] }", "note": "A plan is two lists, and a session names its course by slug, the same string the address uses."},
 {"code": "export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {\n  const id = Math.max(0, ...plan.sessions.map((s) => s.id)) + 1;\n  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };\n}\n\nexport function markDone(plan: Plan, id: number): Plan {\n  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };\n}", "note": "Adding and marking done never change the plan they were given. They return a new one, which is what makes them easy to test and safe to call anywhere."},
 {"code": "// A date is a calendar day, \"2026-10-23\", so the arithmetic is done in UTC,\n// where no day is 23 or 25 hours long.\nexport function mondayOf(date: string): string {\n  const d = new Date(date + \"T00:00:00Z\");\n  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));\n  return d.toISOString().slice(0, 10);\n}", "note": "A week starts on Monday. getUTCDay is 0 on Sunday, so (day + 6) % 7 counts the days back to Monday."},
 {"code": "export function weekTotal(sessions: Session[], monday: string): number {\n  return sessions.filter((s) => mondayOf(s.date) === monday).reduce((sum, s) => sum + s.minutes, 0);\n}\n\n// Every week that has a session in it, earliest first.\nexport function weeks(sessions: Session[]): string[] {\n  return [...new Set(sessions.map((s) => mondayOf(s.date)))].sort();\n}", "note": "The week's total, and the list of weeks the home page shows a total for."}
]}
```

## The pages

`src/view.ts` turns a plan into HTML, as strings, and puts that HTML on the page. **The two halves
are kept apart on purpose**: the functions that return strings run anywhere, and only `mount`
needs a browser.

```schooling-example
{"language": "typescript", "file": "src/view.ts", "parts": [
 {"code": "// src/view.ts: the planner's pages as HTML, and the DOM that shows them.\nimport { addSession, markDone, weekTotal, weeks, type Plan } from \"./planner.ts\";\n\nconst esc = (s: string) => s.replace(/[&<>\"']/g, (c) => `&#${c.charCodeAt(0)};`);", "note": "Every piece of text that came from the data goes through esc, so a title with a < in it is shown rather than read as a tag."},
 {"code": "export function homePage(plan: Plan): string {\n  const courses = plan.courses.map((c) => {\n    const n = plan.sessions.filter((s) => s.course === c.slug).length;\n    return `<li><a href=\"/courses/${esc(c.slug)}\">${esc(c.title)}</a> · ${n} sessions</li>`;\n  });\n  const totals = weeks(plan.sessions).map((monday) => {\n    const done = weekTotal(plan.sessions.filter((s) => s.done), monday);\n    return `<li>Week of ${monday}: ${weekTotal(plan.sessions, monday)} min, ${done} done</li>`;\n  });\n  return `<h1>Study planner</h1>\n<ul class=\"courses\">${courses.join(\"\")}</ul>\n<h2>Weeks</h2>\n<ul class=\"weeks\">${totals.join(\"\")}</ul>`;\n}", "note": "The home page: each course with a link and a count, then one line per week."},
 {"code": "export function coursePage(plan: Plan, slug: string): string {\n  const course = plan.courses.find((c) => c.slug === slug);\n  if (!course) return `<h1>No such course</h1><p><a href=\"/\">All courses</a></p>`;\n  const rows = plan.sessions.filter((s) => s.course === slug).map((s) =>\n    `<li>${s.date} · ${s.minutes} min ${s.done ? \"· done\" : `<button data-done=\"${s.id}\">Mark done</button>`}</li>`);\n  return `<p><a href=\"/\">All courses</a></p>\n<h1>${esc(course.title)}</h1>\n<ul class=\"sessions\">${rows.join(\"\")}</ul>\n<form>\n  <label>Date <input name=\"date\" type=\"date\" required></label>\n  <label>Minutes <input name=\"minutes\" type=\"number\" min=\"5\" step=\"5\" required></label>\n  <button>Add session</button>\n</form>`;\n}", "note": "A course's page: its sessions, a button on each one not yet done, and the form that adds one. The button carries the session's id, which is how a click finds the session."},
 {"code": "// The page an address names: /courses/<slug> is one course, anything else the list.\nexport function page(plan: Plan, path: string): string {\n  const m = path.match(/^\\/courses\\/([a-z0-9-]+)$/);\n  return m ? coursePage(plan, m[1]) : homePage(plan);\n}", "note": "The router, in one line: an address decides which page. This is the function a server will call too."},
 {"code": "// Draw the page into root, and draw it again after every change.\nexport function mount(root: HTMLElement, start: Plan): void {\n  let plan = start;\n  const draw = () => { root.innerHTML = page(plan, location.pathname); };\n  root.addEventListener(\"click\", (e) => {\n    const target = e.target as HTMLElement;\n    const link = target.closest(\"a\");\n    if (link) {\n      e.preventDefault();\n      history.pushState(null, \"\", link.pathname);\n      draw();\n    } else if (target.dataset.done) {\n      plan = markDone(plan, Number(target.dataset.done));\n      draw();\n    }\n  });\n  root.addEventListener(\"submit\", (e) => {\n    e.preventDefault();\n    const form = new FormData(e.target as HTMLFormElement);\n    const slug = location.pathname.split(\"/\")[2];\n    plan = addSession(plan, slug, String(form.get(\"date\")), Number(form.get(\"minutes\")));\n    draw();\n  });\n  addEventListener(\"popstate\", draw);\n  draw();\n}", "note": "The browser half. One listener on the container catches every click and every form, so redrawing the HTML never loses a listener. A link changes the address with pushState and redraws, without asking the server for anything."}
]}
```

Changes live in memory: a session you add is gone when you reload, because nothing writes it
anywhere. That is enough to measure, and lesson 10 is where the planner learns to keep things.

## Starting it

`src/main.ts` fetches the data and hands it to the view. It replaces the template's file:

```typescript
// src/main.ts: fetch the plan and hand it to the view.
import "./style.css";
import type { Plan } from "./planner.ts";
import { mount } from "./view.ts";

const plan: Plan = await (await fetch("/courses.json")).json();
mount(document.querySelector<HTMLElement>("#app")!, plan);
```

The page around it replaces the template's too. The `<main>` is empty, and that emptiness is what
the next section is about. Save it as `index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
  </head>
  <body>
    <main id="app"></main>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

And a few lines of style, replacing the template's long stylesheet, in `src/style.css`:

```css
body { font: 16px/1.5 system-ui, sans-serif; margin: 0 auto; max-width: 40rem; padding: 1rem; }
a { color: #1d4ed8; }
ul { padding-left: 1.2rem; }
li { margin: 0.4rem 0; }
form { display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: end; }
label { display: flex; flex-direction: column; font-size: 0.9rem; }
```

`npm run dev` starts Vite's development server. Run it in a second terminal and leave it there:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 226 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

Then, in the first terminal, ask it for the page and check that TypeScript agrees with the code:

```
ana@dev:~/planner$ curl -s http://localhost:5173/courses.json | head -3
{
  "courses": [
    { "slug": "html-css", "title": "HTML and CSS" },
ana@dev:~/planner$ npx tsc
```

`npx tsc` prints nothing when the types agree. The template's `tsconfig.json` tells it to check and
not to write any files, because Vite does the building. Open `http://localhost:5173/` in your own browser and
click around: a course, *Mark done*, the form. This is the app every lesson from here on measures.
