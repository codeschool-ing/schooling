---
title: $props
version: 1
---

**`$props` is how a component receives values from the component that uses it.** So far the planner
is one component. The week's total, shown as a sentence, is a small piece worth giving a name to,
because the course's own total will want the same sentence. Save this as `src/lib/WeekTotal.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/WeekTotal.svelte", "parts": [
 {"code": "<script>\n\tlet { minutes, label = 'this week' } = $props();", "note": "`$props()` returns an object with every prop the parent passed. Destructuring it names them; `= 'this week'` is the value when the parent passes none."},
 {"code": "\tlet hours = $derived(Math.floor(minutes / 60));\n\tlet rest = $derived(minutes % 60);\n</script>\n\n<p>{minutes} minutes {label} ({hours} h {rest} min)</p>", "note": "Props are reactive: when the parent passes a new `minutes`, these recalculate."}
]}
```

And use it twice in `+page.svelte`: once for the week, and once under the selected course with a
different label. Here is the whole page; the notes mark the three places that change:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add() {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date: week, minutes: 30, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>\n\n\t<ul>\n\t\t{#each data.courses as c}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t\t{byCourse[c.id] ?? 0} min\n\t\t\t</li>\n\t\t{/each}\n\t</ul>", "note": "The import goes with the others, at the top of the script."},
 {"code": "\t<WeekTotal minutes={total} />\n\n\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={session.done} onclick={() => (session.done = !session.done)}>\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</button>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>", "note": "A component is used as a tag. `minutes={total}` passes the current value of `total`, and keeps passing it as it changes."},
 {"code": "\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<button onclick={add}>Add 30 minutes on {format(week)}</button>\n</main>", "note": "The second use passes a label too. Inside the quotes, `{course.name}` is an expression like any other."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Guitar'
-- click Guitar
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra"
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar" [pressed]
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - heading "Guitar" [level=2]
  - list:
    - listitem:
      - button "20 Oct 2026, 45 min"
  - paragraph: 45 minutes for Guitar this week (0 h 45 min)
  - button "Add 30 minutes on 19 Oct 2026"
```

The first sentence uses the default label; the second, under Guitar, uses the one the page passed.
Both follow the page's state, because a prop is a value the child reads, and reading it is tracked
like any other read.

## Props flow one way

**A child reads its props and does not assign to them.** `WeekTotal` computes `hours` from
`minutes`; it never sets `minutes`, and if it did, the next change in the parent would overwrite it.
When a child needs to change something the parent owns, there are two ways, and lesson 5 is about
choosing between them: the parent passes a function the child calls, or the parent explicitly lets
the prop be bound in both directions with `$bindable`.

Three more forms you will meet, here so that you can read them:

- `let { minutes, ...rest } = $props()` collects every other prop into `rest`, so that a wrapper can
  pass them on with `<p {...rest}>`.
- `let props = $props()` without destructuring keeps them all in one object, read as `props.minutes`.
- A prop whose name and variable match can be passed as `{minutes}` instead of `minutes={minutes}`.
