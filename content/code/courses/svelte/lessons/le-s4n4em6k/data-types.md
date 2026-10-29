---
title: Types for the data
version: 1
---

**TypeScript in a SvelteKit project is a matter of file names and a configuration file.** A `.ts` file is
TypeScript, a component with `<script lang="ts">` is TypeScript, and everything else stays JavaScript
and keeps working beside them. The build strips the types out; the browser and Node never see them. So
a project can be converted one file at a time, and this one is, starting where the data is described.

First the configuration. `jsconfig.json` and `tsconfig.json` are the same file under two names, the
second being what TypeScript projects use, and Node's own modules need their types installed:

```
ana@dev:~/planner$ git mv jsconfig.json tsconfig.json
```

```
ana@dev:~/planner$ npm install --save-dev @types/node@22.20.5

added 2 packages, removed 1 package, and audited 59 packages in 797ms

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

`@types/node` describes Node's built-in modules, such as `node:fs/promises`, and its major version
follows Node's: 22, as `node --version` said in lesson 1.

## The shape of a session

**The data file has a shape, and nothing so far has written it down.** Save it as `src/lib/types.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/types.ts", "parts": [
 {"code": "// types.ts: the shape of the planner's data, as the file holds it.\nexport interface Course {\n\tid: string;\n\tname: string;\n}\n\nexport interface Session {\n\tid: number;\n\tcourse: string;\n\tdate: string;\n\tminutes: number;\n\tdone: boolean;\n}\n\nexport interface PlannerData {\n\tcourses: Course[];\n\tsessions: Session[];\n}", "note": "An `interface` names a shape. It exists only for the checker: the build removes it, and nothing of it is left at run time."}
]}
```

Three files use those shapes first: the dates, the check, and the module that reads and writes the file.
Rename them, so that Git keeps their history:

```
ana@dev:~/planner$ git mv src/lib/week.js src/lib/week.ts
ana@dev:~/planner$ git mv src/lib/server/check.js src/lib/server/check.ts
ana@dev:~/planner$ git mv src/lib/server/planner.js src/lib/server/planner.ts
```

The imports elsewhere keep saying `#lib/week.js`. TypeScript and Vite both look for `week.ts` when
`week.js` does not exist, which is what lets the two languages import each other freely. Replace
`src/lib/week.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/week.ts", "parts": [
 {"code": "// week.ts: dates as 'YYYY-MM-DD' strings, and the week they fall in.\n// Weeks start on Monday.\nconst DAY = 24 * 60 * 60 * 1000;\nconst toTime = (date: string) => Date.parse(`${date}T00:00:00Z`);\nconst toDate = (time: number) => new Date(time).toISOString().slice(0, 10);"},
 {"code": "/** Whether `text` is a real date, written as 'YYYY-MM-DD'. */\nexport function isDate(text: unknown): text is string {\n\treturn typeof text === 'string' && /^\\d{4}-\\d{2}-\\d{2}$/.test(text) && toDate(toTime(text)) === text;\n}", "note": "`text is string` is a type guard: where `isDate(x)` is true, the checker treats `x` as a string. It takes `unknown` because its job is to check values nobody has checked yet."},
 {"code": "/** The Monday of the week `date` falls in. */\nexport function mondayOf(date: string) {\n\tconst day = new Date(toTime(date)).getUTCDay();\n\treturn toDate(toTime(date) - ((day + 6) % 7) * DAY);\n}\n\n/** `date` moved by `days`, which may be negative. */\nexport function addDays(date: string, days: number) {\n\treturn toDate(toTime(date) + days * DAY);\n}\n\n/** Whether `date` falls in the week that starts on `monday`. */\nexport function inWeek(date: string, monday: string) {\n\treturn date >= monday && date < addDays(monday, 7);\n}\n\n/** `2026-10-19` as `19 Oct 2026`. */\nexport function format(date: string) {\n\treturn new Date(toTime(date)).toLocaleDateString('en-GB', {\n\t\tday: 'numeric',\n\t\tmonth: 'short',\n\t\tyear: 'numeric',\n\t\ttimeZone: 'UTC'\n\t});\n}"}
]}
```

`src/lib/server/check.ts` takes values from forms and requests, which could be anything:

```schooling-example
{"language": "typescript", "file": "src/lib/server/check.ts", "parts": [
 {"code": "// check.ts: what a session must look like, wherever it comes from.\nimport { isDate } from '#lib/week.js';"},
 {"code": "/** What is wrong with a session's date and minutes, or undefined if nothing is. */\nexport function problemWith({ date, minutes }: { date: unknown; minutes: unknown }) {\n\tif (!isDate(date)) return 'The session needs a date.';\n\tif (typeof minutes !== 'number' || !Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\treturn 'Minutes must be a whole number from 5 to 600.';\n\t}\n}", "note": "`unknown` says \"check before use\", and the checker holds the function to it: `minutes < 5` is only allowed after `typeof minutes !== 'number'` has ruled the rest out."}
]}
```

and `src/lib/server/planner.ts` says what it reads and what each change takes:

```schooling-example
{"language": "typescript", "file": "src/lib/server/planner.ts", "parts": [
 {"code": "// planner.ts: the planner's data, read from and written to the file the server keeps it in.\nimport { readFile, writeFile, rename } from 'node:fs/promises';\nimport type { PlannerData, Session } from '#lib/types.js';\n\nconst FILE = 'data/planner.json';"},
 {"code": "export async function readPlanner(): Promise<PlannerData> {\n\treturn JSON.parse(await readFile(FILE, 'utf8'));\n}\n\n// Changes run one at a time: each waits for the one before it to finish, so two\n// requests arriving together cannot both read the old file and lose a change.\nlet queue: Promise<unknown> = Promise.resolve();", "note": "`Promise<PlannerData>` is a claim, not a check: `JSON.parse` returns whatever the file holds, and this line tells the checker to believe it is a planner. The last section of this lesson comes back to that."},
 {"code": "\nfunction change<T>(edit: (planner: PlannerData) => T): Promise<T> {\n\tconst result = queue.then(async () => {\n\t\tconst planner = await readPlanner();\n\t\tconst answer = edit(planner);\n\t\t// Write a new file and then put it in the old one's place, so that a crash\n\t\t// halfway through leaves the old file whole rather than half of a new one.\n\t\tawait writeFile(`${FILE}.new`, JSON.stringify(planner, null, '\\t') + '\\n');\n\t\tawait rename(`${FILE}.new`, FILE);\n\t\treturn answer;\n\t});\n\tqueue = result.catch(() => {});\n\treturn result;\n}\n\n/** Add a session; false if there is no such course. */\nexport function addSession({ course, date, minutes }: Omit<Session, 'id' | 'done'>) {\n\treturn change((planner) => {\n\t\tif (!planner.courses.some((c) => c.id === course)) return false;\n\t\tconst id = Math.max(0, ...planner.sessions.map((s) => s.id)) + 1;\n\t\tplanner.sessions.push({ id, course, date, minutes, done: false });\n\t\treturn true;\n\t});\n}\n\n/** Mark a session done or not done; the session, or undefined if there is none. */\nexport function setDone(id: number, done: boolean) {\n\treturn change((planner) => {\n\t\tconst session = planner.sessions.find((s) => s.id === id);\n\t\tif (session) session.done = done;\n\t\treturn session;\n\t});\n}", "note": "`change` is generic: `T` is whatever `edit` returns, so `addSession` gets back a boolean and `setDone` a session, each with its own type."}
]}
```

`Omit<Session, 'id' | 'done'>` is a session without the two fields the module fills in itself, which is
exactly what a caller has to provide. Count again:

```
ana@dev:~/planner$ npm run check 2>&1 | tail -1
svelte-check found 36 errors and 0 warnings in 9 files
```

**Thirty-six, from sixty-six**, and no file's behaviour has changed: every line that runs is the line
that ran before. The errors left are in the files that use these modules, which do not say yet what
their own parameters are.
