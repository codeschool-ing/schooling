---
title: The study planner, the app this course carries
version: 1
---

**Every lesson of this course takes the same small web app somewhere else**: into an Android and an
iOS project, into a desktop window, into an installer. It is a **study planner**. You list your
courses, open one, add study sessions with a date and a length, mark them done, and see how many
minutes this week holds. It is written in plain TypeScript with Vite and no framework, so nothing in
it belongs to React, Angular, Vue or Svelte, and whatever framework you learnt, the same steps apply
to your own app.

If you built the planner in `front-quality`, use yours and skip to the next section once `npm run
build` works. If you have not, this section gives you the whole of it: five short files.

## Creating the project

Vite has a starter for a TypeScript app with no framework, called `vanilla-ts`. `npm create` runs
the starter's own program without installing anything permanently. Its last lines say what to do
next, and `ls` shows what it wrote:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template vanilla-ts --no-interactive | tail -n 6
└  Done. Now run:

  cd planner
  npm install
  npm run dev

ana@dev:~$ ls -A planner planner/src
planner:
.gitignore
index.html
package.json
public
src
tsconfig.json

planner/src:
assets
counter.ts
main.ts
style.css
```

The starter writes a demonstration page with a counter and some pictures. The planner replaces all
of it, so remove the demonstration's files and then install the two tools the project needs, at the
versions this course was recorded with:

```
ana@dev:~$ cd planner
ana@dev:~/planner$ rm -r src public
ana@dev:~/planner$ npm install -E -D vite@8.3.5 typescript@6.0.3

added 16 packages, and audited 17 packages in 2s

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

**`-E` writes exact versions.** Without it npm writes `^8.3.5`, which means "8.3.5 or any later 8",
and a project that builds today may install something different next month. With it, and with the
`package-lock.json` npm writes beside it, two people installing the same project get the same
files. The lockfile goes into git; `node_modules` does not.

## The five files

Save each file under the name in its first line. **`src/planner.ts` holds the rules** and touches no
page: it adds a session, marks one done, and totals a week. Keeping it free of the DOM is what lets
lesson 7 reuse it unchanged in an app that has no DOM at all.

```typescript
// src/planner.ts: the study planner's rules, with no DOM in them.
export type Course = { id: string; name: string };
export type Session = { id: string; course: string; date: string; minutes: number; done: boolean };
export type Plan = { courses: Course[]; sessions: Session[] };

export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {
  if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);
  if (!Number.isInteger(minutes) || minutes <= 0) throw new Error(`not a duration: ${minutes}`);
  const id = `s${plan.sessions.length + 1}`;
  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };
}

export function markDone(plan: Plan, id: string): Plan {
  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };
}

// The Monday of the week a date falls in, as YYYY-MM-DD.
export function mondayOf(date: string): string {
  const d = new Date(`${date}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return d.toISOString().slice(0, 10);
}

// Minutes planned in the week that starts on `monday`, and how many are done.
export function weekTotal(plan: Plan, monday: string): { planned: number; done: number } {
  const end = new Date(`${monday}T12:00:00Z`);
  end.setUTCDate(end.getUTCDate() + 7);
  const last = end.toISOString().slice(0, 10);
  const week = plan.sessions.filter((s) => s.date >= monday && s.date < last);
  return {
    planned: week.reduce((n, s) => n + s.minutes, 0),
    done: week.filter((s) => s.done).reduce((n, s) => n + s.minutes, 0),
  };
}
```

**`src/view.ts` draws the plan** and reports what the person did. Every control is a real `<button>`
or a labelled `<input>`, so a keyboard and a screen reader reach all of it without any extra work:

```typescript
// src/view.ts: draws the plan, and tells main.ts what the person did.
import { weekTotal, type Plan } from "./planner";

export type Actions = {
  open: (course: string | null) => void;
  add: (course: string, date: string, minutes: number) => void;
  done: (session: string) => void;
};

function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = ""): HTMLElementTagNameMap[K] {
  const e = document.createElement(tag);
  e.textContent = text;
  return e;
}

export function render(root: HTMLElement, plan: Plan, monday: string, open: string | null, act: Actions) {
  root.replaceChildren();
  const total = weekTotal(plan, monday);
  const week = el("p", `This week: ${total.done} of ${total.planned} minutes done`);
  week.id = "week";
  const course = plan.courses.find((c) => c.id === open);
  if (!course) {
    root.append(el("h1", "Study planner"), week);
    const list = el("ul");
    for (const c of plan.courses) {
      const b = el("button", c.name);
      b.addEventListener("click", () => act.open(c.id));
      const li = el("li");
      li.append(b);
      list.append(li);
    }
    root.append(list);
    return;
  }
  const back = el("button", "All courses");
  back.addEventListener("click", () => act.open(null));
  root.append(back, el("h1", course.name), week);
  const list = el("ul");
  for (const s of plan.sessions.filter((s) => s.course === course.id)) {
    const li = el("li", `${s.date}, ${s.minutes} min `);
    if (s.done) li.append(el("span", "done"));
    else {
      const b = el("button", "Mark done");
      b.addEventListener("click", () => act.done(s.id));
      li.append(b);
    }
    list.append(li);
  }
  const form = el("form");
  form.innerHTML = `<label>Date <input name="date" type="date" required></label>
<label>Minutes <input name="minutes" type="number" min="1" required></label>
<button>Add session</button>`;
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const f = new FormData(form);
    act.add(course.id, String(f.get("date")), Number(f.get("minutes")));
  });
  root.append(list, form);
}
```

**`src/main.ts` connects the two.** It loads the data, keeps the current plan, and redraws after each
change. The `?today=` in the address is for this course: it lets every transcript show the same week,
whatever day you read it. Without it the planner uses the real date.

```typescript
// src/main.ts: loads the plan, keeps it, and redraws it after every change.
import { addSession, markDone, mondayOf, type Plan } from "./planner";
import { render } from "./view";

const root = document.querySelector<HTMLElement>("#app")!;
const today = new URLSearchParams(location.search).get("today") ?? new Date().toISOString().slice(0, 10);
let plan: Plan = await (await fetch("courses.json")).json();
let open: string | null = null;

function draw() {
  render(root, plan, mondayOf(today), open, {
    open: (c) => { open = c; draw(); },
    add: (c, d, m) => { plan = addSession(plan, c, d, m); draw(); },
    done: (s) => { plan = markDone(plan, s); draw(); },
  });
}
draw();
```

The page itself replaces the starter's, as `index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
  </head>
  <body>
    <main id="app"></main>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

And the data, three courses and six sessions in the second half of October 2026, saved as
`public/courses.json`:

```json
{
  "courses": [
    { "id": "spanish", "name": "Spanish A2" },
    { "id": "statistics", "name": "Statistics" },
    { "id": "guitar", "name": "Guitar" }
  ],
  "sessions": [
    { "id": "s1", "course": "spanish", "date": "2026-10-19", "minutes": 30, "done": true },
    { "id": "s2", "course": "statistics", "date": "2026-10-20", "minutes": 45, "done": true },
    { "id": "s3", "course": "guitar", "date": "2026-10-21", "minutes": 20, "done": false },
    { "id": "s4", "course": "spanish", "date": "2026-10-22", "minutes": 30, "done": false },
    { "id": "s5", "course": "statistics", "date": "2026-10-26", "minutes": 60, "done": false },
    { "id": "s6", "course": "guitar", "date": "2026-10-28", "minutes": 20, "done": false }
  ]
}
```

Vite copies whatever is in `public/` into the built site as it is, so the app fetches the file by its
plain name, `courses.json`.

## Building it

`npm run build` runs the two commands `package.json` names: `tsc`, which checks the types and writes
nothing, and `vite build`, which writes the finished site into `dist/`:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 6 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                0.32 kB │ gzip: 0.23 kB
dist/assets/index-kF5hUKai.js  2.90 kB │ gzip: 1.34 kB

✓ built in 150ms
```

**`dist/` is the thing every later lesson wraps.** Capacitor copies it into an Android and an iOS
project, Electron and Tauri load it into a window. If `npm run build` fails, nothing downstream can
work, so this command comes first whenever something looks wrong.

Last, make the project a git repository, so every later lesson can show you exactly what a tool
added to it:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -q -m "The study planner, as lesson 1 gives it"
ana@dev:~/planner$ git log --oneline
558b1c0 The study planner, as lesson 1 gives it
```
