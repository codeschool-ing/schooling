---
title: The study planner
version: 1
---

**The planner keeps a list of courses and the study sessions you plan for each, and adds up your
week.** You open a course, add a session with a date and a number of minutes, mark it done when you
have studied, and see the week's total. That is all it does, and it is enough to need every kind of
test this course teaches. As it grows, it also needs the defences of lessons 5 to 9, and the
repairs of lessons 10 to 13 for the people this first version shuts out.

## A project from a template

Vite is the tool that serves the app while you write it and builds it for publishing. Its
`create-vite` package makes a new project from a template, and `vanilla-ts` is the one with
TypeScript and no framework:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template vanilla-ts --no-interactive

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

`npm create vite@9.3.1` downloads `create-vite` at that version and runs it; everything after the
`--` goes to it rather than to npm, and `--no-interactive` stops it asking questions it already has
answers to. It wrote a small demonstration app, a counter, which is not this course's app:

```
ana@dev:~$ cd planner
ana@dev:~/planner$ ls -A . src public
.:
.gitignore
index.html
package.json
public
src
tsconfig.json

public:
favicon.svg
icons.svg

src:
assets
counter.ts
main.ts
style.css
```

The counter's files go, and so do the two pictures it used:

```
ana@dev:~/planner$ rm -r src/counter.ts src/assets public/favicon.svg public/icons.svg
```

## The data

The planner reads its courses and sessions from one file that Vite serves as it is. Anything in
`public/` is served at the site's root, so this file will be at `/courses.json`. Save this as
`public/courses.json`:

```json
{
  "courses": [
    { "id": "html-css", "title": "HTML and CSS" },
    { "id": "javascript", "title": "JavaScript" },
    { "id": "git", "title": "Git" }
  ],
  "sessions": [
    { "id": 1, "course": "git", "date": "2026-10-14", "minutes": 20, "done": true },
    { "id": 2, "course": "html-css", "date": "2026-10-19", "minutes": 45, "done": true },
    { "id": 3, "course": "javascript", "date": "2026-10-20", "minutes": 60, "done": true },
    { "id": 4, "course": "javascript", "date": "2026-10-22", "minutes": 30, "done": false },
    { "id": 5, "course": "git", "date": "2026-10-25", "minutes": 25, "done": false },
    { "id": 6, "course": "html-css", "date": "2026-10-26", "minutes": 40, "done": false }
  ]
}
```

Three courses and six sessions in October 2026. Four of the sessions fall in the week of Monday 19
to Sunday 25 October, one the week before and one the week after, so a total for that week has
something to leave out at each end.

## The rules, apart from the page

`src/planner.ts` holds what the planner knows about sessions and weeks, and nothing about the page.
Every function in it takes values and returns a value, which is what will make it the easiest file
in the project to test. Save it as `src/planner.ts`:

```schooling-example
{"language": "typescript", "file": "src/planner.ts", "parts": [{"code": "// src/planner.ts\nexport interface Course {\n  id: string;\n  title: string;\n}\n\nexport interface Session {\n  id: number;\n  course: string;\n  date: string;\n  minutes: number;\n  done: boolean;\n}\n\nexport interface Plan {\n  courses: Course[];\n  sessions: Session[];\n}\n", "note": "Three shapes, and they are the whole of the data. A session names its course by the course's `id`, and its date is a string like `2026-10-21`, the way `courses.json` writes it."}, {"code": "export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {\n  if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);\n  if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);\n  if (!Number.isInteger(minutes) || minutes < 1 || minutes > 600) {\n    throw new Error(`minutes must be a whole number from 1 to 600, not ${minutes}`);\n  }\n  const id = Math.max(0, ...plan.sessions.map((s) => s.id)) + 1;\n  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };\n}\n", "note": "Adding a session refuses what it cannot store, and says which value it refused. It never changes the plan it was given: it returns a new one with the session on the end."}, {"code": "export function markDone(plan: Plan, id: number): Plan {\n  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };\n}\n", "note": "The same habit: a new plan, in which one session is done."}, {"code": "export function today(now: Date = new Date()): string {\n  const m = String(now.getMonth() + 1).padStart(2, \"0\");\n  const d = String(now.getDate()).padStart(2, \"0\");\n  return `${now.getFullYear()}-${m}-${d}`;\n}\n", "note": "Today's date on the student's own calendar, in the same shape as a session's. `getMonth()` counts from 0, hence the `+ 1`."}, {"code": "export function weekOf(day: string): [string, string] {\n  const d = new Date(day);\n  const monday = new Date(d);\n  monday.setDate(d.getDate() - ((d.getDay() + 6) % 7));\n  const sunday = new Date(monday);\n  sunday.setDate(monday.getDate() + 6);\n  return [monday.toISOString().slice(0, 10), sunday.toISOString().slice(0, 10)];\n}\n", "note": "The week a day belongs to, Monday to Sunday. `getDay()` says 0 for Sunday and 1 for Monday, so `(getDay() + 6) % 7` is how many days ago Monday was."}, {"code": "export function weekTotal(plan: Plan, day: string, course?: string): number {\n  const [from, to] = weekOf(day);\n  return plan.sessions\n    .filter((s) => s.date >= from && s.date <= to)\n    .filter((s) => course === undefined || s.course === course)\n    .reduce((sum, s) => sum + s.minutes, 0);\n}", "note": "The minutes planned in that week, for every course or for one. Dates written as `YYYY-MM-DD` sort as text in the same order as on a calendar, which is why `>=` and `<=` work on them."}]}
```

## Exact versions

The template asked for `vite` at `^8.3.4` and `typescript` at `~6.0.3`: a caret lets npm take any
later 8, a tilde any later 6.0. That is convenient, and it means two people installing on different
days can get different code. **This course pins every package to one version**, so what you install
is what the lessons recorded. `--save-exact` writes the number without the symbol:

```
ana@dev:~/planner$ npm install --save-exact vite@8.3.5 typescript@6.0.3

added 16 packages, and audited 17 packages in 4s

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

`npm install` also wrote `package-lock.json`, which pins every package those two brought with them,
down to the last one. Keep both files in Git. The next section writes the page.
