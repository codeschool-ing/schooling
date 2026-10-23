---
title: $bindable, for the exception
version: 1
---

**`$bindable` is how a component says that a prop may be bound**, so that the parent can write
`bind:selected` and the child can assign to `selected` and have the parent see it. It is the same
two-way connection `bind:value` makes with an input, offered by a component of your own.

`CourseList` is a fair candidate. Its whole job is to choose one value, the selected course; the page
does nothing with a choice except store it; and the callback the page passes, `(id) => (selected =
id)`, is exactly what a binding does. Change the component:

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes, selected = $bindable() } = $props();\n</script>", "note": "`$bindable()` marks `selected` as a prop the parent may bind. There is no `onselect` any more."},
 {"code": "<ul>\n\t{#each courses as c}\n\t\t<li>\n\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t{minutes[c.id] ?? 0} min\n\t\t</li>\n\t{/each}\n</ul>", "note": "The button assigns to its own prop. With a binding in place, the assignment reaches the page's variable."}
]}
```

and in the page, the line that uses it becomes:

```html
<CourseList courses={data.courses} minutes={byCourse} bind:selected />
```

`bind:selected` is short for `bind:selected={selected}`, as `{selected}` was short for
`selected={selected}`.

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Guitar'
-- click Guitar
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
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar" [pressed]
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - heading "Guitar" [level=2]
  - list:
    - listitem:
      - checkbox "20 Oct 2026, 45 min"
      - text: 20 Oct 2026, 45 min
  - paragraph: 45 minutes for Guitar this week (0 h 45 min)
  - paragraph:
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session" [disabled]
```

## A binding has to be offered, and nothing says when it is not

Take `= $bindable()` out of `CourseList` for a moment, so the line reads
`let { courses, minutes, selected } = $props();`, and leave the page's `bind:selected` as it is:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Guitar'
console: [vite] connecting...
console: [vite] connected.
-- click Guitar
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
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar" [pressed]
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
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
  - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
  - paragraph:
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session" [disabled]
```

**The page and the list now disagree, and nothing complained.** The list shows Guitar pressed,
because the button assigned to the component's own `selected`, as a child may do with a prop; the page
still shows Linear algebra's sessions, because without `$bindable` that assignment never travels
upwards. There is no error and no warning in the console. A missing `$bindable` looks exactly like a
component that works, until the two halves of the page are compared, which is why it is worth
checking for both a binding and its `$bindable` whenever a selection "does not stick". Put the line
back.

## Choosing between a binding and a callback

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The planner page and its four child components. The page owns sessions, week and selected. WeekTotal receives minutes as a prop and sends nothing back. WeekNav receives week and calls onchange with the week it wants. AddSession calls onadd with a date and minutes, and the page decides what a session is. CourseList is bound to selected, so its assignment travels up into the page&#x27;s variable.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">+page.svelte</text><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">owns: sessions, week, selected</text><rect x=\"20\" y=\"190\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekTotal</text><line x1=\"85\" y1=\"92\" x2=\"85\" y2=\"186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"85.0,186.0 81.9,178.6 88.1,178.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"79\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"195\" y=\"190\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekNav</text><line x1=\"260\" y1=\"92\" x2=\"260\" y2=\"186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,186.0 256.9,178.6 263.1,178.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"254\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">week</text><line x1=\"284\" y1=\"188\" x2=\"284\" y2=\"94\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"284.0,94.0 287.1,101.4 280.9,101.4\" fill=\"var(--amber)\"></polygon><text x=\"290\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">onchange(next)</text><rect x=\"370\" y=\"190\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">AddSession</text><line x1=\"459\" y1=\"188\" x2=\"459\" y2=\"94\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"459.0,94.0 462.1,101.4 455.9,101.4\" fill=\"var(--amber)\"></polygon><text x=\"465\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">onadd({ date, minutes })</text><rect x=\"545\" y=\"190\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseList</text><line x1=\"612\" y1=\"92\" x2=\"612\" y2=\"186\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"612.0,186.0 608.9,178.6 615.1,178.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"632\" y1=\"188\" x2=\"632\" y2=\"94\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"632.0,94.0 635.1,101.4 628.9,101.4\" fill=\"var(--phosphor)\"></polygon><text x=\"606\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bind:selected</text><text x=\"20\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grey: a prop, down</text><text x=\"240\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">amber: a callback, up</text><text x=\"470\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">blue: a binding, both ways</text></svg>", "caption": "Data down, choices up, and one binding where the child's whole job is to edit a value."}
```

| | bind | callback |
|---|---|---|
| the child's job | edit one value, like a field does | report an event: something was chosen, added, moved |
| what the parent does with it | stores it, nothing else | decides: may add, refuse, change something else as well |
| who can tell what happened | the parent sees a new value, not why | the parent receives exactly what was asked |
| in the planner | `CourseList`'s `selected` | `WeekNav`'s `onchange`, `AddSession`'s `onadd` |

`WeekNav` could have been bound too, and nothing would break today. It stays a callback because moving
the week is the kind of thing a page later wants a say in, such as refusing to go more than a year
ahead, and a callback is where that check goes. `AddSession` must stay
a callback, because adding a session is the page's decision, as the previous section showed.
