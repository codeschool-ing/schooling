---
title: $state
version: 1
---

**`$state` declares a value the page depends on, and assigning to it is how the page changes.** You
met it in lessons 1 and 2 as a counter. In the planner the first piece of state is the week being
shown, and two buttons move it. Replace `src/routes/+page.svelte` with the planner's first real page:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, format } from '#lib/week.js';", "note": "Imports of plain modules and of JSON work in a component's script as they do anywhere else."},
 {"code": "\tlet week = $state(mondayOf(data.sessions.at(-1).date));\n</script>", "note": "The week starts as the Monday of the latest session. `$state` makes it a signal; the initial value is computed once."},
 {"code": "<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>", "note": "Each button assigns a new string to `week`. That assignment is all it takes: the text that reads `week` updates."},
 {"code": "\t<ul>\n\t\t{#each data.courses as course}\n\t\t\t<li>{course.name}</li>\n\t\t{/each}\n\t</ul>\n</main>", "note": "`{#each}` repeats its content for each course; lesson 8 is about it. The course list does not change, so it is not state."}
]}
```

The page now opens on the week of 19 October:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem: Linear algebra
    - listitem: Spanish
    - listitem: Guitar
```

And the buttons move it. `look` presses them in order, so this goes forward one week and back two:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week' --click 'Previous week' --click 'Previous week'
-- click Next week
-- click Previous week
-- click Previous week
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem: Linear algebra
    - listitem: Spanish
    - listitem: Guitar
```

## What may go in `$state`

Anything: a number, a string, an object, an array. **What changes is the variable**, and that is
also its limit. `week` is reactive because the compiler rewrote every read and write of the name
`week` in this component. The moment the value leaves the variable, for example passed to a plain
function or copied into another variable, it is just a string again, as `hours` was in lesson 2.

The initial value is computed **once**, when the component is created. `mondayOf(…)` ran a single
time; after that `week` only changes when something assigns to it. That is why it is safe, and normal,
to compute a starting value from data in the declaration.

## What should not be state

**A value that can be computed from other state is not state of its own.** The label
"Week of 19 Oct 2026" is computed from `week` every time it is shown, and storing it in a second
`$state` would mean remembering to update both, and one day forgetting. The next section gives those
values their own rune. The course list is not state either: it comes from the data and nothing on the
page changes it, so it is a plain import.

A good test when you are unsure: **if you deleted this variable, could you work its value out from
the others?** If yes, it is derived. If no, it is state.
