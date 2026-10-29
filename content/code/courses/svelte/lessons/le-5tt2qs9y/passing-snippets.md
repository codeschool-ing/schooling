---
title: Passing snippets to a component
version: 1
---

**A component can take snippets as props, which lets it decide the structure and leave the content to
whoever uses it.** A list that knows how to be a list, with its `<ul>`, its keys and its empty state,
but not what each row says, is the classic case. Save it as `src/lib/List.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script>\n\tlet { items, row, empty } = $props();\n</script>", "note": "Two snippet props: `row`, rendered once per item, and `empty`, rendered when there are none."},
 {"code": "{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>", "note": "`(item.id)` is a key: it tells Svelte which row is which when the list changes. Lesson 8 is about why that matters."},
 {"code": "{:else}\n\t{@render empty?.()}\n{/if}", "note": "`empty?.()` renders nothing when the parent gave no `empty` snippet, instead of failing."}
]}
```

`List` has no idea what a session is. It receives `items`, and two pieces of markup to use, and the
page provides all three. A snippet declared **between a component's tags** becomes a prop of that
component with the snippet's name, so the page passes `row` and `empty` like this:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));", "note": "`List` joins the imports."},
 {"code": "\tlet ofCourse = $derived(thisWeek.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n\t<WeekTotal minutes={total} />", "note": "The panel now shows the course's sessions in the week being shown, so it agrees with the total under it, and can be empty."},
 {"code": "\t<Panel title={course.name}>\n\t\t<List items={ofCourse}>\n\t\t\t{#snippet row(session)}\n\t\t\t\t<label class:done={session.done}>\n\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</label>\n\t\t\t{/snippet}\n\t\t\t{#snippet empty()}\n\t\t\t\t<p>Nothing planned for {course.name} this week.</p>\n\t\t\t{/snippet}\n\t\t</List>\n\t\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t\t<AddSession onadd={add} />\n\t</Panel>\n</main>\n\n<style>\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "Both snippets are declared between `<List>` and `</List>`, so they become its `row` and `empty` props. `row` takes the session as its parameter."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/
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
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - paragraph:
      - text: Date
      - textbox "Date"
      - text: Minutes
      - spinbutton "Minutes": "30"
      - button "Add session" [disabled]
```

Linear algebra this week: the session of the 19th, done, and the 24th, not yet. One week on, the
`empty` snippet takes over:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week'
-- click Next week
at /
title: 0 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 26 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 0 min
    - listitem:
      - button "Spanish"
      - text: 0 min
    - listitem:
      - button "Guitar"
      - text: 0 min
  - paragraph: 0 minutes this week (0 h 0 min)
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - paragraph: Nothing planned for Linear algebra this week.
    - paragraph: 0 minutes for Linear algebra this week (0 h 0 min)
    - paragraph:
      - text: Date
      - textbox "Date"
      - text: Minutes
      - spinbutton "Minutes": "30"
      - button "Add session" [disabled]
```

## What went where

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Who owns what in the session list. List.svelte owns the structure: the ul, one li per item with its key, and the choice between the list and the empty state. The page owns the content: the row snippet, with the bound checkbox and the date, and the empty snippet with its sentence. The page hands both snippets to List, and List calls row once per session and empty when there are none.\"><rect x=\"20\" y=\"20\" width=\"300\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">+page.svelte: the content</text><rect x=\"40\" y=\"60\" width=\"260\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{#snippet row(session)}</text><text x=\"64\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;input bind:checked …&gt;</text><text x=\"64\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">{format(session.date)} …</text><rect x=\"40\" y=\"152\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{#snippet empty()}</text><text x=\"64\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;p&gt;Nothing planned …&lt;/p&gt;</text><rect x=\"420\" y=\"20\" width=\"280\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">List.svelte: the structure</text><text x=\"440\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{#if items.length}</text><text x=\"456\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;ul&gt;</text><text x=\"472\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{#each items as item (item.id)}</text><text x=\"488\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;li&gt;{@render row(item)}&lt;/li&gt;</text><text x=\"440\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{:else}</text><text x=\"456\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">{@render empty?.()}</text><line x1=\"300\" y1=\"100\" x2=\"418\" y2=\"132\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,132.0 410.1,133.1 411.7,127.1\" fill=\"var(--amber)\"></polygon><line x1=\"300\" y1=\"177\" x2=\"418\" y2=\"182\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,182.0 410.5,184.8 410.8,178.6\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">snippets travel as props; the markup in them stays the page's</text></svg>", "caption": "List decides the shape and when to show each part. The page decides what a row and the empty state say."}
```

**The structure is `List`'s and the content is the page's.** `List` owns the `<ul>`, the keys, and the
decision to show the empty state; the page owns what a row looks like and what "empty" says. Change
either without touching the other: a table instead of a list is a change to `List`, a time next to
each date is a change to `row`.

The binding in the row still reaches the page's state, and the `.done` style still applies, for the
reason the previous section gave: the snippet was written in the page, so it reads, binds and is
styled as the page, wherever `List` renders it. That is the difference from passing data down and
letting the child draw it. Here the child never touches a session at all, so the question of who may
change one does not arise.
