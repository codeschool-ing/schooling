---
title: A Svelte 4 component in the planner
version: 1
---

**The fastest way to read Svelte 4 is to run some.** The planner's week navigation, the two buttons
and the label between them, is a good piece to take out of the page and give a component of its own.
This section writes that component the way it would have been written in 2023, and uses it from the
runes page as it stands.

Save this as `src/lib/WeekNav.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/WeekNav.svelte", "parts": [
 {"code": "<svelte:options runes={false} />", "note": "The first line puts this one file in legacy mode. Without it, the project's configuration forces runes, and the rest is an error."},
 {"code": "<script>\n\timport { createEventDispatcher } from 'svelte';\n\timport { addDays, format } from '#lib/week.js';", "note": "`createEventDispatcher` is how a Svelte 4 component told its parent that something happened."},
 {"code": "\texport let week;\n\texport let label = 'Week of';\n\n\tconst dispatch = createEventDispatcher();", "note": "`export let` declares a prop. `label` has a default, so the parent may leave it out."},
 {"code": "\t$: shown = `${label} ${format(week)}`;", "note": "A `$:` statement re-runs whenever a name that appears in it changes: here `label` or `week`."},
 {"code": "\tfunction move(days) {\n\t\tweek = addDays(week, days);\n\t\tdispatch('change', { week });\n\t}\n</script>", "note": "Assigning to `week` updates this component; `dispatch` sends a `change` event, with the new week in its `detail`."},
 {"code": "<p>\n\t<button on:click={() => move(-7)}>Previous week</button>\n\t{shown}\n\t<button on:click={() => move(7)}>Next week</button>\n</p>", "note": "`on:click` is the Svelte 4 way to listen for an event."}
]}
```

Then, in `src/routes/+page.svelte`, import it with the other components and replace the paragraph
with the two buttons by this one line. Everything else in the page stays as lesson 3 left it:

```html
<WeekNav {week} on:change={(event) => (week = event.detail.week)} />
```

The page is a runes component and `WeekNav` is a legacy one, and they work together. The page passes
`week` down as a prop, and listens with `on:change`, the Svelte 4 syntax for a component event, which
runes mode still accepts for exactly this case:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week' --click 'Previous week' --click 'Previous week'
-- click Next week
-- click Previous week
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

The tree is the same as lesson 3's, because the markup is the same: an outside reader cannot tell
which mode a component was compiled in.

## Without the first line

Delete the `<svelte:options runes={false} />` line from `WeekNav.svelte` and save. The page breaks,
and the terminal running `npm run dev` says why:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:56:08 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 523 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
200 GET /
7:56:12 PM [vite] (ssr) page reload src/lib/WeekNav.svelte
7:56:12 PM [vite] (ssr) program reload
7:56:12 PM [vite] (ssr) An error happened during full reload
src/lib/WeekNav.svelte:4:1 Cannot use `export let` in runes mode — use `$props()` instead
https://svelte.dev/e/legacy_export_invalid

Internal server error: src/lib/WeekNav.svelte:4:1 Cannot use `export let` in runes mode — use `$props()` instead
https://svelte.dev/e/legacy_export_invalid
  Plugin: vite-plugin-svelte:compile
  File: src/lib/WeekNav.svelte:4:1
   2 |    import { createEventDispatcher } from 'svelte';
   3 |    import { addDays, format } from '#lib/week.js';
   4 |    export let week;
                          ^
   5 |    export let label = 'Week of';
   6 |  
500 GET /
```

**`legacy_export_invalid` is the compiler refusing Svelte 4 syntax in a runes component**, and its
message names the replacement. Every piece of the legacy syntax has an error like this one, and
each message says what to write instead, which makes the compiler a decent migration guide on its
own. Put the line back before going on.

## Reading it again

Go back over `WeekNav` with the table of the previous section beside it. `export let` is `$props`,
`$:` is `$derived`, `on:click` is `onclick`, and `createEventDispatcher` with `on:change` is a
callback prop. Nothing here is hard to read once you know the spelling. The trouble with Svelte 4
code is not reading it; it is one of those four, `$:`, which looks like it does what `$derived` does
and sometimes does not. The next section shows when.
