---
title: The planner with JavaScript switched off
version: 1
---

**Progressive enhancement means building the page so that it works as plain HTML first, and then
letting JavaScript make it better.** A link that works without JavaScript, a form that the browser can
send on its own, a page the server renders whole: those are the base. Client-side navigation, a form
sent without a reload, an animation, are what JavaScript adds on top. If the script fails to arrive,
on a slow train, behind a company proxy, in a browser with an extension that blocks it, or because a
deploy broke it, the base is still there and the person can still do what they came to do.

Lesson 13 got the planner half of the way. The server renders every page with its data, so with
JavaScript off it can at least be **read**. `look --no-js` opens a page in a browser with JavaScript
switched off:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --no-js --click 'Previous week'
-- click Previous week
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

**The week did not move.** The button is a `<button>` with an `onclick`, and with no JavaScript nobody
is listening. Adding a session goes no better:

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
  - paragraph: 45 minutes for Guitar this week (0 h 45 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

No session on the 21st. With no script to call `preventDefault()`, the browser did what a browser does
with a form: it sent it, with `GET`, to the page's own address, with the fields in a query after a `?`,
and loaded the answer. The query was empty, because the inputs have no `name` and a field without a name
is not sent, and the server rendered the page again from the same file. Nothing changed, and nothing
said so.

Everything the planner does when something is clicked happens in the browser, in memory, and is gone
on the next reload. This lesson moves those changes to the server, where they are saved, and it does it
with forms, so that they work **with JavaScript off first** and then, with `use:enhance`, without a
reload when JavaScript is on. SvelteKit's name for the server half is a **form action**.
