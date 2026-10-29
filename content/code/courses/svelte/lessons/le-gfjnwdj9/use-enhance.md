---
title: use:enhance, and the same forms without a reload
version: 1
---

**`use:enhance` makes a form that already works send itself with JavaScript, when there is
JavaScript.** It comes from `$app/forms` and goes on the `<form>` as an attribute, `use:enhance`, which
is Svelte's syntax for an **action** in the other sense of the word: a function that runs on an
element when it is created. This one listens for `submit`, stops the browser's own submission, sends
the same fields to the same address with `fetch`, and then does what the browser would have done with
the answer, without loading a new page.

Nothing about the server changes, and nothing about the form's fields. Replace
`src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\timport { enhance } from '$app/forms';\n\timport { page } from '$app/state';\n\n\tlet { action } = $props();\n\tlet form = $derived(page.form);"},
 {"code": "\tlet sending = $state(false);", "note": "`sending` is true while the form is on its way, which takes long enough to matter on a slow connection."},
 {"code": "\tfunction submit() {\n\t\tsending = true;\n\t\treturn async ({ update }) => {\n\t\t\tawait update();\n\t\t\tsending = false;\n\t\t};\n\t}\n</script>", "note": "Called when the form is submitted. What it returns is called with the answer; `update()` then does everything `use:enhance` would have done by itself."},
 {"code": "<form method=\"POST\" {action} use:enhance={submit}>\n\t{#if form?.problem}\n\t\t<p role=\"alert\">{form.problem}</p>\n\t{/if}\n\t<label>Date <input type=\"date\" name=\"date\" required value={form?.date ?? ''} /></label>\n\t<label>Minutes <input type=\"number\" name=\"minutes\" min=\"5\" max=\"600\" step=\"5\" required value={form?.minutes ?? 30} /></label>", "note": "Without JavaScript this attribute does nothing, and the form is sent the way the previous sections sent it."},
 {"code": "\t<button disabled={sending}>{sending ? 'Adding…' : 'Add session'}</button>\n</form>", "note": "A disabled button cannot be pressed twice, so a slow answer cannot become two sessions."}
]}
```

and the rows' forms get it too, plainly, with no function. In
`src/routes/(planner)/courses/[id=slug]/+page.svelte`, which this is the last version of:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { enhance } from '$app/forms';\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} />\n<List items={sessions}>\n\t{#snippet row(session)}\n\t\t<form method=\"POST\" action=\"?week={planner.week}&/done\" use:enhance>\n\t\t\t<input type=\"hidden\" name=\"id\" value={session.id} />\n\t\t\t<input type=\"hidden\" name=\"done\" value={session.done ? 'no' : 'yes'} />\n\t\t\t<span class:done={session.done}>{format(session.date)}, {session.minutes} min</span>\n\t\t\t<button aria-label=\"{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}\">\n\t\t\t\t{session.done ? 'Mark not done' : 'Mark done'}\n\t\t\t</button>\n\t\t</form>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession action=\"?week={planner.week}&/add\" />\n{/key}", "note": "`enhance` is imported here for the rows' forms. `AddSession` imports its own."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

Restart the dev server so its terminal is empty, and add a session with JavaScript on:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --fill 'Date=2026-10-21' --click 'Add session' --wait 500
-- fill Date=2026-10-21
-- click Add session
-- wait 500
at /courses/guitar?week=2026-10-19
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-12"
    - text: Week of 19 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-26"
  - list:
    - listitem:
      - text: 20 Oct 2026, 45 min
      - 'button "Mark done: 20 Oct 2026"': Mark done
    - listitem:
      - text: 21 Oct 2026, 30 min
      - 'button "Mark done: 21 Oct 2026"': Mark done
  - paragraph: 75 minutes for Guitar this week (1 h 15 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

The page opened on the week of the 12th, the week of the session added last, and moved to the week of
the 19th, which the 21st is in, when the answer came. `--wait 500` gives the row for the 14th time to finish sliding out of
the list, as lesson 9's transitions do. The result is the one JavaScript off gave, and the terminal
running `npm run dev` shows it arrived differently:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:41:13 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 597 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
200 GET /courses/guitar
200 POST /courses/guitar?week=2026-10-12&/add
200 GET /courses/guitar/__data.json?week=2026-10-19&x-sveltekit-invalidated=011
```

**One `POST` and one request for data, where JavaScript off made a `POST` and then
asked for a whole page.** After the
first page, there is no `GET` of a page at all. The action's answer came back as JSON, the answer "A form action" said a
request without `Accept: text/html` gets. `curl` can ask the same way:

```
ana@dev:~/planner$ curl -s -w '\n' -d 'date=2026-10-22&minutes=30' 'http://localhost:5173/courses/guitar?week=2026-10-19&/add'
{"type":"redirect","status":303,"location":"/courses/guitar?week=2026-10-19"}
```

`use:enhance` followed it with a client-side navigation to `location`, which reran the load functions,
the `__data.json` line; the `+layout.js` read the week from the new address, and the planner, which
reads its data instead of copying it, showed the new session. **That is the previous section paying
off.** A planner made once from `untrack(() => data)` would have kept the old sessions on the screen
with the new ones saved on the disk.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The same form sent two ways. Left, with JavaScript off: the browser sends the form with POST, the action answers 303, the browser asks for the whole page with GET, and the server renders it. Right, with use:enhance: the browser&#x27;s script stops the submission and sends the same fields with fetch; the action answers with JSON saying redirect; the script asks for __data.json, the load functions&#x27; data and not a page, and updates the page already on the screen. The action and the load functions are the same code in both.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">JavaScript off</text><rect x=\"20\" y=\"40\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">POST</text><text x=\"140\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the browser sends the form</text><line x1=\"180\" y1=\"86\" x2=\"180\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,102.0 176.9,94.6 183.1,94.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"20\" y=\"104\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">303</text><text x=\"140\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the action saves and redirects</text><line x1=\"180\" y1=\"150\" x2=\"180\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,166.0 176.9,158.6 183.1,158.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"20\" y=\"168\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">GET</text><text x=\"140\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the browser asks for the page</text><line x1=\"180\" y1=\"214\" x2=\"180\" y2=\"230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,230.0 176.9,222.6 183.1,222.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"20\" y=\"232\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">HTML</text><text x=\"140\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a whole new page</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">use:enhance</text><rect x=\"380\" y=\"40\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"394\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">fetch POST</text><text x=\"500\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the same fields, from a script</text><line x1=\"540\" y1=\"86\" x2=\"540\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,102.0 536.9,94.6 543.1,94.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"104\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"394\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">JSON</text><text x=\"500\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the same action, its answer as data</text><line x1=\"540\" y1=\"150\" x2=\"540\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,166.0 536.9,158.6 543.1,158.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"168\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"394\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">__data.json</text><text x=\"500\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the load functions run again</text><line x1=\"540\" y1=\"214\" x2=\"540\" y2=\"230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,230.0 536.9,222.6 543.1,222.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"232\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"394\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">DOM</text><text x=\"500\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the page already on the screen</text><text x=\"360\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the action and the load functions are the same code on both sides</text></svg>", "caption": "use:enhance changes how the form travels and what comes back, not what the server does with it."}
```

## What else it does

With no function, or when the function calls `update()`, `use:enhance` does what a browser would have
done, in place:

- **A redirect** becomes a client-side navigation to its address, with every load function rerun.
- **A `fail()`** updates `page.form` and the page's status, so the `role="alert"` message appears, and
  nothing navigates. The fields keep what was typed.
- **A success with no redirect** reruns every load function, `refreshAll`, and empties the form, as a
  page that reloaded would show it.
- **An error** renders the nearest `+error.svelte`.
- **The focus** moves as it would on a new page, so a screen reader is not left on a button that has
  changed its meaning.

`sending` cannot be seen in a transcript: the answer arrives in milliseconds on a computer talking to
itself. To watch the button say "Adding…", open the course page in your own browser, open its developer
tools, set the network to one of the slow presets in the Network panel, and add a session.

## Form actions and remote functions

SvelteKit 3 also has **remote functions**, an experimental feature whose `form` function covers what
actions do, with a different shape and some additions. The documentation says actions are complete and
will keep working, and that new development is going into remote functions, whose interface may still
change while they are experimental. This course teaches actions because they are stable, and because
what they rest on, a form the browser can send by itself, is the same either way.
