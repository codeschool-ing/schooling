---
title: A clean start, and the data the screen will draw
version: 1
---

**The template's page goes, and the planner's first screen takes its place.** This section clears
the template away and writes the three files that have nothing to do with React: the shape of the
data, the data itself, and the arithmetic of weeks. The four sections after it write the components
that draw them, one idea at a time, and the screen appears at the end of the fourth.

## Clearing the template

The template's stylesheet, its images and the sprite of icons in `public/` belong to the page you are
replacing:

```
ana@dev:~/planner$ rm -r src/App.css src/assets public/icons.svg
ana@dev:~/planner$ ls src public
public:
courses.json
favicon.svg

src:
App.tsx
index.css
main.tsx
```

`main.tsx` stays exactly as it was, and so does `index.html`. The planner keeps the template's
`index.css` by name and replaces what is in it with a stylesheet of its own, short enough to read
whole and with nothing in it this course depends on:

```css
:root {
  font-family: system-ui, sans-serif;
  line-height: 1.5;
  color-scheme: light dark;
}

body {
  margin: 0;
}

main {
  max-width: 36rem;
  margin: 0 auto;
  padding: 1.5rem 1rem;
}

.card {
  border: 1px solid #8888;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  margin: 0.5rem 0;
}

.card h2 {
  font-size: 1.1rem;
  margin: 0;
}

.card p {
  margin: 0.25rem 0 0;
}
```

## The shape of the data

`src/types.ts` says in TypeScript what lesson 1's `courses.json` says in JSON:

```typescript
export type Course = {
  id: string
  name: string
}

export type Session = {
  id: string
  course: string
  date: string
  minutes: number
  done: boolean
}
```

`export type` gives a shape a name that other files import. **A type exists only while you write
the code**: it tells the editor and the compiler what a `Session` holds, and nothing of it reaches
the browser. Lesson 19 says more; for now, a `Session` has five fields, and every component that
receives one knows their names and their types.

## The data, for now

The planner will fetch `public/courses.json` from the server, and that is lesson 5, because fetching
is an effect and effects have a lesson of their own. Until then the same data lives in a module:

```typescript
import type { Course, Session } from './types'

// The same data as public/courses.json, until lesson 5 fetches that file.
export const courses: Course[] = [
  { id: 'statistics', name: 'Statistics' },
  { id: 'spanish', name: 'Spanish' },
  { id: 'chemistry', name: 'Organic chemistry' },
]

export const sessions: Session[] = [
  { id: 's1', course: 'statistics', date: '2026-10-19', minutes: 50, done: true },
  { id: 's2', course: 'statistics', date: '2026-10-21', minutes: 40, done: false },
  { id: 's3', course: 'spanish', date: '2026-10-20', minutes: 30, done: true },
  { id: 's4', course: 'spanish', date: '2026-10-23', minutes: 30, done: false },
  { id: 's5', course: 'chemistry', date: '2026-10-14', minutes: 60, done: true },
  { id: 's6', course: 'chemistry', date: '2026-10-22', minutes: 45, done: false },
]
```

The `import type` line takes only the types, so the compiler can remove it completely. The two
arrays are typed with them, which means a session with `minutes: '50'` in quotes would be refused
before the app ever ran.

## Weeks, without React

Every number on the first screen depends on which sessions fall in a week. That is plain
arithmetic on dates, and it lives in a file that imports nothing from React:

```schooling-example
{"language": "typescript", "file": "src/week.ts", "parts": [{"code": "import type { Session } from './types'\n", "note": "The type of a session, imported only for its shape."}, {"code": "// A day is a 'YYYY-MM-DD' string, and a week starts on Monday. The arithmetic\n// is done at noon UTC, so that no time zone can move a date to its neighbour.\nconst noon = (day: string) => new Date(`${day}T12:00:00Z`)\n", "note": "Days travel as `'YYYY-MM-DD'` strings, like the JSON. Turning one into a `Date` at noon UTC means no time zone, however far east or west, can push it across midnight into the day before or after."}, {"code": "export function addDays(day: string, n: number): string {\n  const d = noon(day)\n  d.setUTCDate(d.getUTCDate() + n)\n  return d.toISOString().slice(0, 10)\n}\n", "note": "Adding days on the UTC calendar and cutting the result back to its first ten characters gives another day string."}, {"code": "export function mondayOf(day: string): string {\n  const back = (noon(day).getUTCDay() + 6) % 7\n  return addDays(day, -back)\n}\n", "note": "`getUTCDay()` counts Sunday as 0. Adding 6 and taking the remainder by 7 counts Monday as 0 instead, which is how many days to go back."}, {"code": "export function inWeek(day: string, monday: string): boolean {\n  return day >= monday && day <= addDays(monday, 6)\n}\n", "note": "Because the format sorts as text, a week is two string comparisons: on or after Monday, on or before Sunday."}, {"code": "export function minutes(sessions: Session[]): number {\n  return sessions.reduce((sum, s) => sum + s.minutes, 0)\n}\n", "note": "A total is a sum of `minutes` over whatever sessions it is given, all of them or only the done ones."}, {"code": "export function formatDay(day: string): string {\n  return noon(day).toLocaleDateString('en-GB', {\n    weekday: 'short', day: 'numeric', month: 'short', timeZone: 'UTC',\n  })\n}\n\nexport function formatWeek(monday: string): string {\n  return noon(monday).toLocaleDateString('en-GB', {\n    day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC',\n  })\n}", "note": "The two ways a day is printed on screen. `en-GB` puts the day before the month, and `timeZone: 'UTC'` reads the date back the way it was made."}]}
```

Ask Node, which runs a TypeScript file directly as long as it only needs its types removed:

```
ana@dev:~/planner$ node -e "import('./src/week.ts').then((w) => console.log(w.mondayOf('2026-10-21'), w.inWeek('2026-10-14', '2026-10-19'), w.formatDay('2026-10-19'), w.formatWeek('2026-10-19')))"
2026-10-19 false Mon 19 Oct 19 Oct 2026
```

Wednesday 21 October belongs to the week of Monday the 19th, the 14th does not, and the two
formats are the ones lesson 1's screens show. **Keeping this out of the components is a decision,
not a convenience**: a function that takes strings and returns strings can be checked in a line of
Node, as here, and lesson 22 tests it without a browser.
