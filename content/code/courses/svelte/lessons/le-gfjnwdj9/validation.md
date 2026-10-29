---
title: When the form is wrong
version: 1
---

**The browser checks a form before sending it, and the server has to check it again.** The `required`,
`min` and `max` on the inputs are checked by the browser itself, with or without JavaScript, and it
refuses to send a form that breaks them. Try three minutes:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --no-js --fill 'Date=2026-10-22' --fill 'Minutes=3' --click 'Add session'
-- fill Date=2026-10-22
-- fill Minutes=3
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
    - listitem:
      - checkbox "23 Oct 2026, 30 min"
      - text: 23 Oct 2026, 30 min
  - paragraph: 105 minutes for Guitar this week (1 h 45 min)
  - text: Date
  - textbox "Date": 2026-10-22
  - text: Minutes
  - spinbutton "Minutes": "3"
  - button "Add session"
```

Still `at /courses/guitar`, no session on the 22nd, and the two values still in their fields: the form
was never sent. A person using the page sees the browser's own message beside the field, in their own
language. **That is a convenience, not a protection.** Anything can send a `POST` to the page, `curl`
did in the last section, and the action as it stands writes whatever arrives:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' -d 'date=2026-10-22&minutes=-40' http://localhost:5173/courses/guitar
303
```

A 303, the action's answer for a session saved, and the planner believes it:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar | grep min
      - checkbox "20 Oct 2026, 45 min"
      - text: 20 Oct 2026, 45 min
      - checkbox "21 Oct 2026, 30 min"
      - text: 21 Oct 2026, 30 min
      - checkbox "22 Oct 2026, -40 min"
      - text: 22 Oct 2026, -40 min
      - checkbox "23 Oct 2026, 30 min"
      - text: 23 Oct 2026, 30 min
  - paragraph: 65 minutes for Guitar this week (1 h 5 min)
```

Minus forty minutes of guitar, counted into the week. Put the file back as Git last saw it, which also
takes away the sessions the last section added, before going on:

```
ana@dev:~/planner$ git checkout data/planner.json
Updated 1 path from the index
```

## `fail()`

**`fail(status, data)` is how an action says the form was wrong.** It does not throw, it is returned,
and it does not show the error page. The page renders again, as the answer to the `POST`, with the
status given and `data` available to it as the **form result**. So the page can say what was wrong and
keep what the person typed. Replace `+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's form does, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession } from '#lib/server/planner.js';\nimport { isDate } from '#lib/week.js';\n\nexport const actions = {\n\tdefault: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));"},
 {"code": "\t\tif (!isDate(date)) return fail(400, { date, minutes, problem: 'The session needs a date.' });\n\t\tif (!Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\t\treturn fail(400, { date, minutes, problem: 'Minutes must be a whole number from 5 to 600.' });\n\t\t}", "note": "400 is Bad Request: the problem is in what was sent. The object goes back to the page, so it should hold only what the page may show."},
 {"code": "\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}`);\n\t}\n};", "note": "A course that does not exist is not a mistake in the form, so it is `error()` and the error page, as in the load function."}
]}
```

`isDate` is new. A date that matches `YYYY-MM-DD` can still be no date at all, the 31st of February, so
it writes the date back out and checks that the same text comes back. Add it to `src/lib/week.js`,
which now reads:

```schooling-example
{"language": "javascript", "file": "src/lib/week.js", "parts": [
 {"code": "// week.js: dates as 'YYYY-MM-DD' strings, and the week they fall in.\n// Weeks start on Monday.\nconst DAY = 24 * 60 * 60 * 1000;\nconst toTime = (date) => Date.parse(`${date}T00:00:00Z`);\nconst toDate = (time) => new Date(time).toISOString().slice(0, 10);"},
 {"code": "/** Whether `text` is a real date, written as 'YYYY-MM-DD'. */\nexport function isDate(text) {\n\treturn /^\\d{4}-\\d{2}-\\d{2}$/.test(text) && toDate(toTime(text)) === text;\n}\n\n/** The Monday of the week `date` falls in. */\nexport function mondayOf(date) {\n\tconst day = new Date(toTime(date)).getUTCDay();\n\treturn toDate(toTime(date) - ((day + 6) % 7) * DAY);\n}\n\n/** `date` moved by `days`, which may be negative. */\nexport function addDays(date, days) {\n\treturn toDate(toTime(date) + days * DAY);\n}\n\n/** Whether `date` falls in the week that starts on `monday`. */\nexport function inWeek(date, monday) {\n\treturn date >= monday && date < addDays(monday, 7);\n}\n\n/** `2026-10-19` as `19 Oct 2026`. */\nexport function format(date) {\n\treturn new Date(toTime(date)).toLocaleDateString('en-GB', {\n\t\tday: 'numeric',\n\t\tmonth: 'short',\n\t\tyear: 'numeric',\n\t\ttimeZone: 'UTC'\n\t});\n}", "note": "`2026-02-31` parses as the 3rd of March, and writes back out as `2026-03-03`, which is not what came in."}
]}
```

The form shows the problem and puts the values back. The form result reaches any component through
`page.form` from `$app/state`, so the course page does not have to pass it down. Replace
`src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';"},
 {"code": "\tlet form = $derived(page.form);\n</script>\n\n<form method=\"POST\">", "note": "`page.form` is what the last action returned, while the page shows that action's answer, and `undefined` otherwise."},
 {"code": "\t{#if form?.problem}\n\t\t<p role=\"alert\">{form.problem}</p>\n\t{/if}\n\t<label>Date <input type=\"date\" name=\"date\" required value={form?.date ?? ''} /></label>\n\t<label>Minutes <input type=\"number\" name=\"minutes\" min=\"5\" max=\"600\" step=\"5\" required value={form?.minutes ?? 30} /></label>\n\t<button>Add session</button>\n</form>", "note": "`role=\"alert\"` makes a screen reader announce the message when it appears, without the person having to look for it."}
]}
```

```
ana@dev:~/planner$ curl -s -w '%{http_code}\n' -H 'Accept: text/html' -d 'date=2026-02-31&minutes=30' http://localhost:5173/courses/guitar | grep -o '<p role="alert">[^<]*</p>\|^[0-9]*$'
<p role="alert">The session needs a date.</p>
400
```

**A 400, and the page with the problem in it**, rendered on the server. A person with JavaScript off
whose form got past the browser's checks would see exactly that page, with their values still in the
fields. The browser's checks make mistakes cheap to fix; the action's make them impossible to save.
