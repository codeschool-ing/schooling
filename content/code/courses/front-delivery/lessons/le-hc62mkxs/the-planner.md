---
title: The study planner, the app this course ships
version: 1
---

**Every lesson of this course works on one small app, and you build it here, whole.** It is a study
planner: it lists your courses, opens one, lets you add study sessions with a date and a length, marks
them done, and shows the total for the week. It is plain TypeScript built with Vite, with no framework,
because nothing this course teaches depends on one: a host serves the files a React, Angular, Vue or
Svelte build writes exactly as it serves these. If you took front-quality or front-performance you
have met this app already. The files below are the version this course starts from, so build it again
from them: if a `~/planner` from an earlier course is still there, move it aside first with
`mv ~/planner ~/planner-before`, and nothing you added to it changes what you see here.

## The project

`npm create vite` writes a starter project from a template. The version after the `@` is pinned so
that you get the same files this lesson got, and `vanilla-ts` is the template with TypeScript and no
framework:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template vanilla-ts --no-interactive
npm warn exec The following package was not found and will be installed: create-vite@9.3.1

> npx
> cva planner --template vanilla-ts --no-interactive


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/planner...
│
└  Done. Now run:

  cd planner
  npm install
  npm run dev
```

The template comes with a counter demo, which goes, and with its dependencies written as ranges:
`^8.3.4` means any 8.x from 8.3.4 up. **This course pins exact versions**, so that the build you run in
lesson 3 on a clean machine is the build you ran here, and `--save-exact` writes them without the `^`:

```
ana@dev:~$ cd planner
ana@dev:~/planner$ rm -r src/counter.ts src/assets public/icons.svg
ana@dev:~/planner$ npm install --save-dev --save-exact vite@8.3.5 typescript@6.0.3

added 16 packages, and audited 17 packages in 10s

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

The two versions in `package.json` are now exact: **Vite 8.3.5 and TypeScript 6.0.3**. The lockfile,
`package-lock.json`, records the exact version of every package underneath them too, and it is
committed with the code. Lesson 3 says why that file is the one CI trusts.

## The data

The planner reads one file, served beside the page. Anything in `public/` is copied into the build
unchanged, so this file is reachable at `/courses.json` both while you develop and once it is deployed.

```schooling-example
{"language": "json", "file": "public/courses.json", "parts": [
 {"code": "{\n  \"courses\": [\n    { \"id\": \"html-css\", \"title\": \"HTML and CSS\" },\n    { \"id\": \"javascript\", \"title\": \"JavaScript\" },\n    { \"id\": \"git\", \"title\": \"Git\" }\n  ],", "note": "Three courses. The `id` is what a link and a session refer to; the `title` is only what a person reads, and it can change without breaking anything."},
 {"code": "  \"sessions\": [\n    { \"id\": 1, \"course\": \"html-css\", \"date\": \"2026-10-05\", \"minutes\": 50, \"done\": true },\n    { \"id\": 2, \"course\": \"javascript\", \"date\": \"2026-10-06\", \"minutes\": 40, \"done\": true },\n    { \"id\": 3, \"course\": \"git\", \"date\": \"2026-10-08\", \"minutes\": 30, \"done\": true },", "note": "Six sessions in October 2026. A date is written as `YYYY-MM-DD`, which sorts correctly as text, so two dates can be compared with `<` without parsing either."},
 {"code": "    { \"id\": 4, \"course\": \"javascript\", \"date\": \"2026-10-12\", \"minutes\": 60, \"done\": true },\n    { \"id\": 5, \"course\": \"html-css\", \"date\": \"2026-10-14\", \"minutes\": 25, \"done\": false },\n    { \"id\": 6, \"course\": \"javascript\", \"date\": \"2026-10-15\", \"minutes\": 45, \"done\": false }\n  ]\n}", "note": "The last three fall in the week starting Monday 12 October, which is the week the front page totals: 130 minutes planned, 60 of them done."}
]}
```

## The rules, with no DOM in them

`src/planner.ts` holds what the app knows about sessions, as functions that take data and return
data. None of them touches the page, which is what lets lesson 3 test them without a browser.

```schooling-example
{"language": "typescript", "file": "src/planner.ts", "parts": [
 {"code": "// src/planner.ts\nexport interface Course {\n  id: string;\n  title: string;\n}\n\nexport interface Session {\n  id: number;\n  course: string;\n  date: string;\n  minutes: number;\n  done: boolean;\n}", "note": "The two shapes in `courses.json`, written as types. A session names its course by `id`, never by title."},
 {"code": "\nexport function addSession(sessions: Session[], course: string, date: string, minutes: number): Session[] {\n  const id = Math.max(0, ...sessions.map((s) => s.id)) + 1;\n  return [...sessions, { id, course, date, minutes, done: false }];\n}", "note": "A new list with one more session, never a change to the old one. The id is one more than the largest; `Math.max(0, …)` gives 1 for an empty list."},
 {"code": "\nexport function markDone(sessions: Session[], id: number): Session[] {\n  return sessions.map((s) => (s.id === id ? { ...s, done: true } : s));\n}", "note": "The same list with one session copied and marked done. Done is never undone here."},
 {"code": "\nexport function mondayOf(date: string): string {\n  const d = new Date(`${date}T00:00:00Z`);\n  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));\n  return d.toISOString().slice(0, 10);\n}", "note": "The Monday that starts a date's week. Everything is in UTC, so the answer is the same whatever time zone the reader's computer is in. `getUTCDay()` is 0 on a Sunday, and `+ 6) % 7` turns that into six days back."},
 {"code": "\nexport function weekTotal(sessions: Session[], monday: string): { planned: number; done: number } {\n  const next = new Date(`${monday}T00:00:00Z`);\n  next.setUTCDate(next.getUTCDate() + 7);\n  const end = next.toISOString().slice(0, 10);\n  const week = sessions.filter((s) => s.date >= monday && s.date < end);\n  const sum = (list: Session[]) => list.reduce((n, s) => n + s.minutes, 0);\n  return { planned: sum(week), done: sum(week.filter((s) => s.done)) };\n}", "note": "Minutes planned and minutes done from that Monday up to, and not including, the next one."}
]}
```

## The page

`src/view.ts` builds the three screens as elements. Every piece of text goes in through `textContent`,
which treats it as text and never as markup, so a course title containing `<` is shown as a `<`.

```typescript
// src/view.ts
import type { Course, Session } from "./planner";

export interface Actions {
  add(date: string, minutes: number): void;
  done(id: number): void;
}

const base = import.meta.env.BASE_URL;

function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = ""): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  node.textContent = text;
  return node;
}

export function courseList(courses: Course[], week: { planned: number; done: number }): HTMLElement {
  const main = el("main");
  const list = el("ul");
  for (const course of courses) {
    const link = el("a", course.title);
    link.href = `${base}course/${course.id}`;
    list.append(el("li"));
    list.lastElementChild!.append(link);
  }
  main.append(el("h1", "Study planner"), el("p", `This week: ${week.planned} min planned, ${week.done} min done`), list);
  return main;
}

export function coursePage(course: Course, sessions: Session[], actions: Actions): HTMLElement {
  const main = el("main");
  const back = el("a", "All courses");
  back.href = base;
  const list = el("ul");
  for (const s of sessions) {
    const item = el("li", `${s.date} · ${s.minutes} min `);
    if (s.done) {
      item.append(el("span", "done"));
    } else {
      const button = el("button", "Mark done");
      button.addEventListener("click", () => actions.done(s.id));
      item.append(button);
    }
    list.append(item);
  }
  const form = el("form");
  const date = el("input");
  date.type = "date";
  date.required = true;
  const minutes = el("input");
  minutes.type = "number";
  minutes.min = "5";
  minutes.required = true;
  const dateLabel = el("label", "Date ");
  dateLabel.append(date);
  const minutesLabel = el("label", "Minutes ");
  minutesLabel.append(minutes);
  form.append(dateLabel, minutesLabel, el("button", "Add session"));
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    actions.add(date.value, Number(minutes.value));
  });
  main.append(back, el("h1", course.title), list, el("h2", "New session"), form);
  return main;
}

export function notFound(): HTMLElement {
  const main = el("main");
  const back = el("a", "All courses");
  back.href = base;
  main.append(el("h1", "Not found"), back);
  return main;
}
```

**`import.meta.env.BASE_URL` is the one line in this file that matters to a deploy.** It is the path
the site is served from, `/` unless the build is told otherwise, and every link starts with it. The
last section of this lesson is about the day it is not `/`.

`src/main.ts` holds the state and decides which screen to draw from the address:

```schooling-example
{"language": "typescript", "file": "src/main.ts", "parts": [
 {"code": "// src/main.ts\nimport \"./style.css\";\nimport { addSession, markDone, mondayOf, weekTotal, type Course, type Session } from \"./planner\";\nimport { courseList, coursePage, notFound } from \"./view\";\n\nconst base = import.meta.env.BASE_URL;\nconst app = document.querySelector<HTMLDivElement>(\"#app\")!;\nlet courses: Course[] = [];\nlet sessions: Session[] = [];", "note": "The whole state is two lists in memory. Nothing is saved: reloading the page goes back to what `courses.json` says, which is all a course about delivery needs."},
 {"code": "\nfunction render(): void {\n  const path = location.pathname.slice(base.length);\n  if (path === \"\") {\n    const latest = sessions.map((s) => s.date).sort().at(-1) ?? \"2026-10-01\";\n    app.replaceChildren(courseList(courses, weekTotal(sessions, mondayOf(latest))));\n    return;\n  }", "note": "The address IS the screen. At the base path, the list of courses, with the total for the week of the latest session."},
 {"code": "  const course = courses.find((c) => path === `course/${c.id}`);\n  if (!course) {\n    app.replaceChildren(notFound());\n    return;\n  }", "note": "Any other path that names no course draws the app's own *Not found* screen."},
 {"code": "  const own = sessions.filter((s) => s.course === course.id);\n  app.replaceChildren(\n    coursePage(course, own, {\n      add(date, minutes) {\n        sessions = addSession(sessions, course.id, date, minutes);\n        render();\n      },\n      done(id) {\n        sessions = markDone(sessions, id);\n        render();\n      },\n    }),\n  );\n}", "note": "A course's own page. Each action replaces the list with the one `planner.ts` returns and draws the screen again."},
 {"code": "\ndocument.addEventListener(\"click\", (event) => {\n  const link = (event.target as Element).closest(\"a\");\n  if (link && link.origin === location.origin && link.pathname.startsWith(base)) {\n    event.preventDefault();\n    history.pushState(null, \"\", link.pathname);\n    render();\n  }\n});\nwindow.addEventListener(\"popstate\", render);", "note": "A click on one of the app's own links changes the address with `history.pushState` and draws the new screen, without asking the server for a page. The Back button fires `popstate`."},
 {"code": "\nasync function start(): Promise<void> {\n  const response = await fetch(`${base}courses.json`);\n  ({ courses, sessions } = await response.json());\n  render();\n}\n\nstart();", "note": "Fetch the data, then draw. The data's address starts with the base path too."}
]}
```

**The addresses are real paths, `/course/git`, and not fragments like `#/course/git`.** That is a
choice with a cost, and lesson 4 pays it: a host asked for `/course/git` directly looks for a file of
that name, and there is none.

The last three files are short. The stylesheet:

```css
/* src/style.css */
body {
  font-family: system-ui, sans-serif;
  margin: 2rem auto;
  max-width: 40rem;
  padding: 0 1rem;
  line-height: 1.5;
}

li {
  margin: 0.25rem 0;
}

form {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  align-items: end;
}
```

The page, which is the template's with its title changed and a comment naming it:

```html
<!-- index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

## Running it

`npm run dev` starts Vite's development server, which compiles each file as the browser asks for it.
It holds the terminal, so start it in one and use a second:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 269 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

```
ana@dev:~/planner$ curl -s http://localhost:5173/courses.json | head -3
{
  "courses": [
    { "id": "html-css", "title": "HTML and CSS" },
```

Open `http://localhost:5173/` in your browser. You should see the heading *Study planner*, the line
*This week: 130 min planned, 60 min done*, and the three courses as links. Open *JavaScript*: three
sessions, one done, a form below them. Add one and it appears in the list; press *Mark done* and the
button becomes the word *done*. Back on the front page, a session you added in the same week moves the
total.

Then make it a repository, which is where everything after this starts:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -qm "The study planner"
ana@dev:~/planner$ git log --oneline
833a261 The study planner
```

The template's `.gitignore` already leaves out `node_modules` and `dist`, so the commit holds the
source, the lockfile and nothing built.
