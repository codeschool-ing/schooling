---
title: The week belongs in the address
version: 1
---

**Every form now ends in a redirect, and every redirect forgets the week.** The week is a field of the
planner in memory, so any full page load starts again from the default, the week of the session added
last. With JavaScript on, go back a week on the Spanish page and change your mind about the 15th:

```
ana@dev:~/planner$ look http://localhost:5173/courses/spanish --click 'Previous week' --click 'Mark not done: 15 Oct 2026'
-- click Previous week
-- click Mark not done: 15 Oct 2026
at /courses/spanish
title: Spanish · Study planner
- main:
  - heading "Spanish" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - text: 22 Oct 2026, 30 min
      - 'button "Mark done: 22 Oct 2026"': Mark done
  - paragraph: 30 minutes for Spanish this week (0 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

The change was saved, and the student, who was looking at the week of the 12th, is now looking at the
week of the 19th, where the session they just changed is not. With JavaScript off it is worse: the week
buttons do nothing at all, so the week of the 19th is the only one there is.

**State that says what the person is looking at belongs in the address.** Then a link can carry it, a
redirect can go back to it, a reload keeps it, a bookmark saves it, and the server can render it,
because the server sees the address. The week becomes a query parameter, `?week=2026-10-12`, and the
buttons become links to the weeks either side.

## Reading it

The week comes from the URL, so it is read in a load function, and a universal one: it needs nothing
from the server, and in the browser it can move the week without asking the server anything. The
`(planner)` group already has a `+layout.server.js`. A `+layout.js` beside it receives what the server's
function returned, as `data`, and what it returns in turn is what the pages get. Save it as `src/routes/(planner)/+layout.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.js", "parts": [
 {"code": "// +layout.js: the week the address asks for, added to what the server loaded.\nimport { isDate, mondayOf } from '#lib/week.js';"},
 {"code": "export function load({ data, url }) {\n\tconst asked = url.searchParams.get('week');", "note": "`data` is what `+layout.server.js` returned. Reading `url.searchParams` makes this function rerun whenever `?week` changes, and only then."},
 {"code": "\tconst week = isDate(asked ?? '') ? mondayOf(asked) : mondayOf(data.sessions.at(-1).date);\n\treturn { ...data, week };\n}", "note": "An address can hold anything, so `?week=banana` gets the default week rather than an error."}
]}
```

and the buttons become links. Replace `src/lib/WeekNav.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/WeekNav.svelte", "parts": [
 {"code": "<script>\n\timport { addDays, format } from '#lib/week.js';\n\n\tlet { week, label = 'Week of' } = $props();\n</script>"},
 {"code": "<p data-sveltekit-reset=\"false\">\n\t<a href=\"?week={addDays(week, -7)}\">Previous week</a>\n\t{label} {format(week)}\n\t<a href=\"?week={addDays(week, 7)}\">Next week</a>\n</p>", "note": "`data-sveltekit-reset=\"false\"` keeps the focus on the link that was pressed and the page where it was scrolled to, so a person pressing Enter on \"Next week\" can press it again."}
]}
```

A link that starts with `?` keeps the page and changes only the query, so the same component works on
the week page and on a course page. Try it:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week'
-- click Next week
at /?week=2026-10-26
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-12"
    - text: Week of 19 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-26"
  - list:
    - listitem:
      - link "Linear algebra":
        - /url: /courses/algebra
      - text: 150 min
    - listitem:
      - link "Spanish":
        - /url: /courses/spanish
      - text: 30 min
    - listitem:
      - link "Guitar":
        - /url: /courses/guitar
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
```

**The address says the 26th and the page says the 19th.** The link worked and the load function
returned the new week: the planner never asked. It still has a `week` of its own, set once in its
constructor from the data it was given, and `PlannerProvider` gave it that data once, through
`untrack`, as lesson 13 warned at the end of "When a load function runs again". There are two answers
to "which week" now, the address and the planner's copy, which is the situation lesson 12 removed the
selected course to avoid.

## A planner that reads the data instead of copying it

The cure is for the planner to hold no copy at all: it is given a **function that returns the current
data**, and every field it has is derived from what that function returns. When a load function reruns,
`data` changes, the function returns the new data, and every derived field recalculates. Replace
`src/lib/planner.svelte.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/planner.svelte.js", "parts": [
 {"code": "// planner.svelte.js: the planner's rules, over data that arrives from the load functions.\nimport { inWeek } from '#lib/week.js';\n\nexport class Planner {\n\t#data;"},
 {"code": "\tcourses = $derived(this.#data().courses);\n\tsessions = $derived(this.#data().sessions);\n\tweek = $derived(this.#data().week);\n\n\tthisWeek = $derived(this.sessions.filter((s) => inWeek(s.date, this.week)));\n\ttotal = $derived(minutesOf(this.thisWeek));\n\tdoneMinutes = $derived(minutesOf(this.thisWeek.filter((s) => s.done)));\n\tbyCourse = $derived(totalsBy(this.thisWeek, 'course'));\n\tbyDay = $derived(totalsBy(this.thisWeek, 'date'));", "note": "Three fields that used to be state are derived now. Nothing in the planner is set any more; it only reads."},
 {"code": "\t/** @param {() => any} data a function that returns the current data */\n\tconstructor(data) {\n\t\tthis.#data = data;\n\t}\n\n\tcourse(id) {\n\t\treturn this.courses.find((c) => c.id === id);\n\t}\n\n\tsessionsFor(id) {\n\t\treturn this.thisWeek.filter((s) => s.course === id).toSorted((a, b) => (a.date < b.date ? -1 : 1));\n\t}\n}\n\nfunction minutesOf(sessions) {\n\treturn sessions.reduce((sum, s) => sum + s.minutes, 0);\n}\n\nfunction totalsBy(sessions, field) {\n\tconst minutes = {};\n\tfor (const s of sessions) minutes[s[field]] = (minutes[s[field]] ?? 0) + s.minutes;\n\treturn minutes;\n}", "note": "A derived field is worked out when it is first read, which is after the constructor has stored the function."}
]}
```

`add` and `move` have gone: adding is the server's job now, and moving the week is a change of address.
The keyboard shortcut moves the week the same way, with `goto` from `$app/navigation`, which is a click
on a link written in code. Replace `src/lib/PlannerProvider.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/PlannerProvider.svelte", "parts": [
 {"code": "<script>\n\timport { goto } from '$app/navigation';\n\timport { addDays } from '#lib/week.js';\n\timport { Planner } from '#lib/planner.svelte.js';\n\timport { setPlanner } from '#lib/context.js';\n\n\tlet { data, children } = $props();"},
 {"code": "\tconst planner = setPlanner(new Planner(() => data));\n\n\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tconst days = { ArrowLeft: -7, ArrowRight: 7 }[event.key];", "note": "`() => data` reads the prop each time it is called, so it always returns the newest data. No `untrack`: nothing is read here, only later."},
 {"code": "\t\tif (days) goto(`?week=${addDays(planner.week, days)}`, { reset: false });\n\t}\n</script>\n\n<svelte:window onkeydown={shortcut} />\n\n{@render children()}", "note": "`reset: false` is the same as the attribute on the links: the focus and the scroll stay where they are."}
]}
```

The comment at the top of `src/lib/context.js` still names `Planner.svelte`, from before lesson 12. Make
it say what is true:

```schooling-example
{"language": "javascript", "file": "src/lib/context.js", "parts": [
 {"code": "// context.js: the planner, shared with the pages inside PlannerProvider.svelte.\nimport { createContext } from 'svelte';\n\nexport const [getPlanner, setPlanner] = createContext();", "note": "Only the comment changes. The context still holds one planner object for as long as the provider exists; what changes is what that object reads."}
]}
```

## Keeping the week everywhere it should go

The course links on the week page carry the week to the course page. Replace `src/lib/CourseList.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes, week } = $props();\n</script>\n\n<ul>\n\t{#each courses as c}\n\t\t<li><a href=\"/courses/{c.id}?week={week}\">{c.name}</a> {minutes[c.id] ?? 0} min</li>\n\t{/each}\n</ul>", "note": "`week` is new: each link carries the week the student is looking at."},
 {"code": "<style>\n\tul {\n\t\tlist-style: none;\n\t\tpadding: 0;\n\t}\n\n\tli {\n\t\tdisplay: flex;\n\t\tjustify-content: space-between;\n\t\tmax-width: 20rem;\n\t}\n</style>"}
]}
```

and the week page passes it, and no longer has a week to change. Replace
`src/routes/(planner)/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/+page.svelte", "parts": [
 {"code": "<script>\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport Status from '#lib/Status.svelte';\n\timport Days from '#lib/Days.svelte';\n\n\tconst planner = getPlanner();\n</script>\n\n<svelte:head>\n\t<title>{planner.total} min this week · Study planner</title>\n</svelte:head>\n\n<h1>Study planner</h1>\n<p>Left and right arrows move the week.</p>\n<WeekNav week={planner.week} />\n<CourseList courses={planner.courses} minutes={planner.byCourse} week={planner.week} />\n<WeekTotal minutes={planner.total} />\n<Status />\n<Days />", "note": "No `onchange` on `WeekNav` any more, and the week is passed to `CourseList`."}
]}
```

The actions redirect to the week of the session they changed, so a session added on the 14th is shown
in the week of the 12th. Replace `+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's forms do, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession, setDone } from '#lib/server/planner.js';\nimport { isDate, mondayOf } from '#lib/week.js';\n\nexport const actions = {\n\tadd: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));\n\n\t\tif (!isDate(date)) return fail(400, { date, minutes, problem: 'The session needs a date.' });\n\t\tif (!Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\t\treturn fail(400, { date, minutes, problem: 'Minutes must be a whole number from 5 to 600.' });\n\t\t}\n\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(date)}`);\n\t},\n\n\tdone: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst session = await setDone(Number(form.get('id')), form.get('done') === 'yes');\n\t\tif (!session) error(404, 'There is no such session.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(session.date)}`);\n\t}\n};", "note": "Both redirects now name a week: the week of the date added, or of the session marked."}
]}
```

The course page's forms need one more change, and it is the one that is easy to miss. A form whose
`action` is `?/add` is sent to the page's path with **that** query, so `?week=2026-10-12` is dropped on
the way. A failed form then renders the default week. The week goes into the form's address too, before
the action's name: `?week=2026-10-12&/add`. Replace
`src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} />\n<List items={sessions}>\n\t{#snippet row(session)}"},
 {"code": "\t\t<form method=\"POST\" action=\"?week={planner.week}&/done\">\n\t\t\t<input type=\"hidden\" name=\"id\" value={session.id} />\n\t\t\t<input type=\"hidden\" name=\"done\" value={session.done ? 'no' : 'yes'} />\n\t\t\t<span class:done={session.done}>{format(session.date)}, {session.minutes} min</span>\n\t\t\t<button aria-label=\"{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}\">\n\t\t\t\t{session.done ? 'Mark not done' : 'Mark done'}\n\t\t\t</button>\n\t\t</form>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession action=\"?week={planner.week}&/add\" />\n{/key}", "note": "The week first, then `&`, then the action's name, which SvelteKit reads from the end of the query."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

## With JavaScript off, every part of it

```
ana@dev:~/planner$ look http://localhost:5173/ --no-js --click 'Previous week' --click 'Guitar' --fill 'Date=2026-10-14' --click 'Add session'
-- click Previous week
-- click Guitar
-- fill Date=2026-10-14
-- click Add session
at /courses/guitar?week=2026-10-12
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-05"
    - text: Week of 12 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-19"
  - list:
    - listitem:
      - text: 14 Oct 2026, 30 min
      - 'button "Mark done: 14 Oct 2026"': Mark done
  - paragraph: 30 minutes for Guitar this week (0 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

**Back a week, into Guitar, a session on the 14th, and the page shows the week it is in**, all of it
without a line of JavaScript in the browser. The `Guitar` link on the week page carried the week to the
course page, the form carried it to the action, and the action's redirect sent the browser to the week
of the 14th. With JavaScript on, the same links are client-side navigations, and
the arrow keys work again:

```
ana@dev:~/planner$ look 'http://localhost:5173/?week=2026-10-19' --press ArrowLeft --wait 300 | head -10
-- press ArrowLeft
-- wait 300
at /?week=2026-10-12
title: 120 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-05"
```
