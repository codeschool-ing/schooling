---
title: The page, and the planner running
version: 1
---

**The page is three small files: `index.html` loads one script, `src/main.ts` fetches the data,
and `src/view.ts` draws the screen from it.** Save each under the name in its first line.

`index.html` is the template's with the title changed and the icon gone:

```html
<!-- index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

The book drawn beside each course goes in `public/`:

```xml
<!-- public/book.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path d="M2 2h5a2 2 0 0 1 1 .3A2 2 0 0 1 9 2h5v11H9a1 1 0 0 0-1 1 1 1 0 0 0-1-1H2z" fill="none" stroke="#2f6f4e" stroke-width="1.2"/></svg>
```

## Drawing the screen

`src/view.ts` turns a plan into elements. It builds them one by one with `createElement` and puts
text in with `textContent`, apart from the three fields of the form, which are short enough to
write as markup:

```schooling-example
{"language": "typescript", "file": "src/view.ts", "parts": [{"code": "// src/view.ts\nimport { addSession, markDone, weekTotal, type Plan } from \"./planner\";\n\nexport function render(root: HTMLElement, plan: Plan, day: string, route: string, update: (next: Plan) => void): void {\n  const course = plan.courses.find((c) => route === `#/course/${c.id}`);\n  root.replaceChildren();", "note": "One function draws the whole screen into `root`, from the plan, today's date and the address after `#`. When something changes it does not touch the plan itself: it hands a new plan to `update`, and whoever called it draws again."}, {"code": "  if (!course) {\n    root.append(el(\"h1\", \"Study planner\"));\n    const list = el(\"ul\", \"\", \"courses\");\n    for (const c of plan.courses) {\n      const link = el(\"a\", c.title);\n      link.href = `#/course/${c.id}`;\n      const icon = el(\"img\");\n      icon.src = \"/book.svg\";\n      link.prepend(icon);\n      const item = el(\"li\");\n      item.append(link, el(\"span\", ` ${weekTotal(plan, day, c.id)} min this week`, \"mins\"));\n      list.append(item);\n    }\n    root.append(list, el(\"p\", `This week: ${weekTotal(plan, day)} min`, \"week\"));\n    return;\n  }", "note": "No course in the address: the list of courses, each a link to its own page with a small book in front of it, and the week's total for everything at the bottom."}, {"code": "  const back = el(\"a\", \"←\", \"back\");\n  back.href = \"#/\";\n  root.append(back, el(\"h1\", course.title));\n  const list = el(\"ul\", \"\", \"sessions\");\n  for (const s of plan.sessions.filter((s) => s.course === course.id)) {\n    const item = el(\"li\", `${s.date} · ${s.minutes} min `, s.done ? \"session done\" : \"session\");\n    if (s.done) {\n      item.append(el(\"span\", \"done\", \"state\"));\n    } else {\n      const tick = el(\"button\", \"Done\", \"tick\");\n      tick.addEventListener(\"click\", () => update(markDone(plan, s.id)));\n      item.append(tick);\n    }\n    list.append(item);\n  }", "note": "A course's page: an arrow back to the list, the title, and its sessions. A session still to do carries a Done button; one already done says so."}, {"code": "  const form = el(\"form\", \"\", \"add\");\n  form.innerHTML = `<input name=\"date\" type=\"date\" placeholder=\"Date\">\n    <input name=\"minutes\" type=\"number\" placeholder=\"Minutes\">\n    <button>Add session</button>`;\n  form.addEventListener(\"submit\", (event) => {\n    event.preventDefault();\n    const data = new FormData(form);\n    update(addSession(plan, course.id, String(data.get(\"date\")), Number(data.get(\"minutes\"))));\n  });\n  root.append(list, form, el(\"p\", `This week: ${weekTotal(plan, day, course.id)} min`, \"week\"));\n}\n", "note": "The form that adds a session, and the course's total for the week. `preventDefault()` keeps the browser from sending the form anywhere; `FormData` reads the two fields by their `name`."}, {"code": "function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = \"\", cls = \"\"): HTMLElementTagNameMap[K] {\n  const e = document.createElement(tag);\n  e.textContent = text;\n  if (cls) e.className = cls;\n  return e;\n}", "note": "A small helper: an element, its text and its class in one call. The type parameter makes `el(\"a\")` an `HTMLAnchorElement`, so `link.href` type-checks."}]}
```

## Starting it

`src/main.ts` is the entry point `index.html` names. It fetches the data, keeps the current plan,
and draws again whenever the plan or the address changes:

```typescript
// src/main.ts
import "./style.css";
import { today, type Plan } from "./planner";
import { render } from "./view";

const root = document.querySelector<HTMLElement>("#app")!;
let plan: Plan = { courses: [], sessions: [] };

function draw(): void {
  render(root, plan, today(), location.hash, (next) => {
    plan = next;
    draw();
  });
}

const response = await fetch("/courses.json");
if (response.ok) {
  plan = await response.json();
  window.addEventListener("hashchange", draw);
  draw();
} else {
  root.textContent = "Could not load your courses.";
}
```

`await` at the top of a module is allowed in every current browser, and it means nothing is drawn
until the data has arrived. A plan you add to lives only in memory: reload the page and it is back to
the file. Lesson 5 gives it somewhere to be kept.

And the styles, which are short and, as lessons 10 to 13 show, not all correct:

```css
/* src/style.css */
body { font-family: system-ui, sans-serif; margin: 2rem auto; max-width: 36rem; padding: 0 1rem; color: #1d1d1d; }
a { color: #2f6f4e; }
ul { padding: 0; list-style: none; }
li { padding: 0.4rem 0; border-bottom: 1px solid #ddd; }
.courses img { vertical-align: middle; margin-right: 0.4rem; }
.mins { color: #555; }
.session.done { color: #aaa; }
.tick { font-size: 0.7rem; padding: 1px 4px; }
button:focus { outline: none; }
.add { display: flex; gap: 0.5rem; margin: 1rem 0; }
.week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
@keyframes pulse { 50% { transform: scale(1.06); } }
```

TypeScript checks the whole project without running it, and says nothing when it is happy:

```
ana@dev:~/planner$ npx tsc --noEmit
```

Then the development server:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 176 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

**Open `http://localhost:5173/` in your browser.** You see the three courses, each with its minutes
this week, and the total under them; a course's name opens its page, with its sessions, a Done
button on each one still to do, and a form to add another. The totals are all 0 unless your
calendar says it is the week of 19 October 2026, because "this week" is read from the computer's
clock. Lesson 4 sets the clock of the browser its tests drive, which is how a test of a date gets
the same answer every day. The server keeps running until you
press Ctrl+C in its terminal, and it reloads the page each time you save a file.

What the browser receives is worth one look, from a second terminal. The data comes as it is in
`public/`, and a TypeScript file comes with its types removed, because a browser runs JavaScript
and nothing else:

```
ana@dev:~/planner$ curl -s http://localhost:5173/courses.json | head -n 4
{
  "courses": [
    { "id": "html-css", "title": "HTML and CSS" },
    { "id": "javascript", "title": "JavaScript" },
ana@dev:~/planner$ curl -s http://localhost:5173/src/planner.ts | head -n 3
export function addSession(plan, course, date, minutes) {
	if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);
	if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);
```

## Into Git

The project is a repository from here on. The template's `.gitignore` already leaves out
`node_modules`, which `npm ci` can rebuild from the lockfile:

```
ana@dev:~/planner$ git init
Initialized empty Git repository in /home/ana/planner/.git/
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "The study planner"
ana@dev:~/planner$ git log --oneline
050e2d3 The study planner
```

Every lesson in this course ends with a commit like this one, so `git log` is the course's own
record of what changed and why.
