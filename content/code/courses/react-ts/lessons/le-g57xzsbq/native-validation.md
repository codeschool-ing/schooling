---
title: What the browser checks for you
version: 1
---

**HTML can refuse a form before any JavaScript runs.** `required` refuses an empty field, `min` and
`max` refuse a number outside their range, and `type="date"` refuses text that is not a date. When a
form fails them, the browser does not fire `submit` at all, so `addSession` is never called. The
fields that failed match the CSS selector `:invalid`, which `look --html` can print:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Add session' --quiet --html 'input:invalid'
-- click button Statistics
-- click button Add session
<input required="" type="date" name="date">
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=500' --do 'click button Add session' --quiet --html 'input:invalid'
-- click button Statistics
-- fill Date=2026-10-24
-- fill Minutes=500
-- click button Add session
<input min="5" max="240" required="" type="number" value="30" name="minutes">
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | sed -n '/list:/,/heading "Add/p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
    - listitem:
      - checkbox "Sat 24 Oct · 45 min"
      - text: Sat 24 Oct · 45 min
  - heading "Add a session" [level=2]
```

The empty date was refused, then a minutes field of 500, and only the third try, a date and 45
minutes, added a session. **Nothing invalid reached the planner**, with no validation code written.

It is a good floor and a poor ceiling. What the browser does not give you:

- **Its messages are its own.** The text, its language and its look are the browser's; they appear in
  a bubble that disappears, and you cannot put "A session is at most 240 minutes" in it without
  JavaScript.
- **They appear one at a time**, for the first failing field only.
- **Screen readers handle the bubble unevenly**, and nothing in the page records which field failed
  once the bubble has gone.
- **It knows types, not rules.** "At most 240" fits `max`; "not more than four hours on one day" does
  not fit any attribute.

So keep the attributes, which cost nothing and still guard the form if your script fails, and add
messages of your own on top. That is a job worth handing to a library.
