---
title: A page's own load, parent() and error()
version: 1
---

**A page can have a load function of its own, and it receives what the layouts above it loaded through
`parent()`.** The course page is the place for one. Since lesson 12 it has looked the course up in the
planner and, when there was no such course, rendered its own "No such course" heading with a 200
status. A load function can do the looking up before the page renders, and answer an unknown course
with the error page and a 404, which is what it is.

Save this as `src/routes/(planner)/courses/[id=slug]/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.js", "parts": [
 {"code": "// +page.js: the course a course page is about, or a 404.\nimport { error } from '@sveltejs/kit';"},
 {"code": "export async function load({ params, parent }) {", "note": "`params` holds the parts of the address the route matched, as the page's own `params` prop did."},
 {"code": "\tconst { courses } = await parent();\n\tconst course = courses.find((c) => c.id === params.id);", "note": "`parent()` waits for the layouts' load functions and returns their data merged into one object."},
 {"code": "\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn { course };\n}", "note": "`error()` throws, so nothing after it runs. The message is what `page.error.message` shows."}
]}
```

It is universal, in a `+page.js`, and that is deliberate: it needs nothing the server has that the
browser does not, since the courses arrive from the layout either way.

The page becomes simpler, because by the time it renders, the course exists. Replace
`src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';"},
 {"code": "\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>", "note": "`data` holds the layout's data and the page's own, merged: `data.courses` is there too, beside `data.course`."},
 {"code": "<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<List items={sessions}>\n\t{#snippet row(session)}\n\t\t<label class:done={session.done}>\n\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t{format(session.date)}, {session.minutes} min\n\t\t</label>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession onadd={(session) => planner.add({ ...session, course: course.id })} />\n{/key}", "note": "No `{#if course}` and no \"No such course\": a page that renders has a course."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/piano
at /courses/piano
title: 404 · Study planner
- main:
  - heading "Nothing at this address" [level=1]
  - paragraph: There is no course called “piano”.
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/courses/piano
404
```

**The error page, with the load function's message, and a 404** where lesson 12 answered 200. A course
that exists renders as before:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar
at /courses/guitar
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - checkbox "20 Oct 2026, 45 min"
      - text: 20 Oct 2026, 45 min
  - paragraph: 45 minutes for Guitar this week (0 h 45 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

## Parent data, and waiting for it

`parent()` exists because the load functions of a page and of its layouts **run at the same time**, not
one after the other. Running them together is faster, and most of them do not need each other. One that
does says so by awaiting `parent()`, which waits only for the layouts above it. Awaiting it first and
then fetching something that did not depend on it would make the two requests wait for each other for
no reason: when a load function needs both, it starts its own work, then awaits `parent()`.

What `parent()` returns is the merged data of every layout above the page, not only the nearest. Here
that is one layout, the `(planner)` group's; the root layout has no load function and adds nothing.
