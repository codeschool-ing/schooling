---
title: $derived
version: 1
---

**`$derived` declares a value computed from other values, and keeps it up to date by itself.** The
planner needs three: the sessions in the week being shown, their total, and the minutes for each
course. Each depends on `week`, and none should ever be assigned by hand. This version of
`+page.svelte` adds them:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\n\tlet week = $state(mondayOf(data.sessions.at(-1).date));", "note": "`inWeek` joins the imports."},
 {"code": "\tlet thisWeek = $derived(data.sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));", "note": "An expression in `$derived(…)` is recalculated when something it read changes. `thisWeek` reads `week`."},
 {"code": "\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>", "note": "`$derived.by` takes a function, for a value that needs more than one expression to compute."},
 {"code": "\t<ul>\n\t\t{#each data.courses as course}\n\t\t\t<li>{course.name}: {byCourse[course.id] ?? 0} min</li>\n\t\t{/each}\n\t</ul>\n\t<p>{total} minutes this week</p>\n</main>", "note": "The markup reads the derived values like any variable."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week'
-- click Previous week
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem: "Linear algebra: 60 min"
    - listitem: "Spanish: 30 min"
    - listitem: "Guitar: 0 min"
  - paragraph: 90 minutes this week
```

The week of 12 October has an hour of algebra and half an hour of Spanish, and the total follows.
Nothing in the button's handler mentions `total`: it sets `week`, `thisWeek` depended on `week`,
`total` and `byCourse` depended on `thisWeek`, and the chain did the rest.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The chain of values in the planner page. week is state. thisWeek is derived from week and the sessions. total and byCourse are both derived from thisWeek. The markup reads total, byCourse and week. Pressing Previous week sets week, and the change travels along the chain to the label, the course minutes and the total.\"><rect x=\"20\" y=\"40\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">week</text><text x=\"80.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$state</text><rect x=\"20\" y=\"140\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sessions</text><text x=\"80.0\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">data</text><rect x=\"200\" y=\"90\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">thisWeek</text><text x=\"265.0\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$derived</text><rect x=\"390\" y=\"40\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">total</text><text x=\"455.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$derived</text><rect x=\"390\" y=\"140\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">byCourse</text><text x=\"455.0\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$derived.by</text><rect x=\"580\" y=\"40\" width=\"120\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the markup</text><text x=\"640\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Week of …</text><text x=\"640\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">… min</text><text x=\"640\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">… minutes</text><line x1=\"140\" y1=\"65\" x2=\"198\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,108.0 190.2,106.1 193.9,101.1\" fill=\"var(--phosphor)\"></polygon><line x1=\"140\" y1=\"165\" x2=\"198\" y2=\"122\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,122.0 193.9,128.9 190.2,123.9\" fill=\"var(--wire)\"></polygon><line x1=\"330\" y1=\"108\" x2=\"388\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"388.0,68.0 383.7,74.7 380.2,69.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"330\" y1=\"122\" x2=\"388\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"388.0,160.0 380.1,158.6 383.5,153.4\" fill=\"var(--phosphor)\"></polygon><line x1=\"520\" y1=\"65\" x2=\"578\" y2=\"155\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,155.0 571.4,150.5 576.6,147.1\" fill=\"var(--phosphor)\"></polygon><line x1=\"520\" y1=\"165\" x2=\"578\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,125.0 573.7,131.7 570.2,126.6\" fill=\"var(--phosphor)\"></polygon><path d=\"M80 40 C 80 15, 600 10, 620 36\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"617\" y1=\"32\" x2=\"621\" y2=\"38\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"621.0,38.0 614.3,33.6 619.5,30.1\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a button sets week; everything downstream is recalculated when next read</text></svg>", "caption": "Only week is set by hand. Every other value on the way to the screen is derived from it."}
```

## Three properties of a derived value

**It is lazy.** A derived value is not recalculated the moment something it read changes. It is
marked out of date, and recalculated the next time somebody reads it. If nobody reads it, it costs
nothing.

**It is remembered.** Read `total` ten times in the markup and it is calculated once, until
something it depends on changes. That is what `useMemo` does in React, except that here it is the
default and there is no list of dependencies to keep right: the reads are the list, exactly as for an
effect in lesson 2.

**It is not for side effects.** The expression should compute a value and do nothing else: no
`fetch`, no assignment to other state, no writing to the page. If something should *happen* when a
value changes, that is an effect, and the section after next is about when you really need one.

## `$derived` against a function

`byCourse[course.id]` could have been a function, `minutesFor(course)`, called from the markup. That
works too, and it is not wrong. The difference is that a function call in the markup runs every time
that piece of markup updates, and a derived value runs once per change and is shared by every reader.
For a calculation over six sessions you will not see the difference. **Prefer `$derived` when a value
has a name**, because the name documents it and the rune makes it cheap.
