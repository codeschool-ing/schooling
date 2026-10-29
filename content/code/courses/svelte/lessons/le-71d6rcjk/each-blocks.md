---
title: "{#each}, its forms, and declarations in the markup"
version: 1
---

**`{#each list as item}…{/each}` repeats its content once per item**, and the planner has used it since
lesson 3. It has a few more forms worth knowing, and this section uses them to add one thing the
planner is missing: a line per day of the week, so the student can see when the minutes fall.

| form | gives you |
|---|---|
| `{#each sessions as session}` | each item |
| `{#each sessions as session, i}` | each item and its index, from 0 |
| `{#each courses as { id, name }}` | the item destructured, like a function's parameters |
| `{#each sessions as session (session.id)}` | a key, which the next section is about |
| `{#each { length: 7 }, i}` | no item, only an index: anything with a `length` can be walked |
| `{#each list as item}…{:else}…{/each}` | the `{:else}` content when the list is empty |

The days come from the week's Monday, seven times. Add a derived value that totals the minutes per
date, beside the others in the page's script:

```javascript
let byDay = $derived.by(() => {
	const minutes = {};
	for (const s of thisWeek) minutes[s.date] = (minutes[s.date] ?? 0) + s.minutes;
	return minutes;
});
```

and this list in the markup, just under the `{#if}` block of the previous section:

```html
<ol aria-label="Minutes per day">
	{#each { length: 7 }, i}
		{const day = addDays(week, i)}
		<li>{format(day)}: {byDay[day] ?? 0} min</li>
	{/each}
</ol>
```

**`{const day = …}` declares a variable in the markup**, visible to everything after it in the same
block. It is new in Svelte 5.56, and it exists so that a value used twice in one iteration is written
once. Open the page, and move one week forward:

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
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 0 min"
    - listitem: "20 Oct 2026: 0 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 0 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 0 min"
    - listitem: "25 Oct 2026: 0 min"
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

The label says the week of 26 October, the days still say 19 to 25 October, and every one of them
says 0 minutes. Half of each line followed the week and half did not: `byDay` is derived, so it moved
to the new week and has nothing for those dates, while `day` stayed where it was. **A declaration in the
markup behaves like one in the script**: `const day = addDays(week, i)` ran once, when that `<li>` was
created, exactly as `let hours = minutes / 60` did in lesson 2, and the seven `<li>` elements were not
created again when the week changed, because there were still seven of them. The fix is the same as
it was then. A value that should follow the state is derived:

```html
<ol aria-label="Minutes per day">
	{#each { length: 7 }, i}
		{const day = $derived(addDays(week, i))}
		<li>{format(day)}: {byDay[day] ?? 0} min</li>
	{/each}
</ol>
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

and back on the week of 19 October, each day with its minutes:

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
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
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

`aria-label` on the `<ol>` gives the list a name, which `look` prints beside it: a page with two lists
of numbers is easier to navigate when each says what it is.

You will meet the older spelling, **`{@const day = addDays(week, i)}`**, in code written before 5.56.
It recalculates by itself, without `$derived`, and may only appear directly inside a block. The new
form follows the same rules as the script, which is one rule fewer to remember, and Svelte's
documentation now calls `{@const}` legacy.

## The index is not an identity

`i` above is fine, because the seven days are always the same seven positions of the same week. **Do
not use an index to identify an item that can move.** If the sessions list were sorted, deleted from
or added to in the middle, "the session at position 2" would be a different session after the change.
That is the subject of the next section, and the reason the planner's `List` already uses
`(item.id)`.
