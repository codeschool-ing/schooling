---
title: Snippets, named pieces of markup
version: 1
---

**A snippet is a named piece of markup that can be rendered more than once, and passed around like a
value.** `{#snippet name(parameters)}…{/snippet}` declares one, and `{@render name(arguments)}` renders
it. The `children` of the previous section was a snippet too, one that Svelte made for you out of the
content between the tags.

The simplest use is inside one component, to avoid writing the same markup twice. The planner's
session line, a checkbox and a sentence, is about to be handed to another component, so it needs a
name. In the page, the list becomes:

```html
{#snippet sessionLine(session)}
	<label class:done={session.done}>
		<input type="checkbox" bind:checked={session.done} />
		{format(session.date)}, {session.minutes} min
	</label>
{/snippet}

<ul>
	{#each ofCourse as session}
		<li>{@render sessionLine(session)}</li>
	{/each}
</ul>
```

Nothing a visitor can see changes, which is the test that the snippet renders exactly what it
replaced:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Spanish'
-- click Spanish
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra"
      - text: 150 min
    - listitem:
      - button "Spanish" [pressed]
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - region "Spanish":
    - heading "Spanish" [level=2]
    - list:
      - listitem:
        - checkbox "15 Oct 2026, 30 min" [checked]
        - text: 15 Oct 2026, 30 min
      - listitem:
        - checkbox "22 Oct 2026, 30 min"
        - text: 22 Oct 2026, 30 min
    - paragraph: 30 minutes for Spanish this week (0 h 30 min)
    - paragraph:
      - text: Date
      - textbox "Date"
      - text: Minutes
      - spinbutton "Minutes": "30"
      - button "Add session" [disabled]
```

Read it as a function that returns markup, because that is what it compiles to. `session` is a
parameter, and inside the snippet it is whatever `{@render}` passed. The snippet can also read
anything in scope where it was declared, here `format` and the page's state, exactly as a nested
function can read the variables around it.

## Where a snippet can be used

A snippet declared at the top level of a component's markup is visible everywhere in that markup, and
in the `<script>` as well, so it can be passed to other components or stored in a variable. A snippet
declared inside an `{#each}` or an `{#if}` is visible only inside that block, as a variable declared
in a block would be.

**The binding inside the snippet still works**, because the snippet belongs to the page: the
checkbox is bound to `session.done` on an object the page owns, wherever the snippet ends up rendered.
That is what makes the next section possible, where the snippet is handed to another component that
draws the list around it.
