---
title: A round trip through process death, on your computer
version: 1
---

**A program can play both halves of the round trip: save the screen's UI state, be killed with no
warning, and on the next run read the state back and draw the same screen.** On a phone the system
does the killing. Here the program does it to itself, with the one signal no process can catch, so
that what survives is only what was written down before.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l05-round-trip\" aria-label=\"A round trip through process death. Process 1, node restore.ts use: Ana opens a course, scrolls and types 45; on the way out the program writes the UI state. Then the kill: SIGKILL, and nothing more runs. The UI state is in saved-state.json: course id, scroll position and draft. Process 2, node restore.ts open, starts from nothing, as an app does at onCreate, reads the saved state and draws the same screen.\"><defs><marker id=\"l05-round-trip-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"290\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165.0\" y=\"66.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">process 1: restore.ts use</text><text x=\"165.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Ana opens a course, scrolls, types \"45\"</text><text x=\"165.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">on the way out: writes the UI state</text><rect x=\"410\" y=\"40\" width=\"290\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"555.0\" y=\"66.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">process 2: restore.ts open</text><text x=\"555.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">starts from nothing, like onCreate</text><text x=\"555.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reads the UI state, draws the screen</text><path d=\"M360 32 L360 140\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">the kill: SIGKILL, and nothing more runs</text><rect x=\"250\" y=\"166\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"181.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">saved-state.json</text><text x=\"360.0\" y=\"194.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">course id · scroll · draft</text><path d=\"M165 118 L165 188 L248 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-round-trip-ah-paper-dim)\"></path><path d=\"M472 188 L555 188 L555 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-round-trip-ah-paper-dim)\"></path></svg>", "caption": "What crosses the kill is what was written before it. The process, its memory and its exit handler do not."}
```

## restore.ts

It has three modes: `use` plays Ana working in the app until the system kills it, `open` is the next
launch, and `sizes` is for the next section. Save it in `~/planner` as `restore.ts`:

```schooling-example
{"language": "typescript", "file": "restore.ts", "parts": [{"code": "// restore.ts: the screen's state, saved on the way out and put back after a kill\nimport { existsSync, readFileSync, writeFileSync } from \"node:fs\";\nimport { weekTotal, type Plan, type Session } from \"./planner.ts\";\n\n// The data. In the app it lives in a database on the device (lesson 16).\nconst plan: Plan = {\n  courses: [\n    { id: \"sql\", title: \"SQL Databases\" },\n    { id: \"mobile\", title: \"Mobile Fundamentals\" },\n  ],\n  sessions: [\n    { id: \"s1\", courseId: \"sql\", date: \"2026-10-19\", minutes: 50, done: true },\n    { id: \"s2\", courseId: \"mobile\", date: \"2026-10-20\", minutes: 40, done: true },\n    { id: \"s3\", courseId: \"sql\", date: \"2026-10-23\", minutes: 60, done: false },\n    { id: \"s5\", courseId: \"mobile\", date: \"2026-10-22\", minutes: 30, done: false },\n  ],\n};\n", "note": "The data, as a constant standing in for the database. It survives the kill because it was never only in memory, so nothing here saves it."}, {"code": "// The UI state: where the user was and what they had half typed. Ids, not objects.\ntype UiState = {\n  courseId: string;\n  scrollY: number;\n  draft: { date: string; minutes: string } | null;\n};\nconst FILE = \"saved-state.json\";\nconst TODAY = \"2026-10-21\";\n\nfunction draw(ui: UiState) {\n  const course = plan.courses.find((c) => c.id === ui.courseId);\n  if (!course) throw new Error(`saved state names a course that does not exist: ${ui.courseId}`);\n  const own = { ...plan, sessions: plan.sessions.filter((s) => s.courseId === course.id) };\n  const t = weekTotal(own, TODAY);\n  console.log(`  ${course.title}, week of ${t.monday}: ${t.done} of ${t.planned} minutes done`);\n  console.log(`  scrolled to ${ui.scrollY} px`);\n  console.log(ui.draft ? `  new session, not saved yet: ${ui.draft.date}, \"${ui.draft.minutes}\" minutes` : \"  no session being written\");\n}\n", "note": "The UI state names the course by its id and keeps the typed minutes as a string. `draw` is the screen: it looks the course up in the data and computes the week's numbers again rather than trusting a saved copy."}, {"code": "const mode = process.argv[2] ?? \"open\";\n\nif (mode === \"use\") {\n  // Ana opens a course, scrolls, starts typing a session...\n  const ui: UiState = { courseId: \"mobile\", scrollY: 640, draft: { date: \"2026-10-22\", minutes: \"45\" } };\n  console.log(\"on screen:\");\n  draw(ui);\n  process.on(\"exit\", () => console.log(\"goodbye\")); // never printed\n  // ...the app goes to the background, and saves while it is still being told things.\n  const text = JSON.stringify(ui);\n  writeFileSync(FILE, text);\n  console.log(`saved ${Buffer.byteLength(text)} bytes to ${FILE}`);\n  // The system kills the suspended process: no callback, no exit handler.\n  process.kill(process.pid, \"SIGKILL\");\n", "note": "`use` draws the screen, saves the UI state on the way out, and then kills its own process with `SIGKILL`, the signal no handler can catch. The `exit` handler is there to show that it does not run."}, {"code": "} else if (mode === \"open\") {\n  if (existsSync(FILE)) {\n    console.log(`restored from ${FILE}:`);\n    draw(JSON.parse(readFileSync(FILE, \"utf8\")) as UiState);\n  } else {\n    console.log(\"nothing saved, a fresh start:\");\n    draw({ courseId: plan.courses[0].id, scrollY: 0, draft: null });\n  }\n", "note": "`open` is the next launch: a new process that knows nothing, reads the saved state if there is one, and otherwise opens on its default screen."}, {"code": "} else if (mode === \"sizes\") {\n  // The same screen, saved two ways, for a plan of 2,000 sessions.\n  const sessions: Session[] = [];\n  for (let i = 1; i <= 2000; i++) {\n    const day = String(1 + (i % 28)).padStart(2, \"0\");\n    sessions.push({ id: `s${i}`, courseId: i % 2 ? \"sql\" : \"mobile\", date: `2026-11-${day}`, minutes: 30 + (i % 4) * 15, done: i % 3 === 0 });\n  }\n  const big = { ...plan, sessions };\n  const ui: UiState = { courseId: \"mobile\", scrollY: 640, draft: { date: \"2026-10-22\", minutes: \"45\" } };\n  const ids = Buffer.byteLength(JSON.stringify(ui));\n  const whole = Buffer.byteLength(JSON.stringify({ ...ui, course: big.courses[1], plan: big }));\n  console.log(`ids only:       ${ids} bytes`);\n  console.log(`the whole plan: ${whole} bytes, ${(whole / 1024).toFixed(1)} KiB, ${Math.round(whole / ids)} times as much`);\n} else {\n  console.error(`unknown mode \"${mode}\": use, open or sizes`);\n  process.exit(1);\n}", "note": "`sizes` builds a plan of 2,000 generated sessions and measures the same screen saved two ways: by ids, and with the course and the whole plan inside it. Any other mode is refused by name."}]}
```

## First launch, with nothing saved

```
ana@dev:~/planner$ node restore.ts open
nothing saved, a fresh start:
  SQL Databases, week of 2026-10-19: 50 of 110 minutes done
  scrolled to 0 px
  no session being written
```

**With no saved state the app opens on its default**, the first course, at the top, with no form open.
That is the correct first launch, and it is also what the user would see after a kill if the app saved
nothing: the plan is still there, because it is data, and everything about where they were is gone.

## Using it, and being killed

```
ana@dev:~/planner$ node restore.ts use; echo "exit status $?"
on screen:
  Mobile Fundamentals, week of 2026-10-19: 40 of 70 minutes done
  scrolled to 640 px
  new session, not saved yet: 2026-10-22, "45" minutes
saved 80 bytes to saved-state.json
bash: line 1:     5 Killed                  node restore.ts use
exit status 137
```

**Read the last two lines together.** The state was written while the program was still running, the
equivalent of `onStop` or `.background`. Then the process received `SIGKILL`, the signal that ends a
process without running any more of its code, and the shell reported it: `Killed`, and an exit status
of 137, which is 128 plus the signal's number, 9. The `exit` handler registered a few lines earlier
never printed its `goodbye`, because nothing in a killed process runs, which is lesson 4's rule seen
from the inside.

What was written is small enough to read whole:

```
ana@dev:~/planner$ cat saved-state.json; echo
{"courseId":"mobile","scrollY":640,"draft":{"date":"2026-10-22","minutes":"45"}}
```

## The next launch

```
ana@dev:~/planner$ node restore.ts open
restored from saved-state.json:
  Mobile Fundamentals, week of 2026-10-19: 40 of 70 minutes done
  scrolled to 640 px
  new session, not saved yet: 2026-10-22, "45" minutes
```

**The same screen, from a new process.** The course, the scroll position and the half-typed "45" are
back, and the week's numbers were not saved at all: they were computed again from the plan, because
they are derived from the data and a saved copy could have gone stale. The saved state named the
course by its id, `mobile`, and the title came from the data, so a course renamed while the app was
dead would come back with its new name.

**This is the restore path a rotation does not prove.** Lesson 4's model said a killed app can only be
launched again; this is that launch, with the one thing that makes it look like a return.

Commit the file, and keep the saved state out of the repository, since it belongs to a run and not to
the program:

```
ana@dev:~/planner$ echo saved-state.json >> .gitignore
ana@dev:~/planner$ git add .gitignore restore.ts
ana@dev:~/planner$ git commit -q -m "Saved UI state, restored after a kill"
ana@dev:~/planner$ git status --short
```
