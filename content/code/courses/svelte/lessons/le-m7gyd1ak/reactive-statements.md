---
title: What `$:` got wrong
version: 1
---

**A Svelte 4 `$:` statement re-runs when a name written inside it changes, and the compiler decides
which names those are by reading the statement, once, at build time.** That is the whole rule, and it
is the source of the bug that made the Svelte team replace it. A value read anywhere else, inside a
function the statement calls for instance, is invisible to it.

To see it, move `WeekNav`'s label into a function, the kind of tidying anybody might do:

```schooling-example
{"language": "html", "file": "src/lib/WeekNav.svelte", "parts": [
 {"code": "<svelte:options runes={false} />\n\n<script>\n\timport { createEventDispatcher } from 'svelte';\n\timport { addDays, format } from '#lib/week.js';\n\n\texport let week;\n\texport let label = 'Week of';\n\n\tconst dispatch = createEventDispatcher();"},
 {"code": "\tfunction describe() {\n\t\treturn `${label} ${format(week)}`;\n\t}\n\n\t$: shown = describe();\n\n\tfunction move(days) {\n\t\tweek = addDays(week, days);\n\t\tdispatch('change', { week });\n\t}\n</script>\n\n<p>\n\t<button on:click={() => move(-7)}>Previous week</button>\n\t{shown}\n\t<button on:click={() => move(7)}>Next week</button>\n</p>", "note": "The text is now built by a function. The `$:` statement contains one name, `describe`, which never changes."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week' --click 'Next week'
-- click Next week
-- click Next week
at /
title: 0 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 2 Nov 2026
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
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - button "13 Oct 2026, 60 min" [pressed]
    - listitem:
      - button "19 Oct 2026, 90 min" [pressed]
    - listitem:
      - button "24 Oct 2026, 60 min"
  - paragraph: 0 minutes for Linear algebra this week (0 h 0 min)
  - button "Add 30 minutes on 2 Nov 2026"
```

Two presses forward. **The week changed**: the page's total dropped to 0 because there are no
sessions planned for the 2nd of November, which is what the page received through `on:change`. **The
label did not**: it still says 19 October. The compiler looked at `$: shown = describe();`, found the
name `describe`, saw that nothing ever assigns to `describe`, and concluded that the statement never
needs to run again. It was wrong, and nothing told anybody.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two ways to find what a statement depends on. Above, Svelte 4: the compiler reads the text of $: shown = describe(), finds one name, describe, which never changes, and concludes the statement never needs to re-run; the reads of label and week inside the function are invisible to it. Below, Svelte 5: $derived(describe()) runs, and while it runs the function reads label and week, so both signals record it as a reader.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">Svelte 4: decided once, at build time, from the text</text><rect x=\"20\" y=\"36\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$: shown = describe();</text><line x1=\"250\" y1=\"56\" x2=\"318\" y2=\"56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,56.0 310.6,59.1 310.6,52.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"320\" y=\"36\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">names it contains:</text><text x=\"405\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">describe</text><line x1=\"490\" y1=\"56\" x2=\"538\" y2=\"56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,56.0 530.6,59.1 530.6,52.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"540\" y=\"36\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">never re-runs</text><rect x=\"320\" y=\"88\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">label, week: not seen</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Svelte 5: recorded while it runs</text><rect x=\"20\" y=\"164\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$derived(describe())</text><line x1=\"250\" y1=\"184\" x2=\"318\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,184.0 310.6,187.1 310.6,180.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"320\" y=\"164\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads while running:</text><text x=\"405\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">label, week</text><line x1=\"490\" y1=\"184\" x2=\"538\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,184.0 530.6,187.1 530.6,180.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"540\" y=\"164\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">re-runs when either changes</text><text x=\"360\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same function, same text: only the second sees inside it</text></svg>", "caption": "$: knew what a line looked like; a rune knows what it did."}
```

## The same function, under a rune

The runes version of that line is `let shown = $derived(describe());`, and it works, for the reason
lesson 2 drew: a derived value records what it read **while it runs**, and `describe` read `label`
and `week` when it ran. The reads inside the function count as much as reads written out in the
expression. **Runes track what code does; `$:` tracked what code looked like.**

That one difference is most of why Svelte 5 exists. `$:` was concise, and it was right for the
statements people wrote in tutorials. It was wrong for the statements people wrote a year into a
project, after the obvious refactorings, and it was wrong silently. Put `WeekNav.svelte` back to the
version in the previous section before the next one.
