---
title: Migrating a component
version: 1
---

**Svelte's compiler can rewrite a Svelte 4 component as a Svelte 5 one**, and it does most of the
work. The function is `migrate`, exported from `svelte/compiler` next to the `compile` you called in
lesson 1, and a script of the same size calls it. Save it as `migrate.mjs` beside `compile.mjs`:

```javascript
// migrate.mjs: print a Svelte 4 component rewritten for Svelte 5.
//   node migrate.mjs FILE.svelte
import { migrate } from "svelte/compiler";
import fs from "node:fs";

const [file] = process.argv.slice(2);
const { code } = migrate(fs.readFileSync(file, "utf8"), { filename: file });
process.stdout.write(code);
```

It prints the rewritten component and changes nothing on disk, so you can read it before deciding.
Run it on `WeekNav.svelte` as the section before last left it:

```
ana@dev:~/planner$ node migrate.mjs src/lib/WeekNav.svelte
<svelte:options runes={false} />
<script>
	import { createEventDispatcher } from 'svelte';
	import { addDays, format } from '#lib/week.js';
	/**
	 * @typedef {Object} Props
	 * @property {any} week
	 * @property {string} [label]
	 */

	/** @type {Props} */
	let { week = $bindable(), label = 'Week of' } = $props();

	const dispatch = createEventDispatcher();
	let shown = $derived(`${label} ${format(week)}`);
	function move(days) {
		week = addDays(week, days);
		dispatch('change', { week });
	}
</script>
<p>
	<button onclick={() => move(-7)}>Previous week</button>
	{shown}
	<button onclick={() => move(7)}>Next week</button>
</p>
```

## What it did

Line by line, the table from the start of this lesson:

- **`<svelte:options runes={false} />` is still there, and you have to remove it.** The migrator
  changes the syntax and leaves the file's options alone, and that line would put the result back in
  legacy mode, where `$props` is an error.
- **`export let` became `$props()`**, with a JSDoc comment describing each prop's type, inferred from
  what it could see: `label` has a string default, so it is a `string`, and `week` could be anything.
- **`$: shown = …` became `$derived(…)`**, which is safe here: the expression's reads are tracked at
  runtime now, so even the `describe()` version of the previous section would have been fixed by it.
- **`on:click` became `onclick`.**

## What it left for you

Two things, and both are decisions rather than syntax, which is why a tool will not make them.

**`createEventDispatcher` is still there.** It still works in Svelte 5, deprecated, and the migrator
leaves it alone because replacing it means changing the component's parents too: every `on:change`
in the project would have to become an `onchange`.

**`week` came out as `$bindable()`**, because the Svelte 4 component assigned to its own prop. The
migrator kept that behaviour as it was. But the component never needed to own the week: it only has
to tell its parent which week to show next. A callback prop says that more plainly than a two-way
binding, and lesson 5 is about when each is right.

So finish it by hand. This is the version the planner keeps:

```schooling-example
{"language": "html", "file": "src/lib/WeekNav.svelte", "parts": [
 {"code": "<script>\n\timport { addDays, format } from '#lib/week.js';\n\n\tlet { week, label = 'Week of', onchange } = $props();\n\n\tlet shown = $derived(`${label} ${format(week)}`);\n</script>", "note": "`onchange` is a prop like the others: a function the parent passes, which this component calls."},
 {"code": "<p>\n\t<button onclick={() => onchange(addDays(week, -7))}>Previous week</button>\n\t{shown}\n\t<button onclick={() => onchange(addDays(week, 7))}>Next week</button>\n</p>", "note": "The component no longer assigns to `week`. It asks the parent to move it, and the new `week` comes back down as a prop."}
]}
```

And in `+page.svelte`, the line that uses it listens with the callback instead of `on:change`:

```html
<WeekNav {week} onchange={(next) => (week = next)} />
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week'
-- click Previous week
at /
title: 90 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
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
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - button "13 Oct 2026, 60 min" [pressed]
    - listitem:
      - button "19 Oct 2026, 90 min" [pressed]
    - listitem:
      - button "24 Oct 2026, 60 min"
  - paragraph: 60 minutes for Linear algebra this week (1 h 0 min)
  - button "Add 30 minutes on 12 Oct 2026"
```

The week of 12 October, as in lesson 3, with one component fewer to read in the page. To migrate a
whole project rather than one file, `npx sv migrate svelte-5` runs the same rewrite over every
component and updates `package.json`; it was not run for this course, because the planner was born
in Svelte 5.
