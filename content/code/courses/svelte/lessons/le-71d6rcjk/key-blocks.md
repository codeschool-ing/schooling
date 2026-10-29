---
title: "{#key}: starting a component again"
version: 1
---

**`{#key value}…{/key}` destroys its content and creates it again whenever the value changes.** Most of
the time that is the opposite of what you want, and it is why keys in lists exist: to keep elements
alive across a change. Once in a while, though, starting afresh is exactly right, and `{#key}` says so
in one line.

The planner has a case. The add form keeps whatever date was typed in it, and the week buttons do not
touch the form. Type a date in the week of 19 October, move to the next week, and the form still holds
a date in the week before, ready to add a session to a week the student is no longer looking at:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --click 'Next week'
-- fill Date=2026-10-21
-- click Next week
at /
title: 0 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
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
  - paragraph: Nothing planned this week.
  - list "Minutes per day":
    - listitem: "26 Oct 2026: 0 min"
    - listitem: "27 Oct 2026: 0 min"
    - listitem: "28 Oct 2026: 0 min"
    - listitem: "29 Oct 2026: 0 min"
    - listitem: "30 Oct 2026: 0 min"
    - listitem: "31 Oct 2026: 0 min"
    - listitem: "1 Nov 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - paragraph: Nothing planned for Linear algebra this week.
    - paragraph: 0 minutes for Linear algebra this week (0 h 0 min)
    - text: Date
    - textbox "Date": 2026-10-21
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

The date is still there. In `Planner.svelte`, wrap the form in a `{#key}` on the week:

```html
{#key week}
	<AddSession onadd={add} />
{/key}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --click 'Next week'
-- fill Date=2026-10-21
-- click Next week
at /
title: 0 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
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
  - paragraph: Nothing planned this week.
  - list "Minutes per day":
    - listitem: "26 Oct 2026: 0 min"
    - listitem: "27 Oct 2026: 0 min"
    - listitem: "28 Oct 2026: 0 min"
    - listitem: "29 Oct 2026: 0 min"
    - listitem: "30 Oct 2026: 0 min"
    - listitem: "31 Oct 2026: 0 min"
    - listitem: "1 Nov 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - paragraph: Nothing planned for Linear algebra this week.
    - paragraph: 0 minutes for Linear algebra this week (0 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

**The field is empty.** When `week` changed, the old `AddSession` was destroyed, with its `date` and
`minutes`, and a new one was created with the starting values. Nothing in `AddSession` had to know
about weeks, and the form did not grow a prop just to be reset.

## When to reach for it

`{#key}` is right when a piece of the page holds state of its own that belongs to one value of
something outside it, as the form's date belonged to one week. It is also how you restart something
that only runs when created: an effect that should begin again, or, in lesson 9, a transition that
should play again each time a value changes.

It is wrong as a way of forcing something to update. A component that does not follow a value it
should follow is missing a `$derived` or reading a prop once, and destroying it on every change hides
that bug at the cost of throwing the component away.
