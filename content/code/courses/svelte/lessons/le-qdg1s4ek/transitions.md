---
title: Transitions on the elements that come and go
version: 1
---

**A transition animates an element as it enters or leaves the page**, and in Svelte it is an attribute
on the element: `transition:slide`, `transition:fade`, `transition:fly`. The framework knows exactly
when an element is created and when it is about to be destroyed, because it is the one doing both, so
it can play an animation at each moment without you tracking anything. The transitions themselves come
in `svelte/transition`.

The planner's session list is the natural place for one: rows come and go as the week changes and as
sessions are added. The rows are `List`'s, so the transition goes there. Replace `src/lib/List.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script>\n\timport { slide } from 'svelte/transition';\n\n\tlet { items, row, empty } = $props();\n</script>", "note": "`slide` grows an element's height from nothing as it enters and shrinks it as it leaves."},
 {"code": "{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li transition:slide>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>\n{:else}\n\t{@render empty?.()}\n{/if}", "note": "`transition:` plays both ways: in when the row is created, out when it is removed."}
]}
```

Go back a week, and print the page at once, while the animation is still running:

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

**Three rows, in a week that has one session of algebra.** The 13th is new, and the 19th and 24th are
leaving: they stay in the page, shrinking, until their outro finishes, and only then are they removed.
Half a second later:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week' --wait 500
-- click Previous week
-- wait 500
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

The tree `look` printed is what a screen reader would be given at that moment, so for the length of
an outro, a leaving element is still there to be read. Keep outros short: the ones in this lesson
stay at Svelte's default of 400 milliseconds or less.

## Local, and what that leaves out

Now go a week forward instead, to the week of 26 October, which has nothing planned:

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

**No leaving rows this time**, although two rows left. Transitions in Svelte 5 are **local** by
default: an element's transition plays when the block it belongs to adds or removes it, here the
`{#each}`, and not when a block further out is destroyed. Moving to an empty week did not remove the
rows from the `{#each}`; it switched `List`'s `{#if}` to its `{:else}`, which threw away the whole list
at once, `{#each}` included. `transition:slide|global` would make them play in that case too. Local is
the default because a page usually changes many things at once, and animating every element of a
section that is being replaced is noise.

## In, out, and the parameters

`transition:` is the same animation both ways. `in:` and `out:` set them separately, so that a row can
fly in from above and simply fade out, `in:fly={{ y: -8 }} out:fade`. Every transition takes parameters
in an object: `duration` and `delay` in milliseconds, and `easing`, a function from `svelte/easing`
that shapes the speed through the animation, which the section on writing your own transition draws.
The double braces are not special syntax: they are an object inside an expression.
