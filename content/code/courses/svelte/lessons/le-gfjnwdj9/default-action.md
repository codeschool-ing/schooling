---
title: A form action
version: 1
---

**A form action is a function in a page's `+page.server.js` that runs when a form is sent to that page
with `POST`.** The browser sends the form the way browsers always have, as fields with names, and the
action reads them, does the work and answers. There is no `fetch` and no JSON in the component, and no
JavaScript needed in the browser at all.

Save this beside the course page, as `src/routes/(planner)/courses/[id=slug]/+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's form does, on the server.\nimport { addSession } from '#lib/server/planner.js';"},
 {"code": "export const actions = {\n\tdefault: async ({ request, params }) => {", "note": "`actions` is an object of functions. One called `default` answers every `POST` to the page."},
 {"code": "\t\tconst form = await request.formData();\n\t\tawait addSession({\n\t\t\tcourse: params.id,\n\t\t\tdate: String(form.get('date')),\n\t\t\tminutes: Number(form.get('minutes'))\n\t\t});\n\t}\n};", "note": "`request` is the standard `Request`, and `formData()` reads the fields the browser sent, by name."}
]}
```

The form has to be one a browser can send on its own: `method="POST"`, and a `name` on every field.
It no longer calls anybody, so it needs no props and no script of its own. Replace
`src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<form method=\"POST\">"},
 {"code": "\t<label>Date <input type=\"date\" name=\"date\" required /></label>\n\t<label>Minutes <input type=\"number\" name=\"minutes\" min=\"5\" max=\"600\" step=\"5\" required value=\"30\" /></label>\n\t<button>Add session</button>\n</form>", "note": "The `name` is the key the action reads with `form.get('date')`. The label still names the field for a person."}
]}
```

On the course page, the `AddSession` loses its `onadd`, which nothing calls any more. Replace
`src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<List items={sessions}>\n\t{#snippet row(session)}\n\t\t<label class:done={session.done}>\n\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t{format(session.date)}, {session.minutes} min\n\t\t</label>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />"},
 {"code": "{#key planner.week}\n\t<AddSession />\n{/key}", "note": "The only change: no `onadd`. The form sends itself."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

Now, with JavaScript still off:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --no-js --fill 'Date=2026-10-21' --click 'Add session'
-- fill Date=2026-10-21
-- click Add session
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
    - listitem:
      - checkbox "21 Oct 2026, 30 min"
      - text: 21 Oct 2026, 30 min
  - paragraph: 75 minutes for Guitar this week (1 h 15 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

**Thirty minutes on the 21st, saved.** The browser sent `date=2026-10-21&minutes=30` to
`/courses/guitar` with `POST`; SvelteKit ran the default action, then the page's load functions, which
read the file the action had just written, and answered with the page. It is in the file:

```
ana@dev:~/planner$ tail -8 data/planner.json
			"id": 7,
			"course": "guitar",
			"date": "2026-10-21",
			"minutes": 30,
			"done": false
		}
	]
}
```

## Answer a POST with a redirect

The page that came back is the answer to a `POST`. If the student now presses reload, the browser
offers to send the form again, and if they agree, there are two sessions on the 21st. The Back button
can do the same. The old, reliable cure is to answer a `POST` that worked with a **redirect** to an
ordinary page, so that what the browser has on screen is the answer to a `GET`, and reloading it only
reads. The pattern has a name, **Post/Redirect/Get**, and the status for it is **303 See Other**,
which tells the browser to fetch the new address with `GET` whatever method brought it there. Replace
`+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's form does, on the server.\nimport { redirect } from '@sveltejs/kit';\nimport { addSession } from '#lib/server/planner.js';\n\nexport const actions = {\n\tdefault: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tawait addSession({\n\t\t\tcourse: params.id,\n\t\t\tdate: String(form.get('date')),\n\t\t\tminutes: Number(form.get('minutes'))\n\t\t});"},
 {"code": "\t\tredirect(303, `/courses/${params.id}`);\n\t}\n};", "note": "`redirect()` throws, like `error()`, so nothing after it runs."}
]}
```

`curl` can send a form too, `-d` with the fields, and show what came back:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' -H 'Accept: text/html' -d 'date=2026-10-23&minutes=30' http://localhost:5173/courses/guitar
303 http://localhost:5173/courses/guitar
```

`-H 'Accept: text/html'` says what a browser says, that it wants a page. Without it, SvelteKit takes the
request for one from its own JavaScript, which the last section of this lesson is about, and answers
with JSON.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Post/Redirect/Get, as three exchanges between the browser on the left and the server on the right. First the browser sends POST /courses/guitar with date and minutes; the server runs the action, which saves the session, and answers 303 See Other with a Location header naming /courses/guitar. Then the browser sends GET /courses/guitar; the server runs the load functions, which read the file again, and answers 200 with the page. What the browser now shows is the answer to a GET, so reloading it only reads the page again.\"><text x=\"90\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">browser</text><text x=\"630\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">server</text><line x1=\"90\" y1=\"32\" x2=\"90\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\"></line><line x1=\"630\" y1=\"32\" x2=\"630\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\"></line><line x1=\"92\" y1=\"60\" x2=\"520\" y2=\"60\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"520.0,60.0 512.6,63.1 512.6,56.9\" fill=\"var(--phosphor)\"></polygon><text x=\"300\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /courses/guitar  date=2026-10-21&amp;minutes=30</text><rect x=\"522\" y=\"42\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"617\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the action saves</text><text x=\"617\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">addSession(…)</text><line x1=\"520\" y1=\"110\" x2=\"94\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"94.0,110.0 101.4,106.9 101.4,113.1\" fill=\"var(--amber)\"></polygon><text x=\"300\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">303 See Other   Location: /courses/guitar</text><line x1=\"92\" y1=\"160\" x2=\"520\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"520.0,160.0 512.6,163.1 512.6,156.9\" fill=\"var(--phosphor)\"></polygon><text x=\"300\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET /courses/guitar</text><rect x=\"522\" y=\"142\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"617\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the load functions read</text><text x=\"617\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">readPlanner()</text><line x1=\"520\" y1=\"210\" x2=\"94\" y2=\"210\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"94.0,210.0 101.4,206.9 101.4,213.1\" fill=\"var(--amber)\"></polygon><text x=\"300\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">200, the page with the new session</text><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reloading now repeats the GET, which only reads</text></svg>", "caption": "A form that worked is answered with a redirect, so the page on the screen is the answer to a GET."}
```
