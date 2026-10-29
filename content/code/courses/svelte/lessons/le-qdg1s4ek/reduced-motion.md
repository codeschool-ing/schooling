---
title: Motion for the people who asked for less
version: 1
---

**Some people get dizzy or nauseous from movement on a screen, and their operating system has a
setting that says so.** The browser exposes it as the media query `prefers-reduced-motion: reduce`, and
WCAG asks that motion started by an interaction can be turned off. The planner now slides rows, glides
them into place, counts numbers up and flashes totals, and every one of those should stop for somebody
who asked for less.

**Svelte's transitions do not do that by themselves.** They run on the Web Animations API, not on CSS
transitions, so the usual stylesheet rule that sets every `transition-duration` to zero does not touch
them. `look --reduce-motion` opens the page as a browser with that setting would:

```
ana@dev:~/planner$ look http://localhost:5173/ --reduce-motion --click 'Previous week'
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
  - list "Minutes per day":
    - listitem: "12 Oct 2026: 0 min"
    - listitem: "13 Oct 2026: 60 min"
    - listitem: "14 Oct 2026: 0 min"
    - listitem: "15 Oct 2026: 30 min"
    - listitem: "16 Oct 2026: 0 min"
    - listitem: "17 Oct 2026: 0 min"
    - listitem: "18 Oct 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "13 Oct 2026, 60 min" [checked]
        - text: 13 Oct 2026, 60 min
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 60 minutes for Linear algebra this week (1 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

The leaving rows are still there, sliding out for somebody who asked for no sliding.

## `prefersReducedMotion`

`svelte/motion` exports `prefersReducedMotion`, an object whose `current` is `true` while the setting is
on, and which updates if the setting changes while the page is open. Every animation in the planner
takes its duration from it. In `List.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script>\n\timport { slide } from 'svelte/transition';\n\timport { flip } from 'svelte/animate';\n\timport { prefersReducedMotion } from 'svelte/motion';\n\n\tlet { items, row, empty } = $props();\n\n\tlet duration = $derived(prefersReducedMotion.current ? 0 : 300);\n</script>\n\n{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li transition:slide={{ duration }} animate:flip={{ duration }}>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>\n{:else}\n\t{@render empty?.()}\n{/if}", "note": "One value decides the speed of everything in the list: 0 milliseconds for somebody who asked for less motion."}
]}
```

and the same in the other two places, with the same import of `prefersReducedMotion`: in `Planner.svelte`
the tween becomes

```javascript
const shownDone = Tween.of(() => doneMinutes, {
	duration: prefersReducedMotion.current ? 0 : 400
});
```

and in `WeekTotal.svelte` the flash becomes `in:flash={{ duration: prefersReducedMotion.current ? 0 : 600 }}`.

```
ana@dev:~/planner$ look http://localhost:5173/ --reduce-motion --click 'Previous week'
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
  - list "Minutes per day":
    - listitem: "12 Oct 2026: 0 min"
    - listitem: "13 Oct 2026: 60 min"
    - listitem: "14 Oct 2026: 0 min"
    - listitem: "15 Oct 2026: 30 min"
    - listitem: "16 Oct 2026: 0 min"
    - listitem: "17 Oct 2026: 0 min"
    - listitem: "18 Oct 2026: 0 min"
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
ana@dev:~/planner$ look http://localhost:5173/ --reduce-motion --check '24 Oct 2026, 60 min' --wait 0
-- check 24 Oct 2026, 60 min
-- wait 0
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
  - paragraph: 150 of 225 minutes done.
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
        - checkbox "24 Oct 2026, 60 min" [checked]
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

**One row, at once, and the full number, at once.** With a duration of zero, an outro ends the moment
it starts and a tween arrives the moment it is set, so the page behaves as if there were no animation,
without a second version of any component. Nothing about the planner works differently; only its
movement stops.

## Reduce, or remove

"Reduced" does not have to mean "none". A fade does not move anything across the screen, and many
designers keep short fades for people who asked for reduced motion while removing slides, flips and
anything that travels. What it must never mean is nothing changes: a student with the setting on still
needs to see that the session was added. Here everything still happens; it just happens without
travelling.
