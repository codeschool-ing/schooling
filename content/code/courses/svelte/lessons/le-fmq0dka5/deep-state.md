---
title: Deep state, and changing it in place
version: 1
---

**`$state` given an array or an object makes it deeply reactive: you change it in place, with ordinary
JavaScript, and everything that read the changed part updates.** Push onto the array, assign to a
property, splice something out: each is tracked. This is the section where the planner's sessions
become state, so that the page can add one and mark one done.

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));", "note": "The sessions become state. `$state` wraps the array, and each object in it, in a proxy that reports reads and writes."},
 {"code": "\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));", "note": "The selected course is kept by its id, a plain string, rather than as the course object."},
 {"code": "\tfunction add() {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date: week, minutes: 30, done: false });\n\t}", "note": "`push` on the state array is all it takes. Every derived value that read `sessions` is now out of date."},
 {"code": "\t$inspect(total).with(console.log);\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>", "note": "`$inspect` reports a value when it is first read and every time it changes, in development only; `.with(console.log)` prints each report as one plain line."},
 {"code": "\t<ul>\n\t\t{#each data.courses as c}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t\t{byCourse[c.id] ?? 0} min\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<p>{total} minutes this week</p>", "note": "Each course is a button now. `aria-pressed` tells a screen reader which one is selected."},
 {"code": "\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={session.done} onclick={() => (session.done = !session.done)}>\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</button>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<button onclick={add}>Add 30 minutes on {format(week)}</button>\n</main>", "note": "Each session is a toggle button: pressed when done. The handler assigns to a property of an object inside the state array."}
]}
```

Open it, add a session to Linear algebra, and mark the session of the 24th done:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Add 30 minutes on 19 Oct 2026' --click '24 Oct 2026, 60 min'
console: [vite] connecting...
console: [vite] connected.
console: init 225
-- click Add 30 minutes on 19 Oct 2026
console: update 255
-- click 24 Oct 2026, 60 min
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 180 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 255 minutes this week
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - button "13 Oct 2026, 60 min" [pressed]
    - listitem:
      - button "19 Oct 2026, 90 min" [pressed]
    - listitem:
      - button "24 Oct 2026, 60 min" [pressed]
    - listitem:
      - button "19 Oct 2026, 30 min"
  - button "Add 30 minutes on 19 Oct 2026"
```

Read the console lines first. `$inspect(total)` printed `init 225` when the page appeared and
`update 255` when the push added thirty minutes; without `.with(console.log)` it prints the same
values with a stack trace under each update, which is useful when you need to find what changed a
value and noisy when you do not. Marking a session done printed nothing, because
`total` adds up minutes and does not read `done`, so it did not change.

Then the tree. The new session is in the list with the date of the week's Monday, Linear algebra's
minutes went from 150 to 180, and the button for the 24th is now `[pressed]`, which is how a screen
reader is told that a toggle is on. **None of that code mentions the list, the total or the
buttons**: `push` and an assignment to `session.done` were enough, because the proxy reported them.

## What the proxy does, and what it does not

`$state` wraps arrays and plain objects in a **proxy**, an object that intercepts reads and writes.
Reads of `sessions[3].done` are recorded the way lesson 2 drew it, one signal per property, and a
write to `done` reaches exactly the code that read `done` of that session. It reaches into objects
inside arrays inside objects, as deep as the data goes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The sessions array inside a $state proxy. The proxy holds one signal per property it has been asked about: the array&#x27;s length, and for the session of the 24th its minutes and its done. The total read minutes, so it is on that signal&#x27;s list; the toggle button read done. Assigning session.done reaches the button and not the total; pushing a session changes length and reaches everything that walked the array.\"><rect x=\"20\" y=\"30\" width=\"330\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"36\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">$state proxy around sessions</text><rect x=\"40\" y=\"66\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">length</text><text x=\"54\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sessions[5]</text><rect x=\"54\" y=\"154\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">minutes</text><rect x=\"194\" y=\"154\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"254\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">done</text><rect x=\"450\" y=\"60\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">everything that walked the array</text><rect x=\"450\" y=\"120\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total, byCourse</text><rect x=\"450\" y=\"180\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the session's toggle button</text><line x1=\"160\" y1=\"84\" x2=\"448\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"448.0,80.0 440.7,83.2 440.6,77.0\" fill=\"var(--phosphor)\"></polygon><path d=\"M114 154 C 114 112, 380 128, 440 139\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"436\" y1=\"138\" x2=\"446\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"446.0,140.0 438.2,141.6 439.4,135.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"314\" y1=\"178\" x2=\"448\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"448.0,198.0 440.3,200.0 441.2,193.8\" fill=\"var(--phosphor)\"></polygon><text x=\"400\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">readers</text></svg>", "caption": "One signal per property that was read. Marking a session done reaches its button, and not the total."}
```

Three consequences are worth knowing before they surprise you:

- **The proxy is not the original.** `sessions` is a proxy around the data, so
  `sessions[0] === data.sessions[0]` is false. That is one reason the selected course is kept as an
  id: compare ids, which are strings, and the question does not arise.
- **Classes and other objects are left alone.** A `Date`, a `Map` or an instance of your own class is
  not proxied, so changing it in place is not seen. Svelte provides reactive versions of the common
  ones in `svelte/reactivity`, and a class can make its own fields reactive with `$state`, which
  lesson 10 does.
- **Logging a proxy shows a proxy.** `console.log(sessions)` in the browser prints a `Proxy`, which is
  hard to read. `$state.snapshot(sessions)` gives back a plain copy, and `$inspect` does that for you.

## When you do not want deep state

For a large array that you only ever replace whole, the proxy is work for nothing.
**`$state.raw(...)`** makes a value that is reactive when the variable is assigned and not when its
insides change. The planner's six sessions are changed in place, so plain `$state` is the right
choice here; a list of thousands of rows loaded from a server and replaced on each reload would be a
case for `$state.raw`.
