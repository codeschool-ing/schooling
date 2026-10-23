---
title: animate:flip, for elements that move
version: 1
---

**A transition covers an element entering or leaving; an animation covers an element that stays but
changes place.** In a keyed list, when the order changes or a row appears in the middle, the rows that
stay jump to their new positions. `animate:flip` makes them glide there instead.

The planner's rows are in the order the sessions were added, so a new session always lands at the
bottom. It should land at its date. In `Planner.svelte`, sort the course's sessions as they are
derived:

```javascript
let ofCourse = $derived(
	thisWeek.filter((s) => s.course === selected).toSorted((a, b) => (a.date < b.date ? -1 : 1))
);
```

`toSorted` returns a sorted copy and leaves `thisWeek` alone, which matters: sorting the state array in
place would reorder `sessions` itself, inside a derived value, which is exactly the side effect a
derived value must not have. Then, in `List.svelte`, add the animation beside the transition:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script>\n\timport { slide } from 'svelte/transition';\n\timport { flip } from 'svelte/animate';\n\n\tlet { items, row, empty } = $props();\n</script>", "note": "`flip` joins the imports, from `svelte/animate`."},
 {"code": "{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li transition:slide animate:flip>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>\n{:else}\n\t{@render empty?.()}\n{/if}", "note": "`animate:` only works on the direct child of a keyed `{#each}`: the key is how Svelte knows which element moved."}
]}
```

Add a session on the 21st, which belongs between the two that are there:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter
-- fill Date=2026-10-21
-- press Enter
at /
title: 255 min this week · Study planner
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
      - text: 180 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 255 minutes this week (4 h 15 min)
  - paragraph: 90 of 255 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 30 min"
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
        - checkbox "21 Oct 2026, 30 min"
        - text: 21 Oct 2026, 30 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 180 minutes for Linear algebra this week (3 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

**The list was already in its final order when `look` printed it**, a moment after Enter: the 21st sits
between the 19th and the 24th. An animation never changes the order of the page; the DOM is updated at
once, and what moves is only where each element is drawn while it catches up.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The four steps of FLIP for the 24th when a session on the 21st is added above it. First: the 24th&#x27;s row is measured in the second place. Last: the list is updated, the 21st is inserted, and the 24th is measured again in the third place. Invert: a transform draws the 24th back where it was. Play: the transform is animated away, and the row glides down into its new place.\"><text x=\"95\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">First</text><text x=\"95\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">measure</text><rect x=\"20\" y=\"60\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 Oct</text><rect x=\"20\" y=\"106\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">24 Oct</text><text x=\"270\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Last</text><text x=\"270\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">update, measure</text><rect x=\"195\" y=\"60\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 Oct</text><rect x=\"195\" y=\"106\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">21 Oct</text><rect x=\"195\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">24 Oct</text><text x=\"445\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Invert</text><text x=\"445\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">draw it back</text><rect x=\"370\" y=\"60\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 Oct</text><rect x=\"370\" y=\"106\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"445\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">24 Oct</text><text x=\"445\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">translateY(-46px)</text><text x=\"445\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">over the 21st, sliding in</text><text x=\"620\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Play</text><text x=\"620\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">animate to place</text><rect x=\"545\" y=\"60\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 Oct</text><rect x=\"545\" y=\"106\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">21 Oct</text><rect x=\"545\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">24 Oct</text><line x1=\"705\" y1=\"120\" x2=\"705\" y2=\"158\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"705.0,158.0 701.9,150.6 708.1,150.6\" fill=\"var(--phosphor)\"></polygon><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the DOM changes once; only the drawing travels</text></svg>", "caption": "FLIP: measure, change, draw it back where it was, then let it go."}
```

That is what the name says. **FLIP** stands for First, Last, Invert, Play: measure where each element
is before the change (first), let the change happen and measure again (last), draw each element back at
its first position with a transform (invert), then animate the transform away (play). It works for any
change of position, a sort, an insertion, a deletion, without you ever computing a coordinate.
