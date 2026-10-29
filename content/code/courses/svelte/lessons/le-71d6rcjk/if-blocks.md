---
title: "{#if}: showing one thing or another"
version: 1
---

**`{#if condition}…{/if}` shows its content while the condition is true and removes it from the page
when it is not.** Removes, rather than hides: the elements inside are created when the condition
becomes true and destroyed when it becomes false, so a component inside an `{#if}` starts afresh each
time it appears. `{:else if …}` and `{:else}` add the other branches, and exactly one branch is on the
page at any moment.

The planner has a sentence that should depend on the week: how much of it is done. Three cases,
three sentences. Add a derived value for the minutes already done, beside `total` in the page's
script:

```javascript
let doneMinutes = $derived(thisWeek.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0));
```

and this block in the markup, just under `<WeekTotal minutes={total} />`:

```html
{#if total === 0}
	<p>Nothing planned this week.</p>
{:else if doneMinutes === total}
	<p>Every session this week is done.</p>
{:else}
	<p>{doneMinutes} of {total} minutes done.</p>
{/if}
```

The week of 19 October has one session done, the week before has both done, and the week after has
nothing:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 90 of 225 minutes done.
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week'
-- click Previous week
at /
title: 90 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 60 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 0 min
  - paragraph: 90 minutes this week (1 h 30 min)
  - paragraph: Every session this week is done.
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "13 Oct 2026, 60 min" [checked]
        - text: 13 Oct 2026, 60 min
    - paragraph: 60 minutes for Linear algebra this week (1 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week'
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

## Order matters, and so does the first case

The branches are tested in order and the first true one wins, so **the most specific case goes
first**. `total === 0` has to come before `doneMinutes === total`, because in an empty week both are
true, 0 equals 0, and "Every session this week is done" would be a strange thing to say about a week
with no sessions in it. That is the kind of bug an `{#if}` chain hides well: every branch is correct on
its own, and the order is wrong.

## `{#if}` or a ternary

For a word or two, an expression is shorter: `{n === 1 ? 'session' : 'sessions'}`. For anything with
markup in it, use the block. A ternary chooses between **values**, an `{#if}` between **pieces of the page**, and markup is not a
value in Svelte unless it is wrapped in a snippet, which is a longer way of writing the `{#if}`.

And when something should only be hidden, not destroyed, because it is expensive to create or holds
state the student is in the middle of, keep it on the page and hide it with the `hidden` attribute or
CSS instead. Lesson 9 adds the other reason to prefer `{#if}`: a block that comes and goes can be
animated as it does.
