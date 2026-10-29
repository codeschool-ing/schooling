---
title: createContext, setting and getting
version: 1
---

**`createContext()` returns a pair of functions, one to set a value for the components inside and one
to get it from any of them.** It is Svelte's own helper since 5.40, and it replaced calling
`setContext(key, value)` and `getContext(key)` with a key you had to keep unique. Make the pair once,
in a module of its own, `src/lib/context.js`:

```javascript
// context.js: the planner, shared with the components inside Planner.svelte.
import { createContext } from 'svelte';

export const [getPlanner, setPlanner] = createContext();
```

`Planner.svelte` sets it, right after creating the planner. Then the two pieces become components that
get it. Save the sentence as `src/lib/Status.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/Status.svelte", "parts": [
 {"code": "<script>\n\timport { Tween, prefersReducedMotion } from 'svelte/motion';\n\timport { getPlanner } from '#lib/context.js';\n\n\tconst planner = getPlanner();", "note": "`getPlanner()` returns the planner the nearest `Planner.svelte` above set. It is called while this component is being created."},
 {"code": "\tconst shownDone = Tween.of(() => planner.doneMinutes, {\n\t\tduration: prefersReducedMotion.current ? 0 : 400\n\t});\n</script>", "note": "The tween moved here with the sentence that uses it."},
 {"code": "{#if planner.total === 0}\n\t<p>Nothing planned this week.</p>\n{:else if planner.doneMinutes === planner.total}\n\t<p>Every session this week is done.</p>\n{:else}\n\t<p>{Math.round(shownDone.current)} of {planner.total} minutes done.</p>\n{/if}", "note": "The markup is `Planner.svelte`'s, unchanged, reading the same instance."}
]}
```

and the list of days as `src/lib/Days.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/Days.svelte", "parts": [
 {"code": "<script>\n\timport { addDays, format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\n\tconst planner = getPlanner();\n</script>\n\n<ol aria-label=\"Minutes per day\">\n\t{#each { length: 7 }, i}\n\t\t{const day = $derived(addDays(planner.week, i))}\n\t\t<li>{format(day)}: {planner.byDay[day] ?? 0} min</li>\n\t{/each}\n</ol>", "note": "No props at all: everything this list needs is on the planner."}
]}
```

`Planner.svelte` gets shorter. The two blocks become two tags, and the tween leaves with the sentence:

```schooling-example
{"language": "html", "file": "src/lib/Planner.svelte", "parts": [
 {"code": "<script>\n\timport { untrack } from 'svelte';\n\timport { format } from '#lib/week.js';\n\timport { Planner } from '#lib/planner.svelte.js';\n\timport { setPlanner } from '#lib/context.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';\n\timport Status from '#lib/Status.svelte';\n\timport Days from '#lib/Days.svelte';\n\n\tlet { data } = $props();", "note": "`Status`, `Days` and `setPlanner` join the imports; `Tween` and `addDays` leave with the code that used them."},
 {"code": "\tconst planner = setPlanner(new Planner(untrack(() => data)));\n\n\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') planner.move(-7);\n\t\tif (event.key === 'ArrowRight') planner.move(7);\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${planner.total} min this week · Study planner`;\n\t});\n</script>\n<svelte:window onkeydown={shortcut} />", "note": "Set once, while `Planner.svelte` is being created. Every component inside it can now get this planner."},
 {"code": "<p>Left and right arrows move the week.</p>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<CourseList courses={planner.courses} minutes={planner.byCourse} bind:selected={planner.selected} />\n<WeekTotal minutes={planner.total} />\n<Status />\n<Days />\n\n<Panel title={planner.course.name}>\n\t<List items={planner.ofCourse}>\n\t\t{#snippet row(session)}\n\t\t\t<label class:done={session.done}>\n\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t</label>\n\t\t{/snippet}\n\t\t{#snippet empty()}\n\t\t\t<p>Nothing planned for {planner.course.name} this week.</p>\n\t\t{/snippet}\n\t</List>\n\t<WeekTotal minutes={planner.byCourse[planner.selected] ?? 0} label=\"for {planner.course.name} this week\" />\n\t{#key planner.week}\n\t\t<AddSession onadd={(session) => planner.add(session)} />\n\t{/key}\n</Panel>\n\n<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "Two tags where there were thirteen lines."}
]}
```

`setPlanner` returns the value it was given, which is why the planner can be created and set in one
line. Tick a session to see that the components inside read the same instance the page changes:

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 500
-- check 24 Oct 2026, 60 min
-- wait 500
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 150 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min" [checked]
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

The sentence from `Status` and the days from `Days` agree with everything else, because there is only
one planner, and both got it from the component that made it.
