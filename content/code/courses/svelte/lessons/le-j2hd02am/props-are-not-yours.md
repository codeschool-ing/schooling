---
title: A prop is not yours to change
version: 1
---

**A child may change its own state and the state it was explicitly allowed to bind, and nothing
else.** The rule is easy to break by accident, because when the page passes `sessions` down as a prop,
the child receives the page's own proxy, and changing it works: the session appears, the totals
change, everything looks right, and in the version below nothing complains at all.

Here is the tempting version of `AddSession`. It takes the sessions and changes them itself, and it is
even a little clever: adding to a date that already has a session for the course lengthens that
session instead of making a second one.

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\tlet { sessions, course } = $props();\n\n\tlet date = $state('');\n\tlet minutes = $state(30);", "note": "The page's array, received as a prop, and the course to add to."},
 {"code": "\tfunction add() {\n\t\tconst same = sessions.find((s) => s.course === course && s.date === date);\n\t\tif (same) same.minutes += minutes;\n\t\telse sessions.push({ id: sessions.length + 1, course, date, minutes, done: false });\n\t}\n</script>\n\n<p>\n\t<label>Date <input type=\"date\" bind:value={date} /></label>\n\t<label>Minutes <input type=\"number\" min=\"5\" step=\"5\" bind:value={minutes} /></label>\n\t<button disabled={!date} onclick={add}>Add session</button>\n</p>", "note": "Two ways of changing the page's state from the child: a new object pushed onto the array, or a property of an existing one changed."}
]}
```

with the page passing it what it needs, `<AddSession {sessions} course={selected} />`, in place of the
`onadd` line. Add a session on the 21st, a date with nothing on it, and then thirty minutes on the
24th, which already has an hour of algebra:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --fill 'Date=2026-10-21' --click 'Add session' --fill 'Date=2026-10-24' --click 'Add session'
console: [vite] connecting...
console: [vite] connected.
-- fill Date=2026-10-21
-- click Add session
-- fill Date=2026-10-24
-- click Add session
at /
title: 285 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 210 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 285 minutes this week (4 h 45 min)
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - checkbox "13 Oct 2026, 60 min" [checked]
      - text: 13 Oct 2026, 60 min
    - listitem:
      - checkbox "19 Oct 2026, 90 min" [checked]
      - text: 19 Oct 2026, 90 min
    - listitem:
      - checkbox "24 Oct 2026, 90 min"
      - text: 24 Oct 2026, 90 min
    - listitem:
      - checkbox "21 Oct 2026, 30 min"
      - text: 21 Oct 2026, 30 min
  - paragraph: 210 minutes for Linear algebra this week (3 h 30 min)
  - paragraph:
    - text: Date
    - textbox "Date": 2026-10-24
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

Both worked: there is a new session on the 21st, and the 24th went from 60 minutes to 90. **And
nothing was printed.** The page's state was changed twice by a component that does not own it, once by
growing its array and once by changing a property of one of its objects, and the console is silent.

Svelte does have a warning for this, `ownership_invalid_mutation`, and it is narrower than the rule.
It fires when the code assigns through the prop itself, as `sessions[0].minutes += 30` would; the
message names the file and the line, and offers the two ways out, binding the prop or using a
callback. Here the property was changed through `same`, a local variable holding an object found in
the array, and the array was grown with `push`, and the check sees neither.

## Why it matters, when it works

Because the page no longer knows how sessions are made. In "Binding a value to a form field", `add` in
the page decided the id, the course, and that a new session is not done. Spread that over three
components that each change `sessions`, and the day ids have to come from somewhere else, there are
three places to change and no way to find them by reading the page. **The owner of a piece of state
should be the only code that changes its shape.** A callback keeps that true: the child says what the
student asked for, the page decides what that means, including whether "add to the 24th" means a
longer session or a second one.

So the warning is a help when it catches you, and this time it did not. **The rule is the thing to
follow; the warning is a check on some of it.**

Put `AddSession.svelte` back to the version in "Binding a value to a form field", and the page back
to `<AddSession onadd={add} />`.
