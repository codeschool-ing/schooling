---
title: State in a .svelte.js module
version: 1
---

**Runes work outside components, in any file whose name ends in `.svelte.js`**, and that is what
replaced most stores in Svelte 5. A class with `$state` fields and `$derived` fields is reactive state
you can create, pass around and test, written as an ordinary class. The planner's state has been
growing inside `Planner.svelte` since lesson 3: three pieces of state, seven derived values and two
functions, all mixed with the markup. This section moves them into a class of their own.

Save this as `src/lib/planner.svelte.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/planner.svelte.js", "parts": [
 {"code": "// planner.svelte.js: the planner's state and its rules, outside any component.\nimport { mondayOf, addDays, inWeek } from '#lib/week.js';", "note": "The file name is what lets the compiler read runes here: `.svelte.js`, not `.js`."},
 {"code": "export class Planner {\n\tcourses;\n\tsessions = $state([]);\n\tweek = $state('');\n\tselected = $state('');", "note": "A field declared with `$state` is a signal, like a `$state` variable in a component. The proxy makes the sessions array deep, as before."},
 {"code": "\tthisWeek = $derived(this.sessions.filter((s) => inWeek(s.date, this.week)));\n\ttotal = $derived(minutesOf(this.thisWeek));\n\tdoneMinutes = $derived(minutesOf(this.thisWeek.filter((s) => s.done)));\n\tbyCourse = $derived(totalsBy(this.thisWeek, 'course'));\n\tbyDay = $derived(totalsBy(this.thisWeek, 'date'));\n\tcourse = $derived(this.courses.find((c) => c.id === this.selected));\n\tofCourse = $derived(\n\t\tthis.thisWeek.filter((s) => s.course === this.selected).toSorted((a, b) => (a.date < b.date ? -1 : 1))\n\t);", "note": "A `$derived` field is computed from other fields when read, and remembered. They read `this`, which is the instance."},
 {"code": "\tconstructor(data) {\n\t\tthis.courses = data.courses;\n\t\tthis.sessions = data.sessions;\n\t\tthis.week = mondayOf(data.sessions.at(-1).date);\n\t\tthis.selected = data.courses[0].id;\n\t}", "note": "The constructor takes the loaded data and sets the starting values. Nothing here is a copy that can go stale: the fields are the state."},
 {"code": "\tadd({ date, minutes }) {\n\t\tthis.sessions.push({ id: this.sessions.length + 1, course: this.selected, date, minutes, done: false });\n\t}\n\n\tmove(days) {\n\t\tthis.week = addDays(this.week, days);\n\t}\n}", "note": "The two things that change the state are methods, so every change to the planner goes through this file."},
 {"code": "function minutesOf(sessions) {\n\treturn sessions.reduce((sum, s) => sum + s.minutes, 0);\n}\n\nfunction totalsBy(sessions, field) {\n\tconst minutes = {};\n\tfor (const s of sessions) minutes[s[field]] = (minutes[s[field]] ?? 0) + s.minutes;\n\treturn minutes;\n}", "note": "Plain helpers. They are not exported, and they know nothing about runes."}
]}
```

`Planner.svelte` becomes the component that shows a `Planner`. It creates one from the data it is given,
and reads and changes it through `planner.`:

```schooling-example
{"language": "html", "file": "src/lib/Planner.svelte", "parts": [
 {"code": "<script>\n\timport { untrack } from 'svelte';\n\timport { Tween, prefersReducedMotion } from 'svelte/motion';\n\timport { addDays, format } from '#lib/week.js';\n\timport { Planner } from '#lib/planner.svelte.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = new Planner(untrack(() => data));\n\tconst shownDone = Tween.of(() => planner.doneMinutes, {\n\t\tduration: prefersReducedMotion.current ? 0 : 400\n\t});\n\n\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') planner.move(-7);\n\t\tif (event.key === 'ArrowRight') planner.move(7);\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${planner.total} min this week · Study planner`;\n\t});\n</script>\n<svelte:window onkeydown={shortcut} />", "note": "One import replaces the state's own imports. `untrack` stays, for the same reason as in lesson 8: the planner is made once, from the data as it was given."},
 {"code": "<p>Left and right arrows move the week.</p>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<CourseList courses={planner.courses} minutes={planner.byCourse} bind:selected={planner.selected} />\n<WeekTotal minutes={planner.total} />\n{#if planner.total === 0}\n\t<p>Nothing planned this week.</p>\n{:else if planner.doneMinutes === planner.total}\n\t<p>Every session this week is done.</p>\n{:else}\n\t<p>{Math.round(shownDone.current)} of {planner.total} minutes done.</p>\n{/if}\n<ol aria-label=\"Minutes per day\">\n\t{#each { length: 7 }, i}\n\t\t{const day = $derived(addDays(planner.week, i))}\n\t\t<li>{format(day)}: {planner.byDay[day] ?? 0} min</li>\n\t{/each}\n</ol>\n\n<Panel title={planner.course.name}>\n\t<List items={planner.ofCourse}>\n\t\t{#snippet row(session)}\n\t\t\t<label class:done={session.done}>\n\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t</label>\n\t\t{/snippet}\n\t\t{#snippet empty()}\n\t\t\t<p>Nothing planned for {planner.course.name} this week.</p>\n\t\t{/snippet}\n\t</List>\n\t<WeekTotal minutes={planner.byCourse[planner.selected] ?? 0} label=\"for {planner.course.name} this week\" />\n\t{#key planner.week}\n\t\t<AddSession onadd={(session) => planner.add(session)} />\n\t{/key}\n</Panel>\n\n<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "The markup reads the class's fields. `bind:selected={planner.selected}` binds to a field, which works because the field is `$state`."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Spanish' --fill 'Date=2026-10-21' --press Enter --click 'Previous week' --wait 500
-- click Spanish
-- fill Date=2026-10-21
-- press Enter
-- click Previous week
-- wait 500
at /
title: 90 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra"
      - text: 60 min
    - listitem:
      - button "Spanish" [pressed]
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 0 min
  - paragraph: 90 minutes this week (1 h 30 min)
  - paragraph: Every session this week is done.
  - list "Minutes per day":
    - listitem: "12 Oct 2026: 0 min"
    - listitem: "13 Oct 2026: 60 min"
    - listitem: "14 Oct 2026: 0 min"
    - listitem: "15 Oct 2026: 30 min"
    - listitem: "16 Oct 2026: 0 min"
    - listitem: "17 Oct 2026: 0 min"
    - listitem: "18 Oct 2026: 0 min"
  - region "Spanish":
    - heading "Spanish" [level=2]
    - list:
      - listitem:
        - checkbox "15 Oct 2026, 30 min" [checked]
        - text: 15 Oct 2026, 30 min
    - paragraph: 30 minutes for Spanish this week (0 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

Everything as before, which is the test of a refactoring: Spanish selected, a session added on the
21st, then back to the week of 12 October, where Spanish's half hour on the 15th is the one session
shown.

## What the class gives you

**A name for the planner's rules, and one file where they live.** "Add a session" and "move the week"
are methods now, so the question "what can change the planner?" has a short answer: the methods, and
the three fields the component binds. And the class does not need a component to exist: lesson 19
creates a `Planner` in a test, adds a session and checks the total, with no browser and no page.

Two details matter. **A rune on a class field makes the field reactive**: `total = $derived(…)` is
turned by the compiler into a private signal with a getter in front of it, so reading `planner.total`
is tracked, from a component or from anywhere else. And
**destructuring loses it**, exactly as lesson 2 warned: `const { total } = planner` copies the number
once. Read through `planner.` where you need the value.
