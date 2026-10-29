---
title: The contract between two components
version: 1
---

**Props and emits together are a component's public contract: what it must be given, and what it can
report.** Everything else about it, its refs, its computed values, its markup, is private and can change
without anybody else noticing. A component whose contract is clear can be moved, reused and tested on
its own, and lesson 21 tests the planner's components through exactly this contract.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"App at the top owns the sessions. Arrows labelled props go down to two children, CourseCard, which is given a title and three numbers, and SessionRow, which is given a session and a title. An arrow labelled event goes up from SessionRow to App, carrying toggle and an id. App then replaces its list, and the new values flow down again as props.\"><rect x=\"250\" y=\"15\" width=\"220\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">App.vue</text><text x=\"360\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">owns the sessions</text><rect x=\"60\" y=\"170\" width=\"220\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">CourseCard</text><text x=\"170\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">draws, owns nothing</text><rect x=\"440\" y=\"170\" width=\"220\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">SessionRow</text><text x=\"550\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">draws, and reports a tick</text><line x1=\"300\" y1=\"77\" x2=\"190\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"190.0,168.0 193.7,160.9 197.7,165.7\" fill=\"var(--phosphor)\"></polygon><text x=\"150\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">props</text><text x=\"150\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">title, goal, planned, done</text><line x1=\"395\" y1=\"77\" x2=\"500\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"500.0,168.0 492.4,165.5 496.5,160.8\" fill=\"var(--phosphor)\"></polygon><text x=\"436\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">props</text><text x=\"436\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">session, title</text><line x1=\"600\" y1=\"168\" x2=\"470\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></line><polygon points=\"470.0,60.0 477.7,62.3 473.7,67.1\" fill=\"var(--amber)\"></polygon><text x=\"612\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">event</text><text x=\"612\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">toggle('s5')</text></svg>", "caption": "Data goes down as props; news comes up as events, to whoever owns the data."}
```

The figure is the shape of every Vue application: state lives as high as it needs to, flows down
through props, and comes back up as events to the component that owns it. `App.vue` owns the planner's
sessions; when a `SessionRow` is ticked, it says `toggle` with an id, and `App` replaces the list. The
row never touches the list.

## What is not in the contract falls through

An attribute the child did not declare as a prop, nor as an event, is not lost: Vue puts it on the
child's root element. That is called a **fallthrough attribute**, and it is how a parent adds a class,
an `id` or an `aria-` attribute to a component without the component having to know.

```html
<!-- src/demos/Fallthrough.vue -->
<script setup>
import GoalBar from './GoalBar.vue'
</script>

<template>
  <GoalBar label="Statistics" :minutes="45" id="stats" class="wide" aria-describedby="help" />
  <p id="help">Minutes this week.</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Fallthrough' --html p --text -
[vite] connecting...
[vite] connected.
Statistics: minutes is a number
== the HTML of p
<p id="stats" class="wide" aria-describedby="help">Statistics: 45 of 60 minutes</p>
```

`id`, `class` and `aria-describedby` landed on the `<p>` that is `GoalBar`'s root, beside the props it
did declare. The accessibility attribute is the important one: the parent knows that a help text sits
beside the bar, and the bar did not need a prop for it.

Three details complete the rule:

- **`class` and `style` merge** with the root's own, rather than replacing them.
- **A component with several root elements has no single place to put them**, so Vue warns and puts them
  nowhere, unless the component says where with `v-bind="$attrs"` on one of its elements.
- **`defineOptions({ inheritAttrs: false })`** turns it off, for a component that wants to place them
  itself: a labelled input whose root is a `<label>` but whose attributes belong on the `<input>`
  inside.

## Writing a contract worth having

| ask of a component | a good answer |
|---|---|
| what does it need? | the fewest props that let it draw itself: an id and a title, not the whole application's state |
| what can it report? | events named for what the student did, with the detail the parent needs and no more |
| who owns the data it shows? | somebody above it, always; it may hold state only about itself, a hover or a draft |

A component that needs eight props is two components, or is being given state it should have asked for
by id. A component that emits an event for every keystroke is probably a form field, which is the next
section.
