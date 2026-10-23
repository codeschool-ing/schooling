---
title: $effect, and when not to use it
version: 1
---

**`$effect` runs code after the page has updated, and again whenever something it read changes.** It
is for reaching outside the component: the document's title, a timer, a canvas, a third-party
library that manages its own DOM, a connection to a server. Lesson 2 used two as probes. The planner
needs one: the browser tab should say how many minutes are planned this week.

Replace the `$inspect` line of the previous section with this effect, and leave the rest of
`+page.svelte` as it is:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add() {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date: week, minutes: 30, done: false });\n\t}\n", "note": "The script is the previous section's down to `add`."},
 {"code": "\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>", "note": "The effect reads `total`, so it runs once when the page appears and again whenever the total changes. Setting the title is a side effect: it reaches outside the component."},
 {"code": "<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>\n\n\t<ul>\n\t\t{#each data.courses as c}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t\t{byCourse[c.id] ?? 0} min\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<p>{total} minutes this week</p>\n\n\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={session.done} onclick={() => (session.done = !session.done)}>\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</button>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<button onclick={add}>Add 30 minutes on {format(week)}</button>\n</main>", "note": "The markup is the previous section's, unchanged."}
]}
```

`look` prints the title when a page has one:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week'
-- click Previous week
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem: "Linear algebra: 60 min"
    - listitem: "Spanish: 30 min"
    - listitem: "Guitar: 0 min"
  - paragraph: 90 minutes this week
```

The title says 90 because the button moved the week, the total changed, and the effect, which had
read the total, ran again. The page title matters beyond tidiness: it is the first thing a screen
reader announces when a tab opens, and WCAG asks for one that describes the page.

## The function an effect returns

An effect can return a function, and Svelte calls it **before the effect runs again and when the
component goes away**. That is where you undo what the effect did: stop a timer, close a connection,
remove a listener. Lesson 2's observer used it to disconnect. A timer is the usual case:

```javascript
$effect(() => {
	const id = setInterval(() => (now = Date.now()), 1000);
	return () => clearInterval(id);
});
```

Without the returned function, every time the effect re-ran it would start a second timer beside the
first, and the component going away would leave all of them running.

## When an effect is the wrong tool

**Most code that looks like it needs an effect needs a derived value or an event handler.** The test
is what the code does:

| the code… | so use… | because |
|---|---|---|
| computes a value from other values | `$derived` | it is a value, and an effect that assigns state is a derived value written the long way round |
| responds to something the user did | the event handler | the handler already runs at the right moment, once |
| reaches outside the component when values change | `$effect` | nothing else runs after the page has updated |

The first row is the common mistake. An effect like `$effect(() => { total = sum(thisWeek); })`
works, after a fashion: the page shows the old total for a moment, the effect runs, `total` changes,
and everything that read `total` updates a second time. **An effect that writes state it also reads
loops**, and Svelte stops it with an `effect_update_depth_exceeded` error rather than letting it spin.
`$derived` has neither problem, because it is computed when read.

Two more effect runes exist for rare cases. `$effect.pre` runs **before** the page updates, for code
that has to measure the old layout, such as keeping a chat scrolled to the bottom. And `untrack(fn)`,
imported from `svelte`, reads values inside an effect without making the effect depend on them.
