---
title: Named actions, for more than one form
version: 1
---

**A page can have several actions, each with a name, and a form says which one it is sending to in its
`action` attribute, as `?/name`.** The course page needs a second one. The checkbox that marks a
session done changes the planner in memory, so with JavaScript off it does nothing, and with it on the
change is gone on the next reload. As a form, it can be saved like everything else.

`default` cannot live beside named actions, so the action that adds becomes `add`. Replace
`+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's forms do, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession, setDone } from '#lib/server/planner.js';\nimport { isDate } from '#lib/week.js';\n\nexport const actions = {\n\tadd: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));\n\n\t\tif (!isDate(date)) return fail(400, { date, minutes, problem: 'The session needs a date.' });\n\t\tif (!Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\t\treturn fail(400, { date, minutes, problem: 'Minutes must be a whole number from 5 to 600.' });\n\t\t}\n\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}`);\n\t},"},
 {"code": "\tdone: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst session = await setDone(Number(form.get('id')), form.get('done') === 'yes');\n\t\tif (!session) error(404, 'There is no such session.');\n\n\t\tredirect(303, `/courses/${params.id}`);\n\t}\n};", "note": "The form says which session and which way, in two fields. An id that names no session is a 404, like a course that does not exist."}
]}
```

`AddSession` takes the address to send to as a prop, since the page is the one that knows its
actions. Replace `src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';\n\n\tlet { action } = $props();\n\tlet form = $derived(page.form);\n</script>"},
 {"code": "<form method=\"POST\" {action}>\n\t{#if form?.problem}\n\t\t<p role=\"alert\">{form.problem}</p>\n\t{/if}\n\t<label>Date <input type=\"date\" name=\"date\" required value={form?.date ?? ''} /></label>\n\t<label>Minutes <input type=\"number\" name=\"minutes\" min=\"5\" max=\"600\" step=\"5\" required value={form?.minutes ?? 30} /></label>\n\t<button>Add session</button>\n</form>", "note": "`{action}` is short for `action={action}`, the attribute set from the prop of the same name."}
]}
```

Each session's row becomes a small form of its own, with the session's id in a hidden field and one
button. Replace `src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<List items={sessions}>\n\t{#snippet row(session)}"},
 {"code": "\t\t<form method=\"POST\" action=\"?/done\">\n\t\t\t<input type=\"hidden\" name=\"id\" value={session.id} />\n\t\t\t<input type=\"hidden\" name=\"done\" value={session.done ? 'no' : 'yes'} />\n\t\t\t<span class:done={session.done}>{format(session.date)}, {session.minutes} min</span>", "note": "A hidden input is sent with the form and not shown. `done` says what to set, the opposite of what the session is now."},
 {"code": "\t\t\t<button aria-label=\"{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}\">\n\t\t\t\t{session.done ? 'Mark not done' : 'Mark done'}\n\t\t\t</button>\n\t\t</form>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession action=\"?/add\" />\n{/key}", "note": "Every row has a button with the same text, so the label adds the date. It starts with the visible words, so a person who says \"click Mark done\" to voice control is understood."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/algebra --no-js --click 'Mark done: 24 Oct 2026'
-- click Mark done: 24 Oct 2026
at /courses/algebra
title: Linear algebra · Study planner
- main:
  - heading "Linear algebra" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - text: 19 Oct 2026, 90 min
      - 'button "Mark not done: 19 Oct 2026"': Mark not done
    - listitem:
      - text: 24 Oct 2026, 60 min
      - 'button "Mark not done: 24 Oct 2026"': Mark not done
  - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

**The 24th is done, and saved**, with JavaScript off. The browser sent `id=6&done=yes` to
`/courses/algebra?/done`, the `done` action saved it and redirected to `/courses/algebra`, and the page
the browser asked for next read the file again. The `?/done` in the address the form was sent to is
how SvelteKit picks the action; after the redirect it is not in the address bar, which is one more
thing Post/Redirect/Get tidies up.

The button's name, `Mark done: 24 Oct 2026`, is longer than its text on purpose. A screen reader that
lists the buttons on the page would otherwise read "Mark done, Mark done, Mark done" and leave the
person to guess which is which.
